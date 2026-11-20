####    Lazy data descriptors    ####

abstract type AbstractLazyData end

"""
	LazyArray(filnam, mtime, begpos, hdu_type, format, fields, keywds, mapped)

The data of an image-like HDU (Primary, Image or Conform), memory-mapped from its file when the HDU
is read. `mapped` reads each value from the file when it is indexed, so the array reads the file as
it is then, and becomes invalid if the file is truncated.
"""
struct LazyArray{T, N, M <: AbstractArray{T, N}} <: AbstractArray{T, N}
    "File name"
    filnam::String
    "Modification time"
    mtime::Float64
    "Beginning file position"
    begpos::Int64
    "HDU type"
    hdu_type::Type
    "Array format"
    format::DataFormat
    "Field formats"
    fields::Any
    "HDU keywords"
    keywds::NamedTuple
    "The mapped values"
    mapped::M
end

"""
	LazyStructuredData(filnam, mtime, begpos, hdu_type, format, fields, keywds, record, bytes)

The data of a Random, Table or Bintable HDU, whose data unit `bytes` is memory-mapped from its file
when the HDU is read. A field is read from the file when it is indexed, so the data become invalid
if the file is truncated.
"""
struct LazyStructuredData <: AbstractLazyData
    filnam::String
    mtime::Float64
    begpos::Int64
    hdu_type::Type
    format::DataFormat
    fields::Vector
    keywds::NamedTuple
    record::Bool
    bytes::Vector{UInt8}
end

const LAZY_STRUCTURED_INTERNALS =
    (:filnam, :mtime, :begpos, :hdu_type, :format, :fields, :keywds, :record, :bytes)

function lazydata(
        hdu_type::Type, filnam::AbstractString, mtime::Real,
        begpos::Integer, format::DataFormat, fields, keywds::NamedTuple
    )

    scale = get(keywds, :scale, true)
    return open(filnam, "r") do io
        if hdu_type in (Primary, Image, Conform)
            R = format.type
            values = Mmap.mmap(io, Vector{R}, data_padded_nbytes(format) ÷ sizeof(R), begpos)
            field = fields isa AbstractVector ? first(fields) : fields
            shape = Tuple(Int.(format.shape))
            strides = cumprod((1, shape...))[1:(end - 1)]
            blank = hasproperty(field, :miss) ? field.miss : nothing
            mapped = MappedField(values, firstindex(values), shape, strides, field, scale; blank)
            LazyArray{eltype(mapped), length(shape), typeof(mapped)}(
                String(filnam), Float64(mtime), Int64(begpos), hdu_type, format, fields, keywds, mapped
            )
        else
            bytes = Mmap.mmap(io, Vector{UInt8}, data_padded_nbytes(format), begpos)
            LazyStructuredData(
                String(filnam), Float64(mtime), Int64(begpos), hdu_type, format, Vector(fields),
                keywds, get(keywds, :record, false), bytes
            )
        end
    end
end

lazy_format(data::Union{LazyArray, LazyStructuredData}) = getfield(data, :format)
lazy_fields(data::Union{LazyArray, LazyStructuredData}) = getfield(data, :fields)

function open_lazy_source(data::Union{LazyArray, LazyStructuredData})
    isfile(getfield(data, :filnam)) || error("Lazy FITS source no longer exists: $(getfield(data, :filnam))")
    mtime = stat(getfield(data, :filnam)).mtime
    mtime == getfield(data, :mtime) ||
        error("Lazy FITS source has changed since it was read: $(getfield(data, :filnam))")
    return open(getfield(data, :filnam), "r")
end

function read_bigendian(io::IO, type::Type)
    return type <: Bool ? read(io, type) : ntoh(read(io, type))
end

# Whether `field` scales its values: it has a zero point and a scale, and they are not 0 and 1.
# A field without them (`ConformField`, or a logical, bit or string column) keeps its values,
# and so does one with the identity, which keeps an integer field an integer.
function _has_active_scaling(field, scale::Bool)
    scale && hasproperty(field, :zero) || return false
    zero, factor = field.zero, field.scale
    return !isnothing(zero) && !ismissing(zero) && !(iszero(zero) && isone(factor))
end

function scale_value(value, field, scale::Bool)
    return if _has_active_scaling(field, scale)
        getproperty(field, :zero) + getproperty(field, :scale) * value
    else
        value
    end
end

function lazy_eltype(type::Type, field, scale::Bool)
    return if type <: AbstractString
        String
    elseif type <: BitVector
        BitVector
    elseif _has_active_scaling(field, scale)
        typeof(getproperty(field, :zero) + getproperty(field, :scale) * zero(type))
    else
        type
    end
end

function scaled_values(values, field, scale::Bool)
    return if _has_active_scaling(field, scale)
        getproperty(field, :zero) .+ getproperty(field, :scale) .* values
    else
        values
    end
end

"""
    StridedField{R, S}

Where a field of fixed-width numbers of type `R` lies in a data unit of
fixed-size rows: row `r` starts `begpos + (r - 1) * rowbytes` bytes into the
source and the field `offset` bytes into the row. Values are scaled to
`zero + scale * value` unless `zero` and `scale` are `nothing`.
"""
struct StridedField{R, S}
    begpos::Int
    rowbytes::Int
    offset::Int
    zero::S
    scale::S
end

# The field in the rows of `data`'s mapped data unit.
function StridedField(data::LazyStructuredData, field)
    format = getfield(data, :format)
    rowbytes = getfield(data, :hdu_type) == Random ?
        sizeof(format.type) * (format.param + prod(format.shape)) : format.shape[1]
    return StridedField(0, rowbytes, field, get(getfield(data, :keywds), :scale, true))
end

function StridedField(begpos::Integer, rowbytes::Integer, field, scale::Bool)
    zero, factor = _has_active_scaling(field, scale) ? promote(field.zero, field.scale) : (nothing, nothing)
    return StridedField{field.type, typeof(zero)}(begpos, rowbytes, first(field.slice) - 1, zero, factor)
end

const STRIDED_CHUNK_BYTES = 1 << 23

# `out[j, k]` set to value `inner[k]` of `field` in row `rows[j]`, reading the
# rows in contiguous chunks of about `chunkbytes`.
function read_strided!(
        io::IO, out::AbstractMatrix, field::StridedField{R}, rows::AbstractUnitRange,
        inner::AbstractUnitRange; chunkbytes::Integer = STRIDED_CHUNK_BYTES
    ) where {R}
    nchunk = max(1, chunkbytes ÷ field.rowbytes)
    bytes = Vector{UInt8}(undef, min(length(rows), nchunk) * field.rowbytes)
    values = Vector{R}(undef, length(inner))
    raw = reinterpret(UInt8, values)
    start = field.offset + (first(inner) - 1) * sizeof(R)
    for chunk in Iterators.partition(eachindex(rows), nchunk)
        seek(io, field.begpos + (rows[first(chunk)] - 1) * field.rowbytes)
        n = length(chunk) * field.rowbytes
        readbytes!(io, bytes, n) == n || throw(EOFError())
        for (m, j) in enumerate(chunk)
            copyto!(raw, 1, bytes, (m - 1) * field.rowbytes + start + 1, length(raw))
            for (k, x) in zip(axes(out, 2), values)
                out[j - first(eachindex(rows)) + firstindex(out, 1), k] =
                    isnothing(field.zero) ? ntoh(x) : field.zero + field.scale * ntoh(x)
            end
        end
    end
    return out
end

# `read_strided!` from `bytes`, a mapped data unit, copying only the values `inner` of each row.
# Each chunk's pages are released once it is decoded, so about `chunkbytes` of the file stays
# mapped however many rows are read.
function read_mapped!(
        bytes::Vector{UInt8}, out::AbstractMatrix, field::StridedField{R}, rows::AbstractUnitRange,
        inner::AbstractUnitRange; chunkbytes::Integer = STRIDED_CHUNK_BYTES
    ) where {R}
    nchunk = max(1, chunkbytes ÷ field.rowbytes)
    values = Vector{R}(undef, length(inner))
    raw = reinterpret(UInt8, values)
    start = field.begpos + field.offset + (first(inner) - 1) * sizeof(R)
    for chunk in Iterators.partition(eachindex(rows), nchunk)
        for j in chunk
            copyto!(raw, 1, bytes, (rows[j] - 1) * field.rowbytes + start + 1, length(raw))
            for (k, x) in zip(axes(out, 2), values)
                out[j - first(eachindex(rows)) + firstindex(out, 1), k] =
                    isnothing(field.zero) ? ntoh(x) : field.zero + field.scale * ntoh(x)
            end
        end
        release_pages(bytes, field.begpos + (rows[first(chunk)] - 1) * field.rowbytes,
            length(chunk) * field.rowbytes)
    end
    return out
end

# Unmaps bytes `pos + 1:pos + n` of the read-only mapping `bytes`. The mapping stays valid: a later
# read refaults the pages from the file.
function release_pages(bytes::Vector{UInt8}, pos::Integer, n::Integer)
    checkbounds(bytes, (pos + 1):(pos + n))
    @static if Sys.isunix()
        GC.@preserve bytes Mmap.madvise!(unsafe_wrap(Array, pointer(bytes, pos + 1), n), Mmap.MADV_DONTNEED)
    end
    return nothing
end

data_nbytes(format::DataFormat) = sizeof(format.type) * format.leng
data_padded_nbytes(format::DataFormat) = BLOCKLEN * div(data_nbytes(format), BLOCKLEN, RoundUp)

copy_lazy_data_block(io::IO, data::LazyArray) = write(io, data.mapped.values)
copy_lazy_data_block(io::IO, data::LazyStructuredData) = write(io, getfield(data, :bytes))

function materialize_lazy_data(data::LazyArray)
    io = open_lazy_source(data)
    return try
        seek(io, getfield(data, :begpos))
        read(io, getfield(data, :hdu_type), getfield(data, :format), getfield(data, :fields); getfield(data, :keywds)...)
    finally
        close(io)
    end
end

materialize_lazy_data(data::LazyStructuredData) =
    read(IOBuffer(getfield(data, :bytes)), getfield(data, :hdu_type), getfield(data, :format), getfield(data, :fields); getfield(data, :keywds)...)

Base.read(data::Union{LazyArray, LazyStructuredData}) = materialize_lazy_data(data)

####    Image-like lazy arrays    ####

Base.size(data::LazyArray) = size(data.mapped)
Base.@propagate_inbounds Base.getindex(data::LazyArray{T, N}, I::Vararg{Int, N}) where {T, N} =
    data.mapped[I...]

####    Structured lazy data    ####

function field_name(field)
    return Symbol(rstrip(String(field.name)))
end

function field_groups(data::LazyStructuredData)
    names = field_name.(getfield(data, :fields))
    return [name => findall(==(name), names) for name in unique(names)]
end

Base.keys(data::LazyStructuredData) = Tuple(first.(field_groups(data)))
Base.values(data::LazyStructuredData) = map(name -> data[name], keys(data))
Base.pairs(data::LazyStructuredData) = pairs(NamedTuple{keys(data)}(values(data)))
Base.haskey(data::LazyStructuredData, name::Symbol) = name in keys(data)

# Iterates as the data it stands for: the rows of record data, otherwise the columns.
Base.iterate(data::LazyStructuredData, index = 1) =
    index > length(data) ? nothing : (data[index], index + 1)

Base.:(==)(a::LazyStructuredData, b::Union{NamedTuple, AbstractVector}) = read(a) == b
Base.:(==)(a::Union{NamedTuple, AbstractVector}, b::LazyStructuredData) = b == a
Base.:(==)(a::LazyStructuredData, b::LazyStructuredData) = read(a) == read(b)

function Base.propertynames(data::LazyStructuredData, private::Bool = false)
    names = keys(data)
    return private ? (LAZY_STRUCTURED_INTERNALS..., names...) : names
end

Base.hasproperty(data::LazyStructuredData, name::Symbol) =
    name in propertynames(data, true)

function Base.length(data::LazyStructuredData)
    return getfield(data, :record) ? structured_nrows(data) : length(keys(data))
end

function structured_nrows(data::LazyStructuredData)
    return if getfield(data, :hdu_type) == Random
        getfield(data, :format).group
    else
        length(getfield(data, :format).shape) >= 2 ? getfield(data, :format).shape[2] : 0
    end
end

# Whether `field` holds fixed-width numbers at the same place in every row.
is_strided(data::LazyStructuredData, field) = getfield(data, :hdu_type) == Random ||
    (getfield(data, :hdu_type) == Bintable && is_strided(field))

"""
    MappedColumn{T, N, R, S} <: AbstractArray{T, N}

A binary-table column of fixed-width numbers read in place from `bytes`, the mapped data unit of
its table, where `field` lies. A column of one value per row is a vector, otherwise a
`rows × values` matrix. Indexing by ranges, and `collect`, copy a row at a time; a reduction over
the whole column visits it in column-major order, a row apart per value, and is faster on
`collect(column)`.
"""
struct MappedColumn{T, N, R, S} <: AbstractArray{T, N}
    bytes::Vector{UInt8}
    field::StridedField{R, S}
    dims::NTuple{N, Int}
end

function MappedColumn(data::LazyStructuredData, field)
    strided = StridedField(data, field)
    nrows = structured_nrows(data)
    dims = field.leng == 1 ? (nrows,) : (nrows, Int(field.leng))
    T = lazy_eltype(field.type, field, get(getfield(data, :keywds), :scale, true))
    return MappedColumn{T, length(dims), field.type, typeof(strided.zero)}(getfield(data, :bytes), strided, dims)
end

Base.size(c::MappedColumn) = c.dims

@inline function Base.getindex(c::MappedColumn{T, N, R}, r::Int, k::Vararg{Int}) where {T, N, R}
    @boundscheck checkbounds(c, r, k...)
    f = c.field
    pos = f.begpos + (r - 1) * f.rowbytes + f.offset + (N == 1 ? 0 : (only(k) - 1) * sizeof(R))
    x = ntoh(reinterpret(R, ntuple(i -> c.bytes[pos + i], Val(sizeof(R)))))
    return isnothing(f.zero) ? x : f.zero + f.scale * x
end

# Rows `rows` and values `inner` of the column.
function column_block(c::MappedColumn{T}, rows::AbstractUnitRange, inner::AbstractUnitRange) where {T}
    return read_mapped!(c.bytes, Matrix{T}(undef, length(rows), length(inner)), c.field, rows, inner)
end

Base.getindex(c::MappedColumn{T, 1}, rows::Union{Colon, AbstractUnitRange{<:Integer}}) where {T} =
    vec(column_block(c, only(to_indices(c, (rows,))), 1:1))
Base.getindex(c::MappedColumn{T, 2}, rows::Union{Colon, AbstractUnitRange{<:Integer}},
    inner::Union{Colon, AbstractUnitRange{<:Integer}}) where {T} = column_block(c, to_indices(c, (rows, inner))...)
Base.collect(c::MappedColumn) = c[ntuple(_ -> Colon(), ndims(c))...]

"""
    ParsedColumn{T, F} <: AbstractVector{T}

A table column whose rows are parsed one at a time from `parent`'s mapped data unit: strings,
logicals, bits and variable-length arrays of a binary table, and every column of an ASCII table.
"""
struct ParsedColumn{T, F} <: AbstractVector{T}
    parent::LazyStructuredData
    field::F
end

ParsedColumn(data::LazyStructuredData, field) =
    ParsedColumn{field_eltype(data, field), typeof(field)}(data, field)

function field_eltype(data::LazyStructuredData, field)
    T = lazy_eltype(field.type, field, get(getfield(data, :keywds), :scale, true))
    type = getfield(data, :hdu_type)
    #  A blank or null number of an ASCII table is missing.
    type == Table && !(T <: AbstractString) && return Union{Missing, T}
    return type == Bintable && !isnothing(field.pntr) ? Vector{T} : T
end

Base.size(c::ParsedColumn) = (structured_nrows(c.parent),)

function Base.getindex(c::ParsedColumn, r::Int)
    @boundscheck checkbounds(c, r)
    io = IOBuffer(getfield(c.parent, :bytes))
    return getfield(c.parent, :hdu_type) == Bintable ?
        read_bintable_value(io, c.parent, c.field, r) : read_table_value(io, c.parent, c.field, r)
end

# The column of `fields`, the fields of one name.
function column(data::LazyStructuredData, fields::Vector)
    getfield(data, :hdu_type) == Random && return mapdata(data)[field_name(first(fields))]
    field = first(fields)
    return is_strided(data, field) ? MappedColumn(data, field) : ParsedColumn(data, field)
end

function Base.getindex(data::LazyStructuredData, name::Union{Symbol, AbstractString})
    sym = name isa Symbol ? name : Symbol(rstrip(String(name)))
    groups = Dict(field_groups(data))
    haskey(groups, sym) || throw(KeyError(name))
    return column(data, getfield(data, :fields)[groups[sym]])
end

function Base.getindex(data::LazyStructuredData, index::Integer)
    return if getfield(data, :record)
        read_lazy_row(data, index)
    else
        data[collect(keys(data))[index]]
    end
end

# A column is a property, and so are the internals that no column shares a name with.
function Base.getproperty(data::LazyStructuredData, name::Symbol)
    return name in keys(data) ? data[name] : getfield(data, name)
end

# Positions are relative to the start of the data unit, which `io` holds.
function read_bintable_value(io::IO, data::LazyStructuredData, field, row::Integer)
    L, M = getfield(data, :format).shape[1], first(field.slice) - 1
    seek(io, L * (row - 1) + M)
    return if !isnothing(field.pntr)
        K = read_bigendian(io, field.pntr)
        beg = read_bigendian(io, field.pntr)
        seek(io, getfield(data, :format).heap + beg)
        values = [read_bigendian(io, field.type) for _ in 1:K]
        scaled_values(values, field, get(getfield(data, :keywds), :scale, true))
    elseif field.type <: AbstractString
        rstrip(field.type(read(io, length(field.slice))))
    elseif field.type <: BitVector
        read(io, BitVector, field.leng)
    else
        scale_value(read_bigendian(io, field.type), field, get(getfield(data, :keywds), :scale, true))
    end
end

function read_table_value(io::IO, data::LazyStructuredData, field, row::Integer)
    L, M, leng = getfield(data, :format).shape[1], first(field.slice) - 1, length(field.slice)
    seek(io, L * (row - 1) + M)
    item = String(read(io, leng))
    return if field.type <: AbstractString
        rstrip(item)
    elseif (!isnothing(field.null) && field.null == item) ||
            item == repeat(' ', leng) || leng <= 0
        missing
    else
        value = Base.parse(field.type, replace(item, "D" => "e", "E" => "e"))
        scale_value(value, field, get(getfield(data, :keywds), :scale, true))
    end
end

function read_lazy_row(data::LazyStructuredData, row::Integer)
    (1 <= row <= structured_nrows(data)) || throw(BoundsError(data, row))
    return (; (name => row_value(data[name], row) for (name, _) in field_groups(data))...)
end

row_value(c::AbstractArray, r) = c[r, ntuple(_ -> Colon(), ndims(c) - 1)...]

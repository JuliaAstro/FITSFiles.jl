####    Memory-mapped image and random-groups data    ####

"""
    MappedField{T, N, R, A, S, B} <: AbstractArray{T, N}

An image, or one field of random-groups data, read in place from `values`, the
data unit's values of type `R` in file (big-endian) byte order, such as a memory
map of the file. Element `I` is the value at `offset + Σ (I - 1) .* strides`,
byte-swapped and, unless `zero` and `scale` are `nothing`, scaled to
`zero + scale * value`. A stored value equal to `blank` (an image's BLANK) is
`missing`. A random-groups field is record-first, as `read` returns it.
"""
struct MappedField{T, N, R, A <: AbstractVector{R}, S, B} <: AbstractArray{T, N}
    values::A
    offset::Int
    size::NTuple{N, Int}
    strides::NTuple{N, Int}
    zero::S
    scale::S
    blank::B
end

function MappedField(
        values::AbstractVector{R}, offset::Integer, size::Tuple, strides::Tuple, field, scale::Bool;
        blank = nothing
    ) where {R}
    zero, factor = _has_active_scaling(field, scale) ? promote(field.zero, field.scale) : (nothing, nothing)
    S = lazy_eltype(R, field, scale)
    T = isnothing(blank) ? S : Union{Missing, S}
    blank = isnothing(blank) ? nothing : convert(R, blank)
    return MappedField{T, length(size), R, typeof(values), typeof(zero), typeof(blank)}(
        values, offset, size, strides, zero, factor, blank
    )
end

function MappedField(values::AbstractVector{R}, format::DataFormat, field::RandomField, scale::Bool) where {R}
    shape = field.leng == 1 ? () : Tuple(field.shape)
    size = (Int(format.group), shape...)
    strides = (Int(format.param) + prod(format.shape), cumprod((1, shape...))[1:(end - 1)]...)
    offset = firstindex(values) + (first(field.slice) - 1) ÷ sizeof(R)
    return MappedField(values, offset, size, strides, field, scale)
end

Base.size(m::MappedField) = m.size

@inline function Base.getindex(m::MappedField{T, N}, I::Vararg{Int, N}) where {T, N}
    @boundscheck checkbounds(m, I...)
    x = ntoh(m.values[m.offset + sum(map((i, s) -> (i - 1) * s, I, m.strides))])
    isnothing(m.blank) || x != m.blank || return missing
    return isnothing(m.zero) ? x : m.zero + m.scale * x
end

"""
    MappedColumns{T, C} <: AbstractMatrix{T}

Random-groups parameters that share one name, as the `group × k` matrix that
`read` returns for them: column `j` is `columns[j]`.
"""
struct MappedColumns{T, C <: Tuple} <: AbstractMatrix{T}
    columns::C
end

MappedColumns(columns::Tuple) = MappedColumns{promote_type(map(eltype, columns)...), typeof(columns)}(columns)

Base.size(m::MappedColumns) = (length(first(m.columns)), length(m.columns))

@inline function Base.getindex(m::MappedColumns{T}, i::Int, j::Int) where {T}
    @boundscheck checkbounds(m, i, j)
    return convert(T, m.columns[j][i])
end

# The fields of random-groups data read from `values`, by name as `read`
# returns them: one array per name, a `MappedColumns` for a repeated name.
function mapped_fields(values::AbstractVector, format::DataFormat, fields, scale::Bool)
    names = [field.name for field in fields]
    return (;
        [
            Symbol(name) => begin
                    ndx = findall(==(name), names)
                    mapped = map(f -> MappedField(values, format, f, scale), fields[ndx])
                    length(ndx) == 1 ? only(mapped) : MappedColumns(Tuple(mapped))
                end
                for name in unique(names)
        ]...,
    )
end

random_values(format::DataFormat) = Int(format.group) * (Int(format.param) + prod(format.shape))

"""
    mapdata(data)

The random-groups data `data` (the lazy data of a Random HDU, as `fits` reads
it) read in place from its memory-mapped data unit: a NamedTuple keyed and shaped
as `read(data)` returns it, whose arrays read each value from the file when it is
indexed. Indexing reads the file as it is then; the arrays become invalid if the
file is truncated.
"""
mapdata(data::LazyStructuredData) = mapped_fields(
    reinterpret(getfield(data, :format).type, getfield(data, :bytes)), getfield(data, :format), getfield(data, :fields), get(getfield(data, :keywds), :scale, true)
)

Base.read(c::Union{MappedField, MappedColumns, MappedColumn, ParsedColumn}) = collect(c)

row_value(c::MappedColumns, r) = permutedims(c[r, :])

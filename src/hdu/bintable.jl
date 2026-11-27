####    Bintable HDU functions

"""
	Bintable header-data unit (HDU)

A Bintable HDU consists of a vector of cards and optionally a 2-dimensional
array of binary data structured as a vector of records.
"""
struct Bintable <: AbstractHDU end

#  The data of a Bintable HDU are tuples, or named tuples, of the fields
fromdata(::Type{Bintable}, data) = firstrecord(data) !== nothing
frommandatory(::Type{Bintable}, mankeys) = isequal(xtensionvalue(mankeys), "BINTABLE")
registerhdu!(Bintable)

#  The maximum number of fields of the table (Sect. 7.3.1)
const MAXBINTABLEFIELDS = 999

#  The mandatory and reserved keywords of the HDU (see `getreservedkeys`)
union!(MANDATORYKEYS, ["XTENSION", "PCOUNT", "GCOUNT", "THEAP", "TFIELDS", "TFORM"])
union!(RESERVEDKEYS, ["INHERIT", "TFIELDS", "TFORM", "TSCAL", "TZERO", "TNULL", "TTYPE", "TUNIT", "TDISP", "TDIM",
    "TDMAX", "TDMIN", "TLMAX", "TLMIN"])

#  The fill after the data (see `verifyfill`)
fillrule(::Type{Bintable}) = (0x00, "zeros", "Sect. 7.3.3")

const BINARYFMT = Regex(
    "(?<r>\\d*)(?<p>[PQ]?)(?<t>[LXBIJKAEDCM])\\(?(?<a>\\w*)\\)?")

const BINARYTYPE = Dict(
    #  character to type
    "L" => Bool, "X" => BitVector, "B" => UInt8, "I" => Int16, "J" => Int32,
    "K" => Int64, "A" => String, "E" => Float32, "D" => Float64,
    "C" => ComplexF32, "M" => ComplexF64,
    #  type to character
    Bool => "L", BitVector => "X", UInt8 => "B", Int16 => "I", Int32 => "J",
    Int64 => "K", String => "A", Float32 => "E", Float64 => "D",
    ComplexF32 => "C", ComplexF64 => "M")

const POINTERTYPE = Dict("P" => Int32, "Q" => Int64, Int32 => "P", Int64 => "Q")

"""
    BinaryField(name, pntr, type, slice, leng, supp, unit, disp, dims,
        zero, scale, null, dmin, dmax, lmin, lmax)

Binary array element descriptor
"""
struct BinaryField <: AbstractField
    "The name of the field"
    name::String
    "The type of variable array pointer "
    pntr::Union{Type, Nothing}
    "The tye of the field"
    type::Type
    "The slice of the field from start of record"
    slice::UnitRange{Int}
    "The number of elements in the field"
    leng::Int
    "The supplmental information of the field"
    supp::String
    #  optional fields
    "The unit of the field"
    unit::String
    "The display format of the field"
    disp::String
    "The dimension of the field"
    dims::Union{Tuple{Vararg{Int}}, Nothing}
    "The offset of the field"
    zero::Union{AbstractFloat, Nothing}
    "The scale of the field"
    scale::Union{AbstractFloat, Nothing}
    "The missing value of the field"
    null::Union{Int, Nothing}
    "The minimum raw value of the field"
    dmin::Union{AbstractFloat, Nothing}
    "The maximum raw value of the field"
    dmax::Union{AbstractFloat, Nothing}
    "The minimum physical value of the field"
    lmin::Union{AbstractFloat, Nothing}
    "The maximum physical value of the field"
    lmax::Union{AbstractFloat, Nothing}
end

"""
    parsedims(value, j)

Return the dimensions of the TDIM`j` keyword as a tuple of integers, or `nothing` if there is no
keyword. The value is a character string of the form `(l,m,n...)` (Sect. 7.3.2 of the standard), where
`l`, `m`, `n`, ... are the dimensions, and a single dimension, `(l)`, is the tuple `(l,)`. A value that is
not of this form is not read: it gives a warning and `nothing`, and the keyword stays in the header
unchanged.
"""
function parsedims(value::Union{AbstractString, Nothing}, j::Integer)
    isnothing(value) && return nothing
    isempty(strip(value)) && return nothing
    m = match(r"^\s*\(\s*(\d+(?:\s*,\s*\d+)*)\s*\)\s*$", value)
    if isnothing(m)
        @warn "TDIM$j is not of the form (l,m,n...), so it is ignored: $(repr(value))"
        return nothing
    end
    Tuple(parse.(Int, split(m[1], ",")))
end
parsedims(value, j::Integer) = (@warn "TDIM$j is not a string, so it is ignored: $(repr(value))"; nothing)

function Base.read(io::IO, ::Type{Bintable}, format::DataFormat,
    fields::Vector{BinaryField}; record::Bool = false, kwds...)

    begpos = position(io)
    M, N, P = format.shape[1], format.shape[2], format.param
    #  Read data array
    if record
        #  The records are the cells of the columns
        columns = [read(io, field, format, begpos; kwds...) for field in fields]
        data = [(; [Symbol(field.name) => recordcell(field, column, j) for (field, column) in zip(fields, columns)]...)
            for j = 1:N]
    else
        data = (; [Symbol(field.name) =>
            read(io, field, format, begpos; kwds...) for field in fields]... )
    end
    #  Seek to the beginning of the heap
    seek(io, begpos + (P > 0 ? format.heap : M*N))
    #  Read the heap
    ntoh.(read(io, P))
    #  Seek to the end of block
    # seek(io, begpos + BLOCKLEN*div(M*N + P, BLOCKLEN, RoundUp))

    ####    Get WCS keywords
    data
end

#  The value of a field in the record `j` from its column, which has the values of a row in its second and later dimensions if it has
#  two or more, and is nothing for a field that has no elements
recordcell(field::BinaryField, column, j::Integer) = field.leng == 0 && isnothing(field.pntr) ? nothing :
    ndims(column) >= 2 ? column[j, :] : column[j]

#  The value of a field in row `j` of the data, which is a vector of records or a named tuple of columns,
#  where a column of two or more dimensions has the values of a row in its second and later dimensions.
getcell(::Type{Bintable}, data::AbstractArray, field, j::Integer) = data[j][Symbol(field.name)]
function getcell(::Type{Bintable}, data::NamedTuple, field, j::Integer)
    column = data[Symbol(field.name)]
    ndims(column) >= 2 ? column[j, :] : column[j]
end

#  An array is written as a vector, and any other value as it is.
flatten(value) = value isa AbstractArray ? reshape(value, :) : value

function Base.write(io::IO, ::Type{Bintable}, data::Union{AbstractArray, NamedTuple},
    format::DataFormat, fields::Vector{BinaryField}; kwds...)

    #  Write data array, whose variable-length arrays are written to the heap, which follows the gap that THEAP leaves, and the
    #  descriptors of the arrays, which are the number of elements and the offset in the heap, to the table (Sect. 7.3.5)
    M, N = format.shape[1], format.shape[2]
    if N > 0
        heap = IOBuffer()
        for j=1:N
            for field in fields
                cell = getcell(Bintable, data, field, j)
                if isnothing(field.pntr)
                    write(io, field, flatten(cell); kwds...)
                else
                    writearray(io, heap, field, cell)
                end
            end
        end
        bytes = take!(heap)
        gap = max(format.heap - M*N, 0)
        write(io, zeros(UInt8, gap), bytes, zeros(UInt8, format.param - gap - length(bytes)))
        #  Pad last block with zeros
        padblock(io, format)
    end
end

#  Write the descriptor of the variable-length array `cell` to the table `io`, and its elements to the heap `heap`. An array of no
#  elements has no storage, and its offset is 0 (Sect. 7.3.5).
function writearray(io::IO, heap::IOBuffer, field::BinaryField, cell)
    type = field.type
    type <: Union{AbstractString, BitVector} && throw(ArgumentError("The variable-length array of field $(field.name) has " *
        "elements of type $type, which are not written."))
    values = cell isa AbstractArray ? reshape(cell, :) : [cell]
    n = length(values)
    write(io, hton(field.pntr(n)), hton(field.pntr(n == 0 ? 0 : position(heap))))
    n == 0 && return
    if type <: Bool
        write(heap, encodelogical.(values))
    else
        write(heap, hton.(unsetmissing(values, field.null, type)))
    end
end

#  The bytes of the variable-length arrays of the rows of the data fit in the heap of the header, whose PCOUNT bytes follow the table
#  and the gap that THEAP leaves, so the header that is written before the data is right
function verifydata(::Type{Bintable}, data::Union{NamedTuple, AbstractVector{<:NamedTuple}}, format::DataFormat,
    fields::Vector{BinaryField})

    M, N = format.shape[1], format.shape[2]
    variable = [field for field in fields if !isnothing(field.pntr)]
    isempty(variable) && return
    needed = sum(length(getcell(Bintable, data, field, j)) * heapelementsize(field.type) for j = 1:N for field in variable)
    available = format.param - max(format.heap - M*N, 0)
    needed > available && throw(ArgumentError("The variable-length arrays of the data have $needed bytes, but PCOUNT " *
        "$(format.param) and THEAP $(format.heap) leave $available bytes for the heap (Sect. 7.3.5)."))
end

function verify!(::Type{Bintable}, cards::Cards, mankeys::AbstractDict, reskeys::AbstractDict)
    cards = invoke(verify!, Tuple{Type{<:AbstractHDU}, Cards, AbstractDict, AbstractDict}, Bintable, cards,
        mankeys, reskeys)
    verifyrows(Bintable, mankeys)
    #  PCOUNT is the number of bytes of the heap and the gap, and there is a single table (Sect. 7.3.1)
    verifyvalue(mankeys, "PCOUNT", 0:typemax(Int), "non-negative")
    verifyvalue(mankeys, "GCOUNT", 1:1, "the integer 1")
    #  The number of fields, the heap offset, and the null values are integers (Sects. 7.3.1 and 7.3.2)
    verifyinteger(mankeys, r"^(TFIELDS|THEAP)$")
    verifyinteger(reskeys, r"^TNULL\d+$")
    verifyfields!(Bintable, cards, mankeys)
    verifyheap!(cards, mankeys)
end

function verify!(::Type{Bintable}, cards::Cards, format::DataFormat,
    mankeys::AbstractDict)

    verifyshape!(cards, mankeys, format)
    verifycounts!(cards, mankeys, format)
end

function DataFormat(::Type{Bintable}, data::Missing, mankeys::Dict{S, V}) where
    {S <: AbstractString, V <: ValueType}

    #  Mandatory keys determines HDU type.
    type  = BITS2TYPE[get(mankeys, "BITPIX", 8)]
    shape = datasize(mankeys, 1)
    param = get(mankeys, "PCOUNT", 0)
    group = get(mankeys, "GCOUNT", 1)
    leng  = get(mankeys, "NAXIS", 0) > 0 ? group * (param + prod(shape)) : 0
    heap  = get(mankeys, "THEAP", sizeof(type)*prod(shape))
    DataFormat(type, leng, shape, param, group, heap)
end

function FieldFormat(::Type{Bintable}, mankeys::DataFormat, reskeys::Dict{S, V},
    data::Missing; record::Bool = false, kwds...) where
    {S <: AbstractString, V <: ValueType}

    #   Add support TTYPEn and TUNITn in data arrays
    N = get(reskeys, "TFIELDS", 0)
    k, fields = 0, Vector{BinaryField}(undef, N)
    for j = 1:N
        name  = rstrip(get(reskeys, "TTYPE$j", record ? "field$j" : "column$j"))
        form  = match(BINARYFMT, reskeys["TFORM$j"])
        pntr  = !isempty(form[:p]) ? POINTERTYPE[form[:p]] : nothing
        type  = BINARYTYPE[form[:t]]
        leng  = !isempty(form[:r]) ? Base.parse(Int64, form[:r]) : 1
        if !isnothing(pntr)
            if !(leng in [0, 1])
                leng = 1
                @warn "TFORM$j repeat value set to 1."
            end
            byts = 2*sizeof(pntr)
        elseif type <: BitVector
            byts = sizeofbitvector(leng)
        elseif type <: AbstractString
            byts = leng
        else
            byts = leng*sizeof(type)
        end
        supp  = form[:a]
        unit_ = get(reskeys, "TUNIT$j", "")
        disp  = get(reskeys, "TDISP$j", "")
        dims  = parsedims(get(reskeys, "TDIM$j", nothing), j)
        zero_ = leastfloat(get(reskeys, "TZERO$j",
            type <: Union{Bool, BitVector, String} ? nothing : 0.0f0))
        scale = leastfloat(get(reskeys, "TSCAL$j",
            type <: Union{Bool, BitVector, String} ? nothing : 1.0f0))
        null  = get(reskeys, "TNULL$j", nothing)
        dmin  = parsestring(get(reskeys, "TDMIN$j", nothing))
        dmax  = parsestring(get(reskeys, "TDMAX$j", nothing))
        lmin  = parsestring(get(reskeys, "TLMIN$j", nothing))
        lmax  = parsestring(get(reskeys, "TLMAX$j", nothing))

        fields[j] = BinaryField(name, pntr, type, k+1:k+byts, leng, supp,
            unit_, disp, dims, zero_, scale, null, dmin, dmax, lmin, lmax)
        k += byts
    end
    fields
end

function DataFormat(::Type{Bintable}, data::AbstractArray,
    mankeys::Dict{S, V}) where {S <: AbstractString, V <: ValueType}

    heapformat(data, length(data))
end

function FieldFormat(::Type{Bintable}, mankey::DataFormat, reskeys::Dict{S, V},
    data::AbstractArray; kwds...) where {S <: AbstractString, V <: ValueType}

    #   Add support TTYPEn and TUNITn in data arrays
    N = length(data[1])
    k, fields = 0, Vector{BinaryField}(undef, N)
    for j = 1:N
        name = typeof(data[1]) <: NamedTuple ? rstrip(String(keys(data[1])[j])) :
            rstrip(get(reskeys, "TTYPE$j", "field$j"))
        type, leng, byts, pntr, supp = columndescriptor(record[j] for record in data)
        # unit_ = unit(data[1][j]) != NoUnits ? unit(data[1][j]) :
        #     get(reskeys, "TUNIT$j", "")
        unit_ = get(reskeys, "TUNIT$j", "")
        disp  = get(reskeys, "TDISP$j", "")
        dims  = parsedims(get(reskeys, "TDIM$j", nothing), j)
        zero_ = leastfloat(get(reskeys, "TZERO$j",
            type <: Union{Bool, BitVector, String} ? nothing : 0.0f0))
        scale = leastfloat(get(reskeys, "TSCAL$j",
            type <: Union{Bool, BitVector, String} ? nothing : 1.0f0))
        null  = get(reskeys, "TNULL$j", nothing)
        dmin  = get(reskeys, "TDMIN$j", nothing)
        dmax  = get(reskeys, "TDMAX$j", nothing)
        lmin  = get(reskeys, "TLMIN$j", nothing)
        lmax  = get(reskeys, "TLMAX$j", nothing)

        fields[j] = BinaryField(name, pntr, type, k+1:k+byts, leng, supp,
            unit_, disp, dims, zero_, scale, null, dmin, dmax, lmin, lmax)
        k += byts
    end
    fields
end

function DataFormat(::Type{Bintable}, data::U, mankeys::Dict{S, V}) where
    {U <: Union{Tuple, NamedTuple}, S <: AbstractString, V <: ValueType}

    heapformat(data, length(data[1]))
end

function FieldFormat(::Type{Bintable}, mankey::DataFormat, reskeys::Dict{S, V},
    data::U; kwds...) where {U <: Union{Tuple, NamedTuple},
    S <: AbstractString, V <: ValueType}

    #   Add support TTYPEn and TUNITn in data arrays
    N = length(data)
    k, fields = 0, Vector{BinaryField}(undef, N)
    for j = 1:N
        name  = typeof(data) <: NamedTuple ? rstrip(String(keys(data)[j])) :
            rstrip(get(reskeys, "TTYPE$j", "column$j"))
        type, leng, byts, pntr, supp = columndescriptor(data[j])
        # unit_ = unit(data[j]) != NoUnits ? unit(data[j]) :
        #     get(reskeys, "TUNIT$j", "")
        unit_ = get(reskeys, "TUNIT$j", "")
        disp  = get(reskeys, "TDISP$j", "")
        dims  = parsedims(get(reskeys, "TDIM$j", nothing), j)
        zero_ = leastfloat(get(reskeys, "TZERO$j",
            type <: Union{Bool, BitVector, String} ? nothing : 0.0f0))
        scale = leastfloat(get(reskeys, "TSCAL$j",
            type <: Union{Bool, BitVector, String} ? nothing : 1.0f0))
        null  = get(reskeys, "TNULL$j", nothing)
        dmin  = get(reskeys, "TDMIN$j", nothing)
        dmax  = get(reskeys, "TDMAX$j", nothing)
        lmin  = get(reskeys, "TLMIN$j", nothing)
        lmax  = get(reskeys, "TLMAX$j", nothing)

        fields[j] = BinaryField(name, pntr, type, k+1:k+byts, leng, supp,
            unit_, disp, dims, zero_, scale, null, dmin, dmax, lmin, lmax)
        k += byts
    end
    fields
end

#  The cells of each field of data that are a vector of records, or a tuple or a named tuple of columns
columnsof(data::AbstractArray) = [(record[j] for record in data) for j = 1:length(data[1])]
columnsof(data::Union{Tuple, NamedTuple}) = [data[j] for j = 1:length(data)]

#  The number of bytes of a value of an array in the heap
heapelementsize(type::Type) = type <: Bool ? 1 : sizeof(type)

#  The type, the number of elements, the bytes in a row, the type of the array descriptor, the largest number of elements of a
#  variable-length array, and the bytes of the heap of a field from the cells `values` of its column. The cells that are arrays of
#  different lengths are a variable-length array, whose descriptor is two 32-bit integers (P) or two 64-bit integers (Q) if the heap
#  is too large for them (Sect. 7.3.5), and the other cells are an array, a string, or a number, of the size of the first value that
#  is not missing.
function columndescriptor(values)
    value = fieldvalue(values)
    if value isa AbstractArray && !(value isa BitVector)
        lengths = [length(cell) for cell in values if !ismissing(cell)]
        if !all(==(first(lengths)), lengths)
            type = nonmissingtype(eltype(value))
            heap = sum(lengths) * heapelementsize(type)
            pntr = heap > typemax(Int32) ? Int64 : Int32
            return (type, 1, 2sizeof(pntr), pntr, string(maximum(lengths)), heap)
        end
    end
    type, leng, byts = fielddescriptor(value)
    (type, leng, byts, nothing, "", 0)
end

#  The data format of data of `nrows` rows: the bytes of a row and the rows, which are followed by the heap of the variable-length
#  arrays, whose bytes are PCOUNT, so that the heap begins after the table
function heapformat(data, nrows::Integer)
    columns = [columndescriptor(values) for values in columnsof(data)]
    shape = (sum(column[3] for column in columns; init = 0), nrows)
    param = sum(column[6] for column in columns; init = 0)
    DataFormat(BITS2TYPE[8], prod(shape) + param, shape, param, 1, prod(shape))
end

sizeofbitvector(v::BitVector)::Integer = (length(v)-1)÷8 + 1

#  The first value that is not missing, which gives the type of a field whose first values may be
#  undefined; a column with no defined value has the zero of its element type.
function definedvalue(values)
	for value in values
		ismissing(value) || return value
	end
	type = nonmissingtype(eltype(values))
	type <: Number && return zero(type)
	throw(ArgumentError("the type of a field of missing values cannot be determined"))
end

#  The value that gives the type and the size of a field from the values of its column: the first value that is not missing, and the
#  longest string of a column of strings, whose width is the number of bytes of the longest (Sect. 7.3.3.1)
function fieldvalue(values)
    value = definedvalue(values)
    value isa AbstractString || return value
    for other in values
        !ismissing(other) && ncodeunits(other) > ncodeunits(value) && (value = other)
    end
    value
end

sizeofbitvector(len::Integer)::Integer = (len-1)÷8 + 1

function fielddescriptor(field)
    if typeof(field) <: AbstractString
        type, leng = String, ncodeunits(field)
        byts = leng
    elseif typeof(field) <: BitVector
        type, leng = BitVector, length(field)
        byts = sizeofbitvector(leng)
    elseif typeof(field) <: AbstractArray
        type, leng = nonmissingtype(eltype(field)), length(field)
        byts = leng*sizeof(type)
    else
        type, leng = typeof(field), 1
        byts = leng*sizeof(type)
    end
    (type, leng, byts)
end

function createcards!(::Type{Bintable}, format::DataFormat,
    fields::Vector{BinaryField}, cards::Cards; kwds...)

    required = tablekeys(Bintable, format, length(fields))
    #  Include TTYPE cards if any name is not an empty string
    named = any(!isempty(field.name) for field in fields)
    for (j, field) in enumerate(fields)
        push!(required, "TFORM$j" => isnothing(field.pntr) ? "$(field.leng)$(BINARYTYPE[field.type])" :
            "$(field.leng)$(POINTERTYPE[field.pntr])$(BINARYTYPE[field.type])($(field.supp))")
        named && push!(required, "TTYPE$j" => field.name)
    end
    arrangecards!(cards, required)
end

function createdata(::Type{Bintable}, format::DataFormat,
    fields::Vector{BinaryField}; record::Bool = false, kwds...)
    #  Create vector of tuples.
    if format.leng > 0
        if record
            data = [(; [Symbol(f.name) => bintabzeros(f) for f in fields]...)
                    for k=1:format.shape[2]]
        else
            data = (; [Symbol(f.name) => bintabzeros(f, format.shape[2])
                    for f in fields]...)
        end
    else
        data = missing
    end
end

function bintabzeros(f)
    if f.type <: AbstractString
        repeat(" ", f.leng)
    elseif f.type <: BitVector
        BitVector(zeros(f.leng))
    elseif f.leng == 1
        zero(f.type)
    else
        zeros(f.type, f.leng)
    end
end

function bintabzeros(f, n)
    if f.type <: AbstractString
        fill(repeat(" ", f.leng), n)
    elseif f.type <: BitVector
        fill(BitVector(zeros(f.leng)), n)
    elseif f.leng == 1
        zeros(f.type, n)
    else
        zeros(f.type, (n, f.leng))
    end
end

function Base.read(io::IO, field::BinaryField, format::DataFormat,
    begpos::Integer; scale::Bool = true)

    #  Without TSCAL/TZERO the data pass through unchanged; scaling by the
    #  Float32 defaults would round integers above 2^24 (e.g. Int32 pointers)
    scale = scale && !isnothing(field.scale) && !(field.scale == 1 && field.zero == 0)

    type, leng = field.type, field.leng

    L, M, N = format.shape[1], first(field.slice)-1, format.shape[2]
    #  Read data array
    if !isnothing(field.pntr)
        #  The arrays of the rows may have missing values, or be scaled, so they are not all of one type. The heap is the PCOUNT bytes
        #  of the table after the gap that THEAP leaves (Sect. 7.3.5).
        heaplen = format.param - max(format.heap - L*N, 0)
        column = Array{Any}(undef, N)
        for j = 1:N
            seek(io, begpos + L*(j-1) + M)
            K   = Int(ntoh(read(io, field.pntr)))
            beg = Int(ntoh(read(io, field.pntr)))
            col = readarray(io, field, begpos + format.heap, K, beg, heaplen, j)
            column[j] = scale ? scaled(col, field.scale, field.zero) : col
        end
        column = map(identity, column)
    elseif type <: Bool
        #  The bytes of the N rows, which are T, F, or 0 for undefined (Sect. 7.3.3.1)
        bytes = Array{UInt8}(undef, (N, leng))
        for j = 1:N
            seek(io, begpos + L*(j-1) + M)
            bytes[j,:] .= read(io, leng)
        end
        column = decodelogical(bytes)
        column = leng == 1 ? reshape(column, :) : column
    elseif type <: BitVector
        column = Array{type}(undef, N)
        for j = 1:N
            seek(io, begpos + L*(j-1) + M)
            column[j] = read(io, type, leng)
        end
    elseif type <: AbstractString
        column = Array{String}(undef, N)
        for j = 1:N
            seek(io, begpos + L*(j-1) + M)
            column[j] = decodestring(read(io, length(field.slice)))
        end
    elseif leng == 1
        column = Array{type}(undef, N)
        for j = 1:N
            seek(io, begpos + L*(j-1) + M)
            column[j] = ntoh(read(io, type))
        end
        column = setmissing(column, field.null)
        column = scale ? scaled(column, field.scale, field.zero) : column
    else
        column = Array{type}(undef, (N, leng))
        for j = 1:N
            seek(io, begpos + L*(j-1) + M)
            column[j,:] .= ntoh.([read(io, type) for k=1:leng])
        end
        column = setmissing(column, field.null)
        column = scale ? scaled(column, field.scale, field.zero) : column
    end
    column
end

#  The elements of the variable-length array of the descriptor (`K`, `beg`) of row `j`, which are read from the heap that begins at the
#  position `heap` and has `heaplen` bytes. The storage of an array must lie entirely in the heap, and a negative length or offset is
#  not defined (Sect. 7.3.5), so the array is read as empty, with a warning. An array of no elements has no storage.
function readarray(io::IO, field::BinaryField, heap::Integer, K::Integer, beg::Integer, heaplen::Integer, j::Integer)
    type = field.type
    empty = type <: Bool ? Bool[] : type <: AbstractString ? "" : type <: BitVector ? falses(0) : type[]
    K == 0 && return empty
    nbytes = type <: BitVector ? sizeofbitvector(K) : K*heapelementsize(type)
    if K < 0 || beg < 0 || beg + nbytes > heaplen
        @warn "The array descriptor ($K, $beg) of row $j of field $(field.name) is not in the heap of $heaplen bytes " *
            "(Sect. 7.3.5), so the array is read as empty."
        return empty
    end
    seek(io, heap + beg)
    if type <: Bool
        decodelogical(read(io, K))
    elseif type <: AbstractString
        decodestring(read(io, K))
    elseif type <: BitVector
        read(io, BitVector, K)
    else
        values = Vector{type}(undef, K)
        read!(io, values)
        setmissing(ntoh.(values), field.null)
    end
end

function Base.write(io::IO, field::BinaryField, value::U; kwds...) where
    U <: Union{AbstractArray, AbstractString, BitVector, Real, Complex, Missing}

    type, leng = field.type, field.leng
    #  A logical value is written as T or F, and an undefined value as a 0 byte (Sect. 7.3.3.1)
    type <: Bool && return leng == 0 ? 0 : write(io, encodelogical.(value))
    #  The undefined values are written as TNULLn (Sect. 7.3.2), or NaN for floating-point data
    value = unsetmissing(value, field.null, type)

    if type <: AbstractString
        write(io, padstring(value, field.leng))
    elseif type <: BitVector
        write(io, type, value)
    elseif leng == 0
        0
    elseif leng == 1
        write(io, hton(value))
    else
        write(io, hton.(value))
    end
end

#  The string of the bytes of a field of characters, which ends at the first ASCII NULL, since the characters after it are not defined, and
#  without the spaces that fill the field (Sect. 7.3.3.1)
function decodestring(bytes::AbstractVector{UInt8})
    nul = findfirst(==(0x00), bytes)
    String(rstrip(String(bytes[1:(isnothing(nul) ? length(bytes) : nul - 1)])))
end

#  The bytes of a string in a field of `width` bytes, which are filled with spaces. A string that is longer than the field is an error,
#  since its bytes would be those of the fields after it.
function padstring(value::AbstractString, width::Integer)
    bytes = codeunits(value)
    length(bytes) > width && throw(ArgumentError("The string $(repr(value)) has $(length(bytes)) bytes, but the field has " *
        "$width (Sect. 7.3.3.1)."))
    vcat(bytes, fill(0x20, width - length(bytes)))
end

#  The values of the bytes of a logical field, which are an ASCII T for true, an ASCII F for false, and a 0
#  byte for undefined (Sect. 7.3.3.1). Any other byte is not a logical value, and is read as false. The
#  values have no missing if none of the bytes is 0.
function decodelogical(bytes::AbstractArray{UInt8})
    invalid = count(b -> !(b in (UInt8('T'), UInt8('F'), 0x00)), bytes)
    invalid > 0 && @warn "$invalid bytes of a logical field are not T, F, or 0; read as false."
    values = map(b -> b == 0x00 ? missing : b == UInt8('T'), bytes)
    any(ismissing, values) ? values : Array{Bool}(values)
end

encodelogical(value::Bool) = value ? UInt8('T') : UInt8('F')
encodelogical(::Missing) = 0x00

function Base.read(io::IO, ::Type{BitVector}, len)
    #  Read the bytes from IO and convert the UInt8s to a Bitvector
    bv  = falses(len)
    if len > 0
        siz = sizeofbitvector(len)
        vec = [read(io, UInt8) for j=1:siz]
        unsafe_copyto!(reinterpret(Ptr{UInt8}, pointer(bv.chunks)), pointer(vec), siz)
    end
    bv
end

function Base.write(io::IO, ::Type{BitVector}, value)
    #  Convert the BitVector to UInt8s and write the bytes to IO
    siz = sizeofbitvector(value)
    vec = zeros(UInt8, siz)
    unsafe_copyto!(pointer(vec), reinterpret(Ptr{UInt8}, pointer(value.chunks)), siz)
    write(io, vec)
end

"""
	verifyheap!(cards, mankeys)

Warn if THEAP of a binary table is outside of the range that the standard allows (Sect. 7.3.2), and
return the cards unchanged. The heap starts THEAP bytes after the start of the main data table, so THEAP
cannot be less than NAXIS1*NAXIS2 or more than that plus PCOUNT, the bytes of the gap and the heap.
"""
function verifyheap!(cards::Cards, mankeys::AbstractDict)
	haskey(mankeys, "THEAP") || return cards
	heap = mankeys["THEAP"]
	#  THEAP is not used if PCOUNT is 0, since there is no heap (Sect. 7.3.2)
	if get(mankeys, "PCOUNT", 0) == 0
		@warn "THEAP must not be used if PCOUNT is 0 (Sect. 7.3.2), since there is no heap. It is not used."
		return cards
	end
	table = get(mankeys, "NAXIS1", 0) * get(mankeys, "NAXIS2", 0)
	if heap < table
		@warn "THEAP $heap is less than NAXIS1*NAXIS2, $table, and the heap overlaps the table."
	elseif heap > table + get(mankeys, "PCOUNT", 0)
		@warn "THEAP $heap is more than NAXIS1*NAXIS2 + PCOUNT, $(table + get(mankeys, "PCOUNT", 0)), and the heap is past the data."
	end
	cards
end

#  The structure of a binary table extension, which is an array of bytes with NAXIS = 2 axes, the length of a row and the number
#  of rows (Sect. 7.3.1)
function verifyrows(::Type{Bintable}, mankeys::AbstractDict)
	verifyvalue(mankeys, "BITPIX", 8:8, "the integer 8")
	verifyvalue(mankeys, "NAXIS", 2:2, "the integer 2")
	verifyaxes(mankeys)
end

"""
	verifyfields!(Bintable, cards, mankeys)

Verify the keywords that describe the fields of a binary table extension, and return the cards unchanged
(Sect. 7.3.1 of the standard). It is an error, since the fields cannot be read, if TFIELDS
is negative, or if TFORMn is missing for an n from 1 to TFIELDS. It is a warning, since the extra keywords
are not used, if TFIELDS is more than 999, the maximum, or if TFORMn is present for an n greater than TFIELDS. A header with no TFIELDS is not verified.
"""
function verifyfields!(::Type{Bintable}, cards::Cards, mankeys::AbstractDict)
	N = get(mankeys, "TFIELDS", nothing)
	isnothing(N) && return cards
	N < 0 && throw(ArgumentError("TFIELDS must be non-negative, but its value is $N."))
	N > MAXBINTABLEFIELDS && @warn "TFIELDS $N is more than the maximum of $MAXBINTABLEFIELDS."
	for j = 1:N
		haskey(mankeys, "TFORM$j") || throw(ArgumentError("TFORM$j is missing, but TFIELDS is $N."))
	end
	for key in sort!(collect(keys(mankeys)))
		m = match(r"^TFORM(\d+)$", key)
		!isnothing(m) && Base.parse(Int, m[1]) > N &&
			@warn "$key is beyond TFIELDS $N, and is not used."
	end
	cards
end

#  The keywords of a binary table extension from XTENSION to TFIELDS, where the shape is the length of a row and the number of rows
function tablekeys(::Type{Bintable}, format::DataFormat, nfields::Integer)
	M, N = length(format.shape) == 2 ? format.shape : (0, 0)
	Pair{String, Any}["XTENSION" => "BINTABLE", "BITPIX" => 8, "NAXIS" => 2, "NAXIS1" => M,
		"NAXIS2" => N, "PCOUNT" => format.param, "GCOUNT" => 1, "TFIELDS" => nfields]
end

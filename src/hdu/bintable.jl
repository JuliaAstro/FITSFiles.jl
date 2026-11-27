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
recordcell(field::BinaryField, column, j::Integer) = field.leng == 0 && isnothing(field.pntr) ? nothing : cellof(column, j)

#  The cell in row `j` of a column, which is an element of a vector, or the array of the other dimensions of an array
cellof(column::AbstractArray, j::Integer) = ndims(column) >= 2 ? copy(selectdim(column, 1, j)) : column[j]

#  The value of a field in row `j` of the data, which is a vector of records or a named tuple of columns,
#  where a column of two or more dimensions has the values of a row in its second and later dimensions.
getcell(::Type{Bintable}, data::AbstractArray, field, j::Integer) = data[j][Symbol(field.name)]
function getcell(::Type{Bintable}, data::NamedTuple, field, j::Integer)
    cellof(data[Symbol(field.name)], j)
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
        #  The bytes of a row that no field has are written as zeros
        unused = zeros(UInt8, M - sum(length(field.slice) for field in fields; init = 0))
        for j=1:N
            for field in fields
                cell = getcell(Bintable, data, field, j)
                if isnothing(field.pntr)
                    write(io, field, flatten(cell); kwds...)
                else
                    writearray(io, heap, field, cell; check = get(kwds, :check, true))
                end
            end
            write(io, unused)
        end
        bytes = take!(heap)
        gap = max(format.heap - M*N, 0)
        write(io, zeros(UInt8, gap), bytes, zeros(UInt8, format.param - gap - length(bytes)))
        #  Pad last block with zeros
        padblock(io, format)
    end
end

#  A table that has no data has no data blocks
Base.write(io::IO, ::Type{Bintable}, data::Missing, format::DataFormat, fields::Vector{BinaryField}; kwds...) = nothing

#  Write the descriptor of the variable-length array `cell` to the table `io`, and its elements to the heap `heap`. An array of no
#  elements has no storage, and its offset is 0 (Sect. 7.3.5).
function writearray(io::IO, heap::IOBuffer, field::BinaryField, cell; check::Bool = true)
    type = field.type
    type <: Union{AbstractString, BitVector} && throw(ArgumentError("The variable-length array of field $(field.name) has " *
        "elements of type $type, which are not written."))
    values = cell isa AbstractArray ? reshape(cell, :) : [cell]
    values = storedcell(field, values; check)
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
    #  A header that is being created does not have the keywords yet, and is arranged when it is created.
    created = !haskey(mankeys, "XTENSION")
    #  The data cannot be read without BITPIX and NAXIS, which say how many axes there are (Sect. 7.3.1). A header with no TFIELDS has no
    #  fields.
    for key in ("BITPIX", "NAXIS")
        created || haskey(mankeys, key) || throw(ArgumentError(
            "$key is missing, but it is a mandatory keyword of a BINTABLE extension (Sect. 7.3.1)."))
    end
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
    created && return cards
    verifykeys(Bintable, cards, mankeys, reskeys)
end

#  The keywords that are in order and in fixed format, and the keywords of the fields (Sects. 4.4.1.2, 7.3.1, and 7.3.2)
function verifykeys(::Type{Bintable}, cards::Cards, mankeys::AbstractDict, reskeys::AbstractDict)
    #  PCOUNT and GCOUNT have the values 0 and 1 if they are missing, so the data can be read without them
    for (key, value) in ("PCOUNT" => 0, "GCOUNT" => 1)
        haskey(mankeys, key) || @warn "$key is missing, but it is a mandatory keyword of a BINTABLE extension " *
            "(Sect. 7.3.1), and has the value $value. It is read as $value."
    end
    #  The mandatory keywords are the first keywords, in order and in fixed format
    required = filter(key -> haskey(mankeys, key), ["XTENSION", "BITPIX", "NAXIS", "NAXIS1", "NAXIS2", "PCOUNT", "GCOUNT", "TFIELDS"])
    verifyorder(cards, required; section = "Sects. 4.4.1.2 and 7.3.1",
        names = "XTENSION, BITPIX, NAXIS, NAXIS1, NAXIS2, PCOUNT, GCOUNT, and TFIELDS")
    verifyfixed(cards, required)
    #  The keywords of the primary header, and of the physical blocks, are not in an extension (Sects. 4.4.1.1, 4.4.2.1, and 7.3.2)
    haskey(mankeys, "SIMPLE") && @warn "SIMPLE must not appear in an extension header (Sect. 4.4.1.1). It is read as it is."
    for key in ("EXTEND", "BLOCKED")
        haskey(reskeys, key) && @warn "$key must not appear in a BINTABLE extension header (Sects. 4.4.2.1 and 7.3.2). " *
            "It is read as it is."
    end
    #  INHERIT is a logical that is immediately after the mandatory keywords (Sect. 4.4.2.6 and Appendix K)
    verifylogical(reskeys, r"^INHERIT$")
    j = Base.findfirst("INHERIT", cards)
    if !ismissing(j) && j != length(required) + 1
        @warn "INHERIT must be the keyword immediately after the mandatory keywords, keyword $(length(required) + 1) " *
            "of this header (Sect. 4.4.2.6 and Appendix K), but it is keyword $j. It is read as it is."
    end
    verifyfieldkeys(Bintable, mankeys, reskeys)
    cards
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
        name  = stringkey(reskeys, "TTYPE$j", record ? "field$j" : "column$j")
        form  = match(BINARYFMT, reskeys["TFORM$j"])
        pntr  = !isempty(form[:p]) ? POINTERTYPE[form[:p]] : nothing
        type  = BINARYTYPE[form[:t]]
        leng  = !isempty(form[:r]) ? Base.parse(Int64, form[:r]) : 1
        if !isnothing(pntr)
            if !(leng in [0, 1])
                leng = 1
                @warn "TFORM$j repeat value set to 1."
            end
            byts = leng*2*sizeof(pntr)
        elseif type <: BitVector
            byts = sizeofbitvector(leng)
        elseif type <: AbstractString
            byts = leng
        else
            byts = leng*sizeof(type)
        end
        supp  = form[:a]
        unit_ = stringkey(reskeys, "TUNIT$j", "")
        disp  = stringkey(reskeys, "TDISP$j", "")
        dims  = parsedims(get(reskeys, "TDIM$j", nothing), j)
        zero_ = scalekey(reskeys, "TZERO$j", type, 0.0f0)
        scale = scalekey(reskeys, "TSCAL$j", type, 1.0f0)
        null  = nullkey(reskeys, "TNULL$j", type)
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

#  The string of a keyword of a field without the spaces at its end, or the default if the header does not have it or it is not a string
stringkey(reskeys::AbstractDict, key::AbstractString, default::AbstractString) =
    get(reskeys, key, default) isa AbstractString ? rstrip(get(reskeys, key, default)) : default

#  The scale or the zero of a field, which the header has or the default is, and nothing for the fields of type A, L, and X, which do not have
#  them (Sect. 7.3.2)
scalekey(reskeys::AbstractDict, key::AbstractString, type::Type, default) =
    type <: Union{Bool, BitVector, AbstractString} ? nothing : leastfloat(get(reskeys, key, default))

#  The integer of a field that stands for an undefined value, which only the fields of type B, I, J, and K have (Sect. 7.3.2)
nullkey(reskeys::AbstractDict, key::AbstractString, type::Type) =
    type <: Union{UInt8, Int16, Int32, Int64} ? get(reskeys, key, nothing) : nothing

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
            stringkey(reskeys, "TTYPE$j", "field$j")
        type, leng, byts, pntr, supp, _, shape = columndescriptor(record[j] for record in data)
        type, offset = rawtype(type), offsetof(type)
        # unit_ = unit(data[1][j]) != NoUnits ? unit(data[1][j]) :
        #     get(reskeys, "TUNIT$j", "")
        unit_ = stringkey(reskeys, "TUNIT$j", "")
        disp  = stringkey(reskeys, "TDISP$j", "")
        dims  = parsedims(get(reskeys, "TDIM$j", nothing), j)
        dims  = isnothing(dims) ? shape : dims
        zero_ = scalekey(reskeys, "TZERO$j", type, offset)
        scale = scalekey(reskeys, "TSCAL$j", type, 1.0f0)
        null  = nullkey(reskeys, "TNULL$j", type)
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

    heapformat(data, size(data[1], 1))
end

function FieldFormat(::Type{Bintable}, mankey::DataFormat, reskeys::Dict{S, V},
    data::U; kwds...) where {U <: Union{Tuple, NamedTuple},
    S <: AbstractString, V <: ValueType}

    #   Add support TTYPEn and TUNITn in data arrays
    N = length(data)
    k, fields = 0, Vector{BinaryField}(undef, N)
    for j = 1:N
        name  = typeof(data) <: NamedTuple ? rstrip(String(keys(data)[j])) :
            stringkey(reskeys, "TTYPE$j", "column$j")
        type, leng, byts, pntr, supp, _, shape = columndescriptor(data[j])
        type, offset = rawtype(type), offsetof(type)
        # unit_ = unit(data[j]) != NoUnits ? unit(data[j]) :
        #     get(reskeys, "TUNIT$j", "")
        unit_ = stringkey(reskeys, "TUNIT$j", "")
        disp  = stringkey(reskeys, "TDISP$j", "")
        dims  = parsedims(get(reskeys, "TDIM$j", nothing), j)
        dims  = isnothing(dims) ? shape : dims
        zero_ = scalekey(reskeys, "TZERO$j", type, offset)
        scale = scalekey(reskeys, "TSCAL$j", type, 1.0f0)
        null  = nullkey(reskeys, "TNULL$j", type)
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

#  The type of the stored values of the physical type of a field, which is the type of Table 19 with a TZERO (e.g., an Int16 for a
#  UInt16), and the TZERO of the physical type, which is 0 for the others
rawtype(type::Type) = get(RAWTYPE, type, type)
offsetof(type::Type) = haskey(RAWTYPE, type) ? OFFSETTYPE[RAWTYPE[type]][2] : 0.0f0

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
    #  A column of two or more dimensions has the values of a row in its second and later dimensions, which are the dimensions TDIMn
    #  of an array of the field that has more than one (Sect. 7.3.2)
    if values isa AbstractArray && ndims(values) >= 2
        type = nonmissingtype(eltype(values))
        shape = size(values)[2:end]
        leng = prod(shape)
        return (type, leng, leng*heapelementsize(type), nothing, "", 0, length(shape) > 1 ? shape : nothing)
    end
    value = fieldvalue(values)
    if value isa AbstractArray && !(value isa BitVector)
        lengths = [length(cell) for cell in values if !ismissing(cell)]
        if !isempty(lengths) && !all(==(first(lengths)), lengths)
            type = nonmissingtype(eltype(value))
            heap = sum(lengths) * heapelementsize(type)
            pntr = heap > typemax(Int32) ? Int64 : Int32
            return (type, 1, 2sizeof(pntr), pntr, string(maximum(lengths)), heap, nothing)
        end
    end
    type, leng, byts = fielddescriptor(value)
    (type, leng, byts, nothing, "", 0, value isa AbstractArray && ndims(value) > 1 ? size(value) : nothing)
end

#  The data format of data of `nrows` rows: the bytes of a row and the rows, which are followed by the heap of the variable-length
#  arrays, whose bytes are PCOUNT, so that the heap begins after the table
function heapformat(data, nrows::Integer)
    columns = [columndescriptor(values) for values in columnsof(data)]
    shape = (sum(column[3] for column in columns; init = 0), nrows)
    param = sum(column[6] for column in columns; init = 0)
    DataFormat(BITS2TYPE[8], prod(shape) + param, shape, param, 1, prod(shape))
end

sizeofbitvector(v::BitVector)::Integer = sizeofbitvector(length(v))

#  The first value that is not missing, which gives the type of a field whose first values may be
#  undefined; a column with no defined value has the zero of its element type.
function definedvalue(values)
	for value in values
		ismissing(value) || return value
	end
	type = nonmissingtype(eltype(values))
	type <: Number && return zero(type)
	#  A column of no values has the size of an empty string, or of an empty array
	type <: AbstractString && return ""
	type <: AbstractArray && return type()
	throw(ArgumentError("the type of a field of missing values cannot be determined"))
end

#  The value that gives the type and the size of a field from the values of its column: the first value that is not missing, and the
#  longest string of a column of strings, whose width is the number of bytes of the longest (Sect. 7.3.3.1), or the longest bit array
function fieldvalue(values)
    value = definedvalue(values)
    value isa Union{AbstractString, BitVector} || return value
    size(x) = x isa AbstractString ? ncodeunits(x) : length(x)
    for other in values
        !ismissing(other) && size(other) > size(value) && (value = other)
    end
    value
end

sizeofbitvector(len::Integer)::Integer = len <= 0 ? 0 : (len-1)÷8 + 1

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
    #  The dimensions of an array of a field that has more than one dimension are its TDIMn (Sect. 7.3.2)
    for (j, field) in enumerate(fields)
        !isnothing(field.dims) && length(field.dims) > 1 && push!(required, "TDIM$j" => "(" * join(field.dims, ",") * ")")
    end
    #  The offset of the physical type of a field is its TZERO (Table 19)
    for (j, field) in enumerate(fields)
        !isnothing(field.scale) && !isnothing(offsettype(field.type, field.scale, field.zero)) &&
            push!(required, "TZERO$j" => OFFSETTYPE[field.type][2])
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

#  The data of a table that has no rows have no data blocks, and are the empty columns of the fields, or the empty vector of records. A table that
#  has no fields has no data.
function emptydata(::Type{Bintable}, format::DataFormat, fields::Vector{BinaryField}; kwds...)
    isempty(fields) || format.shape[2] > 0 ? missing : read(IOBuffer(UInt8[]), Bintable, format, fields; kwds...)
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

    #  The physical values of the stored values are the stored values, if TSCAL is 1 and TZERO is 0, the values of the offsets of Table 19
    #  (e.g., a UInt16 for an Int16 and a TZERO of 32768), or the scaled values (Eq. 7)
    scale = scale && !isnothing(field.scale)

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
            column[j] = scale ? physical(col, type, field.scale, field.zero) : col
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
        #  The strings of an array of strings, whose first dimension is the number of characters of each, are the characters of the field in
        #  order (Sect. 7.3.2)
        dims = stringdims(field)
        column = isnothing(dims) ? Array{String}(undef, N) : Array{String}(undef, (N, dims[2:end]...))
        for j = 1:N
            seek(io, begpos + L*(j-1) + M)
            bytes = read(io, length(field.slice))
            if isnothing(dims)
                column[j] = decodestring(bytes)
            else
                for k = 1:prod(dims[2:end])
                    column[j + N*(k-1)] = decodestring(bytes[dims[1]*(k-1)+1:dims[1]*k])
                end
            end
        end
    elseif leng == 1
        column = Array{type}(undef, N)
        for j = 1:N
            seek(io, begpos + L*(j-1) + M)
            column[j] = ntoh(read(io, type))
        end
        column = setmissing(column, field.null)
        column = scale ? physical(column, type, field.scale, field.zero) : column
    else
        column = Array{type}(undef, (N, leng))
        for j = 1:N
            seek(io, begpos + L*(j-1) + M)
            column[j,:] .= ntoh.([read(io, type) for k=1:leng])
        end
        column = setmissing(column, field.null)
        column = scale ? physical(column, type, field.scale, field.zero) : column
    end
    applydims(column, field)
end

#  The dimensions of an array of strings, which are the dimensions TDIMn if there is more than one and they hold no more characters
#  than the field has, or nothing (Sect. 7.3.2)
function stringdims(field::BinaryField)
    dims = field.dims
    (isnothing(dims) || length(dims) < 2 || prod(dims) > field.leng || dims[1] == 0) && return nothing
    dims
end

#  The array of each row of the column has the dimensions TDIMn of the field, which are the first elements of the array of the row, so
#  that the unused elements at the end of the array are not read (Sect. 7.3.2). The dimensions are not used if they have more
#  elements than the field has, with a warning, and the elements of a row are a vector for a field of no more than one dimension.
function applydims(column, field::BinaryField)
    dims = field.dims
    (isnothing(dims) || length(dims) < 2 || field.type <: AbstractString) && return column
    n = prod(dims)
    if column isa AbstractVector
        #  The cells of a variable-length array, or of a bit array, are the elements of the arrays that are the rows
        return map(cell -> n <= length(cell) ? reshape(cell[1:n], dims) : cell, column)
    end
    if n > field.leng
        @warn "TDIM of field $(field.name), $(join(dims, " × ")), has $n elements, more than the $(field.leng) of its TFORM " *
            "(Sect. 7.3.2), so it is not used."
        return column
    end
    reshape(column[:, 1:n], (size(column, 1), dims...))
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

#  The stored values of the physical values of a cell: the values of the offsets of Table 19 have the offset, and the values that are
#  not of the type of the field are inverted from the scale and the zero (Eq. 7), as the values of an array of an image are
function storedcell(field::BinaryField, value; check::Bool = true)
    (isnothing(field.scale) || field.type <: Union{Bool, BitVector, AbstractString} ||
        (field.scale == 1 && field.zero == 0 && !haskey(OFFSETTYPE, field.type))) && return value
    stored(values) = storedvalues(values, field.type, field.scale, field.zero, field.null; check)
    value isa AbstractArray ? stored(value) : only(stored([value]))
end

function Base.write(io::IO, field::BinaryField, value::U; check::Bool = true, kwds...) where
    U <: Union{AbstractArray, AbstractString, BitVector, Real, Complex, Missing}

    type, leng = field.type, field.leng
    #  A logical value is written as T or F, and an undefined value as a 0 byte (Sect. 7.3.3.1)
    type <: Bool && return leng == 0 ? 0 : write(io, encodelogical.(value))
    #  The stored values of the physical values, and the undefined values, which are written as TNULLn (Sect. 7.3.2), or NaN for
    #  floating-point data
    value = unsetmissing(storedcell(field, value; check), field.null, type)

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

#  The bits of a bit array are in order from the most significant bit of the first byte to the least significant bit of the last byte,
#  and the bits after the end of the array are zeros (Sect. 7.3.3.1)
function Base.read(io::IO, ::Type{BitVector}, len)
    bytes = read(io, sizeofbitvector(len))
    BitVector([bytes[(j-1) >> 3 + 1] & (0x80 >> ((j-1) & 7)) != 0 for j = 1:len])
end

function Base.write(io::IO, ::Type{BitVector}, value)
    bytes = zeros(UInt8, sizeofbitvector(value))
    for j in findall(value)
        bytes[(j-1) >> 3 + 1] |= 0x80 >> ((j-1) & 7)
    end
    write(io, bytes)
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

#  The form of the value of TFORMn: a repeat count, the data type of Table 18 in upper case, and the characters that follow, which are
#  the type of the elements and the largest number of them of a variable-length array (Sect. 7.3.1)
const TFORMFORM = r"^(\d*)([PQ]?)([LXBIJKAEDCM])(.*)$"

#  The number of bytes of a field in a row of the table from the value of its TFORMn, which must be of the form rTa
function tformbytes(key::AbstractString, value)
    value isa AbstractString || throw(ArgumentError("$key must be a character string of the form rTa, but its value is $(repr(value))."))
    m = match(TFORMFORM, rstrip(value))
    if isnothing(m)
        case = occursin(r"^\d*[PQ]?[a-z]", value) ? ", and the format codes must be upper case" : ""
        throw(ArgumentError("$key must be of the form rTa, with a data type of Table 18: L, X, B, I, J, K, A, E, D, C, M, P, or Q" *
            "$case (Sect. 7.3.1), but its value is $(repr(value))."))
    end
    r = isempty(m[1]) ? 1 : Base.parse(Int, m[1])
    isempty(m[2]) || return min(r, 1)*2*sizeof(POINTERTYPE[m[2]])
    type = BINARYTYPE[m[3]]
    type <: BitVector ? sizeofbitvector(r) : type <: AbstractString ? r : r*sizeof(type)
end

#  The number of bytes of a row is the sum of the bytes of the fields (Eq. 8 of the standard), and is the value of NAXIS1. The fields
#  do not fit in a row that has fewer bytes, so the table cannot be read. The bytes of a row that no field has are not read, and are written
#  as zeros.
function verifyrowbytes(mankeys::AbstractDict, reskeys::AbstractDict)
    N = get(mankeys, "TFIELDS", 0)
    N isa Integer && N > 0 || return
    all(j -> haskey(reskeys, "TFORM$j"), 1:N) || return
    nbytes = sum(tformbytes("TFORM$j", reskeys["TFORM$j"]) for j = 1:N)
    row = get(mankeys, "NAXIS1", nbytes)
    row < nbytes && throw(ArgumentError("NAXIS1 is $row, but the fields of TFORMn have $nbytes bytes in a row, " *
        "which is the value that NAXIS1 must have (Eq. 8, Sect. 7.3.1)."))
    row > nbytes && @warn "NAXIS1 is $row, but the fields of TFORMn have $nbytes bytes in a row, which is the value that NAXIS1 " *
        "must have (Eq. 8, Sect. 7.3.1). The $(row - nbytes) bytes after the fields of a row are not read, and are written as zeros."
    nothing
end

#  The keywords that describe the fields (Sect. 7.3.2): TFORMn is of the form rTa, TTYPEn and TUNITn are character strings, TUNITn is a
#  units string, the names of the fields are unique without regard to the case, TSCALn and TZEROn are numbers that are not used for
#  the fields of type A, L, or X, TNULLn is an integer that is used only for the fields of type B, I, J, or K, TDISPn is a display format
#  of Table 20, and the minimum and maximum values are numbers.
function verifyfieldkeys(::Type{Bintable}, mankeys::AbstractDict, reskeys::AbstractDict)
    N = get(mankeys, "TFIELDS", 0)
    N isa Integer || return
    verifyrowbytes(mankeys, reskeys)
    verifystring(reskeys, r"^(TTYPE|TUNIT|TDISP)\d+$")
    verifyunit(reskeys, r"^TUNIT\d+$")
    verifynumber(reskeys, r"^(TSCAL|TZERO|TDMIN|TDMAX|TLMIN|TLMAX)\d+$")
    names = Dict{String, Int}()
    for j = 1:N
        form = get(reskeys, "TFORM$j", nothing)
        isnothing(form) && continue
        type = match(TFORMFORM, rstrip(form))[3]
        (haskey(reskeys, "TSCAL$j") || haskey(reskeys, "TZERO$j")) && type in ("A", "L", "X") &&
            @warn "TSCAL$j and TZERO$j must not be used for a field of type $type (Sect. 7.3.2). They are not used."
        haskey(reskeys, "TNULL$j") && !(type in ("B", "I", "J", "K")) && @warn "TNULL$j must not be used for a field of type " *
            "$type (Sect. 7.3.2), which is not an integer. It is not used."
        disp = get(reskeys, "TDISP$j", nothing)
        disp isa AbstractString && !occursin(TDISPFORM, strip(disp)) && @warn "TDISP$j must be a display format of Table 20 " *
            "(Sect. 7.3.2), but its value is $(repr(disp)). It is read as it is."
        name = get(reskeys, "TTYPE$j", nothing)
        if name isa AbstractString && !isempty(strip(name))
            other = get(names, lowercase(rstrip(name)), 0)
            other > 0 ? @warn("TTYPE$j and TTYPE$other have the same name, $(repr(rstrip(name))), without regard to the case, " *
                "but the names of the fields should be unique (Sect. 7.3.2).") : names[lowercase(rstrip(name))] = j
        end
    end
    nothing
end

#  The display formats of Table 20: Aw, Lw, Iw.m, Bw.m, Ow.m, Zw.m, Fw.d, Ew.dEe, ENw.d, ESw.d, Gw.dEe, and Dw.dEe, in upper case
const TDISPFORM = r"^(A\d+|L\d+|[IBOZ]\d+(\.\d+)?|F\d+\.\d+|(E|EN|ES|G|D)\d+\.\d+(E\d+)?)$"

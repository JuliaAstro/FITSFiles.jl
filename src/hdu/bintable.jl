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
    #  The table and the heap have the bytes that the header says, which are checked before the data are allocated
    nbytes = M*N + P
    nbytes > unreadbytes(io) && throw(ArgumentError("The data of the HDU is $nbytes bytes, as its header says, but the file has " *
        "only $(unreadbytes(io)) of them."))
    #  Read data array
    if record
        #  The records are the cells of the columns
        columns = [read(io, field, format, begpos; kwds...) for field in fields]
        data = [(; [Symbol(field.name) => recordcell(field, column, j) for (field, column) in zip(fields, columns)]...)
            for j = 1:N]
        #  The records that have fields of scaled floating-point values are written as the stored values
        scales = Dict{Symbol, Tuple{Any, Any}}(Symbol(field.name) => (field.scale, field.zero)
            for field in fields if get(kwds, :scale, true) && physicalfloat(field) && isnothing(field.pntr))
        isempty(scales) || (data = ScaledTable(data, scales))
    else
        data = (; [Symbol(field.name) =>
            read(io, field, format, begpos; kwds...) for field in fields]... )
    end
    #  The heap is not read, since the arrays of the fields are read from it, so the stream is at the end of the table and the heap, which
    #  have the bytes that the header says (Sect. 7.3.5)
    seek(io, begpos + M*N + P)

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
                    write(io, field, flatten(cell); physical = physicalscale(data, field), kwds...)
                elseif field.leng > 0
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
    elseif format.param > 0
        #  A table that has no rows has no arrays, so its heap, and the gap before it, are zeros
        write(io, zeros(UInt8, format.param))
        padblock(io, format)
    end
end

#  A table that has no data has no data blocks
Base.write(io::IO, ::Type{Bintable}, data::Missing, format::DataFormat, fields::Vector{BinaryField}; kwds...) = nothing

#  Write the descriptor of the variable-length array `cell` to the table `io`, and its elements to the heap `heap`. An array of no
#  elements has no storage, and its offset is 0 (Sect. 7.3.5).
function writearray(io::IO, heap::IOBuffer, field::BinaryField, cell; check::Bool = true)
    type = field.type
    #  An array that is missing has no elements, since the standard has no undefined array, and is read as an array of no elements
    ismissing(cell) && (cell = emptyarray(type))
    #  The characters of a string are the bytes of the array, and the bits of a bit array are the bits of its bytes, whose number is the
    #  length of the array, and the bits after the end of the array are zeros
    if type <: Union{AbstractString, BitVector}
        n = type <: AbstractString ? ncodeunits(cell) : length(cell)
        write(io, hton(field.pntr(n)), hton(field.pntr(n == 0 ? 0 : position(heap))))
        n == 0 && return
        type <: AbstractString ? write(heap, codeunits(checkascii(cell))) : write(heap, BitVector, cell)
        return
    end
    values = cell isa AbstractArray ? reshape(cell, :) : [cell]
    values = storedcell(field, values; check, physical = cell isa ScaledArray ? (cell.scale, cell.zero) : nothing)
    hasmissing(values) && checknull(field)
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
    #  The largest number of elements of the arrays of a field is at most the emax of its TFORMn, which is guaranteed to be the
    #  largest (Sect. 7.3.5)
    for field in variable
        #  The repeat count 0 is an empty field of zero bytes, which has no descriptor and no array (Sect. 7.3.3.1)
        field.leng == 0 && any(j -> heapbytes(field, getcell(Bintable, data, field, j)) > 0, 1:N) && throw(ArgumentError(
            "Field $(field.name) has the repeat count 0 in its TFORMn, which is an empty field of zero bytes, but its data have " *
            "elements (Sect. 7.3.3.1)."))
        emax = tryparse(Int, field.supp)
        isnothing(emax) && continue
        longest = maximum((ismissing(cell) ? 0 : field.type <: AbstractString ? ncodeunits(cell) : length(cell)
            for j = 1:N for cell in (getcell(Bintable, data, field, j),)); init = 0)
        longest > emax && @warn "The longest array of field $(field.name) has $longest elements, more than the largest number of " *
            "elements, $emax, that its TFORM says (Sect. 7.3.5). The TFORM is written as it is."
    end
    #  A 32-bit descriptor (P) has the number of elements and the offset of an array in the heap that are 32-bit integers, which the arrays are written in
    #  the order of the rows and then the fields, so their offsets are the bytes before them (Sect. 7.3.5)
    offset = 0
    for j = 1:N, field in variable
        cell = getcell(Bintable, data, field, j)
        n = ismissing(cell) ? 0 : field.type <: AbstractString ? ncodeunits(cell) : length(cell)
        field.pntr == Int32 && (offset > typemax(Int32) || n > typemax(Int32)) && throw(ArgumentError("The array of row $j of field " *
            "$(field.name) is at the offset $offset in the heap and has $n elements, which a 32-bit array descriptor (P) cannot address " *
            "(Sect. 7.3.5). Use the 64-bit descriptor, Q, with the keyword variable or in TFORM$(findfirst(==(field), fields))."))
        offset += heapbytes(field, cell)
    end
    needed = offset
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
    verifysize(Bintable, mankeys)
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
    #  A NAXIS1 or a NAXIS2 that the cards give without the other is the length of a row and the number of rows of the data too
    for j = 1:2
        key = "NAXIS$j"
        if haskey(cards, key) && cards[key] != format.shape[j]
            @warn "$key set to $(format.shape[j])"
            cards[key] = format.shape[j]
        end
    end
    verifycounts!(cards, mankeys, format)
end

"""
	Base.size(hdu::HDU{Bintable})

The size of the two-dimensional byte array of the main table of a binary table extension, which is the number of bytes in a row and the number
of rows, the NAXIS1 and the NAXIS2 of its header (Sect. 7.3.3 of the standard), so that the size of an HDU whose data are not read yet (see
[`fits`](@ref)) is known without reading them. The number of rows is also the number of values of each column of the data, and TFIELDS is the
number of columns. A header that does not have them has none, `(0, 0)`.
"""
Base.size(hdu::HDU{Bintable}) = (get(getfield(hdu, :cards), "NAXIS1", 0), get(getfield(hdu, :cards), "NAXIS2", 0))

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
    k, fields, names = 0, Vector{BinaryField}(undef, N), Set{String}()
    for j = 1:N
        name  = uniquename(stringkey(reskeys, "TTYPE$j", record ? "field$j" : "column$j"), record ? "field$j" : "column$j", names)
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

#  The name of a field, which is the default if the name is empty, and which no other field has, since the columns of the data are named by
#  the fields, and the columns of two fields that have the same name would be one. The position of the field follows the name of the
#  field that is a repeat of another.
function uniquename(name::AbstractString, default::AbstractString, names::Set{String})
    name = isempty(name) ? default : String(name)
    unique = name
    while unique in names
        unique = unique == name ? "$(name)_$(length(names) + 1)" : unique * "_"
    end
    push!(names, unique)
    unique
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

    heapformat(data, length(data), mankeys)
end

function FieldFormat(::Type{Bintable}, mankey::DataFormat, reskeys::Dict{S, V},
    data::AbstractArray; kwds...) where {S <: AbstractString, V <: ValueType}

    #   Add support TTYPEn and TUNITn in data arrays
    N = length(data[1])
    k, fields, names = 0, Vector{BinaryField}(undef, N), Set{String}()
    for j = 1:N
        name = typeof(data[1]) <: NamedTuple ? rstrip(String(keys(data[1])[j])) :
            uniquename(stringkey(reskeys, "TTYPE$j", "column$j"), "column$j", names)
        type, leng, byts, pntr, supp, _, shape = columndescriptor((record[j] for record in data), forcedpointer(reskeys, j))
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

    checkrows(data)
    heapformat(data, size(data[1], 1), mankeys)
end

#  The columns of data have the same number of rows, which is NAXIS2, since every field has an entry in every row (Sects. 7.3.1 and 7.3.3.1)
function checkrows(data::Union{Tuple, NamedTuple})
    rows = [size(column, 1) for column in columnsof(data)]
    all(==(first(rows)), rows) || throw(ArgumentError("The columns of the data have different numbers of rows, but every field of a binary " *
        "table has an entry in each of the NAXIS2 rows (Sects. 7.3.1 and 7.3.3.1): " *
        join(["$name has $n" for (name, n) in zip(datanames(data), rows)], ", ") * "."))
end

function FieldFormat(::Type{Bintable}, mankey::DataFormat, reskeys::Dict{S, V},
    data::U; kwds...) where {U <: Union{Tuple, NamedTuple},
    S <: AbstractString, V <: ValueType}

    #   Add support TTYPEn and TUNITn in data arrays
    N = length(data)
    k, fields, names = 0, Vector{BinaryField}(undef, N), Set{String}()
    for j = 1:N
        name  = typeof(data) <: NamedTuple ? rstrip(String(keys(data)[j])) :
            uniquename(stringkey(reskeys, "TTYPE$j", "column$j"), "column$j", names)
        type, leng, byts, pntr, supp, _, shape = columndescriptor(data[j], forcedpointer(reskeys, j))
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

#  The number of bytes of a value of an array in the heap, which is a byte for a character
heapelementsize(type::Type) = type <: Union{Bool, AbstractString} ? 1 : sizeof(type)

#  The number of bytes of the variable-length array `cell` of a field in the heap: the characters of a string, the bits of a bit array
#  in whole bytes, or the elements of an array
heapbytes(field::BinaryField, cell) = field.type <: AbstractString ? ncodeunits(cell) :
    field.type <: BitVector ? sizeofbitvector(length(cell)) : length(cell) * heapelementsize(field.type)
#  An array that is missing is an array of no elements, which has no storage (Sect. 7.3.5)
heapbytes(field::BinaryField, ::Missing) = 0

#  The type, the number of elements, the bytes in a row, the type of the array descriptor, the largest number of elements of a
#  variable-length array, and the bytes of the heap of a field from the cells `values` of its column. The cells that are arrays of
#  different lengths are a variable-length array, whose descriptor is two 32-bit integers (P) or two 64-bit integers (Q) if the heap
#  is too large for them (Sect. 7.3.5), and the other cells are an array, a string, or a number, of the size of the first value that
#  is not missing.
function columndescriptor(values, pntr::Union{Type, Nothing} = nothing)
    #  A field that is variable-length, whose descriptor `pntr` is a 32-bit (P) or 64-bit (Q) integer, whatever the lengths of its arrays are
    isnothing(pntr) || return variabledescriptor(values, pntr)
    #  A column of two or more dimensions has the values of a row in its second and later dimensions, which are the dimensions TDIMn
    #  of an array of the field that has more than one (Sect. 7.3.2)
    if values isa AbstractArray && ndims(values) >= 2
        #  The strings of an array of strings have the number of bytes of the longest as their first dimension (Sect. 7.3.2)
        if nonmissingtype(eltype(values)) <: AbstractString
            width = maximum(ncodeunits, values; init = 0)
            shape = size(values)[2:end]
            return (String, width*prod(shape), width*prod(shape), nothing, "", 0, (width, shape...))
        end
        type = checkfieldtype(nonmissingtype(eltype(values)))
        shape = size(values)[2:end]
        leng = prod(shape)
        return (type, leng, leng*heapelementsize(type), nothing, "", 0, length(shape) > 1 ? shape : nothing)
    end
    value = fieldvalue(values)
    if value isa AbstractArray && nonmissingtype(eltype(value)) <: AbstractString
        cells = [cell for cell in values if !ismissing(cell)]
        all(cell -> size(cell) == size(value), cells) || throw(ArgumentError("The arrays of strings of a field have " *
            "different sizes, but the arrays of strings of a binary table have the same size (Sect. 7.3.2)."))
        width = maximum(ncodeunits(string) for cell in cells for string in cell; init = 0)
        return (String, width*length(value), width*length(value), nothing, "", 0, (width, size(value)...))
    end
    if value isa AbstractArray && !(value isa BitVector)
        lengths = [length(cell) for cell in values if !ismissing(cell)]
        if !isempty(lengths) && !all(==(first(lengths)), lengths)
            type = checkfieldtype(nonmissingtype(eltype(value)))
            heap = sum(lengths) * heapelementsize(type)
            pntr = heap > typemax(Int32) ? Int64 : Int32
            return (type, 1, 2sizeof(pntr), pntr, string(maximum(lengths)), heap, nothing)
        end
    end
    type, leng, byts = fielddescriptor(value)
    (type, leng, byts, nothing, "", 0, value isa AbstractArray && ndims(value) > 1 ? size(value) : nothing)
end

#  The type of the array descriptor of a field, which is a P (32-bit) or Q (64-bit) in its TFORMn, or nothing if it is not variable-length. The
#  keyword `variable` and the cards give it, which the data would not (see `columndescriptor`), since the arrays of the rows can have the same length
#  (Sect. 7.3.5).
function forcedpointer(keys::AbstractDict, j::Integer)
    form = get(keys, "TFORM$j", nothing)
    form isa AbstractString || return nothing
    m = match(r"^\s*\d*([PQ])", form)
    isnothing(m) ? nothing : POINTERTYPE[m[1]]
end

#  The type, the number of elements, the bytes in a row, the type of the array descriptor, the largest number of elements of an array, and
#  the bytes of the heap of a field from the cells `values` of its column, which is variable-length whatever the lengths of its arrays are: the
#  cells are arrays, strings, or bit arrays, a number is an array of one element, and the rows of a column of two or more dimensions are the
#  cells. The descriptor `pntr` is 32-bit or 64-bit, and the bytes of the heap must be a value of its type (Sect. 7.3.5).
function variabledescriptor(values, pntr::Type)
    if values isa AbstractArray && ndims(values) >= 2
        nonmissingtype(eltype(values)) <: AbstractString && throw(ArgumentError("An array of strings cannot be a variable-length " *
            "field, whose arrays are the elements of one type (Sect. 7.3.5)."))
        cells = [selectdim(values, 1, j) for j = 1:size(values, 1)]
    else
        cells = collect(values)
    end
    defined = [cell for cell in cells if !ismissing(cell)]
    #  The type is that of the first array, or of the column if there are none
    first_ = isempty(defined) ? nothing : first(defined)
    type = if first_ isa AbstractString
        String
    elseif first_ isa BitVector
        BitVector
    elseif first_ isa AbstractArray
        nonmissingtype(eltype(first_))
    elseif isnothing(first_)
        element = nonmissingtype(eltype(cells))
        element <: AbstractArray ? nonmissingtype(eltype(element)) : element
    else
        typeof(first_)
    end
    type <: Union{AbstractString, BitVector} || checkfieldtype(type)
    sizes = [cell isa AbstractString ? ncodeunits(cell) : cell isa AbstractArray ? length(cell) : 1 for cell in defined]
    bytes = type <: BitVector ? sum(sizeofbitvector, sizes; init = 0) : sum(sizes; init = 0) * heapelementsize(type)
    code = POINTERTYPE[pntr]
    bytes > typemax(pntr) && throw(ArgumentError("The variable-length arrays of the field have $bytes bytes, which a $(sizeof(pntr)*8)-bit " *
        "array descriptor ($code) cannot address (Sect. 7.3.5). Use the 64-bit descriptor, Q."))
    (type, 1, 2sizeof(pntr), pntr, string(maximum(sizes; init = 0)), bytes, nothing)
end

#  The names of the fields of data that are a named tuple, or the default names of the fields of data that are a tuple, in records or columns
datanames(data::NamedTuple) = collect(keys(data))
datanames(data::Tuple) = [Symbol("column$j") for j = 1:length(data)]
datanames(data::AbstractArray) = datanames(first(data))

#  The repeat count, the type of the descriptor, and the data type of the value of a TFORMn, which say whether two TFORMn are the format of the same
#  field, whatever follows the data type: the largest number of elements of an array, which is not more than the arrays have, or the characters
#  of the legacy form rAw (Sect. 7.3.2)
function formcode(form)
    m = form isa AbstractString ? match(r"^\s*(\d*)([PQ]?)([A-Z])", form) : nothing
    isnothing(m) ? nothing : (isempty(m[1]) ? 1 : Base.parse(Int, m[1]), m[2], m[3])
end

#  The cards of the fields of an HDU that is made from data: the data are the fields, so a TFORMn or a TFIELDS that the cards give that is not the
#  format or the number of the fields of the data is set to it, with a warning (as it is for a table, see `correctfieldcards!`), but a P or a Q that
#  the card gives is the type of the array descriptor of the field, whose arrays may have the same length. The keyword `variable` gives the type of the
#  array descriptor, `'P'` (32-bit) or `'Q'` (64-bit), of the fields that it names, which are the names of the data, or their numbers, in a named tuple
#  or a dictionary, and has priority over the TFORMn card, which has priority over the lengths of the arrays (Sect. 7.3.5).
function keywordcards!(::Type{Bintable}, cards::Cards, data; variable = nothing, kwds...)
    data isa AbstractArray && isempty(data) && return cards
    columns = columnsof(data)
    names = datanames(data)
    #  The type of the array descriptor of each field that the keyword names
    descriptors = Dict{Int, Type}()
    requested = isnothing(variable) ? Pair{Any, Any}[] : collect(pairs(variable))
    for (key, code) in requested
        j = key isa Integer ? Int(key) : findfirst(==(Symbol(key)), names)
        (isnothing(j) || !(1 <= j <= length(columns))) && throw(ArgumentError("The keyword variable names the field $(repr(key)), " *
            "but the data have the fields $(join(repr.(names), ", "))."))
        letter = string(code)
        letter in ("P", "Q") || throw(ArgumentError("The descriptor of a variable-length field is 'P' or 'Q', but the keyword variable " *
            "has $(repr(code)) for the field $(repr(key))."))
        descriptors[j] = POINTERTYPE[letter]
    end
    if haskey(cards, "TFIELDS") && cards["TFIELDS"] != length(columns)
        @warn "TFIELDS set to $(length(columns)), the number of fields of the data."
        cards["TFIELDS"] = length(columns)
    end
    for j = 1:length(columns)
        key = "TFORM$j"
        given = haskey(cards, key)
        (given || haskey(descriptors, j)) || continue
        form = given ? cards[key] : nothing
        pntr = get(descriptors, j, nothing)
        isnothing(pntr) && form isa AbstractString && (m = match(r"^\s*\d*([PQ])", form); isnothing(m) || (pntr = POINTERTYPE[m[1]]))
        type, leng, _, pntr, supp = columndescriptor(columns[j], pntr)
        new = isnothing(pntr) ? "$leng$(BINARYTYPE[rawtype(type)])" : "$leng$(POINTERTYPE[pntr])$(BINARYTYPE[rawtype(type)])($supp)"
        #  The card of the field is kept, with the largest number of elements that it gives, if it is the format of the field
        formcode(form) == formcode(new) && !haskey(descriptors, j) && continue
        given && !haskey(descriptors, j) && @warn "$key set to $(repr(new)), the format of field $j of the data, and not " *
            "$(repr(form isa AbstractString ? rstrip(form) : form))."
        popat!(cards, key)
        push!(cards, Card(key, new))
    end
    cards
end

#  The data format of data of `nrows` rows: the bytes of a row and the rows, which are followed by the heap of the variable-length
#  arrays, whose bytes are PCOUNT, so that the heap begins after the table
function heapformat(data, nrows::Integer, keys::AbstractDict = Dict{String, Any}())
    cells = columnsof(data)
    length(cells) > MAXBINTABLEFIELDS && throw(ArgumentError("The data have $(length(cells)) fields, but a binary table has at most " *
        "$MAXBINTABLEFIELDS (Sect. 7.3.1)."))
    columns = [columndescriptor(values, forcedpointer(keys, j)) for (j, values) in enumerate(cells)]
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
        ismissing(other) && continue
        other isa AbstractString && checkascii(other)
        size(other) > size(value) && (value = other)
    end
    value isa AbstractString && checkascii(value)
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
        checkfieldtype(type)
        byts = leng*sizeof(type)
    else
        type, leng = typeof(field), 1
        checkfieldtype(type)
        byts = leng*sizeof(type)
    end
    (type, leng, byts)
end

#  The element types of a field are the types of Table 18 of the data types, and the physical types of Table 19 (Sect. 7.3.3)
function checkfieldtype(type::Type)
    haskey(BINARYTYPE, rawtype(type)) && return type
    throw(ArgumentError("The data have the element type $type, but the data of a field of a binary table have one of the types " *
        "of Table 18: Bool (L), BitVector (X), UInt8 (B), Int16 (I), Int32 (J), Int64 (K), String (A), Float32 (E), Float64 (D), " *
        "ComplexF32 (C), or ComplexF64 (M), or the physical types of Table 19: Int8, UInt16, UInt32, or UInt64 (Sect. 7.3.3)."))
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

#  The data of a table that has no data blocks are the empty columns of the fields, or the empty vector of records, whether the table has no rows or its
#  rows have no bytes, e.g., a field of strings of no characters, which are the empty values of the rows (Sect. 7.3.1). A table that has no fields has no
#  data.
function emptydata(::Type{Bintable}, format::DataFormat, fields::Vector{BinaryField}; kwds...)
    isempty(fields) ? missing : read(IOBuffer(UInt8[]), Bintable, format, fields; kwds...)
end

#  Name the data that are given as tuples, which are the columns or the records, by the names of the fields (see `FieldFormat`), so that they are
#  matched to the fields by name as named tuples are
namedata(::Type{Bintable}, data::Tuple, fields, format::DataFormat) = NamedTuple{Tuple(Symbol(field.name) for field in fields)}(data)
namedata(::Type{Bintable}, data::AbstractArray{<:Tuple}, fields, format::DataFormat) =
    [NamedTuple{Tuple(Symbol(field.name) for field in fields)}(record) for record in data]

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

#  The number of bytes of the rows of a table that are read at a time
const ROWCHUNKBYTES = 1 << 23

#  The `w` bytes of a field, which begin after the `M` bytes of the fields before it, of each of the `N` rows of `L` bytes of the table that begins
#  at `begpos`, as a matrix of `w` rows and `N` columns, one column for each row of the table. The rows are read a chunk of about
#  `ROWCHUNKBYTES` at a time, so that a column is read with a few reads and not a seek and a read for each row, and the bytes of the table are not
#  in memory at once.
function fieldbytes(io::IO, begpos::Integer, L::Integer, M::Integer, w::Integer, N::Integer; chunk::Integer = ROWCHUNKBYTES)
    bytes = Matrix{UInt8}(undef, w, N)
    (w == 0 || N == 0) && return bytes
    nrows = max(1, chunk ÷ L)
    buffer = Vector{UInt8}(undef, min(N, nrows) * L)
    for first = 1:nrows:N
        n = min(nrows, N - first + 1)
        seek(io, begpos + L*(first - 1))
        readbytes!(io, buffer, n*L) == n*L || throw(ArgumentError("The file has fewer bytes than the header of the HDU says."))
        copyto!(bytes, CartesianIndices((1:w, first:first+n-1)), reshape(view(buffer, 1:n*L), L, n), CartesianIndices((M+1:M+w, 1:n)))
    end
    bytes
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
            if leng == 0
                #  The repeat count 0 is an empty field of zero bytes, which has no descriptor, so the arrays are empty (Sect. 7.3.3.1)
                col = emptyarray(type)
            else
                seek(io, begpos + L*(j-1) + M)
                K   = Int(ntoh(read(io, field.pntr)))
                beg = Int(ntoh(read(io, field.pntr)))
                col = readarray(io, field, begpos + format.heap, K, beg, heaplen, j)
            end
            column[j] = scale ? physical(col, type, field.scale, field.zero) : col
        end
        column = map(identity, column)
    elseif type <: Bool
        #  The bytes of the N rows, which are T, F, or 0 for undefined (Sect. 7.3.3.1)
        column = decodelogical(permutedims(fieldbytes(io, begpos, L, M, length(field.slice), N)))
        column = leng == 1 ? reshape(column, :) : column
    elseif type <: BitVector
        bytes = fieldbytes(io, begpos, L, M, length(field.slice), N)
        column = BitVector[decodebits(view(bytes, :, j), leng) for j = 1:N]
    elseif type <: AbstractString
        #  The strings of an array of strings, whose first dimension is the number of characters of each, are the characters of the field in
        #  order (Sect. 7.3.2)
        dims = stringdims(field)
        column = isnothing(dims) ? Array{String}(undef, N) : Array{String}(undef, (N, dims[2:end]...))
        bytes = fieldbytes(io, begpos, L, M, length(field.slice), N)
        for j = 1:N
            if isnothing(dims)
                column[j] = decodestring(view(bytes, :, j))
            else
                for k = 1:prod(dims[2:end])
                    column[j + N*(k-1)] = decodestring(bytes[dims[1]*(k-1)+1:dims[1]*k, j])
                end
            end
        end
    else
        #  The numbers of the N rows, which are the values of a row in the second dimension if there are more than one (Sect. 7.3.3)
        values = ntoh.(reinterpret(type, fieldbytes(io, begpos, L, M, length(field.slice), N)))
        column = leng == 1 ? vec(values) : permutedims(values)
        column = nullcomplex(setmissing(column, field.null))
        column = scale ? physical(column, type, field.scale, field.zero) : column
    end
    scalefloats(applydims(column, field), field, scale)
end

#  Are the physical values of a field the same type as its stored values, which are floating-point or complex? They are if the field is
#  scaled by a TSCAL that is not 1 or a TZERO that is not 0 (Eq. 7). The values do not say that they are scaled, so they are a
#  `ScaledArray`, which has the scale and the zero, and is written as the stored values.
physicalfloat(field::BinaryField) = !isnothing(field.scale) && field.type <: Union{AbstractFloat, Complex} &&
    !(field.scale == 1 && field.zero == 0)

function scalefloats(column, field::BinaryField, scale::Bool)
    scale && physicalfloat(field) || return column
    isnothing(field.pntr) ? ScaledArray(column, field.scale, field.zero) :
        map(cell -> ScaledArray(cell, field.scale, field.zero), column)
end

####    The data of a binary table that is mapped    ####

#  The data of a binary table that is read from a file, memory-mapped (see `mapdata`): the fields of a fixed number of elements, which are the bytes of
#  the rows of the table in the file, are mapped, and the fields of variable-length arrays, which are in the heap, are read at once. The records
#  (`record = true`) are not mapped.
mappable(::Type{Bintable}) = true
mappable(::Type{Bintable}, keywds::NamedTuple) = !get(keywds, :record, false)

#  Is a field mapped? It has a fixed number of elements, which are in the row of the table, and not an array in the heap.
mappedfield(field::BinaryField) = isnothing(field.pntr)

function mapdata(::Type{Bintable}, data::LazyArray)
    get(data.keywds, :record, false) && throw(ArgumentError("The data of a binary table that are records cannot be mapped."))
    format, fields, scale = data.format, data.fields, get(data.keywds, :scale, true)
    mapped = any(mappedfield, fields)
    bytes = mapped ? (format.leng == 0 ? UInt8[] : mappedvalues(data)) : UInt8[]
    columns = Any[]
    io = openlazy(data)
    try
        for field in fields
            push!(columns, mappedfield(field) ? mappedcolumn(bytes, field, format, scale, data) :
                read(io, field, format, data.begpos; scale))
        end
    finally
        close(io)
    end
    (; [Symbol(field.name) => column for (field, column) in zip(fields, columns)]...)
end

#  The undefined value of a logical is a 0 byte, and the value of the others is whether the byte is a T (Sect. 7.3.3.1), and the value of a complex
#  number is undefined if its real or its imaginary part is a NaN. The values of an array of them are always of the type that has `missing`, since
#  the data would have to be read to know that none of them is undefined.
logicalvalue(byte::UInt8) = byte == 0x00 ? missing : byte == UInt8('T')
logicalvalues(raw::AbstractArray{UInt8}) = (out = Array{Union{Missing, Bool}}(undef, size(raw)); out .= logicalvalue.(raw); out)
undefinedcomplex(value::Complex) = isnan(real(value)) || isnan(imag(value))
function nullcomplexes(raw::AbstractArray{C}) where C<:Complex
    out = Array{Union{Missing, C}}(raw)
    out[undefinedcomplex.(raw)] .= missing
    out
end

function mappedcolumn(bytes::Vector{UInt8}, field::BinaryField, format::DataFormat, scale::Bool, source::LazyArray)
    type, leng = field.type, field.leng
    N = format.shape[2]
    scale = scale && !isnothing(field.scale)
    offset = first(field.slice) - 1
    if type <: Bool
        #  The values of a row are in the second and later dimensions if there are more than one: the dimensions TDIMn, or the elements
        dims = leng == 1 ? nothing : arraydims(field)
        shape = !isnothing(dims) ? (N, dims...) : leng == 1 ? (N,) : (N, leng)
        column = MappedColumn(bytes, format.shape[1], offset, shape, 1, 1, logicalvalues, logicalvalue, zeros(UInt8, 1), source)
    elseif type <: BitVector
        #  The bits of a row are a vector, or an array of the dimensions TDIMn if there are two or more and they have no more elements
        dims = field.dims
        n = isnothing(dims) || length(dims) < 2 ? nothing : prod(dims)
        !isnothing(n) && leng > 0 && warnshortarrays(field, dims, n > leng ? N : 0)
        cell(bits) = isnothing(n) || n > length(bits) ? bits : reshape(bits[1:n], dims)
        column = MappedColumn(bytes, format.shape[1], offset, (N,), leng, sizeofbitvector(leng), raw -> map(cell, raw), cell,
            [falses(leng)], source)
    elseif type <: AbstractString
        #  The strings of an array of strings have the characters of the first dimension, and are in the later dimensions (Sect. 7.3.2)
        dims = stringdims(field)
        width = isnothing(dims) ? leng : dims[1]
        shape = isnothing(dims) ? (N,) : (N, dims[2:end]...)
        column = MappedColumn(bytes, format.shape[1], offset, shape, width, width, identity, identity, [""], source)
    else
        #  The numbers are those of the file, with `missing` for the undefined values (Sect. 7.3.2), and are scaled (Eq. 7), with the complex numbers
        #  that have a NaN undefined (Sect. 7.3.3.1)
        dims = leng == 1 ? nothing : arraydims(field)
        shape = !isnothing(dims) ? (N, dims...) : leng == 1 ? (N,) : (N, leng)
        complex = type <: Complex
        scaled1 = scale ? physicalfunction(type, field.scale, field.zero) : identity
        isnull(x) = !isnothing(field.null) && x == field.null
        value = complex ? x -> undefinedcomplex(x) || isnull(x) ? missing : scaled1(x) :
            isnothing(field.null) ? scaled1 : x -> isnull(x) ? missing : scaled1(x)
        function decode(raw)
            values = setmissing(raw, field.null)
            values = complex ? nullcomplexes(values) : values
            scale ? physical(values, type, field.scale, field.zero) : values
        end
        probe = complex ? [zero(type), type(NaN, NaN)] : field.null isa Integer && typemin(type) <= field.null <= typemax(type) ?
            type[0, field.null] : zeros(type, 1)
        column = MappedColumn(bytes, format.shape[1], offset, shape, 1, sizeof(type), decode, value, probe, source)
    end
    scalefloats(column, field, scale)
end

"""
    MappedColumn(bytes, rowlen, offset, size, count, stride, decode, value, probe, source)

The values of a field of a fixed number of elements of a binary table that is read in place from its file, which is memory-mapped, so that only the
values that are indexed are read from the file. The `bytes` are the bytes of the table in the file, whose rows are `rowlen` bytes, and the field begins
`offset` bytes after the beginning of a row. The first axis of the array is the rows, and the elements of a row are the later axes, which are `size`.
Each element is `stride` bytes, and has `count` characters of a string or bits of a bit array. The type of the values of the file is that of the
`probe`, which has values of the file: a number, a byte of a logical, a string, or a bit array. The function `decode` is that of an array of the values
of the file to the values of the field, and `value` is that of one value, as for a [`FITSFiles.MappedArray`](@ref), and the type of the values is
that of `decode` of the `probe`. The `source` is the lazy array of the HDU that the values are read from, which the data are copied from when the HDU
is written. The array is read-only.
"""
struct MappedColumn{T, N, R, F, G, S} <: AbstractArray{T, N}
    bytes::Vector{UInt8}
    rowlen::Int
    offset::Int
    size::NTuple{N, Int}
    count::Int
    stride::Int
    decode::F
    value::G
    source::S
end

function MappedColumn(bytes::Vector{UInt8}, rowlen::Integer, offset::Integer, size::NTuple{N, Int}, count::Integer, stride::Integer, decode, value,
    probe::AbstractVector{R}, source) where {N, R}

    T = eltype(decode(probe))
    MappedColumn{T, N, R, typeof(decode), typeof(value), typeof(source)}(bytes, rowlen, offset, size, count, stride, decode, value, source)
end

lazysource(column::MappedColumn) = column.source
Base.size(column::MappedColumn) = column.size
Base.IndexStyle(::Type{<:MappedColumn}) = IndexCartesian()

#  The unsigned integer of the size of a type, whose bytes, which are in the order of the file (big-endian), are the bytes of the value
unsignedtype(::Type{R}) where R = sizeof(R) == 1 ? UInt8 : sizeof(R) == 2 ? UInt16 : sizeof(R) == 4 ? UInt32 : UInt64

#  The value of the type `R` of the bytes that begin at the place `pos`, which are in the order of the file, so the order of the machine is not used.
#  The real and the imaginary part of a complex number are in order, and a string or a bit array has `count` characters or bits.
@inline function rawelement(::Type{R}, bytes::Vector{UInt8}, pos::Integer, count::Integer) where R<:Union{Integer, AbstractFloat}
    U = unsignedtype(R)
    bits = zero(U)
    @inbounds for i = 0:sizeof(U)-1
        bits = (bits << 8) | U(bytes[pos + i])
    end
    reinterpret(R, bits)
end
@inline rawelement(::Type{Complex{F}}, bytes::Vector{UInt8}, pos::Integer, count::Integer) where F =
    Complex(rawelement(F, bytes, pos, count), rawelement(F, bytes, pos + sizeof(F), count))
@inline rawelement(::Type{String}, bytes::Vector{UInt8}, pos::Integer, count::Integer) = decodestring(view(bytes, pos:pos + count - 1))
@inline rawelement(::Type{BitVector}, bytes::Vector{UInt8}, pos::Integer, count::Integer) =
    decodebits(view(bytes, pos:pos + sizeofbitvector(count) - 1), count)

#  The value of the file of the row `j` and the element `k` of the row
@inline rawvalue(column::MappedColumn{T, N, R}, j::Integer, k::Integer) where {T, N, R} =
    rawelement(R, column.bytes, column.offset + (j - 1)*column.rowlen + (k - 1)*column.stride + 1, column.count)

#  The element of a row of the indices `I` of the axes after the first
@inline elementindex(column::MappedColumn, I::Tuple{}) = 1
@inline elementindex(column::MappedColumn, I::Tuple) = LinearIndices(Base.tail(column.size))[I...]

Base.@propagate_inbounds function Base.getindex(column::MappedColumn{T, N}, I::Vararg{Int, N}) where {T, N}
    @boundscheck checkbounds(column, I...)
    column.value(rawvalue(column, I[1], elementindex(column, Base.tail(I))))
end

#  A slice, of ranges, integers, and colons, is read from the file as an array of the values that are indexed
function Base.getindex(column::MappedColumn{T, N, R}, I::Vararg{Union{Colon, Integer, AbstractRange{<:Integer}}, N}) where {T, N, R}
    checkbounds(column, I...)
    ranges = map((i, n) -> i isa Colon ? (1:n) : i isa Integer ? (i:i) : i, I, size(column))
    raw = Array{R}(undef, map(length, ranges))
    for (n, index) in enumerate(CartesianIndices(ranges))
        raw[n] = rawvalue(column, index[1], elementindex(column, Base.tail(Tuple(index))))
    end
    keep = Tuple(length(range) for (range, i) in zip(ranges, I) if !(i isa Integer))
    length(keep) == 0 ? column.value(only(raw)) : column.decode(reshape(raw, keep))
end

Base.getindex(column::MappedColumn, i::Int) = column[CartesianIndices(column)[i].I...]

Base.setindex!(column::MappedColumn, value, I...) = throw(ArgumentError("A mapped field of the data of an HDU is read-only, since its values are " *
    "those of the file. Change a copy of the array, e.g., `collect(column)`."))

Base.Array(column::MappedColumn{T, N}) where {T, N} = column[ntuple(_ -> Colon(), Val(N))...]
Base.collect(column::MappedColumn) = Array(column)
Base.copy(column::MappedColumn) = Array(column)

"""
    ScaledTable(records, scales)

The records of a binary table (`record = true`) that has fields of floating-point or complex stored values that are scaled by a TSCALn and a
TZEROn. The values of those fields are the physical values (see [`ScaledArray`](@ref)), which the dictionary `scales` has the scale and the
zero of, by the name of the field, and are written as the stored values. The records are the values of `parent`.
"""
struct ScaledTable{R, V<:AbstractVector{R}} <: AbstractVector{R}
    parent::V
    scales::Dict{Symbol, Tuple{Any, Any}}
end

Base.parent(table::ScaledTable) = table.parent
Base.size(table::ScaledTable) = size(table.parent)
Base.IndexStyle(::Type{<:ScaledTable}) = IndexLinear()
Base.getindex(table::ScaledTable, i::Int) = table.parent[i]
Base.setindex!(table::ScaledTable, value, i::Int) = (table.parent[i] = value; table)
Base.copy(table::ScaledTable) = ScaledTable(copy(table.parent), table.scales)

#  The scale and the zero of a field of the data, if its values are the physical values of floating-point stored values, and nothing if they are
#  the stored values
physicalscale(data::NamedTuple, field::BinaryField) = (column = data[Symbol(field.name)];
    column isa ScaledArray ? (column.scale, column.zero) : nothing)
physicalscale(data::ScaledTable, field::BinaryField) = get(data.scales, Symbol(field.name), nothing)
physicalscale(data, field::BinaryField) = nothing

#  The TSCALn and TZEROn cards of the fields that are the physical values of floating-point stored values, which have the scale and the zero of
#  the data
function scalecards!(::Type{Bintable}, cards::Cards, data::Union{NamedTuple, Tuple})
    for (j, column) in enumerate(data)
        column isa ScaledArray || continue
        setscalecard!(cards, "TSCAL$j", column.scale, 1)
        setscalecard!(cards, "TZERO$j", column.zero, 0)
    end
    cards
end
function scalecards!(::Type{Bintable}, cards::Cards, data::ScaledTable)
    for (j, name) in enumerate(keys(data[1]))
        haskey(data.scales, name) || continue
        setscalecard!(cards, "TSCAL$j", data.scales[name][1], 1)
        setscalecard!(cards, "TZERO$j", data.scales[name][2], 0)
    end
    cards
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
        #  The cells of a variable-length array, or of a bit array, are the elements of the arrays that are the rows. An array has at least the
        #  elements that the dimensions have (Sect. 7.3.2), and is not reshaped if it has fewer, which is a warning, but not for an array of no
        #  elements, which TDIMn is not applicable to.
        isnothing(field.pntr) && !(field.type <: BitVector) || warnshortarrays(field, dims, count(cell -> 0 < length(cell) < n, column))
        return map(cell -> n <= length(cell) ? reshape(cell[1:n], dims) : cell, column)
    end
    isnothing(arraydims(field)) && return column
    reshape(column[:, 1:n], (size(column, 1), dims...))
end

#  The warning that `short` arrays of a field have fewer elements than the dimensions TDIMn, which they are not reshaped by
function warnshortarrays(field::BinaryField, dims, short::Integer)
    short > 0 && @warn "TDIM of field $(field.name), $(join(dims, " × ")), has $(prod(dims)) elements, but $short of its arrays $(short == 1 ? "has" : "have") " *
        "fewer (Sect. 7.3.2), so $(short == 1 ? "it is" : "they are") not reshaped."
end

#  The dimensions TDIMn of the array of each row of a field of numbers, if they are used: there are two or more, and they have no more elements than
#  the field has, which is a warning if they have more (Sect. 7.3.2). They are nothing if they are not used.
function arraydims(field::BinaryField)
    dims = field.dims
    (isnothing(dims) || length(dims) < 2) && return nothing
    if prod(dims) > field.leng
        @warn "TDIM of field $(field.name), $(join(dims, " × ")), has $(prod(dims)) elements, more than the $(field.leng) of its TFORM " *
            "(Sect. 7.3.2), so it is not used."
        return nothing
    end
    dims
end

#  The array of no elements of a field of the type `type`, which is the value of an array that has no storage
emptyarray(type::Type) = type <: Bool ? Bool[] : type <: AbstractString ? "" : type <: BitVector ? falses(0) : type[]

#  The elements of the variable-length array of the descriptor (`K`, `beg`) of row `j`, which are read from the heap that begins at the
#  position `heap` and has `heaplen` bytes. The storage of an array must lie entirely in the heap, and a negative length or offset is
#  not defined (Sect. 7.3.5), so the array is read as empty, with a warning. An array of no elements has no storage.
function readarray(io::IO, field::BinaryField, heap::Integer, K::Integer, beg::Integer, heaplen::Integer, j::Integer)
    type = field.type
    empty = emptyarray(type)
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
        #  The values are changed to the byte order of the machine where they are, so they are not copied
        map!(ntoh, values, values)
        nullcomplex(setmissing(values, field.null))
    end
end

#  The stored values of the physical values of a cell: the values of the offsets of Table 19 have the offset, and the values that are
#  not of the type of the field are inverted from the scale and the zero (Eq. 7), as the values of an array of an image are
function storedcell(field::BinaryField, value; check::Bool = true, physical = nothing)
    #  The values of the data that are the physical values of floating-point stored values are inverted, if the data have the scale and the
    #  zero of the header
    if !isnothing(physical) && !isnothing(field.scale)
        physical == (field.scale, field.zero) || throw(ArgumentError("The scale and the zero of the data of field $(field.name), " *
            "$(physical[1]) and $(physical[2]), are not the TSCAL and the TZERO of the header, $(field.scale) and $(field.zero)."))
        return invertscale(value, field.type, field.scale, field.zero)
    end
    (isnothing(field.scale) || field.type <: Union{Bool, BitVector, AbstractString} ||
        (field.scale == 1 && field.zero == 0 && !haskey(OFFSETTYPE, field.type))) && return value
    stored(values) = storedvalues(values, field.type, field.scale, field.zero, field.null; check)
    value isa AbstractArray ? stored(value) : only(stored([value]))
end

#  Does the value, or the array of values, have an undefined value?
hasmissing(value) = value isa Missing || (value isa AbstractArray && any(ismissing, value))

#  The integer TNULLn of a field, which stands for an undefined value, is a value of the type of the field (Sect. 7.3.2), so that the undefined
#  values can be written
function checknull(field::BinaryField)
    type, null = field.type, field.null
    (isnothing(null) || (type <: Union{UInt8, Int16, Int32, Int64} && typemin(type) <= null <= typemax(type))) && return
    throw(ArgumentError("TNULL of field $(field.name), $null, is not a value of the $type of the field, from $(typemin(type)) " *
        "to $(typemax(type)) (Sect. 7.3.2), so the undefined values cannot be written."))
end

#  The stored values (value - TZERO)/TSCAL of the physical values of floating-point or complex values (Eq. 7), whose undefined values are missing
function invertscale(values, type::Type, scale::Real, zero::Real)
    scale == 0 && throw(ArgumentError("The values cannot be written as stored values, since TSCAL is 0."))
    wide(x) = x isa Complex ? ComplexF64(x) : Float64(x)
    stored(x) = ismissing(x) ? missing : type((wide(x) - wide(zero)) / wide(scale))
    values isa AbstractArray ? map(stored, values) : stored(values)
end

function Base.write(io::IO, field::BinaryField, value::U; check::Bool = true, physical = nothing, kwds...) where
    U <: Union{AbstractArray, AbstractString, BitVector, Real, Complex, Missing}

    type, leng = field.type, field.leng
    #  The elements of an array are written, and the elements of the field that follow them, which are the elements that TDIMn does not
    #  use, are zeros, so that the field has its bytes in every row. An array that has more elements than the field has would shift the
    #  fields after it.
    n = value isa AbstractArray ? length(value) : 1
    type <: AbstractString || n <= leng || throw(ArgumentError("The array of field $(field.name) has $n elements, " *
        "but the field has $leng (Sect. 7.3.1)."))
    #  A logical value is written as T or F, and an undefined value as a 0 byte (Sect. 7.3.3.1)
    type <: Bool && return leng == 0 ? 0 : write(io, padelements(encodelogical.(value), leng, 0x00))
    #  The stored values of the physical values, and the undefined values, which are written as TNULLn (Sect. 7.3.2), or NaN for
    #  floating-point data
    value = storedcell(field, value; check, physical)
    hasmissing(value) && checknull(field)
    value = unsetmissing(value, field.null, type)

    if type <: AbstractString && value isa AbstractArray
        #  The strings of an array of strings are the characters of the field in order, with the number of characters of the first
        #  dimension of TDIMn (Sect. 7.3.2)
        dims = stringdims(field)
        isnothing(dims) && throw(ArgumentError("The array of strings of field $(field.name) needs the dimensions of TDIM, " *
            "whose first dimension is the number of characters of a string (Sect. 7.3.2)."))
        bytes = reduce(vcat, [padstring(string, dims[1]) for string in value]; init = UInt8[])
        length(bytes) > leng && throw(ArgumentError("The strings of field $(field.name) have $(length(bytes)) bytes, but the field has $leng."))
        write(io, vcat(bytes, fill(UInt8(' '), leng - length(bytes))))
    elseif type <: AbstractString
        write(io, padstring(value, field.leng))
    elseif type <: BitVector
        write(io, type, BitVector(padelements(value, leng, false)))
    elseif leng == 0
        0
    elseif leng == 1
        write(io, hton(value))
    else
        write(io, hton.(padelements(value, leng, zero(type))))
    end
end

#  The elements of an array and the `pad` elements that follow them up to `leng` elements
padelements(values::AbstractArray, leng::Integer, pad) = length(values) < leng ? vcat(values, fill(pad, leng - length(values))) : values
padelements(value, leng::Integer, pad) = value

#  A complex value that has a NaN as its real part or as its imaginary part is undefined, as a whole, and is missing (Sect. 7.3.3.1)
nullcomplex(values::AbstractArray{<:Complex}) = any(value -> isnan(real(value)) || isnan(imag(value)), values) ?
    map(value -> isnan(real(value)) || isnan(imag(value)) ? missing : value, values) : values
nullcomplex(values) = values

#  The string of the bytes of a field of characters, which ends at the first ASCII NULL, since the characters after it are not defined, and
#  without the spaces that fill the field (Sect. 7.3.3.1)
function decodestring(bytes::AbstractVector{UInt8})
    nul = findfirst(==(0x00), bytes)
    String(rstrip(String(bytes[1:(isnothing(nul) ? length(bytes) : nul - 1)])))
end

#  The characters of a field are the restricted set of ASCII text characters (Sect. 7.3.3.1)
checkascii(value::AbstractString) = isascii(value) ? value : throw(ArgumentError("The string $(repr(value)) has characters that " *
    "are not ASCII, but the characters of a field of a binary table are the ASCII text characters (Sect. 7.3.3.1)."))

#  The bytes of a string in a field of `width` bytes, which are filled with spaces. A string that is longer than the field is an error,
#  since its bytes would be those of the fields after it.
function padstring(value::AbstractString, width::Integer)
    checkascii(value)
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
    decodebits(read(io, sizeofbitvector(len)), len)
end

decodebits(bytes::AbstractVector{UInt8}, len::Integer) =
    BitVector([bytes[(j-1) >> 3 + 1] & (0x80 >> ((j-1) & 7)) != 0 for j = 1:len])

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

#  The bytes of the table, NAXIS1 × NAXIS2, and the bytes of the heap, PCOUNT, are at most the largest integer, so that the data can be read
#  and indexed (Sect. 7.3.1)
function verifysize(::Type{Bintable}, mankeys::AbstractDict)
    nbytes = BigInt(get(mankeys, "NAXIS1", 0)) * BigInt(get(mankeys, "NAXIS2", 0)) + BigInt(get(mankeys, "PCOUNT", 0))
    nbytes > typemax(Int) && throw(ArgumentError("The table is too large: NAXIS1 × NAXIS2 + PCOUNT, " *
        "$(get(mankeys, "NAXIS1", 0)) × $(get(mankeys, "NAXIS2", 0)) + $(get(mankeys, "PCOUNT", 0)) bytes, is more than " *
        "$(typemax(Int)) bytes."))
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
        nulltype = get(NULLTYPES, type, nothing)
        null = get(reskeys, "TNULL$j", nothing)
        !isnothing(nulltype) && null isa Integer && !(typemin(nulltype) <= null <= typemax(nulltype)) && @warn "TNULL$j, $null, " *
            "is not a value of the $nulltype of its field, from $(typemin(nulltype)) to $(typemax(nulltype)) (Sect. 7.3.2), so no " *
            "value is undefined. The undefined values cannot be written."
        verifyextremes(reskeys, j, type)
        disp = get(reskeys, "TDISP$j", nothing)
        if disp isa AbstractString && !occursin(TDISPFORM, strip(disp))
            @warn "TDISP$j must be a display format of Table 20 (Sect. 7.3.2), but its value is $(repr(disp)). It is read as it is."
        elseif disp isa AbstractString
            #  The display format is one that Sect. 7.3.4 gives for the type of the field
            code = match(r"^[A-Z]+", strip(disp)).match
            code in DISPCODES[type] || @warn "TDISP$j, $(repr(strip(disp))), is not a display format for a field of type $type " *
                "(Sect. 7.3.4), which has the formats $(join(DISPCODES[type], ", ")). It is read as it is."
        end
        name = get(reskeys, "TTYPE$j", nothing)
        if name isa AbstractString && !isempty(strip(name))
            other = get(names, lowercase(rstrip(name)), 0)
            if other > 0
                renamed = rstrip(name) == rstrip(reskeys["TTYPE$other"]) ? " The column of the data of TTYPE$j is named $(rstrip(name))_$j." : ""
                @warn "TTYPE$j and TTYPE$other have the same name, $(repr(rstrip(name))), without regard to the case, but the " *
                    "names of the fields should be unique (Sect. 7.3.2).$renamed"
            else
                names[lowercase(rstrip(name))] = j
            end
        end
    end
    nothing
end

#  The display formats of Table 20: Aw, Lw, Iw.m, Bw.m, Ow.m, Zw.m, Fw.d, Ew.dEe, ENw.d, ESw.d, Gw.dEe, and Dw.dEe, in upper case
#  The minimum and maximum values of a column, TDMINn and TDMAXn, and the minimum and maximum valid values, TLMINn and TLMAXn, have the data
#  type of the physical values of the column, an integer or a floating-point number (Sect. 7.3.2). The physical values of a field of type B,
#  I, J, or K are integers if TSCALn is 1 and TZEROn is an integer, and those of a field of type E or D are floating-point numbers.
function verifyextremes(reskeys::AbstractDict, j::Integer, type::AbstractString)
    type in ("B", "I", "J", "K", "E", "D") || return
    scale, zero = get(reskeys, "TSCAL$j", 1), get(reskeys, "TZERO$j", 0)
    integers = type in ("B", "I", "J", "K") && scale isa Real && zero isa Real && scale == 1 && isinteger(zero)
    for key in ("TDMIN$j", "TDMAX$j", "TLMIN$j", "TLMAX$j")
        value = get(reskeys, key, nothing)
        (value isa Real && !(value isa Bool)) || continue
        if integers && !(value isa Integer)
            @warn "$key must be an integer, since the values of field $j are integers (Sect. 7.3.2), but its value is $(repr(value)). " *
                "It is read as it is."
        elseif !integers && value isa Integer
            @warn "$key must be a floating-point number, since the values of field $j are floating-point numbers (Sect. 7.3.2), " *
                "but its value is $(repr(value)). It is read as it is."
        end
    end
end

#  The codes of the display formats of Table 20 that a field of each data type of Table 18 has (Sect. 7.3.4): characters are Aw and logical
#  values are Lw; the integers, and the bits, are Iw.m, Bw.m, Ow.m, and Zw.m, or are real values, Fw.d, Ew.d, Dw.d, ENw.d, and ESw.d, as they
#  are for scaled values; the real and complex values are real values; and Gw.d is for the data of any type.
const DISPCODES = let integer = ["I", "B", "O", "Z", "F", "E", "D", "EN", "ES", "G"], real = ["F", "E", "D", "EN", "ES", "G"]
    Dict("A" => ["A", "G"], "L" => ["L", "G"], "X" => integer, "B" => integer, "I" => integer, "J" => integer, "K" => integer,
        "E" => real, "D" => real, "C" => real, "M" => real)
end

#  The types of the stored values of the fields that have an integer TNULLn, B, I, J, and K
const NULLTYPES = Dict("B" => UInt8, "I" => Int16, "J" => Int32, "K" => Int64)

const TDISPFORM = r"^(A\d+|L\d+|[IBOZ]\d+(\.\d+)?|F\d+\.\d+|(E|EN|ES|G|D)\d+\.\d+(E\d+)?)$"

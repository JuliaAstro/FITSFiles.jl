#=    Improvements

 * type mappings, e.g., F6.2 to Float32, etc.
 * more tests

 =#

####    Table HDU functions

"""
	Table header-data unit (HDU)

A Table HDU consists of a vector of cards and optionally a 2-dimensional array
of ASCII data structured as vector of records.
"""
struct Table <: AbstractHDU end
XTENSIONTYPE["TABLE"] = Table

#  The mandatory and reserved keywords of the HDU (see `getreservedkeys`)
union!(MANDATORYKEYS, ["XTENSION", "PCOUNT", "GCOUNT", "TFIELDS", "TFORM", "TBCOL"])
union!(RESERVEDKEYS, ["INHERIT", "TFIELDS", "TFORM", "TBCOL", "TSCAL", "TZERO", "TNULL", "TTYPE", "TUNIT", "TDISP",
    "TDMAX", "TDMIN", "TLMAX", "TLMIN"])

#  The fill after the data is ASCII spaces (see `verifyfill`)
fillrule(::Type{Table}) = (0x20, "ASCII spaces", "Sect. 7.2.3")

const TABLEFMT = Regex("(?<t>[AIFED])(?<w>\\d+)(\\.(?<f>\\d+))?")

const TABLETYPE = Dict(
    "A" => String, "I" => Int64, "F" => Float64, "E" => Float64, "D" => Float64,
    String => "A", Int64 => "I", Float64 => "F", Float32 => "E", Float64 => "D")

"""
    TableField(name, type, slice, unit, form, disp, zero, scale, null,
        dmin, dmax, lmin, lmax)

Table array element descriptor
"""
struct TableField <: AbstractField
    "The name of the field"
    name::String
    "The type of the field"
    type::Type
    "The slice of the field from start of record"
    slice::UnitRange{Int}
    "The unit of the field"
    unit::String
    "The format of the field"
    form::String
    "The display of the field"
    disp::String
    "The offset of the field"
    zero::Union{AbstractFloat, Nothing}
    "The scale of the field"
    scale::Union{AbstractFloat, Nothing}
    "The null value of the field"
    null::Union{String, Nothing}
    "The minimum display value of the field"
    dmin::Union{AbstractFloat, Nothing}
    "The maximum display value of the field"
    dmax::Union{AbstractFloat, Nothing}
    "The minimum physical value of the field"
    lmin::Union{AbstractFloat, Nothing}
    "The maximum physical value of the field"
    lmax::Union{AbstractFloat, Nothing}
end

function Base.read(io::IO, type::Type{Table}, format::DataFormat,
    fields::Vector{TableField}; record::Bool = false, kwds...)

    begpos = position(io)
    M, N = format.shape[1], format.shape[2]
    #  Read data array
    if record
        row = [String(read(io, M)) for j = 1:N]
        data = [(; [read(row[j], field; kwds...) for field in fields]...)
            for j = 1:N]
    else
        data = (; [Symbol(field.name) =>
            read(io, field, format, begpos; kwds...) for field in fields]...)
    end
    #  Seek to the end of the block
    # seek(io, begpos + BLOCKLEN*div(M*N, BLOCKLEN, RoundUp))

    ####    Apply WCS
    data
end

#  The value of a field in row `j` of the data, which is a vector of records or a named tuple of columns,
#  where each column has one value for each row.
getcell(::Type{Table}, data::AbstractArray, field, j::Integer) = data[j][Symbol(field.name)]
getcell(::Type{Table}, data::NamedTuple, field, j::Integer) = data[Symbol(field.name)][j]

function Base.write(io::IO, ::Type{Table}, data::Union{AbstractArray, NamedTuple},
    format::DataFormat, fields::Vector{TableField}; kwds...)

    #  Write data array
    N = format.shape[2]
    if N > 0
        for j=1:N
            begpos = position(io)
            for field in fields
                write(io, getcell(Table, data, field, j), field, begpos; kwds...)
            end
            write(io, repeat(" ", format.shape[1]-(position(io)-begpos)))
        end
        #  Pad last block with spaces
        padblock(io, format, 0x20)
    end
end

function verify!(::Type{Table}, cards::Cards, mankeys::AbstractDict, reskeys::AbstractDict)
    cards = invoke(verify!, Tuple{Type{<:AbstractHDU}, Cards, AbstractDict, AbstractDict}, Table, cards,
        mankeys, reskeys)
    verifyrows(Table, mankeys)
    #  An ASCII table has a single table and no heap (Sect. 7.2.1)
    verifyvalue(mankeys, "PCOUNT", 0:0, "the integer 0")
    verifyvalue(mankeys, "GCOUNT", 1:1, "the integer 1")
    #  The number of fields and the first columns of the fields are integers (Sect. 7.2.1)
    verifyinteger(mankeys, r"^(TFIELDS|TBCOL\d+)$")
    verifyfields!(Table, cards, mankeys)
end

function verify!(::Type{Table}, cards::Cards, format::DataFormat,
    mankeys::AbstractDict)

    verifyshape!(cards, mankeys, format)
end

function DataFormat(::Type{Table}, data::Missing, mankeys::Dict{S, V}) where
    {S<:AbstractString, V<:ValueType}

    #  Determine format from data
    type  = BITS2TYPE[get(mankeys, "BITPIX", 8)]
    leng  = datalength(mankeys, 1)
    shape = datasize(mankeys, 1)
    param = get(mankeys, "PCOUNT", 0)
    group = get(mankeys, "GCOUNT", 1)
    heap  = 0
    DataFormat(type, leng, shape, param, group, heap)
end

function FieldFormat(::Type{Table}, format::DataFormat, reskeys::Dict{S, V},
    data::Missing; record::Bool = false, kwds...) where {S<:AbstractString, V<:ValueType}

    N = get(reskeys, "TFIELDS", 0)

    fields = Vector{TableField}(undef, N)
    for j = 1:N
        fmt   = match(TABLEFMT, reskeys["TFORM$j"])

        name  = rstrip(get(reskeys, "TTYPE$j", record ? "field$j" : "column$j"))
        type  = TABLETYPE[fmt[:t]]
        leng  = Base.parse(Int64, fmt[:w])
        k     = reskeys["TBCOL$j"]
        unit  = get(reskeys, "TUNIT$j", "")
        form  = fmt.match
        disp  = get(reskeys, "TDISP$j", "")
        tzero = leastfloat(get(reskeys, "TZERO$j",
            type <: String ? nothing : 0.0f0))
        tscal = leastfloat(get(reskeys, "TSCAL$j",
            type <: String ? nothing : 1.0f0))
        null  = get(reskeys, "TNULL$j", nothing)
        dmin  = parsestring(get(reskeys, "TDMIN$j", nothing))
        dmax  = parsestring(get(reskeys, "TDMAX$j", nothing))
        lmin  = parsestring(get(reskeys, "TLMIN$j", nothing))
        lmax  = parsestring(get(reskeys, "TLMAX$j", nothing))

        fields[j] = TableField(name, type, k:k+leng-1, unit, form, disp,
            tzero, tscal, null, dmin, dmax, lmin, lmax)
    end
    fields
end

function DataFormat(::Type{Table}, data::AbstractArray,
    mankeys::Dict{S, V}) where {S<:AbstractString, V<:ValueType}

    #  Determine format from data
    n   = mankeys["TFIELDS"]
    fmt = match(TABLEFMT, mankeys["TFORM$n"])
    type  = BITS2TYPE[8]
    shape = (mankeys["TBCOL$n"] + Base.parse(Int64, fmt[:w]) - 1, length(data))
    leng  = prod(shape)
    param = get(mankeys, "PCOUNT", 0)
    group = get(mankeys, "GCOUNT", 1)
    heap = 0
    DataFormat(type, leng, shape, param, group, heap)
end

function FieldFormat(::Type{Table}, format::DataFormat, reskeys::Dict{S, V},
    data::AbstractArray, columns=nothing, formats=nothing; kwds...) where
    {S<:AbstractString, V<:ValueType}

    N = get(reskeys, "TFIELDS", 0)

    fields = Vector{TableField}(undef, N)
    for j = 1:N
        fmt = match(TABLEFMT, !isnothing(formats) ? formats[j] :
            reskeys["TFORM$j"])

        name  = rstrip(get(reskeys, "TTYPE$j", "field$j"))
        type  = TABLETYPE[fmt[:t]]
        leng  = Base.parse(Int64, fmt[:w])
        k     = !isnothing(columns) ? columns[j] : reskeys["TBCOL$j"]
        unit  = get(reskeys, "TUNIT$j", "")
        form  = fmt.match
        disp  = get(reskeys, "TDISP$j", "")
        tzero = leastfloat(get(reskeys, "TZERO$j",
            type <: String ? nothing : 0.0f0))
        tscal = leastfloat(get(reskeys, "TSCAL$j",
            type <: String ? nothing : 1.0f0))
        null  = get(reskeys, "TNULL$j", nothing)
        dmin  = parsestring(get(reskeys, "TDMIN$j", nothing))
        dmax  = parsestring(get(reskeys, "TDMAX$j", nothing))
        lmin  = parsestring(get(reskeys, "TLMIN$j", nothing))
        lmax  = parsestring(get(reskeys, "TLMAX$j", nothing))

        fields[j] = TableField(name, type, k:k+leng, unit, form, disp,
            tzero, tscal, null, dmin, dmax, lmin, lmax)
    end
    fields
end

function DataFormat(::Type{Table}, data::U, mankeys::Dict{S, V}) where
    {U<:Union{Tuple, NamedTuple}, S<:AbstractString, V<:ValueType}

    #  Determine format from data
    n   = mankeys["TFIELDS"]
    fmt = match(TABLEFMT, mankeys["TFORM$n"])
    type  = BITS2TYPE[8]
    shape = (mankeys["TBCOL$n"] + Base.parse(Int64, fmt[:w]) - 1, length(data))
    leng  = prod(shape)
    param = get(mankeys, "PCOUNT", 0)
    group = get(mankeys, "GCOUNT", 1)
    heap = 0
    DataFormat(type, leng, shape, param, group, heap)
end

function FieldFormat(::Type{Table}, format::DataFormat, reskeys::Dict{S, V},
    data::U; columns=nothing, formats=nothing, kwds...) where
    {U<:Union{Tuple, NamedTuple}, S<:AbstractString, V<:ValueType}

    N = get(reskeys, "TFIELDS", 0)

    fields = Vector{TableField}(undef, N)
    for j = 1:N
        fmt = match(TABLEFMT, !isnothing(formats) ? formats[j] :
            reskeys["TFORM$j"])

        name  = rstrip(get(reskeys, "TTYPE$j", "column$j"))
        type  = TABLETYPE[fmt[:t]]
        leng  = Base.parse(Int64, fmt[:w])
        k     = !isnothing(columns) : columns[j] : reskeys["TBCOL$j"]
        unit  = get(reskeys, "TUNIT$j", "")
        form  = fmt.match
        disp  = get(reskeys, "TDISP$j", "")
        tzero = leastfloat(get(reskeys, "TZERO$j",
            type <: String ? nothing : 0.0f0))
        tscal = leastfloat(get(reskeys, "TSCAL$j",
            type <: String ? nothing : 1.0f0))
        null  = get(reskeys, "TNULL$j", nothing)
        dmin  = parsestring(get(reskeys, "TDMIN$j", nothing))
        dmax  = parsestring(get(reskeys, "TDMAX$j", nothing))
        lmin  = parsestring(get(reskeys, "TLMIN$j", nothing))
        lmax  = parsestring(get(reskeys, "TLMAX$j", nothing))

        fields[j] = TableField(name, type, k:k+leng, unit, form, disp,
            tzero, tscal, null, dmin, dmax, lmin, lmax)
    end
    fields
end

function createcards!(::Type{Table}, format::DataFormat,
    fields::Vector{TableField}, cards::Cards; kwds...)

    required = tablekeys("TABLE", format, length(fields))
    for (j, field) in enumerate(fields)
        push!(required, "TFORM$j" => field.form, "TBCOL$j" => first(field.slice))
    end
    arrangecards!(cards, required)
end

function createdata(::Type{Table}, format::DataFormat,
    fields::Vector{TableField}; kwds...)
    #  Create simple N-dimensional array of zeros of type BITPIX
    if length(format.shape) == 2
        [repeat(" ", format.shape[1]) for j=1:format.shape[2]]
    else
        missing
    end
end

#  An entry is undefined if it is blank or it is the TNULLn string, which is implicitly space filled to the
#  width of the field (Sect. 7.2.2 of the standard).
isundefined(field::TableField, item::AbstractString) = isempty(item) || all(==(' '), item) ||
    (!isnothing(field.null) && rpad(field.null, length(item)) == item)

function Base.read(io::IO, field::TableField, format::DataFormat,
    begpos::Integer; scale::Bool = true)

    #  Without TSCAL/TZERO (the defaults are 1.0 and 0.0, Sect. 7.2.2) the data pass through unchanged;
    #  scaling by the Float32 defaults would round integers above 2^24
    scale = scale && !(field.scale == 1 && field.zero == 0)

    type, leng = field.type, length(field.slice)
    L, M, N = format.shape[1], first(field.slice)-1, format.shape[2]
    #  Read data array
    if type <: AbstractString
        column = Array{String}(undef, N)
        for j = 1:N
            seek(io, begpos + L*(j-1) + M)
            column[j] = rstrip(type(Base.read(io, leng)))
        end
    else
        column = Array{Union{type, Missing}}(undef, N)
        for j = 1:N
            seek(io, begpos + L*(j-1) + M)
            item = String(Base.read(io, leng))
            if isundefined(field, item)
                column[j] = missing
            else
                column[j] = Base.parse(type, replace(item, "D" => "e", "E" =>"e"))
            end
        end
        #  The column has missing values only if there are undefined entries, and the scaling keeps them
        column = any(ismissing, column) ? column : Array{type}(column)
        column = scale ? scaled(column, field.scale, field.zero) : column
    end
    column
end

function Base.read(row::AbstractString, field::TableField; scale::Bool = true,
    invalid::Bool = true)

    #  Without TSCAL/TZERO (the defaults are 1.0 and 0.0, Sect. 7.2.2) the data pass through unchanged;
    #  scaling by the Float32 defaults would round integers above 2^24
    scale = scale && !(field.scale == 1 && field.zero == 0)

    type, leng = field.type, length(field.slice)
    item = row[field.slice]
    if type <: AbstractString
        value = rstrip(item)
    elseif isundefined(field, item)
        value = missing
    else
        value = Base.parse(type, replace(item, "D" => "e", "E" => "e"))
        value = scale ? scaled(value, field.scale, field.zero) : value
    end
    #  Append units
    # if !ismissing(format.unit) value *= uparse(format.unit) end
    #  Create a Pair for name fields
    isempty(field.name) ? value : Symbol(field.name) => value
end

#  An undefined value is the TNULLn string, space filled to the width of the field, or blanks if there
#  is no TNULLn keyword.
function Base.write(io::IO, ::Missing, field::TableField, begpos::Integer; kwds...)
    write(io, repeat(" ", field.slice.start - (position(io) - begpos + 1)))
    write(io, rpad(something(field.null, ""), length(field.slice)))
end

function Base.write(io::IO, data::ValueType, field::TableField, begpos::Integer; kwds...)
    fmt = replace(field.form, "D" => "E", "I" => "i", "A" => "s")
    value = Printf.format(Printf.Format("%$(fmt[2:end])$(fmt[1])"), data)
    write(io, repeat(" ", field.slice.start - (position(io) - begpos + 1)))
    write(io, occursin("D", field.form) ? replace(value, "E" => "D") : value)
end

#  The structure of an ASCII table extension, which is an array of bytes with NAXIS = 2 axes, the length of a row and the number
#  of rows (Sect. 7.2.1)
function verifyrows(::Type{Table}, mankeys::AbstractDict)
	verifyvalue(mankeys, "BITPIX", 8:8, "the integer 8")
	verifyvalue(mankeys, "NAXIS", 2:2, "the integer 2")
	verifyaxes(mankeys)
end

"""
	verifyfields!(Table, cards, mankeys)

Verify the keywords that describe the fields of an ASCII table extension, and return the cards unchanged
(Sect. 7.2.1 of the standard). It is an error, since the fields cannot be read, if TFIELDS
is negative, if TFORMn is missing for an n from 1 to TFIELDS, or if TBCOLn is missing or less than 1, since the first column of a row is numbered 1. It is a warning,
since the extra keywords are not used, if TFIELDS is more than 999, the maximum, or if TFORMn or TBCOLn
is present for an n greater than TFIELDS. A header with no TFIELDS is not verified.
"""
function verifyfields!(::Type{Table}, cards::Cards, mankeys::AbstractDict)
	N = get(mankeys, "TFIELDS", nothing)
	isnothing(N) && return cards
	N < 0 && throw(ArgumentError("TFIELDS must be non-negative, but its value is $N."))
	N > MAXFIELDS && @warn "TFIELDS $N is more than the maximum of $MAXFIELDS."
	for j = 1:N
		haskey(mankeys, "TFORM$j") || throw(ArgumentError("TFORM$j is missing, but TFIELDS is $N."))
		haskey(mankeys, "TBCOL$j") || throw(ArgumentError("TBCOL$j is missing, but TFIELDS is $N."))
		mankeys["TBCOL$j"] >= 1 || throw(ArgumentError(
			"TBCOL$j must be at least 1, the first column of a row, but its value is $(mankeys["TBCOL$j"])."))
	end
	for key in sort!(collect(keys(mankeys)))
		m = match(r"^(TFORM|TBCOL)(\d+)$", key)
		!isnothing(m) && Base.parse(Int, m[2]) > N &&
			@warn "$key is beyond TFIELDS $N, and is not used."
	end
	cards
end

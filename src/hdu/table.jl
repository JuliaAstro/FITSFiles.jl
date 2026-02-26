#=    Improvements

 * type mappings, e.g., F6.2 to Float32, etc.
 * more tests

 =#

####    Table HDU functions

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
    slice::UnitRange{Integer}
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

function Base.write(io::IO, type::Type{Table}, data::AbstractArray,
    format::DataFormat, fields::Vector{TableField}; kwds...)

    #  Write data array
    N = format.shape[2]
    if N > 0
        for j=1:N
            begpos = position(io)
            for field in fields
                write(io, data[j][Symbol(field.name)], field, begpos; kwds...)
            end
            write(io, repeat(" ", format.shape[1]-(position(io)-begpos)))
        end
        #  Pad last block with spaces
        padblock(io, format, 0x20)
    end
end

function Base.write(io::IO, ::Type{Table}, data::NamedTuple, format::DataFormat,
    fields::Vector{TableField}; kwds...)

    #  Write data array
    N = format.shape[2]
    if N > 0
        for j=1:N
            begpos = position(io)
            for field in fields
                write(io, data[Symbol(field.name)][j], field, begpos; kwds...)
            end
            write(io, repeat(" ", format.shape[1]-(position(io)-begpos)))
        end
        #  Pad last block with spaces
        padblock(io, format, 0x20)
    end
end

function verify!(::Type{Table}, cards::Cards, format::DataFormat,
    mankeys::D) where D<:Dict{AbstractString, ValueType}

    if haskey(mankeys, "BITPIX") && format.type != BITS2TYPE[mankeys["BITPIX"]]
        setindex!(cards, TYPE2BITS[format.type], "BITPIX")
        println("Warning: BITPIX set to $(TYPE2BITS[format.type])).")
    end
    if haskey(mankeys, "NAXIS1") && format.shape != datasize(cards, 1)
        N = length(format.shape)
        setindex!(cards, N, "NAXIS")
        for j=1:N setindex!(cards, format.shape[j], "NAXIS$j") end
        println("Warning: NAXIS$(1:N) set to $(format.shape)")
    end
    cards
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
        tzero = least_float_type(get(reskeys, "TZERO$j",
            type <: String ? nothing : 0.0f0))
        tscal = least_float_type(get(reskeys, "TSCAL$j",
            type <: String ? nothing : 1.0f0))
        null  = get(reskeys, "TNULL$j", nothing)
        dmin  = parse_string(get(reskeys, "TDMIN$j", nothing))
        dmax  = parse_string(get(reskeys, "TDMAX$j", nothing))
        lmin  = parse_string(get(reskeys, "TLMIN$j", nothing))
        lmax  = parse_string(get(reskeys, "TLMAX$j", nothing))

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
        tzero = least_float_type(get(reskeys, "TZERO$j",
            type <: String ? nothing : 0.0f0))
        tscal = least_float_type(get(reskeys, "TSCAL$j",
            type <: String ? nothing : 1.0f0))
        null  = get(reskeys, "TNULL$j", nothing)
        dmin  = parse_string(get(reskeys, "TDMIN$j", nothing))
        dmax  = parse_string(get(reskeys, "TDMAX$j", nothing))
        lmin  = parse_string(get(reskeys, "TLMIN$j", nothing))
        lmax  = parse_string(get(reskeys, "TLMAX$j", nothing))

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
        tzero = least_float_type(get(reskeys, "TZERO$j",
            type <: String ? nothing : 0.0f0))
        tscal = least_float_type(get(reskeys, "TSCAL$j",
            type <: String ? nothing : 1.0f0))
        null  = get(reskeys, "TNULL$j", nothing)
        dmin  = parse_string(get(reskeys, "TDMIN$j", nothing))
        dmax  = parse_string(get(reskeys, "TDMAX$j", nothing))
        lmin  = parse_string(get(reskeys, "TLMIN$j", nothing))
        lmax  = parse_string(get(reskeys, "TLMAX$j", nothing))

        fields[j] = TableField(name, type, k:k+leng, unit, form, disp,
            tzero, tscal, null, dmin, dmax, lmin, lmax)
    end
    fields
end

function create_cards!(::Type{Table}, format::DataFormat,
    fields::Vector{TableField}, cards::Cards; kwds...)
    M, N = length(format.shape) == 2 ? format.shape : (0, 0)
    T = length(fields)
    #  create mandatory header cards and remove them from the deck if necessary
    required = Vector{Card{<:Any}}(undef, 8+2*T)
    required[1] = popat!(cards, "XTENSION", Card("XTENSION", "TABLE   "))
    required[2] = popat!(cards, "BITPIX", Card("BITPIX", 8))
    required[3] = popat!(cards, "NAXIS",  Card("NAXIS", 2))
    required[4] = popat!(cards, "NAXIS1", Card("NAXIS1", M))
    required[5] = popat!(cards, "NAXIS2", Card("NAXIS2", N))
    required[6] = popat!(cards, "PCOUNT", Card("PCOUNT", 0))
    required[7] = popat!(cards, "GCOUNT", Card("GCOUNT", 1))
    required[8] = popat!(cards, "TFIELDS", Card("TFIELDS", T))
    for j=1:T
        required[8+2*j-1] = popat!(cards, "TFORM$j", Card("TFORM$j",
            fields[j].form))
        required[8+2*j] = popat!(cards, "TBCOL$j", Card("TBCOL$j",
            first(fields[j].slice)))
    end

    #  Append remaining cards in deck, but first remove the END card
    popat!(cards, "END")
    K = length(cards)
    kards = Vector{Card{<:Any}}(undef,8+2*T+K)
    kards[1:8+2*T] .= required
    kards[9+2*T:8+2*T+K] .= cards
    #  END card is implied. Will be append on write.
    return kards
end

function create_data(::Type{Table}, format::DataFormat,
    fields::Vector{TableField}; kwds...)
    #  Create simple N-dimensional array of zeros of type BITPIX
    if length(format.shape) == 2
        [repeat(" ", format.shape[1]) for j=1:format.shape[2]]
    else
        missing
    end
end

function Base.read(io::IO, field::TableField, format::DataFormat,
    begpos::Integer; scale::Bool = true)

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
        column = Array{type}(undef, N)
        for j = 1:N
            seek(io, begpos + L*(j-1) + M)
            item = String(Base.read(io, leng))
            if (!isnothing(field.null) && field.null == item) ||
                item == repeat(' ', leng) || leng <= 0
                column[j] = missing
            else
                column[j] = Base.parse(type, replace(item, "D" => "e", "E" =>"e"))
            end
        end
        column = scale ? field.zero .+ field.scale.*skipmissing(column) : column
    end
    column
end

function Base.read(row::AbstractString, field::TableField; scale::Bool = true,
    invalid::Bool = true)

    type, leng = field.type, length(field.slice)
    item = row[field.slice]
    if type <: AbstractString
        value = rstrip(item)
    elseif (!isnothing(field.null) && field.null == item) ||
        item == repeat(' ', leng) || leng <= 0
        value = missing
    else
        value = Base.parse(type, replace(item, "D" => "e", "E" => "e"))
        value = scale ? field.zero + field.scale * value : value
    end
    #  Append units
    # if !ismissing(format.unit) value *= uparse(format.unit) end
    #  Create a Pair for name fields
    isempty(field.name) ? value : Symbol(field.name) => value
end

function Base.write(io::IO, data::ValueType, field::TableField, begpos::Integer; kwds...)
    fmt = replace(field.form, "D" => "E", "I" => "i", "A" => "s")
    value = Printf.format(Printf.Format("%$(fmt[2:end])$(fmt[1])"), data)
    write(io, repeat(" ", field.slice.start - (position(io) - begpos + 1)))
    write(io, occursin("D", field.form) ? replace(value, "E" => "D") : value)
end

####    Conforming HDU functions

"""
    ConformField()

Conforming array element descriptor
"""
struct ConformField <: AbstractField
end

function Base.read(io::IO, ::Type{Conform}, format::DataFormat,
    fields=ConformField; scale::Bool = true, kwds...)

    begpos = position(io)
    #  Read data array
    data = read(io, format, fields)
    #  Seek to end of the last data block
    # seek(io, begpos + BLOCKLEN*div(format.leng, BLOCKLEN, RoundUp))

    data = scale ? scaled(data, fields.scale, fields.zero) : data
    #=
    data = if get(kwds, :unit, true)
        apply_unit(data, cards)
    end
    =#

    ####    Get WCS keywords
    data
end

function Base.write(io::IO, ::Type{Conform}, data::AbstractArray,
        format::DataFormat, fields=ConformField; kwds...)

    data = removeunits(data)

    println(format)
    println(data)
    dbytes = write(io, format, data; kwds...)
    println(dbytes)
    pbytes = padblock(io, format)
    println(dbytes+pbytes)
end

function verify!(::Type{Conform}, cards::Cards, format::DataFormat,
    mankeys::AbstractDict)

    verifyshape!(cards, mankeys, format)
end

function DataFormat(::Type{Conform}, data::Missing, mankeys::Dict{S, V}) where
    {S<:AbstractString, V<:ValueType}

    #  Determine format from data
    type  = BITS2TYPE[get(mankeys, "BITPIX", 32)]
    leng  = datalength(mankeys, 1)
    shape = datasize(mankeys, 1)
    param = get(mankeys, "PCOUNT", 0)
    group = get(mankeys, "GCOUNT", 1)
    heap  = param > 0 ? get(mankeys, "THEAP", 0) : 0
    DataFormat(type, leng, shape, param, group, heap)
end

function FieldFormat(::Type{Conform}, format::DataFormat, reskeys::D) where
    D<:Dict{AbstractString, ValueType}

    [ConformField()]
end

function createcards!(::Type{Conform}, format::DataFormat,
    fields::ConformField, cards::Cards; kwds...)

    arrangecards!(cards, ["SIMPLE" => true; shapekeys(format)])
end

function createdata(::Type{Conform}, format::DataFormat, fields::ConformField;
    kwds...)
    #  Create simple N-dimensional array of zeros of type BITPIX
    length(format.shape) > 0 ? zeros(format.type, format.shape) : missing
end


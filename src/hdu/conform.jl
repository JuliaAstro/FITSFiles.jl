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
    zerosarray(format)
end


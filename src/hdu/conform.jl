####    Conforming HDU functions

"""
    ConformField()

Conforming array element descriptor
"""
struct ConformField <: AbstractField
end

#  The data of a Conform HDU are the values of BITPIX, which are not scaled, since the standard does not
#  describe their use. The data are an array of the shape of the NAXISn keywords, or a vector if the HDU has a
#  heap or groups (PCOUNT and GCOUNT), so that the number of values is not the product of the NAXISn.
function Base.read(io::IO, ::Type{Conform}, format::DataFormat, fields::ConformField; kwds...)
    data = ntoh.(reinterpret(format.type, readbytes(io, sizeof(format.type)*format.leng)))
    length(data) == prod(format.shape) ? reshape(data, format.shape) : data
end

function Base.write(io::IO, ::Type{Conform}, data::Missing, format::DataFormat,
    fields::ConformField; kwds...)
end

function Base.write(io::IO, ::Type{Conform}, data::AbstractArray, format::DataFormat,
    fields::ConformField; kwds...)

    if format.leng > 0
        Base.write(io, hton.(reshape(data, :)))
        padblock(io, format)
    end
end

function verify!(::Type{Conform}, cards::Cards, mankeys::AbstractDict, reskeys::AbstractDict)
    cards = invoke(verify!, Tuple{Type{<:AbstractHDU}, Cards, AbstractDict, AbstractDict}, Conform, cards,
        mankeys, reskeys)
    verifyarray(mankeys, reskeys)
    #  A Conform HDU with SIMPLE is the primary HDU of a file that does not conform to the Standard
    if haskey(mankeys, "SIMPLE")
        mankeys["SIMPLE"] === false && @warn "SIMPLE is F, so the file does not conform to the " *
            "Standard (Sect. 4.4.1.1). The primary HDU is read as a Conform HDU, and its data are not scaled."
        cards = verifyprimary(cards, mankeys)
    end
    cards
end

function verify!(::Type{Conform}, cards::Cards, format::DataFormat,
    mankeys::AbstractDict)

    verifyshape!(cards, mankeys, format)
end

FieldFormat(::Type{Conform}, format::DataFormat, reskeys::AbstractDict, data::Union{Missing, AbstractArray}) =
    ConformField()

function createcards!(::Type{Conform}, format::DataFormat,
    fields::ConformField, cards::Cards; kwds...)

    arrangecards!(cards, ["SIMPLE" => true; shapekeys(format)])
end

function createdata(::Type{Conform}, format::DataFormat, fields::ConformField;
    kwds...)
    zerosarray(format)
end


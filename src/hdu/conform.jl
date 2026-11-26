####    Conforming HDU functions

struct Conform <: AbstractHDU end

#  The mandatory and reserved keywords of the HDU (see `getreservedkeys`)
union!(MANDATORYKEYS, ["SIMPLE", "XTENSION", "PCOUNT", "GCOUNT"])
union!(RESERVEDKEYS, ["INHERIT", "EXTEND", "BLOCKED", "BSCALE", "BZERO", "BUNIT", "BLANK", "DATAMAX", "DATAMIN"])

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
        cards = verifyconform(cards, mankeys)
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

"""
	verifyconform(cards, mankeys)

Warn if the header of the primary HDU of a Conform HDU does not begin with SIMPLE, BITPIX, NAXIS, and the NAXISn keywords, in
that order and with no other keyword between them (Sect. 4.4.1.1 of the standard), or if the values of
these keywords are not in fixed format (Sect. 4.4.1), and return the cards unchanged. The file is read and
written as it is, so the cards are not reordered or reformatted. The NAXIS value of `mankeys` must be
valid, as `verifyarray` checks.
"""
function verifyconform(cards::Cards, mankeys::AbstractDict)
	#  A header that is being created does not have the keywords yet, and is arranged when it is created.
	haskey(mankeys, "SIMPLE") || return cards
	required = vcat(["SIMPLE", "BITPIX", "NAXIS"], ["NAXIS$j" for j = 1:get(mankeys, "NAXIS", 0)])
	verifyorder(cards, required)
	verifyfixed(cards, required)
end

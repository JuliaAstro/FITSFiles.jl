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
    verifyarray(Conform, mankeys, reskeys)
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

#  The keywords of an array, which the HDU verifies: BITPIX is one of the values of Table 8, NAXIS is from 0 to 999 and each
#  NAXISn is a non-negative integer (Sects. 4.4.1.1), and the keywords that describe the array (Sect. 4.4.2.5): BLANK is an
#  integer and only for integer data, BSCALE and BZERO are numbers, DATAMIN and DATAMAX are floating-point numbers, and BUNIT is a
#  units string.
function verifyarray(::Type{Conform}, mankeys::AbstractDict, reskeys::AbstractDict)
    verifybitpix(mankeys)
    verifyvalue(mankeys, "NAXIS", 0:MAXAXES, "an integer from 0 to $MAXAXES")
    verifyaxes(mankeys)
    verifysize(Conform, mankeys)
    verifyarraykeys(Conform, mankeys, reskeys)
end

function verifyarraykeys(::Type{Conform}, mankeys::AbstractDict, reskeys::AbstractDict)
    verifyblank(Conform, mankeys, reskeys)
    verifynumber(reskeys, r"^(BSCALE|BZERO|DATAMIN|DATAMAX)$")
    verifyfloat(reskeys, r"^(DATAMIN|DATAMAX)$")
    verifystring(reskeys, r"^BUNIT$")
    verifyunit(reskeys, r"^BUNIT$")
end

#  The BLANK keyword of an array is an integer, and is for integer data only (Sect. 4.4.2.5).
function verifyblank(::Type{Conform}, mankeys::AbstractDict, reskeys::AbstractDict)
    verifyinteger(reskeys, r"^BLANK$")
    haskey(reskeys, "BLANK") && get(mankeys, "BITPIX", 8) < 0 && @warn "BLANK is for integer data " *
        "(a positive BITPIX) only (Sect. 4.4.2.5), so it is not used."
end

#  The size of the data array, |BITPIX|/8 × NAXIS1 × ... × NAXISm bytes, is at most the largest integer, so
#  that the array can be read and indexed (Eq. 1 of the standard).
function verifysize(::Type{Conform}, mankeys::AbstractDict)
    N, bits = get(mankeys, "NAXIS", 0), get(mankeys, "BITPIX", 0)
    N < 1 && return
    sizes = [BigInt(mankeys["NAXIS$j"]) for j = 1:N]
    nbytes = abs(bits) ÷ 8 * prod(sizes)
    nbytes > typemax(Int) && throw(ArgumentError("The data array is too large: " *
        "$(abs(bits) ÷ 8) bytes × $(join(sizes, " × ")) values is more than $(typemax(Int)) bytes."))
end

#  The data format of the array from the mandatory keywords
function DataFormat(::Type{Conform}, data::Missing, mankeys::Dict{S, V}) where
    {S<:AbstractString, V<:ValueType}

    type  = BITS2TYPE[get(mankeys, "BITPIX", 32)]
    leng  = datalength(mankeys, 1)
    shape = datasize(mankeys, 1)
    param = get(mankeys, "PCOUNT", 0)
    group = get(mankeys, "GCOUNT", 1)
    heap  = param > 0 ? get(mankeys, "THEAP", 0) : 0
    DataFormat(type, leng, shape, param, group, heap)
end

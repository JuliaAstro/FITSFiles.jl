####    Image HDU functions

"""
	Image header-data unit (HDU)

An Image HDU consists of a vector of cards and optionally a multidimensional array
(<=999 dimensions).
"""
struct Image <: AbstractHDU end
XTENSIONTYPE["IMAGE"] = Image

#  The mandatory and reserved keywords of the HDU (see `getreservedkeys`)
union!(MANDATORYKEYS, ["XTENSION", "PCOUNT", "GCOUNT"])
union!(RESERVEDKEYS, ["INHERIT", "BSCALE", "BZERO", "BUNIT", "BLANK", "DATAMAX", "DATAMIN"])

#  The keywords of the cards that are given with the data of an HDU that is made are verified (see `verifycardkeys`)
verifycards!(::Type{Image}, cards::Cards, mankeys::AbstractDict, reskeys::AbstractDict, format::DataFormat) =
    verifycardkeys(Image, cards, mankeys, reskeys)

#  The mandatory keywords of the header of an IMAGE extension, in the order that they must have (Sect. 7.1.1, Table 13)
imagekeys(mankeys::AbstractDict) =
    vcat(["XTENSION", "BITPIX", "NAXIS"], ["NAXIS$j" for j = 1:get(mankeys, "NAXIS", 0)], ["PCOUNT", "GCOUNT"])

function verify!(::Type{Image}, cards::Cards, mankeys::AbstractDict, reskeys::AbstractDict)
    #  A header that is being created does not have the keywords yet, and is arranged when it is created.
    created = !haskey(mankeys, "XTENSION")
    #  BITPIX and NAXIS describe the data, so the data cannot be read without them (Sect. 7.1.1)
    for key in ("BITPIX", "NAXIS")
        created || haskey(mankeys, key) || throw(ArgumentError(
            "$key is missing, but it is a mandatory keyword of an IMAGE extension (Sect. 7.1.1)."))
    end
    cards = invoke(verify!, Tuple{Type{<:AbstractHDU}, Cards, AbstractDict, AbstractDict}, Image, cards,
        mankeys, reskeys)
    verifyarray(Image, mankeys, reskeys)
    #  An IMAGE extension has a single array and no parameters (Sect. 7.1.1)
    verifyvalue(mankeys, "PCOUNT", 0:0, "the integer 0")
    verifyvalue(mankeys, "GCOUNT", 1:1, "the integer 1")
    created && return cards
    #  PCOUNT and GCOUNT have the values 0 and 1, so the data can be read without them
    for (key, value) in ("PCOUNT" => 0, "GCOUNT" => 1)
        haskey(mankeys, key) || @warn "$key is missing, but it is a mandatory keyword of an IMAGE extension " *
            "(Sect. 7.1.1), and has the value $value. It is read as $value."
    end
    #  The mandatory keywords are the first keywords, in order and in fixed format (Sects. 4.4 and 7.1.1)
    #  (a keyword that is missing is warned about above, and is not in the order)
    required = filter(key -> haskey(mankeys, key), imagekeys(mankeys))
    verifyorder(cards, required; section = "Sects. 4.4.1.2 and 7.1.1",
        names = "XTENSION, BITPIX, NAXIS, the NAXISn, PCOUNT, and GCOUNT")
    verifyfixed(cards, required)
    #  The keywords of the primary header, and of the physical blocks, are not in an extension (Sects. 4.4.1.1, 4.4.2.1,
    #  and 7.1.2)
    haskey(mankeys, "SIMPLE") && @warn "SIMPLE must not appear in an extension header (Sect. 4.4.1.1). It is read as it is."
    for key in ("EXTEND", "BLOCKED")
        haskey(reskeys, key) && @warn "$key must not appear in an IMAGE extension header (Sects. 4.4.2.1 and 7.1.2). " *
            "It is read as it is."
    end
    #  INHERIT is a logical that is immediately after the mandatory keywords (Sect. 4.4.2.6 and Appendix K)
    verifylogical(reskeys, r"^INHERIT$")
    j = Base.findfirst("INHERIT", cards)
    if !ismissing(j) && j != length(required) + 1
        @warn "INHERIT must be the keyword immediately after the mandatory keywords, keyword $(length(required) + 1) " *
            "of this header (Sect. 4.4.2.6 and Appendix K), but it is keyword $j. It is read as it is."
    end
    cards
end

function verify!(::Type{Image}, cards::Cards, format::DataFormat,
    mankeys::AbstractDict)

    verifyshape!(cards, mankeys, format)
end

function createcards!(::Type{Image}, format::DataFormat,
    fields::AbstractField, cards::Cards; kwds...)

    #  The mandatory keywords are XTENSION, BITPIX, NAXIS, the NAXISn, PCOUNT of 0, and GCOUNT of 1 (Sect. 7.1.1)
    offsetcards!(arrangecards!(cards, ["XTENSION" => "IMAGE"; shapekeys(Image, format); "PCOUNT" => 0; "GCOUNT" => 1]), fields)
end

"""
    ImageField(type, zero, scale, miss, dmin, dmax)

Image array element descriptor
"""
struct ImageField <: AbstractField
    "The type of the array"
    type::Type
    "The offset of the array"
    zero::AbstractFloat
    "The scale of the array"
    scale::AbstractFloat
    "The value representing a missing value"
    miss::Union{Integer, Nothing}
    "The minimum display value of the array"
    dmin::Union{AbstractFloat, Nothing}
    "The maximum display value of the array"
    dmax::Union{AbstractFloat, Nothing}
end

#  The keywords of an array, which the HDU verifies: BITPIX is one of the values of Table 8, NAXIS is from 0 to 999 and each
#  NAXISn is a non-negative integer (Sects. 4.4.1.1 and 7.1.1), and the keywords that describe the array (Sect. 4.4.2.5): BLANK is an
#  integer and only for integer data, BSCALE and BZERO are numbers, DATAMIN and DATAMAX are floating-point numbers, and BUNIT is a
#  units string.
function verifyarray(::Type{Image}, mankeys::AbstractDict, reskeys::AbstractDict)
    verifybitpix(mankeys)
    verifyvalue(mankeys, "NAXIS", 0:MAXAXES, "an integer from 0 to $MAXAXES")
    verifyaxes(mankeys)
    verifysize(Image, mankeys)
    verifyarraykeys(Image, mankeys, reskeys)
end

function verifyarraykeys(::Type{Image}, mankeys::AbstractDict, reskeys::AbstractDict)
    verifyblank(Image, mankeys, reskeys)
    verifynumber(reskeys, r"^(BSCALE|BZERO|DATAMIN|DATAMAX)$")
    verifyfloat(reskeys, r"^(DATAMIN|DATAMAX)$")
    verifystring(reskeys, r"^BUNIT$")
    verifyunit(reskeys, r"^BUNIT$")
end

#  The BLANK keyword of an array is an integer, and is for integer data only (Sect. 4.4.2.5).
function verifyblank(::Type{Image}, mankeys::AbstractDict, reskeys::AbstractDict)
    verifyinteger(reskeys, r"^BLANK$")
    haskey(reskeys, "BLANK") && get(mankeys, "BITPIX", 8) < 0 && @warn "BLANK is for integer data " *
        "(a positive BITPIX) only (Sect. 4.4.2.5), so it is not used."
end

#  The size of the data array, |BITPIX|/8 × NAXIS1 × ... × NAXISm bytes, is at most the largest integer, so
#  that the array can be read and indexed (Eq. 1 of the standard).
function verifysize(::Type{Image}, mankeys::AbstractDict)
    N, bits = get(mankeys, "NAXIS", 0), get(mankeys, "BITPIX", 0)
    N < 1 && return
    sizes = [BigInt(mankeys["NAXIS$j"]) for j = 1:N]
    nbytes = abs(bits) ÷ 8 * prod(sizes)
    nbytes > typemax(Int) && throw(ArgumentError("The data array is too large: " *
        "$(abs(bits) ÷ 8) bytes × $(join(sizes, " × ")) values is more than $(typemax(Int)) bytes."))
end

#  The data format of the array from the mandatory keywords
function DataFormat(::Type{Image}, data::Missing, mankeys::Dict{S, V}) where
    {S<:AbstractString, V<:ValueType}

    type  = BITS2TYPE[get(mankeys, "BITPIX", 32)]
    shape = datasize(mankeys, 1)
    param = get(mankeys, "PCOUNT", 0)
    group = get(mankeys, "GCOUNT", 1)
    leng  = get(mankeys, "NAXIS", 0) > 0 ? group * (param + prod(shape)) : 0
    heap  = param > 0 ? get(mankeys, "THEAP", 0) : 0
    DataFormat(type, leng, shape, param, group, heap)
end

function DataFormat(::Type{Image}, data::AbstractArray, mankeys::Dict{S, V}) where
    {S<:AbstractString, V<:ValueType}

    #  The type of the stored values, which excludes the undefined (missing) ones, and is the integer of the same
    #  size for the physical types of Table 11 (e.g., an Int16 for a UInt16)
    type  = nonmissingtype(eltype(data))
    type  = get(RAWTYPE, type, type)
    leng  = length(data)
    shape = size(data)
    param = get(mankeys, "PCOUNT", 0)
    group = get(mankeys, "GCOUNT", 1)
    heap  = 0
    DataFormat(type, leng, shape, param, group, heap)
end

function FieldFormat(::Type{Image}, format::DataFormat, reskeys::Dict{S, V},
    data::Union{Missing, AbstractArray}) where {S<:AbstractString, V<:ValueType}

    #  The offset of the data of a physical type of Table 11 is its BZERO, if the header has none
    offset = data isa AbstractArray && haskey(RAWTYPE, nonmissingtype(eltype(data))) ?
        OFFSETTYPE[RAWTYPE[nonmissingtype(eltype(data))]][2] : 0.0f0
    zero_ = leastfloat(get(reskeys, "BZERO", offset))
    scale = leastfloat(get(reskeys, "BSCALE", 1.0f0))
    miss  = format.type in MISSTYPE ? get(reskeys, "BLANK", nothing) : nothing
    dmin  = leastfloat(get(reskeys, "DATAMIN", nothing))
    dmax  = leastfloat(get(reskeys, "DATAMAX", nothing))
    ImageField(format.type, zero_, scale, miss, dmin, dmax)
end

createdata(::Type{Image}, format::DataFormat, ::ImageField; kwds...) = zerosarray(format)

#  The BZERO card of the offset convention, if the header does not have one.
function offsetcards!(cards::Cards, fields::ImageField)
    if !isnothing(offsettype(fields.type, fields.scale, fields.zero)) && !haskey(cards, "BZERO")
        push!(cards, Card("BZERO", OFFSETTYPE[fields.type][2]))
    end
    cards
end

function Base.read(io::IO, ::Type{Image}, format::DataFormat,
    fields::ImageField; scale::Bool = true, kwds...)

    data = read(io, format, fields)
    scale || return data
    #  The physical values of floating-point stored values have the type of the stored values, so the array says that they are
    values = physical(data, fields.type, fields.scale, fields.zero)
    physicalfloat(fields) ? ScaledArray(values, fields.scale, fields.zero) : values
end

#  Are the physical values of the data the same type as the stored values, which are floating-point? They are if the data are not scaled
#  by a BSCALE of 1 and a BZERO of 0.
physicalfloat(fields::ImageField) = fields.type <: AbstractFloat && !(fields.scale == 1 && fields.zero == 0)

function Base.write(io::IO, ::Type{Image}, data::Missing, format::DataFormat,
    fields::ImageField; kwds...)
end

function Base.write(io::IO, ::Type{Image}, data::AbstractArray,
    format::DataFormat, fields::ImageField; kwds...)

    if format.leng > 0
        write(io, data, fields; kwds...)
        padblock(io, format)
    end
end

function Base.read(io::IO, format::DataFormat, fields::ImageField)

    M, N, shape = sizeof(format.type), format.leng, format.shape
    #  Or preallocate array and use read!
    data = reshape(ntoh.(
        reinterpret(format.type, readbytes(io, M*N))), shape)
    #  The undefined values are the raw ones equal to BLANK (Sect. 4.4.2.5)
    setmissing(data, fields.miss)
end

function Base.write(io::IO, data::AbstractArray, fields::ImageField; check::Bool = true, kwds...)
    data = storedvalues(data, fields.type, fields.scale, fields.zero, fields.miss; check)
    #  The undefined values are written as BLANK, or NaN for floating-point data
    data = unsetmissing(data, fields.miss, fields.type)
    n = Base.write(io, hton.(reshape(data, :)))
end

#  The BSCALE and BZERO cards of data that are a ScaledArray, which have the scale and the zero of the data
function scalecards!(::Type{Image}, cards::Cards, data::ScaledArray)
    setscalecard!(cards, "BSCALE", data.scale, 1)
    setscalecard!(cards, "BZERO", data.zero, 0)
end

#  The keywords BITPIX and NAXIS, and NAXISn of the shape of the data of an IMAGE extension
function shapekeys(::Type{Image}, format::DataFormat)
    required = Pair{String, Any}["BITPIX" => TYPE2BITS[format.type], "NAXIS" => length(format.shape)]
    for (j, n) in enumerate(format.shape) push!(required, "NAXIS$j" => n) end
    required
end

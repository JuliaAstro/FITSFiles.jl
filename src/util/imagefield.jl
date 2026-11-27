####    Image array functions of the Primary, Image, and Conform HDUs

"""
    ImageField(type, zero, scale, miss, dmin, dmax)

Image array element descriptor (applicable to Primary and Image HDUs)
"""
struct ImageField <: AbstractField
    "The type of the image"
    type::Type
    "The offset of the image"
    zero::AbstractFloat
    "The scale of the image"
    scale::AbstractFloat
    "The value representing a missing value"
    miss::Union{Integer, Nothing}
    "The minimum display value of the image"
    dmin::Union{AbstractFloat, Nothing}
    "The maximum display value of the image"
    dmax::Union{AbstractFloat, Nothing}
end

#  The HDU types that have an image array, which is described by the keywords of Sect. 4.4.2.5 of the
#  standard: BSCALE and BZERO (the defaults are 1.0 and 0.0), BLANK (only for integer data, i.e., a positive
#  BITPIX), and DATAMIN and DATAMAX.
const ImageHDU = Union{Primary, Image}

#  The keywords of an image array, which Primary, Image, and Conform verify: BITPIX is one of the values of
#  Table 8, NAXIS is from 0 to 999 and each NAXISn is a non-negative integer (Sects. 4.4.1.1 and 7.1.1), and
#  the keywords that describe the array (Sect. 4.4.2.5): BLANK is an integer and only for integer data, BSCALE
#  and BZERO are numbers, DATAMIN and DATAMAX are floating-point numbers, and BUNIT is a units string.
function verifyarray(mankeys::AbstractDict, reskeys::AbstractDict)
    verifybitpix(mankeys)
    verifyvalue(mankeys, "NAXIS", 0:MAXAXES, "an integer from 0 to $MAXAXES")
    verifyaxes(mankeys)
    verifysize(mankeys)
    verifyarraykeys(mankeys, reskeys)
end

#  The keywords that describe an array (Sect. 4.4.2.5), which the primary array, an IMAGE extension, and the array of random
#  groups have: BLANK, BSCALE, BZERO, DATAMIN, DATAMAX, and BUNIT.
function verifyarraykeys(mankeys::AbstractDict, reskeys::AbstractDict)
    verifyblank(mankeys, reskeys)
    verifynumber(reskeys, r"^(BSCALE|BZERO|DATAMIN|DATAMAX)$")
    verifyfloat(reskeys, r"^(DATAMIN|DATAMAX)$")
    verifystring(reskeys, r"^BUNIT$")
    verifyunit(reskeys, r"^BUNIT$")
end

#  The BLANK keyword of an array, which is an integer, and is for integer data only (Sect. 4.4.2.5): the primary array, an
#  IMAGE extension, and the array of random groups.
function verifyblank(mankeys::AbstractDict, reskeys::AbstractDict)
    verifyinteger(reskeys, r"^BLANK$")
    haskey(reskeys, "BLANK") && get(mankeys, "BITPIX", 8) < 0 && @warn "BLANK is for integer data " *
        "(a positive BITPIX) only (Sect. 4.4.2.5), so it is not used."
end

#  The size of the data array, |BITPIX|/8 × NAXIS1 × ... × NAXISm bytes, is at most the largest integer, so
#  that the array can be read and indexed (Eq. 1 of the standard).
function verifysize(mankeys::AbstractDict; first::Integer = 1)
    N, bits = get(mankeys, "NAXIS", 0), get(mankeys, "BITPIX", 0)
    N < first && return
    sizes = [BigInt(mankeys["NAXIS$j"]) for j = first:N]
    nbytes = abs(bits) ÷ 8 * prod(sizes)
    nbytes > typemax(Int) && throw(ArgumentError("The data array is too large: " *
        "$(abs(bits) ÷ 8) bytes × $(join(sizes, " × ")) values is more than $(typemax(Int)) bytes."))
end

#  The data format of an array, from the mandatory keywords or from the data.
function DataFormat(::Type{<:Union{Primary, Image, Conform}}, data::Missing, mankeys::Dict{S, V}) where
    {S<:AbstractString, V<:ValueType}

    type  = BITS2TYPE[get(mankeys, "BITPIX", 32)]
    leng  = datalength(mankeys, 1)
    shape = datasize(mankeys, 1)
    param = get(mankeys, "PCOUNT", 0)
    group = get(mankeys, "GCOUNT", 1)
    heap  = param > 0 ? get(mankeys, "THEAP", 0) : 0
    DataFormat(type, leng, shape, param, group, heap)
end

function DataFormat(::Type{<:ImageHDU}, data::AbstractArray, mankeys::Dict{S, V}) where
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

function FieldFormat(::Type{<:ImageHDU}, format::DataFormat, reskeys::Dict{S, V},
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


createdata(::Type{<:ImageHDU}, format::DataFormat, ::ImageField; kwds...) = zerosarray(format)

#  The BZERO card of the offset convention, if the header does not have one.
function offsetcards!(cards::Cards, fields::ImageField)
    if !isnothing(offsettype(fields.type, fields.scale, fields.zero)) && !haskey(cards, "BZERO")
        push!(cards, Card("BZERO", OFFSETTYPE[fields.type][2]))
    end
    cards
end

#  The physical values of the stored values: scaled, or the values of the offset convention of Table 11.
physical(data, fields::ImageField) = physical(data, fields.type, fields.scale, fields.zero)

function Base.read(io::IO, ::Type{<:ImageHDU}, format::DataFormat,
    fields::ImageField; scale::Bool = true, kwds...)

    data = read(io, format, fields)
    scale || return data
    #  The physical values of floating-point stored values have the type of the stored values, so the array says that they are
    values = physical(data, fields)
    physicalfloat(fields) ? ScaledArray(values, fields.scale, fields.zero) : values
end

#  Are the physical values of the data the same type as the stored values, which are floating-point? They are if the data are not scaled
#  by a BSCALE of 1 and a BZERO of 0.
physicalfloat(fields::ImageField) = fields.type <: AbstractFloat && !(fields.scale == 1 && fields.zero == 0)

function Base.write(io::IO, ::Type{<:ImageHDU}, data::Missing, format::DataFormat,
    fields::ImageField; kwds...)
end

function Base.write(io::IO, ::Type{<:ImageHDU}, data::AbstractArray,
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

#  The stored value of a physical value, and the stored values of the data (see `storedvalue` and `storedvalues` of the values of an array)
storedvalue(x, fields::ImageField, check::Bool = true; keys = ("BSCALE", "BZERO")) =
    storedvalue(x, fields.type, fields.scale, fields.zero, fields.miss, check; keys)
storedvalues(data::AbstractArray, fields::ImageField; check::Bool = true) =
    storedvalues(data, fields.type, fields.scale, fields.zero, fields.miss; check)

function Base.write(io::IO, data::AbstractArray, fields::ImageField; check::Bool = true, kwds...)
    data = storedvalues(data, fields; check)
    #  The undefined values are written as BLANK, or NaN for floating-point data
    data = unsetmissing(data, fields.miss, fields.type)
    n = Base.write(io, hton.(reshape(data, :)))
end



#  The BSCALE and BZERO cards of data that are a ScaledArray, which have the scale and the zero of the data
scalecards!(::Type, cards::Cards, data) = cards
function scalecards!(::Type{<:ImageHDU}, cards::Cards, data::ScaledArray)
    setscalecard!(cards, "BSCALE", data.scale, 1)
    setscalecard!(cards, "BZERO", data.zero, 0)
end

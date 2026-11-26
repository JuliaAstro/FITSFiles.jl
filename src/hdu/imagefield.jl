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
#  BLANK is an integer (Sect. 4.4.2.5).
function verifyarray(mankeys::AbstractDict, reskeys::AbstractDict)
    verifybitpix(mankeys)
    verifyvalue(mankeys, "NAXIS", 0:MAXAXES, "an integer from 0 to $MAXAXES")
    verifyaxes(mankeys)
    verifysize(mankeys)
    verifyinteger(reskeys, r"^BLANK$")
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

#  An N-dimensional array of zeros of the type of BITPIX, or missing if the data has no axes.
zerosarray(format::DataFormat) = length(format.shape) > 0 ? zeros(format.type, format.shape) : missing

createdata(::Type{<:ImageHDU}, format::DataFormat, ::ImageField; kwds...) = zerosarray(format)

#  The type of the physical values of an array of the stored type `type` that has the offset BZERO of Table 11 of
#  the standard and the default BSCALE, i.e., a UInt16 for an Int16 and a BZERO of 32768, or nothing.
function offsettype(type::Type, scale::Real, zero::Real)
    haskey(OFFSETTYPE, type) && scale == 1 && zero == OFFSETTYPE[type][2] ? OFFSETTYPE[type][1] : nothing
end

#  The value of the other type of the offset convention: the stored value for the physical value, and the physical
#  value for the stored value. The offset is a flip of the most significant bit.
offsetvalue(::Missing, ::Type) = missing
function offsetvalue(x::Integer, ::Type{T}) where T<:Integer
    U = unsigned(typeof(x))
    reinterpret(T, reinterpret(U, x) ⊻ (one(U) << (8sizeof(U) - 1)))
end

#  The BZERO card of the offset convention, if the header does not have one.
function offsetcards!(cards::Cards, fields::ImageField)
    if !isnothing(offsettype(fields.type, fields.scale, fields.zero)) && !haskey(cards, "BZERO")
        push!(cards, Card("BZERO", OFFSETTYPE[fields.type][2]))
    end
    cards
end

#  The physical values of the stored values: scaled, or the values of the offset convention of Table 11.
function physical(data, fields::ImageField)
    T = offsettype(fields.type, fields.scale, fields.zero)
    isnothing(T) ? scaled(data, fields.scale, fields.zero) : offsetvalue.(data, T)
end

function Base.read(io::IO, ::Type{<:ImageHDU}, format::DataFormat,
    fields::ImageField; scale::Bool = true, kwds...)

    data = read(io, format, fields)
    scale ? physical(data, fields) : data
end

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

function Base.write(io::IO, data::AbstractArray, fields::ImageField)
    #  The physical values of the offset convention are written as the stored values
    T = offsettype(fields.type, fields.scale, fields.zero)
    !isnothing(T) && nonmissingtype(eltype(data)) == T && (data = offsetvalue.(data, fields.type))
    #  The undefined values are written as BLANK, or NaN for floating-point data
    data = unsetmissing(data, fields.miss, fields.type)
    n = Base.write(io, hton.(reshape(data, :)))
end

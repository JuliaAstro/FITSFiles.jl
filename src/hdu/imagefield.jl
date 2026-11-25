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

#  The undefined value of the array is an integer (Sect. 4.4.2.5).
function verify!(::Type{T}, cards::Cards, mankeys::AbstractDict, reskeys::AbstractDict) where
    T<:Union{Primary, Image, Conform}

    cards = invoke(verify!, Tuple{Type{<:AbstractHDU}, Cards, AbstractDict, AbstractDict}, T, cards,
        mankeys, reskeys)
    verifyinteger(reskeys, r"^BLANK$")
    cards
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

    #  The type of the stored values, which excludes the undefined (missing) ones
    type  = nonmissingtype(eltype(data))
    leng  = length(data)
    shape = size(data)
    param = get(mankeys, "PCOUNT", 0)
    group = get(mankeys, "GCOUNT", 1)
    heap  = 0
    DataFormat(type, leng, shape, param, group, heap)
end

function FieldFormat(::Type{<:ImageHDU}, format::DataFormat, reskeys::Dict{S, V},
    data::Union{Missing, AbstractArray}) where {S<:AbstractString, V<:ValueType}

    zero_ = leastfloat(get(reskeys, "BZERO", 0.0f0))
    scale = leastfloat(get(reskeys, "BSCALE", 1.0f0))
    miss  = format.type in MISSTYPE ? get(reskeys, "BLANK", nothing) : nothing
    dmin  = leastfloat(get(reskeys, "DATAMIN", nothing))
    dmax  = leastfloat(get(reskeys, "DATAMAX", nothing))
    ImageField(format.type, zero_, scale, miss, dmin, dmax)
end

#  An N-dimensional array of zeros of the type of BITPIX, or missing if the data has no axes.
zerosarray(format::DataFormat) = length(format.shape) > 0 ? zeros(format.type, format.shape) : missing

createdata(::Type{<:ImageHDU}, format::DataFormat, ::ImageField; kwds...) = zerosarray(format)

function Base.read(io::IO, ::Type{<:ImageHDU}, format::DataFormat,
    fields::ImageField; scale::Bool = true, kwds...)

    data = read(io, format, fields)
    scale ? scaled(data, fields.scale, fields.zero) : data
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
        reinterpret(format.type, read(io, M*N))), shape)
    #  The undefined values are the raw ones equal to BLANK (Sect. 4.4.2.5)
    setmissing(data, fields.miss)
end

function Base.write(io::IO, data::AbstractArray, fields::ImageField)
    #  The undefined values are written as BLANK, or NaN for floating-point data
    data = unsetmissing(data, fields.miss, fields.type)
    n = Base.write(io, hton.(reshape(data, :)))
end

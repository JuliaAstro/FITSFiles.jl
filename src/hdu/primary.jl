####    Primary HDU functions

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

function Base.read(io::IO, ::Type{Primary}, format::DataFormat,
    fields::ImageField; scale::Bool = true, kwds...)

    #  Read data array
    M, N = sizeof(format.type), format.leng
    data = read(io, format, fields)
    #  Seek to end of the last data block
    # seek(io, position(io) + BLOCKLEN*div(M*N, BLOCKLEN, RoundUp))

    data = scale ? scaled(data, fields.scale, fields.zero) : data
    #=
    if get(kwds, :unit, true)
        data = apply_unit(data, fields)
    end
    =#

    ####    Get WCS keywords
    data
end

function Base.write(io::IO, ::Type{Primary}, data::Missing, format::DataFormat,
    fields::ImageField; kwds...)
end

function Base.write(io::IO, ::Type{Primary}, data::AbstractArray,
    format::DataFormat, fields::ImageField; kwds...)

    if format.leng > 0
        # data = removeunits(data)

        write(io, data, fields; kwds...)
        padblock(io, format)
    end
end

function verify!(::Type{Primary}, cards::Cards, format::DataFormat,
    mankeys::AbstractDict)

    !get(mankeys, "SIMPLE", true) && @warn "Primary HDU is nonconformant."
    verifyshape!(cards, mankeys, format)
end

function DataFormat(::Type{Primary}, data::Missing, mankeys::Dict{S, V}) where
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

function FieldFormat(::Type{Primary}, format::DataFormat, reskeys::Dict{S, V},
    data::Missing) where {S<:AbstractString, V<:ValueType}

    #  Get missing value
    zero_ = leastfloat(get(reskeys, "BZERO", 0.0f0))
    scale = leastfloat(get(reskeys, "BSCALE", 1.0f0))
    miss  = format.type in MISSTYPE ? get(reskeys, "BLANK", nothing) : nothing
    dmin  = leastfloat(get(reskeys, "DATAMIN", nothing))
    dmax  = leastfloat(get(reskeys, "DATAMAX", nothing))
    ImageField(format.type, zero_, scale, miss, dmin, dmax)
end

function DataFormat(::Type{Primary}, data::AbstractArray,
    mankeys::Dict{S, V}) where {S<:AbstractString, V<:ValueType}

    #  Determine format from data
    type  = eltype(data)
    leng  = length(data)
    shape = size(data)
    param = get(mankeys, "PCOUNT", 0)
    group = get(mankeys, "GCOUNT", 1)
    heap = 0
    DataFormat(type, leng, shape, param, group, heap)
end

function FieldFormat(::Type{Primary}, format::DataFormat, reskeys::Dict{S, V},
    data::AbstractArray) where {S<:AbstractString, V<:ValueType}

    #  Get missing value
    zero_ = leastfloat(get(reskeys,  "BZERO", 0.0f0))
    scale = leastfloat(get(reskeys, "BSCALE", 1.0f0))
    miss  = format.type in MISSTYPE ? get(reskeys, "BLANK", nothing) : nothing
    dmin  = leastfloat(get(reskeys, "DATAMIN", nothing))
    dmax  = leastfloat(get(reskeys, "DATAMAX", nothing))
    ImageField(format.type, zero_, scale, miss, dmin, dmax)
end

function createcards!(::Type{Primary}, format::DataFormat,
    fields::ImageField, cards::Cards; kwds...)

    arrangecards!(cards, ["SIMPLE" => true; shapekeys(format)])
end

function createdata(::Type{Primary}, format::DataFormat, ::ImageField;
    kwds...)
    #  Create simple N-dimensional array of zeros of type BITPIX
    length(format.shape) > 0 ? zeros(format.type, format.shape) : missing
end

function Base.read(io::IO, format::DataFormat, fields::ImageField)

    M, N, shape = sizeof(format.type), format.leng, format.shape
    #  Or preallocate array and use read!
    data = reshape(ntoh.(
        reinterpret(format.type, read(io, M*N))), shape)
    #  Assign missing values
    if !isnothing(fields.miss)
        data[data .== fields.miss] .= missing
    end
    data
end

function Base.write(io::IO, data::AbstractArray, fields::ImageField)
    #  Assign missing values
    if !isnothing(fields.miss)
        data[data .== missing] .= fields.miss
    end
    n = Base.write(io, hton.(reshape(data, :)))
end

function applyunits(data::AbstractArray, fields::ImageField)
    !isnothing(fields.unit) ? data*fields.unit : data
end

function removeunits(data::AbstractArray)
    typeof(data) <: Quantity ? data.val : data
end

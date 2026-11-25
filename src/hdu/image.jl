####    Image HDU functions

function Base.read(io::IO, ::Type{Image}, format::DataFormat,
    fields::ImageField; scale::Bool = true, kwds...)

    begpos = position(io)
    #  Read data array
    M, N = sizeof(format.type), format.leng
    data = read(io, format, fields)
    #  Seek to end of the last data block
    # seek(io, begpos + BLOCKLEN*div(M*N, BLOCKLEN, RoundUp))

    data = scale ? scaled(data, fields.scale, fields.zero) : data
    #=
    if get(kwds, :unit, true)
        apply_unit(data, cards)
    end
    =#

    ####    Get WCS keywords
    data
end

function Base.write(io::IO, ::Type{Image}, data::Missing, format::DataFormat,
    fields::ImageField; kwds...)
end

function Base.write(io::IO, ::Type{Image}, data::AbstractArray,
        format::DataFormat, fields::ImageField; kwds...)

    if format.leng > 0
        #  data = removeunits(data)

        write(io, data, fields; kwds...)
        padblock(io, format)
    end
end

function verify!(::Type{Image}, cards::Cards, format::DataFormat,
    mankeys::AbstractDict)

    verifyshape!(cards, mankeys, format)
end

function DataFormat(::Type{Image}, data::Missing, mankeys::Dict{S, V}) where
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

function FieldFormat(::Type{Image}, format::DataFormat, reskeys::Dict{S, V},
    data::Missing) where {S<:AbstractString, V<:ValueType}

    #  Get missing value
    zero_ = leastfloat(get(reskeys, "BZERO", 0.0f0))
    scale = leastfloat(get(reskeys, "BSCALE", 1.0f0))
    miss  = format.type in MISSTYPE ? get(reskeys, "BLANK", nothing) : nothing
    dmin  = leastfloat(get(reskeys, "DATAMIN", nothing))
    dmax  = leastfloat(get(reskeys, "DATAMAX", nothing))
    ImageField(format.type, zero_, scale, miss, dmin, dmax)
end

function DataFormat(::Type{Image}, data::AbstractArray,
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

function FieldFormat(::Type{Image}, format::DataFormat, reskeys::Dict{S, V},
    data::AbstractArray) where {S<:AbstractString, V<:ValueType}

    #  Get missing value
    zero_ = leastfloat(get(reskeys, "BZERO", 0.0f0))
    scale = leastfloat(get(reskeys, "BSCALE", 1.0f0))
    miss  = format.type in MISSTYPE ? get(reskeys, "BLANK", nothing) : nothing
    dmin  = leastfloat(get(reskeys, "DATAMIN", nothing))
    dmax  = leastfloat(get(reskeys, "DATAMAX", nothing))
    ImageField(format.type, zero_, scale, miss, dmin, dmax)
end

function createcards!(::Type{Image}, format::DataFormat,
    fields::ImageField, cards::Cards; kwds...)

    arrangecards!(cards, ["XTENSION" => "IMAGE"; shapekeys(format)])
end

function createdata(::Type{Image}, format::DataFormat, ::ImageField; kwds...)
    #  Create simple N-dimensional array of zeros of type BITPIX
    length(format.shape) > 0 ? zeros(format.type, format.shape) : missing
end

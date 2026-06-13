####    Image HDU functions

function Base.read(
        io::IO, ::Type{Image}, format::DataFormat, fields::ImageField;
        scale::Bool = true, kwds...
    )

    begpos = position(io)
    #  Read data array
    M, N = sizeof(format.type), format.leng
    data = read(io, format, fields)
    #  Seek to end of the last data block
    # seek(io, begpos + BLOCKLEN*div(M*N, BLOCKLEN, RoundUp))

    data = scale ? fields.zero .+ fields.scale .* data : data
    #=
    if get(kwds, :unit, true)
        apply_unit(data, cards)
    end
    =#

    ####    Get WCS keywords
    return data
end

function Base.write(
        io::IO, ::Type{Image}, data::Missing, format::DataFormat,
        fields::ImageField; kwds...
    )
end

function Base.write(
        io::IO, ::Type{Image}, data::AbstractArray,
        format::DataFormat, fields::ImageField; kwds...
    )

    if format.leng > 0
        #  data = remove_units(data)

        write(io, data, fields; kwds...)
        padblock(io, format)
    end
    return
end

function verify!(
        ::Type{Image}, cards::Cards, format::DataFormat,
        mankeys::D
    ) where {D <: Dict{AbstractString, ValueType}}

    if haskey(mankeys, "BITPIX") && format.type != BITS2TYPE[mankeys["BITPIX"]]
        setindex!(cards, TYPE2BITS[format.type], "BITPIX")
        println("Warning: BITPIX set to $(TYPE2BITS[format.type])).")
    end
    if haskey(mankeys, "NAXIS1") && format.shape != datasize(cards, 1)
        N = length(format.shape)
        setindex!(cards, N, "NAXIS")
        for j in 1:N
            setindex!(cards, format.shape[j], "NAXIS$j")
        end
        println("Warning: NAXIS$(1:N) set to $(format.shape)")
    end
    return cards
end

function DataFormat(::Type{Image}, data::Missing, mankeys::Dict{S, V}) where
    {S <: AbstractString, V <: ValueType}

    #  Determine format from data
    type = BITS2TYPE[get(mankeys, "BITPIX", 32)]
    leng = datalength(mankeys, 1)
    shape = datasize(mankeys, 1)
    param = get(mankeys, "PCOUNT", 0)
    group = get(mankeys, "GCOUNT", 1)
    heap = param > 0 ? get(mankeys, "THEAP", 0) : 0
    return DataFormat(type, leng, shape, param, group, heap)
end

function FieldFormat(
        ::Type{Image}, format::DataFormat, reskeys::Dict{S, V},
        data::Missing
    ) where {S <: AbstractString, V <: ValueType}

    #  Get missing value
    zero_ = least_float_type(get(reskeys, "BZERO", 0.0f0))
    scale = least_float_type(get(reskeys, "BSCALE", 1.0f0))
    miss = format.type in MISSTYPE ? get(reskeys, "BLANK", nothing) : nothing
    dmin = least_float_type(get(reskeys, "DATAMIN", nothing))
    dmax = least_float_type(get(reskeys, "DATAMAX", nothing))
    return ImageField(format.type, zero_, scale, miss, dmin, dmax)
end

function DataFormat(
        ::Type{Image}, data::AbstractArray,
        mankeys::Dict{S, V}
    ) where {S <: AbstractString, V <: ValueType}

    #  Determine format from data
    type = eltype(data)
    leng = length(data)
    shape = size(data)
    param = get(mankeys, "PCOUNT", 0)
    group = get(mankeys, "GCOUNT", 1)
    heap = 0
    return DataFormat(type, leng, shape, param, group, heap)
end

function FieldFormat(
        ::Type{Image}, format::DataFormat, reskeys::Dict{S, V},
        data::AbstractArray
    ) where {S <: AbstractString, V <: ValueType}

    #  Get missing value
    zero_ = least_float_type(get(reskeys, "BZERO", 0.0f0))
    scale = least_float_type(get(reskeys, "BSCALE", 1.0f0))
    miss = format.type in MISSTYPE ? get(reskeys, "BLANK", nothing) : nothing
    dmin = least_float_type(get(reskeys, "DATAMIN", nothing))
    dmax = least_float_type(get(reskeys, "DATAMAX", nothing))
    return ImageField(format.type, zero_, scale, miss, dmin, dmax)
end

function create_cards!(
        ::Type{Image}, format::DataFormat, fields::ImageField,
        cards::Cards; kwds...
    )

    N, B = length(format.shape), TYPE2BITS[format.type]
    #  Create mandatory (required) header cards and remove them from the deck
    #  if necessary
    required = Vector{Card{<:Any}}(undef, 3 + N)
    required[1] = popat!(cards, "XTENSION", Card("XTENSION", "IMAGE"))
    required[2] = popat!(cards, "BITPIX", Card("BITPIX", B))
    required[3] = popat!(cards, "NAXIS", Card("NAXIS", N))
    required[4:(3 + N)] .= [
        popat!(
                cards, "NAXIS$j",
                Card("NAXIS$j", format.shape[j])
            ) for j in 1:N
    ]

    #  Append remaining cards in deck, but first remove the END card
    popat!(cards, "END")
    M = length(cards)
    kards = Vector{Card{<:Any}}(undef, 3 + N + M)
    kards[1:(3 + N)] .= required
    kards[(4 + N):(3 + N + M)] .= cards
    #  END card is implied. It will be appended on write.
    return kards
end

function create_data(::Type{Image}, format::DataFormat, ::ImageField; kwds...)
    #  Create simple N-dimensional array of zeros of type BITPIX
    return length(format.shape) > 0 ? zeros(format.type, format.shape) : missing
end

####    Conforming HDU functions

"""
    ConformField()

Conforming array element descriptor
"""
struct ConformField <: AbstractField
end

function Base.read(io::IO, ::Type{Conform}, format::DataFormat,
    fields=ConformField; scale::Bool = true, kwds...)

    begpos = position(io)
    #  Read data array
    data = read(io, format, fields)
    #  Seek to end of the last data block
    # seek(io, begpos + BLOCKLEN*div(format.leng, BLOCKLEN, RoundUp))

    data = scale ? scaled(data, fields.scale, fields.zero) : data
    #=
    data = if get(kwds, :unit, true)
        apply_unit(data, cards)
    end
    =#

    ####    Get WCS keywords
    data
end

function Base.write(io::IO, ::Type{Conform}, data::AbstractArray,
        format::DataFormat, fields=ConformField; kwds...)

    data = remove_units(data)

    println(format)
    println(data)
    dbytes = write(io, format, data; kwds...)
    println(dbytes)
    pbytes = padblock(io, format)
    println(dbytes+pbytes)
end

function verify!(::Type{Conform}, cards::Cards, format::DataFormat,
    mankeys::AbstractDict)

    verifyshape!(cards, mankeys, format)
end

function DataFormat(::Type{Conform}, data::Missing, mankeys::Dict{S, V}) where
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

function FieldFormat(::Type{Conform}, format::DataFormat, reskeys::D) where
    D<:Dict{AbstractString, ValueType}

    [ConformField()]
end

function createcards!(::Type{Conform}, format::DataFormat,
    fields::ConformField, cards::Cards, kwds...)

    N, B = length(format.shape), TYPE2BITS[format.type]
    #  Create mandatory (required) header cards and remove them from the deck
    #  if necessary
    required = Cards(undef, 3+N)
    required[1] = popat!(cards, "SIMPLE", Card("SIMPLE", true))
    required[2] = popat!(cards, "BITPIX", Card("BITPIX", B))
    required[3] = popat!(cards, "NAXIS", Card("NAXIS", N))
    required[4:3+N] .= [popat!(cards, "NAXIS$j",
        Card("NAXIS$j", format.shape[j])) for j = 1:N]

    #  Append remaining cards in deck, but first remove the END card
    popat!(cards, "END")
    M = length(cards)
    kards = Cards(undef, 3+N+M)
    kards[1:3+N] .= required
    kards[4+N:3+N+M] .= cards
    #  END card is implied. It will be appended on write.
    kards
end

function create_data(::Type{Conform}, format::DataFormat, fields::ConformField;
    kwds...)
    #  Create simple N-dimensional array of zeros of type BITPIX
    length(format.shape) > 0 ? zeros(format.type, format.shape) : missing
end


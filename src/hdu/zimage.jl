####    ZImage HDU functions

using CodecZlib
#  add Rice, PLIO, Hcompress, and No compression algorithms

struct ZImageField
    #  Uncompressed image values
    name::String
    type::Type
    comp::String
    mask::String
    quant::String
    dithr::Int64
end

function Base.read(io::IO, ::Type{ZImage}, cards::Vector{Card}; kwds...)

end

function Base.write(io::IO, ::Type{ZImage}, cards::Vector{Card}; kwds...)

end

#  The keywords that describe the compressed image are integers (Sect. 10.1)
function verify!(::Type{ZImage}, cards::Cards, mankeys::AbstractDict, reskeys::AbstractDict)
    cards = invoke(verify!, Tuple{Type{<:AbstractHDU}, Cards, AbstractDict, AbstractDict}, ZImage, cards,
        mankeys, reskeys)
    verifyinteger(mankeys, r"^(ZBITPIX|ZNAXIS\d*|ZPCOUNT)$")
    verifyinteger(reskeys, r"^(ZTILE\d+|ZDITHER0|ZGCOUNT|ZBLANK)$")
    cards
end

function verify!(::Type{ZImage}, type::Type, shape::Tuple, cards::Cards,
    mankeys::D) where D<:Dict{AbstractString, ValueType}

    if haskey(mankeys, "BITPIX") && type != BITS2TYPE[mankeys["BITPIX"]]
        setindex!(cards, "BITPIX", TYPE2BITS[type])
        @warn "BITPIX set to $(TYPE2BITS[type]))."
    end
    if haskey(mankeys, "NAXIS1") && shape != datasize(cards, 1)
        N = length(shape)
        setindex!(cards, "NAXIS", N)
        for j=1:N setindex!(cards, "NAXIS$j", shape[j]) end
        @warn "NAXIS$(1:N) set to $shape"
    end
    cards
end

function DataFormat(::Type{ZImage}, data::Nothing, mankeys::Dict{S, V}) where
    {S<:AbstractString, V<:ValueType}

end

function FieldFormat(::Type{ZImage}, mankeys::DataFormat, reskeys::Dict{S, V},
    data::Nothing) where {S<:AbstractString, V<:ValueType}

end

function createcards!(::Type{ZImage}, format::DataFormat,
    fields::Vector{ZImageField}, cards::Cards; kwds...)

end

function createdata(::Type{ZImage}, format::DataFormat,
    fields::Vector{ZImageField}; kwds...)

end

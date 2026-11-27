####    ZTable HDU functions

struct ZTable <: AbstractHDU end

#  The fill after the data is that of a binary table
fillrule(::Type{ZTable}) = fillrule(Bintable)

using CodecZlib
#  add Rice, PLIO, Hcompress, and No compression algorithms

struct ZTableField
    name::String
    type::Type
    slice::UnitRange{Int}
    leng::Int
    shape::Tuple{Vararg{Int}}
    comp::String
    param::Int
end

function Base.read(io::IO, ::Type{ZTable}, cards::Vector{Card}; kwds...)

end

function Base.write(io::IO, ::Type{ZTable}, cards::Vector{Card}; kwds...)

end

#  The keywords that describe the compressed table are integers (Sect. 10.3)
function verify!(::Type{ZTable}, cards::Cards, mankeys::AbstractDict, reskeys::AbstractDict)
    cards = invoke(verify!, Tuple{Type{<:AbstractHDU}, Cards, AbstractDict, AbstractDict}, ZTable, cards,
        mankeys, reskeys)
    verifyinteger(mankeys, r"^(ZNAXIS\d*|ZPCOUNT|ZTILELEN)$")
    verifyinteger(reskeys, r"^ZTHEAP$")
    cards
end

function verify!(::Type{ZTable}, type::Type, shape::Tuple, cards::Cards,
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

function DataFormat(::Type{ZTable}, data::Nothing, mankeys::Dict{S, V}) where
    {S<:AbstractString, V<:ValueType}

end

function FieldFormat(::Type{ZTable}, mankeys::DataFormat, reskeys::Dict{S, V},
    data::Nothing) where {S<:AbstractString, V<:ValueType}

end

function createcards!(::Type{ZTable}, format::DataFormat,
    fields::Vector{ZTableField}, cards::Cards; kwds...)

end

function createdata(::Type{ZTable}, format::DataFormat,
    fields::Vector{ZTableField}; kwds...)

end

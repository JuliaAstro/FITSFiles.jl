####    ZTable HDU functions

using CodecZlib
#  add Rice, PLIO, Hcompress, and No compression algorithms

"""
Compressed table element descriptor
"""
struct ZTableField <: AbstractField
    "The name of the field"
    name::String
    "The type of the field"
    type::Type
    "The slice of the field bytes from start of record"
    slice::UnitRange{Integer}
    "The number of elements in the field"
    leng::Integer
    "The dimensions of the field"
    shape::Tuple
    "The type of compression"
    comp::String
    "The compression parameter"
    param::Integer
end

function Base.read(io::IO, ::Type{ZTable}, cards::Vector{Card}; kwds...)

end

function Base.write(io::IO, ::Type{ZTable}, cards::Vector{Card}; kwds...)

end

function verify!(::Type{ZTable}, type::Type, shape::Tuple, cards::Cards,
    mankeys::D) where D<:Dict{AbstractString, ValueType}

    if haskey(mankeys, "BITPIX") && type != BITS2TYPE[mankeys["BITPIX"]]
        setindex!(cards, "BITPIX", TYPE2BITS[type])
        println("Warning: BITPIX set to $(TYPE2BITS[type])).")
    end
    if haskey(mankeys, "NAXIS1") && shape != datasize(cards, 1)
        N = length(shape)
        setindex!(cards, "NAXIS", N)
        for j=1:N setindex!(cards, "NAXIS$j", shape[j]) end
        println("Warning: NAXIS$(1:N) set to $shape")
    end
    cards
end

function DataFormat(::Type{ZTable}, data::Missing, mankeys::Dict{S, V}) where
    {S<:AbstractString, V<:ValueType}

end

function FieldFormat(::Type{ZTable}, mankeys::DataFormat, reskeys::Dict{S, V},
    data::Missing) where {S<:AbstractString, V<:ValueType}

end

function create_cards!(::Type{ZTable}, format::DataFormat,
    fields::Vector{ZTableField}, cards::Cards; kwds...)

end

function create_data(::Type{ZTable}, format::DataFormat,
    fields::Vector{ZTableField}; kwds...)

end

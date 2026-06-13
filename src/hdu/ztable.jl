####    ZTable HDU functions

using CodecZlib
#  add Rice, PLIO, Hcompress, and No compression algorithms

struct ZTableField
    name::String
    type::Type
    slice::UnitRange{Int64}
    leng::Int64
    shape::Tuple
    comp::String
    param::Int64
end

function Base.read(io::IO, ::Type{ZTable}, cards::Vector{Card}; kwds...)

end

function Base.write(io::IO, ::Type{ZTable}, cards::Vector{Card}; kwds...)

end

function verify!(
        ::Type{ZTable}, type::Type, shape::Tuple, cards::Cards,
        mankeys::D
    ) where {D <: Dict{AbstractString, ValueType}}

    if haskey(mankeys, "BITPIX") && type != BITS2TYPE[mankeys["BITPIX"]]
        setindex!(cards, "BITPIX", TYPE2BITS[type])
        println("Warning: BITPIX set to $(TYPE2BITS[type])).")
    end
    if haskey(mankeys, "NAXIS1") && shape != datasize(cards, 1)
        N = length(shape)
        setindex!(cards, "NAXIS", N)
        for j in 1:N
            setindex!(cards, "NAXIS$j", shape[j])
        end
        println("Warning: NAXIS$(1:N) set to $shape")
    end
    return cards
end

function DataFormat(::Type{ZTable}, data::Nothing, mankeys::Dict{S, V}) where
    {S <: AbstractString, V <: ValueType}

end

function FieldFormat(
        ::Type{ZTable}, mankeys::DataFormat, reskeys::Dict{S, V},
        data::Nothing
    ) where {S <: AbstractString, V <: ValueType}

end

function create_cards!(
        ::Type{ZTable}, format::DataFormat,
        fields::Vector{ZTableField}, cards::Cards; kwds...
    )

end

function create_data(
        ::Type{ZTable}, format::DataFormat,
        fields::Vector{ZTableField}; kwds...
    )

end

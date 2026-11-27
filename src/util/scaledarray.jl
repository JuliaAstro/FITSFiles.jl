####    ScaledArray    ####

"""
	ScaledArray(values, scale, zero)

The physical values of floating-point data that were read with a BSCALE and a BZERO that are not 1 and 0 (Eq. 3 of the standard), or
with a PSCALn and a PZEROn (Eq. 5), together with that `scale` and `zero`, which have the type of the stored values. The stored values
and the physical values of floating-point data have the same type, so the type does not say which of them an array is. The array that
is a `ScaledArray` is the physical values, and is written as the stored values `(value - zero)/scale`, and the header has the BSCALE
and BZERO (or PSCALn and PZEROn) of the array. The array that is made from a `ScaledArray` by an operation of its values, e.g., a
broadcast or a slice, is a plain array, and is the stored values, which are written as they are, and `copy` is a `ScaledArray`.

The `scale` and the `zero` are numbers, or vectors with a number for each column of a matrix of the parameters of one name of random
groups (Sect. 6.1.2). The values are the values of `parent`.
"""
struct ScaledArray{T, N, A<:AbstractArray{T, N}, S, Z} <: AbstractArray{T, N}
	parent::A
	scale::S
	zero::Z
end

Base.parent(array::ScaledArray) = array.parent
Base.size(array::ScaledArray) = size(array.parent)
Base.axes(array::ScaledArray) = axes(array.parent)
Base.IndexStyle(::Type{<:ScaledArray{T, N, A}}) where {T, N, A} = IndexStyle(A)
Base.getindex(array::ScaledArray, i::Int) = array.parent[i]
Base.getindex(array::ScaledArray{T, N}, I::Vararg{Int, N}) where {T, N} = array.parent[I...]
Base.setindex!(array::ScaledArray, value, i::Int) = (array.parent[i] = value; array)
Base.setindex!(array::ScaledArray{T, N}, value, I::Vararg{Int, N}) where {T, N} = (array.parent[I...] = value; array)

#  A copy has the same scale and zero, and is the physical values, as the array is
Base.copy(array::ScaledArray) = ScaledArray(copy(array.parent), array.scale, array.zero)

#  The scale and the zero of the `j`th column of the array, which are those of the array if they are numbers
scaleof(array::ScaledArray, j::Integer = 1) = array.scale isa AbstractVector ? array.scale[j] : array.scale
zeroof(array::ScaledArray, j::Integer = 1) = array.zero isa AbstractVector ? array.zero[j] : array.zero

"""
	ScaledRecords(records, scales, zeros)

The records of random groups (`record = true`) whose values are the physical values of floating-point stored values (see
[`ScaledArray`](@ref)): the parameters and the array of each record, which have the type of the stored values, and are written as the
stored values. The vectors `scales` and `zeros` have the PSCALn and PZEROn of the parameters, and the BSCALE and BZERO of the array,
in order. The records are the values of `parent`.
"""
struct ScaledRecords{R, V<:AbstractVector{R}, S<:AbstractVector, Z<:AbstractVector} <: AbstractVector{R}
	parent::V
	scales::S
	zeros::Z
end

Base.parent(records::ScaledRecords) = records.parent
Base.size(records::ScaledRecords) = size(records.parent)
Base.IndexStyle(::Type{<:ScaledRecords}) = IndexLinear()
Base.getindex(records::ScaledRecords, i::Int) = records.parent[i]
Base.setindex!(records::ScaledRecords, value, i::Int) = (records.parent[i] = value; records)
Base.copy(records::ScaledRecords) = ScaledRecords(copy(records.parent), records.scales, records.zeros)

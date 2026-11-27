####    MappedArray    ####

"""
	MappedArray(values, size, decode; value, probe, source)

The data array of an HDU that is read in place from its file, which is memory-mapped, so that only the values that are indexed are read from the
file. The `values` are the values of the array of the file, in the byte order of the file (big-endian) and the order of the array (the first
axis varies fastest), whose shape is `size`, e.g., a memory map of the data of the HDU, and `decode` is the function of an array of the
values that are in the byte order of the machine to the values of the HDU, which are scaled and have `missing` for the undefined values, as the
array that is read is. The keyword `value` is the function of one value, which is `decode` of an array of one value if it is not given, and
the type of the values is that of the values of the keyword `probe`, a vector of values of the file. The `source` is the lazy array of the HDU
that the array is read from, which the data are copied from when the HDU is written. The array is read from the file as the file is when it is
indexed, so it is not valid if the file is truncated or changed. It is read-only.

A slice of the array, e.g., `array[1:100, 5, :]`, and `collect(array)` read the values at once, and a value that is indexed is read with the
function `value`.
"""
struct MappedArray{T, N, R, A <: AbstractVector{R}, F, G, S} <: AbstractArray{T, N}
	values::A
	size::NTuple{N, Int}
	decode::F
	value::G
	source::S
end

function MappedArray(values::AbstractVector{R}, size::NTuple{N, Int}, decode; probe::AbstractVector{R} = zeros(R, 1),
	value = x -> first(decode([x])), source::Union{LazyArray, Nothing} = nothing) where {R, N}

	#  The type of the values is that of the decoded values of the `probe`, which has the values of the type of the file, and the undefined
	#  value if the values have one
	T = eltype(decode(probe))
	MappedArray{T, N, R, typeof(values), typeof(decode), typeof(value), typeof(source)}(values, size, decode, value, source)
end

Base.size(array::MappedArray) = array.size
Base.IndexStyle(::Type{<:MappedArray}) = IndexLinear()

#  The value at the place of the file `i`
mappedvalue(array::MappedArray, i::Integer) = array.value(ntoh(array.values[i]))

#  The array is read-only, since the values are those of the file
Base.setindex!(array::MappedArray, value, I...) = throw(ArgumentError("A mapped array of the data of an HDU is read-only, since its values are " *
	"those of the file. Change a copy of the array, e.g., `collect(array)`."))

Base.@propagate_inbounds function Base.getindex(array::MappedArray, i::Int)
	@boundscheck checkbounds(array, i)
	mappedvalue(array, i)
end

Base.@propagate_inbounds function Base.getindex(array::MappedArray{T, N}, I::Vararg{Int, N}) where {T, N}
	@boundscheck checkbounds(array, I...)
	mappedvalue(array, LinearIndices(array.size)[I...])
end

#  A slice, of ranges, integers, and colons, is read from the file as an array of the values that are indexed
function Base.getindex(array::MappedArray{T, N}, I::Vararg{Union{Colon, Integer, AbstractRange{<:Integer}}, N}) where {T, N}
	raw = ntoh.(reshape(array.values, array.size)[I...])
	raw isa AbstractArray ? array.decode(raw) : array.value(raw)
end

Base.Array(array::MappedArray{T, N}) where {T, N} = array[ntuple(_ -> Colon(), Val(N))...]
Base.collect(array::MappedArray) = Array(array)
Base.copy(array::MappedArray) = Array(array)

#  The values of the data of a lazy array, which are the values of the file, memory-mapped. The file must be as it was when the HDU was read, and
#  have the data of the header.
function mappedvalues(data::LazyArray)
	verifylazy(data)
	type, nbytes = data.format.type, sizeof(data.format.type) * data.format.leng
	open(data.filnam) do io
		nbytes > filesize(io) - data.begpos && throw(ArgumentError("The data of the HDU are $nbytes bytes, as its header says, but the file has " *
			"only $(max(filesize(io) - data.begpos, 0)) of them."))
		Mmap.mmap(io, Vector{type}, data.format.leng, data.begpos)
	end
end

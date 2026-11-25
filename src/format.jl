####    DataFormat    ###

"""
	DataFormat(type, leng, shape, param, group, heap)

The generic data format descriptor for HDUs.
"""
struct DataFormat
	"The type of the array element."
	type::Type
	"The number of elements."
	leng::Int
	"The shape of the array."
	shape::Tuple{Vararg{Int}}
	"The number of parameters."
	param::Int
	"The number of groups."
	group::Int
	"The offset of the heap in bytes."
	heap::Int
end

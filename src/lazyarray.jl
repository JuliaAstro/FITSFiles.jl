####    LazyArray    ####

"""
	LazyArray(filnam, mtime, begpos, format, fields, keywds)

The lazy array file descriptor of the data of an HDU, which is read from the file when the data is
accessed.
"""
struct LazyArray
	"File name"
	filnam::String
	"Modification time"
	mtime::Float64
	"Beginning file position"
	begpos::Int64
	"Array format"
	format::DataFormat
	"Field formats"
	fields::Union{AbstractField, AbstractVector{<:AbstractField}}
	"HDU keywords"
	keywds::NamedTuple
end

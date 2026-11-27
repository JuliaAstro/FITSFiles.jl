####    LazyArray    ####

"""
	LazyArray(filnam, mtime, begpos, format, fields, keywds)

The lazy array file descriptor of the data of an HDU, which is read from the file when the data is
accessed. It is the place of the data of an HDU that a file is scanned for, so that the HDUs of the file are read
without reading their data, which `filnam` is the absolute path of, and `mtime` is the modification time of when the HDU was read.
The data are read from the file, or are copied as they are when the HDU is written, only if the file has not changed (see
[`verifylazy`](@ref)).
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

"""
	verifylazy(data::LazyArray)

Return the lazy array `data` of the data of an HDU, or raise an `ArgumentError` if the file that the data are read from does not exist, or
has been modified since the HDU was read, since the position and the size of the data that the header says are not those of the file then.
"""
function verifylazy(data::LazyArray)
	isfile(data.filnam) || throw(ArgumentError("The file $(data.filnam), which the data of the HDU are read from, does not exist."))
	stat(data.filnam).mtime == data.mtime || throw(ArgumentError("The file $(data.filnam), which the data of the HDU are read from, " *
		"has been modified since the HDU was read, so the data are not those that the header describes."))
	data
end

#  The file of the lazy array that is open at the first byte of the data, which `verifylazy` verifies
function openlazy(data::LazyArray)
	verifylazy(data)
	io = open(data.filnam)
	seek(io, data.begpos)
	io
end

#  Copy `n` bytes from `src` to `dst`, a chunk at a time, so that the data of any size are not in memory at once
function copybytes(dst::IO, src::IO, n::Integer; chunk::Integer = 1 << 23)
	buffer = Vector{UInt8}(undef, min(n, chunk))
	while n > 0
		m = min(n, length(buffer))
		readbytes!(src, buffer, m) == m || throw(ArgumentError("The file has fewer bytes than the header of the HDU says."))
		write(dst, view(buffer, 1:m))
		n -= m
	end
	nothing
end

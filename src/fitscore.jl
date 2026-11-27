####    FITS type    ####

"""
    verifyposition(hdu, j)

Warn if the `j`th HDU of a FITS file is not what the standard requires of its position (Sect. 3.1): the first HDU is the
primary HDU, whose header begins with SIMPLE, and the HDUs after it are conforming extensions, whose headers begin with
XTENSION, and so do not have SIMPLE (Sect. 3.4.3). A file that has HDUs that are not in this order is read and written as it
is. Return the HDU. The EXTEND keyword of the primary header is advisory (Sect. 4.4.2.1), so it is not verified.
"""
function verifyposition(hdu::HDU, j::Integer)
	simple = haskey(getfield(hdu, :cards), "SIMPLE")
	if j == 1 && !simple
		@warn "The first HDU of a FITS file must be the primary HDU, which has SIMPLE (Sect. 3.1), but it is an " *
			"extension, which has XTENSION. It is read as it is."
	elseif j > 1 && simple
		@warn "HDU $j of a FITS file has SIMPLE, but only the first HDU is a primary HDU (Sects. 3.1 and 3.4.3): " *
			"the HDUs after it are conforming extensions, which have XTENSION. It is read as it is."
	end
	hdu
end

#  The type of the HDU of a header that begins with SIMPLE, which the primary array is, for the comparison of the names of the HDUs: the
#  primary array is equivalent to an IMAGE extension, and a type of HDU that is not defines its own
primarytype(::Type{<:AbstractHDU}) = "IMAGE"

"""
    verifyname(hdus)

Warn if the last HDU of the vector `hdus` has the same type, EXTNAME, EXTVER, and EXTLEVEL as an HDU before it. It is
recommended that the combination of these keywords is unique in each HDU of a FITS file that has them (Sect. 4.4.2.6 of
the standard). The type of an HDU is the value of its XTENSION, and the primary array is equivalent to an IMAGE extension,
but random groups are not: their type is GROUPS. An absent EXTVER or EXTLEVEL is 1, and the HDUs that have none of the three keywords are not compared. The HDUs are read
and written as they are. Return the HDUs.
"""
function verifyname(hdus::AbstractVector)
	isempty(hdus) && return hdus
	hdu = last(hdus)
	named(hdu) = any(haskey(getfield(hdu, :cards), key) for key in ("EXTNAME", "EXTVER", "EXTLEVEL"))
	named(hdu) || return hdus
	function signature(hdu)
		cards = getfield(hdu, :cards)
		type = haskey(cards, "XTENSION") ? rstrip(string(cards["XTENSION"])) : primarytype(typeofhdu(hdu))
		(type, extname(hdu), extver(hdu), extlevel(hdu))
	end
	for j = 1:(length(hdus)-1)
		if named(hdus[j]) && signature(hdus[j]) == signature(hdu)
			type, name, version, level = signature(hdu)
			@warn "HDU $(length(hdus)) of a FITS file has the same type $type, EXTNAME $(repr(name)), EXTVER $version, " *
				"and EXTLEVEL $level as HDU $j (Sect. 4.4.2.6): it is recommended that the combination is unique. " *
				"It is read as it is."
			break
		end
	end
	hdus
end

"""
    specialrecords(io, n)

Return true, with a warning, if the bytes of `io` that follow the `n`th HDU are special records (Sect. 3.5 of the standard), and
move to the end of `io`. Special records are the blocks after the last HDU, which do not meet the requirements of a conforming
extension, so that the first eight bytes of them are not `XTENSION`. The first eight bytes of the header of an HDU after the first
are `XTENSION`, and `SIMPLE  ` is read as an HDU that is in the wrong place (see [`verifyposition`](@ref)). The special records are
not read, and are not written.
"""
function specialrecords(io::IO, n::Integer)
	pos = position(io)
	head = String(read(io, 8))
	seek(io, pos)
	head in ("XTENSION", "SIMPLE  ") && return false
	nbytes = unreadbytes(io)
	nbytes == typemax(Int) && (nbytes = length(read(io)); seek(io, pos))
	@warn "The $nbytes bytes after HDU $n of the file are special records (Sect. 3.5 of the standard), because they do not " *
		"begin with XTENSION. They are not read."
	seekend(io)
	true
end

"""
	fits(io::IO; <keywords>)
	fits(filename::AbstractString; <keywords>)

Open and read a FITS file, returning a vector of header-data units (HDUs). The first HDU is the primary HDU and the
others are extensions (Sect. 3.1 of the standard), and a file whose HDUs are not in this order is read with a warning.
The special records after the last HDU (Sect. 3.5) are not read, with a warning.

The default data structure for Random and Bintable HDUs is a named tuple of arrays.

The data of the HDUs of a file are not read until they are accessed (`hdu.data`), so that a file is scanned quickly, e.g., to
[`info`](@ref) its HDUs, and `size(hdu)` is the size of the data from the header. They are read from the file each time they are accessed,
so the file must not have been modified since it was read, which is an `ArgumentError`, and an HDU that is written is written with the data
as they are in the file (see [`Base.write(io::IO, hdu::HDU)`](@ref)). The keyword `access` chooses how the data of a file are accessed: `:lazy`
is this default, `:memory` reads all of the data at once, and `:mapped` maps the data of the primary HDU, the IMAGE extensions, the conforming
HDUs, random groups, and the fixed-width numbers of binary tables, so that `hdu.data` is a read-only array that reads only the values that are indexed (see [`mapdata`](@ref) and [`Base.read(io::IO, ::Type{HDU})`](@ref)).

# Keywords

- `checksum::Bool=false`: verify the DATASUM and CHECKSUM keywords of each HDU, with a warning if a sum is not the sum
  of the data or of the HDU (Sect. 4.4.2.7 of the standard)
- `record::Bool=false`: structure the data as a list of records
- `scale::Bool=true`: apply the scale and zero keywords to the data; the data of a BSCALE of 1 and a BZERO of 0 are the stored
  values, e.g., the integers of an integer image, and the scaled values of 32- and 64-bit integers are `Float64`; an image of the offsets of Table 11 of the
  standard (BSCALE of 1 and BZERO of 2^15, 2^31, or 2^63 for 16-, 32-, or 64-bit integers, or -128 for bytes) is
  an array of `UInt16`, `UInt32`, `UInt64`, or `Int8`, and so is the array of random groups, and a parameter that has
  the PSCALn of 1 and the PZEROn of the offsets; floating-point data with a scale and a zero that are not 1 and 0 are a `FITSFiles.ScaledArray`,
  which has them
- `strict::Bool=true`: numbers with a lower case exponent letter (d or e) are invalid cards,
  unless false
- `units::Union{Bool, Module}=true`: the units in the comment of a number are the units of the value (`true` is Unitful, or the module `DynamicQuantities` when it is loaded), unless
  false
"""
function fits(io::IO; kwds...)
	hdus = HDU{<:AbstractHDU}[]
	while !eof(io)
		!isempty(hdus) && specialrecords(io, length(hdus)) && break
		push!(hdus, verifyposition(read(io, HDU; kwds...), length(hdus) + 1))
		verifyname(hdus)
	end
	hdus
end

function fits(file::AbstractString; kwds...)
	io = open(file)
	hdus = fits(io; kwds...)
	close(io)
	hdus
end

"""
    Base.write(io::IO, hdus::AbstractVector{<:HDU})
    Base.write(filename::AbstractString, hdus::AbstractVector{<:HDU})

Write a vector of header-data units (HDUs), of any type of HDU, e.g., the `Vector{HDU{Primary}}` of `[HDU(data, cards)]`, to a file, with a
warning if the first HDU is not a primary HDU or a later one is (Sect. 3.1 of the standard). The keyword `checksum::Bool=false` sets the
DATASUM and CHECKSUM keywords of each HDU (see [`Base.write(io::IO, hdu::HDU)`](@ref)). The data of the HDUs of a file that are not read are
copied from the file, so the vector is not written to that file, which is an `ArgumentError` that leaves the file as it is.
"""
function Base.write(io::IO, hdus::AbstractVector{<:HDU}; kwds...)
    for (j, hdu) in enumerate(hdus)
        verifyname(view(hdus, 1:j))
        write(io, verifyposition(hdu, j); kwds...)
    end
end

#  The methods for a `Vector` and a `SubArray` of HDUs, which are more specific than `Base.write(::IO, ::Array)` and `Base.write(::IO, ::StridedArray)`
#  for a vector of a type of HDU, e.g., `Vector{HDU{Primary}}`, which the method for an `AbstractVector` is not more specific than
Base.write(io::IO, hdus::Vector{<:HDU}; kwds...) = invoke(write, Tuple{IO, AbstractVector{<:HDU}}, io, hdus; kwds...)
Base.write(io::IO, hdus::SubArray{<:HDU, 1}; kwds...) = invoke(write, Tuple{IO, AbstractVector{<:HDU}}, io, hdus; kwds...)

function Base.write(file::AbstractString, hdus::AbstractVector{<:HDU}; kwds...)
    #  The data that are not read are read from their file when they are written, which opening the file for writing empties
    for (j, hdu) in enumerate(hdus)
        source = filesource(getfield(hdu, :data))
        !isnothing(source) && isfile(file) && isfile(source.filnam) && samefile(file, source.filnam) && throw(ArgumentError(
            "The data of HDU $j are not read, and are read from $(source.filnam), which opening it for writing empties. Write to another file."))
    end
    io = open(file, write=true)
    write(io, hdus; kwds...)
    close(io)
end

"""
	info(hdus::AbstractVector{<:HDU})

Briefly describe the list of header-data units (HDUs).
"""
function info(hdus::AbstractVector{<:HDU})
	typ  = rpad("HDU",   INFOTYPELEN)
	nam  = rpad("Name",  INFONAMELEN)
	ver  = lpad("Ver",   INFOVERSLEN)
	crd  = lpad("Cards", INFOCARDLEN)
	ltyp = lpad("Type",  INFOTYPELEN-1)
	siz  = "Shape"
	print(stdout, " #    $typ  $nam  $ver  $crd   $ltyp   $siz")
	print(stdout, "\n")
	for (j, hdu) in enumerate(hdus)
		info(hdu, j)
	end
end

function Base.show(io::IO, ::MIME"text/plain", hdus::AbstractVector{<:HDU})
	typ  = rpad("HDU",   INFOTYPELEN)
	nam  = rpad("Name",  INFONAMELEN)
	ver  = lpad("Ver",   INFOVERSLEN)
	crd  = lpad("Cards", INFOCARDLEN)
	ltyp = lpad("Type",  INFOTYPELEN-1)
	siz  = "Shape"
	print(io, " #    $typ  $nam  $ver  $crd   $ltyp   $siz")
	print(io, "\n")
	for (j, hdu) in enumerate(hdus)
		cards = getfield(hdu, :cards)
		N = cards["NAXIS"]
		typ = rpad(typeofhdu(hdu), INFOTYPELEN)
		nam = rpad(extname(hdu), INFONAMELEN)
		ver = lpad(extver(hdu), INFOVERSLEN)
		crd = lpad(length(cards), INFOCARDLEN)
		siz = join([string(cards["NAXIS$j"])
				for j ∈ firstaxis(typeofhdu(hdu)):N], " × ")
		eltype = lpad(datatype(cards), INFOTYPELEN)
		print(io, "$(lpad(j, 3))   $typ  $nam  $ver  $crd  $eltype   $siz")
		if j != length(hdus)
			print(io, "\n")
		end
	end
end

####    Dictionary-like key function for HDUs

function Base.haskey(hdus::AbstractVector{<:HDU}, key::Type{<:AbstractHDU})::Bool
	for hdu in hdus
		if typeofhdu(hdu) == key
			return true
		end
	end
	false
end

function Base.getindex(hdus::AbstractVector{<:HDU}, key::Type{<:AbstractHDU})::HDU
	for hdu in hdus
		if typeofhdu(hdu) == key
			return hdu
		end
	end
	throw(KeyError(key))
end

function Base.getindex(hdus::AbstractVector{<:HDU}, name::U)::HDU where
	U<:Union{AbstractString, Symbol}

	for hdu in hdus
		if haskey(hdu.cards, "EXTNAME") &&
			uppercase(rstrip(hdu.cards["EXTNAME"])) ==
				uppercase(name isa Symbol ? string(name) : name)
			return hdu
		end
	end
	throw(KeyError(name))
end

"""
    hdus[name]
    hdus[name, version]

Return the HDU of the vector `hdus` whose EXTNAME is `name`, without regard to the case, which is the first HDU of that name
if the name is not unique. With a `version`, return the HDU whose EXTVER is `version`, where an absent EXTVER is 1
(Sect. 4.4.2.6 of the standard). A `KeyError` is raised if there is no such HDU.
"""
function Base.getindex(hdus::AbstractVector{<:HDU}, name::U, version::Integer)::HDU where
	U<:Union{AbstractString, Symbol}

	for hdu in hdus
		if uppercase(extname(hdu)) == uppercase(string(name)) && extver(hdu) == version
			return hdu
		end
	end
	throw(KeyError((name, version)))
end

function Base.get(hdus::AbstractVector{<:HDU}, name::U, default::V = "")::Union{HDU, Nothing}  where
	{U<:Union{AbstractString, Symbol}, V<:Union{AbstractString, Symbol}}

	value::Union{HDU, Nothing} = nothing
	for key in (name, default)
		for hdu in hdus
			if haskey(hdu.cards, "EXTNAME") &&
				uppercase(rstrip(hdu.cards["EXTNAME"])) ==
					uppercase(key isa Symbol ? string(key) : key)
				value = hdu
				break
			end
		end
	end
	value
end

function Base.get(hdus::AbstractVector{<:HDU}, names::K, defaults::D)::Vector where
	{K<:Union{Vector, Tuple}, D<:Union{Vector, Tuple}}

	values = Any[fill(nothing, length(names))...]
	for (j, (name, default)) in enumerate(zip(names, defaults))
		for hdu in hdus
			if haskey(hdu.cards, "EXTNAME")
				if uppercase(rstrip(hdu.cards["EXTNAME"])) ==
					uppercase(name isa Symbol ? string(name) : name)
					values[j] = hdu
				elseif uppercase(rstrip(hdu.cards["EXTNAME"])) ==
					uppercase(default isa Symbol ? string(default) : default)
					values[j] = hdu
				end
			end
		end
	end
	values
end

function Base.findfirst(key::AbstractString, hdus::AbstractVector{<:HDU})::Union{Integer, Nothing}
	for (j, hdu) in enumerate(hdus)
		if uppercase(rstrip(hdu.cards[key])) == uppercase(key)
			return j
		end
	end
	nothing
end

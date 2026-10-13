####    FITS type    ####

#   Verify that first HDU is Primary or Random
#   Verify that first HDU has EXTEND keyword set

"""
	fits(io::IO; <keywords>)
	fits(filename::AbstractString; <keywords>)

Open and read a FITS file, returning a vector of header-data units (HDUs).

The default data stucture for Random and Bintable HDUs is a named tuple of arrays.

# Keywords

- `record::Bool=false`: structure the data as a list of records
- `scale::Bool=true`: apply the scale and zero keywords to the data
"""
function fits(io::IO; kwds...)
	hdus = HDU{<:AbstractHDU}[]
	while !eof(io)
		push!(hdus, read(io, HDU; kwds...))
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

Write a vector of header-data units (HDUs) to a file.
"""
function Base.write(io::IO, hdus::AbstractVector{<:HDU})
    for hdu in hdus
        write(io, hdu)
    end
end

#  Repeated for `Vector` so this method, not `Base.write(::IO, ::Array)`, wins
#  dispatch for concrete HDU vectors such as `[HDU(data, cards)]`.
function Base.write(io::IO, hdus::Vector{<:HDU})
    for hdu in hdus
        write(io, hdu)
    end
end

function Base.write(file::AbstractString, hdus::AbstractVector{<:HDU})
    io = open(file, write=true)
    write(io, hdus)
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
		nam = rpad(haskey(cards, "EXTNAME") ? cards["EXTNAME"] : "", INFONAMELEN)
		ver = lpad(haskey(cards, "EXTVERS") ? cards["EXTVER"] : "1", INFOVERSLEN)
		crd = lpad(length(cards), INFOCARDLEN)
		siz = join([string(cards["NAXIS$j"])
				for j ∈ (typeofhdu(hdu)==Random ? 2 : 1):N], " × ")
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

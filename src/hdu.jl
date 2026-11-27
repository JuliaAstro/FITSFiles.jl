#=   Improvements

 * tighten function argument types

 =#

####    HDU type    ####

abstract type AbstractHDU end

#  The HDU types are defined in the files of src/hdu, which are included after this file

const Cards = Union{Vector{Card}, Vector{Card{<:Any}}}

#   HDU type
"""
	HDU{T}(cards, data)
	HDU([data, [cards]]; <keywords>)
	HDU(cards; <keywords>)
	HDU(type, missing, [cards]; <keywords>)
	HDU(type, data, [cards]; <keywords>)

Create a header-data unit described by data and cards of type AbstractHDU.

The HDU function tries to determine the HDU type based on the data and cards.
If only data is provided, then an array is interpreted as a Primary HDU and a
Tuple or NamedTuple as a Bintable. If mandatory cards are provided, then
they are used to determine the HDU type. Otherwise, the HDU type must be
specified.

HDU types are: Primary, Random, Image, Table, Bintable, and Conform.

# Arguments

- `data::U=missing`: the binary or ASCII data, where `U <: Union{AbstractArray,
   Tuple, NamedTuple, Missing}`
- `cards::U=missing`: the list of cards, where `U <: Union{Card, Vector{Card}, Vector{Card{<:Any}},
  Missing}`

# Keywords

- `record::Bool=false`: structure the data as a list of records
- `scale::Bool=true`: apply the scale and zero keywords to the data; floating-point data that have a scale and a zero that are not 1
  and 0 are a `FITSFiles.ScaledArray`, which has them, and is written as the stored values

The following keywords format the cards that are created, and are those of [`Card`](@ref), which
describes them.

- `append::Bool=false`: append an ampersand to a string that is continued by a CONTINUE card
- `fixed::Bool=true`: create fixed format cards
- `slash::Integer=32`: index of the comment separator (/)
- `lpad::Integer=1`: number of spaces before the comment separator
- `rpad::Integer=1`: number of spaces after the comment separator
- `upad::Integer=1`: number of spaces after the units
- `truncate::Bool=true`: truncate a comment that is longer than the space at the end of the card
"""
struct HDU{S <: AbstractHDU}
	"The vector of cards."
	cards::Cards
	"The data, either an AbstractArray, LazyArray, Tuple, NamedTuple, or Missing"
	data::Union{AbstractArray, LazyArray, Tuple, NamedTuple, Missing}
end

const BLOCKLEN    = 2880
const BYTELEN     = 8
const INFONAMELEN = 24
const INFOVERSLEN = 3
const INFOTYPELEN = 8
const INFOCARDLEN = 6
const INFOLTYPLEN = 8

const BITS2TYPE = Dict(8 => UInt8, 16 => Int16, 32 => Int32, 64 => Int64,
	-32 => Float32, -64 => Float64)
const TYPE2BITS = Dict(UInt8 => 8, Int16 => 16, Int32 => 32, Int64 => 64,
	Float32 => -32, Float64 => -64)

#  The valid values of BITPIX (Table 8 of the standard), and the largest number of axes
const BITPIXVALUES = (8, 16, 32, 64, -32, -64)
const MAXAXES = 999

const OUTTYPE  = Dict(
    UInt8 => Float32, Int16 => Float32, Int32 => Float64, Int64 => Float64,
    Float32 => Float32, Float64 => Float64)

    #  Combine XTENSION values in card.jl and hdu.jl. The trailing spaces of a value are not
    #  significant, so the keys are not padded.
#  The XTENSION value is padded to 8 characters.
const XTENSIONLENGTH = 8
#  The maximum number of fields of a table (Sects. 7.2.1 and 7.3.1)
const MAXFIELDS = 999
#  The HDU type of the value of XTENSION, which each type of extension adds to when it is defined
const XTENSIONTYPE = Dict{String, Type}()

#  The roots of the keywords of the mandatory keywords and of the reserved keywords (see `getreservedkeys`), each root once. The
#  keywords that are common to the HDUs are here, and each type of HDU adds those of its own, which are in its file, when it is defined.
const MANDATORYKEYS = String["END", "BITPIX", "NAXIS"]
const RESERVEDKEYS = String["DATE", "DATE-OBS", "ORIGIN", "AUTHOR", "REFERENC", "OBJECT", "OBSERVER", "CHECKSUM", "DATASUM",
	"EXTNAME", "EXTVER", "EXTLEVEL", "EQUINOX", "EPOCH", "TELESCOP", "INSTRUME",
	#  World-coordinate and time keys that are integers
	"WCSAXES", "MJDREFI", "JDREFI"]

#  Check for header missing END card

#  The scale and the zero cards of data that are the physical values of floating-point stored values, which a type of HDU defines
#  (see `ScaledArray`)
scalecards!(::Type, cards::Cards, data) = cards

function HDU(data::D = missing, cards::C = missing; record::B = false,
	scale::B = true, append::B = false, fixed::B = true, slash::I = 32, lpad::I = 1,
	rpad::I = 1, upad::I = 1, truncate::B = true) where
	{C <: Union{Missing, Card, Cards, Vector{Card{T}}} where T <: AbstractCardType,
	D <: Union{Missing, AbstractArray, Tuple, NamedTuple}, B <: Bool, I <: Integer}

	kwds = (;
		#  data formatting options
		record, scale,
		#  card formatting options
		append, fixed, slash, lpad, rpad, upad, truncate)

	kards = ismissing(cards) ? Card[] : copy(cards)

	#  Remove END card. END card is implied. It will be appended on write.
	if !ismissing(kards)
		popat!(kards, "END")
	end

	#  Detect HDU type from either data or cards
	type = typeofhdu(data, getreservedkeys(kards)[1])
	HDU(type, data, kards; kwds...)
end

HDU(cards::Cards; kwds...) = HDU(missing, cards; kwds...)

function HDU(type::Type, ::Missing = missing, cards::C = missing; kwds...) where
	C <: Union{Card, Vector{Card}, Vector{Card{<:Any}}, Missing}

	kwds  = ismissing(kwds) ? (;) : kwds
	kards = ismissing(cards) ? Card[] : copy(cards)

	#  Remove END card. END card is implied. It will be appended on write.
	if !ismissing(kards)
		popat!(kards, "END")
	end

	#  Create dictionaries of mandatory and reserved keywords
	mankeys, reskeys = getreservedkeys(kards)

	kards  = verify!(type, kards, mankeys, reskeys)
	format = DataFormat(type, missing, mankeys)
	kards  = verify!(type, kards, format, mankeys)
	fields = FieldFormat(type, format, reskeys, missing)
	kards  = createcards!(type, format, fields, kards; kwds...)
	data   = createdata(type, format, fields; kwds...)

	HDU{type}(kards, data)
end


function HDU(type::Type, data::AbstractArray, cards::C = missing; kwds...) where
	C <: Union{Card, Vector{Card}, Vector{Card{<:Any}}, Missing}

	kwds  = ismissing(kwds) ? (;) : kwds
	kards = ismissing(cards) ? Card[] : copy(cards)

	#  Remove END card. END card is implied. It will be appended on write.
	if !ismissing(kards)
		popat!(kards, "END")
	end

	#  Create dictionaries of mandatory and reserved keywords
	mankeys, reskeys = getreservedkeys(kards)

	format = DataFormat(type, data, mankeys)
	verifycards!(type, kards, mankeys, reskeys, format)
	kards  = verify!(type, kards, format, mankeys)
	fields = FieldFormat(type, format, reskeys, data)
	kards  = createcards!(type, format, fields, kards; kwds...)
	kards  = scalecards!(type, kards, data)
	if eltype(data) <: Tuple
		data = [(; [Symbol(fields[j].name) => data[k][j]
					for j ∈ 1:format.param]..., data = data[k][end]) for k ∈ 1:format.group]
	end

	HDU{type}(kards, data)
end

function HDU(type::Type, data::U, cards::C = missing; kwds...) where
	{U <: Union{Tuple, NamedTuple},
	C <: Union{Card, Vector{Card}, Vector{Card{<:Any}}, Missing}}

	kwds  = ismissing(kwds) ? (;) : kwds
	kards = ismissing(cards) ? Card[] : copy(cards)

	#  Remove END card. END card is implied. It will be appended on write.
	if !ismissing(kards)
		popat!(kards, "END")
	end

	#  Create dictionaries of mandatory and reserved keywords
	mankeys, reskeys = getreservedkeys(kards)

	format = DataFormat(type, data, mankeys)
	verifycards!(type, kards, mankeys, reskeys, format)
	kards  = verify!(type, kards, format, mankeys)
	fields = FieldFormat(type, format, reskeys, data; kwds...)
	kards  = createcards!(type, format, fields, kards; kwds...)
	kards  = scalecards!(type, kards, data)
	if typeof(data) <: Tuple
		data = (; [Symbol(fields[j].name) => data[j] for j ∈ 1:format.param]...,
			data = data[end])
	end

	HDU{type}(kards, data)
end

"""
	extname(hdu)
	extver(hdu)
	extlevel(hdu)

Return the value of the EXTNAME, EXTVER, or EXTLEVEL keyword of the header-data unit `hdu` (Sect. 4.4.2.6 of the
standard), which distinguish the extensions of a file. The name is an empty string if the keyword is absent, and the
version and the level are 1, as the standard says, if the keyword is absent. The trailing spaces of the name, which are
not significant, are removed.
"""
function extname(hdu::HDU)
	cards = getfield(hdu, :cards)
	haskey(cards, "EXTNAME") ? rstrip(string(cards["EXTNAME"])) : ""
end
function extver(hdu::HDU)
	cards = getfield(hdu, :cards)
	haskey(cards, "EXTVER") ? cards["EXTVER"] : 1
end
function extlevel(hdu::HDU)
	cards = getfield(hdu, :cards)
	haskey(cards, "EXTLEVEL") ? cards["EXTLEVEL"] : 1
end

"""
	info(hdu::HDU)

Briefly describe the header-data unit.
"""
function info(hdu::HDU, n::Integer = 0)
	cards = getfield(hdu, :cards)
	N = cards["NAXIS"]
	typ = rpad(typeofhdu(hdu), INFOTYPELEN)
	nam = rpad(extname(hdu), INFONAMELEN)
	ver = lpad(extver(hdu), INFOVERSLEN)
	crd = lpad(length(cards), INFOCARDLEN)
	siz = join([string(cards["NAXIS$j"])
				for j ∈ (typeofhdu(hdu)==Random ? 2 : 1):N], " × ")
	eltype = lpad(datatype(cards), INFOTYPELEN)
	print(stdout, "$(n == 0 ? "   " : lpad(n, 3))   $typ  $nam  $ver  $crd  $eltype   $siz\n")
end

function Base.show(io::IO, ::MIME"text/plain", hdu::HDU)
	cards = getfield(hdu, :cards)
	N = cards["NAXIS"]
	typ = rpad(typeofhdu(hdu), INFOTYPELEN)
	nam = rpad(extname(hdu), INFONAMELEN)
	ver = lpad(extver(hdu), INFOVERSLEN)
	crd = lpad(length(cards), INFOCARDLEN)
	siz = join([string(cards["NAXIS$j"])
				for j ∈ (typeofhdu(hdu)==Random ? 2 : 1):N], " × ")
	eltype = lpad(datatype(cards), INFOTYPELEN)
	print(io, "      $typ  $nam  $ver  $crd  $eltype   $siz")
end

function Base.getproperty(hdu::HDU, name::Symbol)
	if name === :data && getfield(hdu, :data) isa LazyArray
		desc = getfield(hdu, :data)
		io = open(desc.filnam)
		seek(io, desc.begpos)
		field = read(io, typeofhdu(hdu), desc.format, desc.fields;
			desc.keywds...)
		close(io)
	else
		field = getfield(hdu, name)
	end
	field
end

"""
    Base.read(io::IO, ::Type{HDU}; <keywords>)

Read the next header-data unit (HDU) from `io` and return it. The data of an HDU that is read
from a file is a lazy array, which is read when the data is accessed, and the data of an HDU that
is read from another stream is read at once. The fill of the last data block is zeros, or ASCII spaces for an ASCII table,
and a warning says if it is not (see [`verifyfill`](@ref)).

# Keywords

- `type=nothing`: the HDU type, e.g., `Image`, which is otherwise determined by the mandatory
  keywords of the header
- `strict::Bool=true`: numbers with a lower case exponent letter (d or e) are invalid cards,
  unless false
- `units::Union{Bool, Module}=true`: the units in the comment of a number are the units of the value (`true` is Unitful, or the module `DynamicQuantities` when it is loaded), unless
  false
- `record::Bool=false`: structure the data as a list of records
- `scale::Bool=true`: apply the scale and zero keywords to the data
"""
function Base.read(io::IO, ::Type{HDU}; type = nothing, strict::Bool = true, units::Union{Bool, Module} = true,
    checksum::Bool = false, kwds...)::HDU
    #  Read cards
    firstpos = checksum ? position(io) : 0
    cards, mankeys, reskeys = read(io, Card; strict, units)
    datapos = checksum ? position(io) : 0

	#  Read data
	type_  = type === nothing ? typeofhdu(mankeys) : type
	cards  = verify!(type_, cards, mankeys, reskeys)
	format = DataFormat(type_, missing, mankeys)
	cards  = verify!(type_, cards, format, mankeys)
	fields = FieldFormat(type_, format, reskeys, missing)
	if format.leng > 0
		#  The data begin at the position, and the next HDU begins after the blocks of the data
		pos = position(io)
		if io isa IOStream
			# create a lazy array for the HDU data field and move to next HDU
			name, mtime = io.name[7:end-1], stat(io).mtime
			data = LazyArray(name, mtime, pos, format, fields, (;kwds...))
		else
			data = read(io, type_, format, fields; kwds...)
		end
		N = sizeof(format.type)*format.leng
		verifyfill(io, type_, pos, N)
		seek(io, pos + BLOCKLEN*div(N, BLOCKLEN, RoundUp))
	else
		# indicate data is missing
		data = missing
	end
	checksum && verifychecksum(io, cards, firstpos, datapos, position(io))
	HDU{type_}(cards, data)
end

"""
    Base.write(io::IO, hdu::HDU; <keywords>)

Write a header-data unit (HDU) to `io`: the header cards, the END card, and blank cards that pad
the header to a multiple of 2880 bytes, followed by the data.

The data of an image array that was read with the BSCALE and BZERO applied, or was changed, is written as the stored
values, which are `(value - BZERO)/BSCALE` rounded to the type of BITPIX (Eq. 3 of the standard). A value that is not in
the range of the type, or NaN when the data do not have a BLANK, is an error. Data that is of the type of BITPIX is the
stored values, and is written as it is, except a [`FITSFiles.ScaledArray`](@ref) (and `ScaledRecords` of random groups), which is the
physical values of floating-point stored values that were read with a BSCALE and a BZERO (or PSCALn and PZEROn) that are not 1 and 0,
with that scale and zero, and the stored values, `(value - BZERO)/BSCALE`, are written. The BSCALE and BZERO of the header of an HDU that
is made from such data are those of the data.

# Keywords

- `check::Bool=true`: check that the stored value of each value of the data gives the value again when BSCALE and BZERO
  are applied to it, and raise an error if it does not, e.g., a value of 11.2 for integer data with a BSCALE of 2.5 and a
  BZERO of 10, whose nearest stored value is 0 and gives 10.0; if false, the nearest stored value is written
- `checksum::Bool=false`: set the DATASUM and CHECKSUM keywords to the checksums of the data and of the HDU
  (Sect. 4.4.2.7 of the standard), which replace the keywords of the header, if it has them
"""
function Base.write(io::IO, hdu::HDU{<:AbstractHDU}; checksum::Bool = false, kwds...)

	cards = getfield(hdu, :cards)
	mankeys, reskeys = getreservedkeys(cards)

	type   = typeofhdu(hdu)
	cards  = verify!(type, cards, mankeys, reskeys)
	format = DataFormat(type, missing, mankeys)
	cards  = verify!(type, cards, format, mankeys)
	fields = FieldFormat(type, format, reskeys, missing)
	if checksum
		#  The sums are of the bytes of the data, and then of the header, which has the sums
		data = IOBuffer()
		write(data, type, getfield(hdu, :data), format, fields; kwds...)
		bytes = take!(data)
		write(io, setchecksum!(copy(cards), bytes))
		write(io, bytes)
	else
		#  Write cards
		write(io, cards)
		#  Write data
		write(io, type, getfield(hdu, :data), format, fields; kwds...)
	end
end

function Base.read(io::IO, ::Type{Card}; strict::Bool = true, units::Union{Bool, Module} = true)
    #  Read cards
    cards = Card{<:Any}[]
    N, M = BLOCKLEN÷CARDLENGTH, CARDLENGTH

    lastblok = false
    nblocks = 0
    while !lastblok
        block = read(io, BLOCKLEN)
        nblocks += 1
        #  The last header block has the END keyword (Sect. 3.3.1), so the file ends before it if there are no more bytes
        isempty(block) && throw(ArgumentError("The header has no END keyword: the file ends after $(nblocks - 1) header " *
            "block$(nblocks == 2 ? "" : "s"), and the last header block must have it (Sect. 3.3.1)."))
        for j=1:min(N, length(block)÷M)
            card = parse(Card, String(block[M*(j-1)+1:M*j]),
                         isempty(cards) ? nothing : cards[end]; strict, units)
            if typename(card) == End
                lastblok = true
                #  The records after END are filled with ASCII spaces (Sect. 3.3.1)
                all(==(0x20), @view block[M*j+1:end]) || @warn "The header has bytes after the END keyword that are not " *
                    "ASCII spaces (Sect. 3.3.1). They are not read, and are written as spaces."
                break
            end
            push!(cards, card)
        end
        #  A block that ends before END is the end of the file
        lastblok || length(block) < BLOCKLEN && throw(ArgumentError("The header has no END keyword: the file ends after " *
            "$(length(block)) bytes of header block $nblocks, and the last header block must have it (Sect. 3.3.1)."))
        #  A header block has 2880 bytes, so the header is cut short if the file ends in the block that has END
        length(block) < BLOCKLEN && @warn "Header block $nblocks, which has the END keyword, has only $(length(block)) of the " *
            "$BLOCKLEN bytes of a block (Sect. 3.3.1), so the file ends in the header. The header is read as it is."
    end
    #  Create dictionaries of mandatory and reserved keywords, which include the END keyword.
    mankeys, reskeys = getreservedkeys(cards)
    mankeys["END"] = missing
    (cards, mankeys, reskeys)
end

function Base.write(io::IO, cards::Cards)
    #  Write header cards
    for card in cards
        Base.write(io, repr(card))
    end
    #  Append END card
    Base.write(io, repr(Card("END")))
    M, ncards = length(cards)+1, BLOCKLEN÷CARDLENGTH
    N = ncards*div(M, ncards, RoundUp)
    #  Pad header with blank cards
    for j = M+1:N
        Base.write(io, repr(Card()))
    end
end

####    Utility functions
"""
	leastfloat(real::Union{Real, Nothing})

Convert an integer to the smallest float type of Float32, Float64, and BigFloat that holds the
integer, i.e., a Float32 for a 32-bit integer, a Float64 for a 64-bit integer, and otherwise a
BigFloat. A value that is not an integer is returned as it is.
"""
function leastfloat(value::Union{Real, Nothing})
	if typeof(value) <: Integer
		if typemin(Int32) <= value <= typemax(Int32)
			return convert(Float32, value)
		elseif typemin(Int64) <= value <= typemax(Int64)
			return convert(Float64, value)
		else
			return convert(BigFloat, value)
		end
	end
	value
end























"""
	arrangecards!(cards, required)

Return the cards with the required cards first, in the order of `required`, and the remaining
cards of `cards` after them. `required` is a list of `key => value` pairs. A required card that
is in `cards` is moved to its place, with its comment and layout, and the others are made from
the values. The END card is removed, since it is implied and is written by `write`.
"""
function arrangecards!(cards::Cards, required)
	kards = Card{<:Any}[popat!(cards, key, Card(key, value)) for (key, value) in required]
	popat!(cards, "END")
	append!(kards, cards)
end

#  The keywords BITPIX and NAXIS, and NAXISn of the shape of the data. The axes begin at NAXIS`first`,
#  which is 2 for random groups, where NAXIS1 is 0.
function shapekeys(format::DataFormat; first::Integer = 1)
	required = Pair{String, Any}["BITPIX" => TYPE2BITS[format.type],
		"NAXIS" => length(format.shape) + first - 1]
	first == 2 && push!(required, "NAXIS1" => 0)
	for (j, n) in enumerate(format.shape) push!(required, "NAXIS$(j+first-1)" => n) end
	required
end

#  The keywords of a table extension from XTENSION to TFIELDS, where the shape is the length of a row
#  and the number of rows.
function tablekeys(xtension::AbstractString, format::DataFormat, nfields::Integer)
	M, N = length(format.shape) == 2 ? format.shape : (0, 0)
	Pair{String, Any}["XTENSION" => xtension, "BITPIX" => 8, "NAXIS" => 2, "NAXIS1" => M,
		"NAXIS2" => N, "PCOUNT" => 0, "GCOUNT" => 1, "TFIELDS" => nfields]
end


function getreservedkeys(cards::Cards)
	mankeys = Dict{AbstractString, ValueType}()
	reskeys = Dict{AbstractString, ValueType}()
	for (j, card) in enumerate(cards)
		if any(occursin.(MANDATORYKEYS, card.key))
			mankeys[card.key] = joinvalue(cards, j)
		end
		if any(occursin.(RESERVEDKEYS, card.key))
			reskeys[card.key] = joinvalue(cards, j)
		end
	end
	(mankeys, reskeys)
end

typeofhdu(::HDU{T}) where T = T

"""
	typeofhdu(data)
	typeofhdu(dict)
	typeofhdu(data, dict)

Determine the HDU type based on the data structure, the mandatory keywords, or
both.
"""
function typeofhdu(data::U) where
	U <: Union{AbstractArray, Tuple, NamedTuple, Missing}

	if !ismissing(data)
		#  An array of numbers with undefined (missing) values is an image
		if nonmissingtype(eltype(data)) <: Real
			type = Primary
		elseif eltype(data) <: AbstractString
			type = Table
		elseif typeof(data) <: Union{Tuple, NamedTuple}
			type = typeof(data[end]) <: AbstractArray &&
				   ndims(data[end]) >= 2 ? Random : Bintable
		elseif basetype(eltype(data)) in (Tuple, NamedTuple)
			type = typeof(data[1][end]) <: AbstractArray &&
				   ndims(data[1][end]) >= 2 ? Random : Bintable
		else
			type = Conform
		end
	else
		type = missing
	end
	type
end

function typeofhdu(mankeys::Dict{S, V}) where {S <: AbstractString, V <: ValueType}
	#  Determine HDU type from mandatory keys
	exval = get(mankeys, "XTENSION", missing)
	if !ismissing(exval)
		type = get(XTENSIONTYPE, exval isa AbstractString ? rstrip(exval) : exval, Conform)
		if type == Bintable
			if get(mankeys, "ZIMAGE", false)
				type = ZImage
			elseif get(mankeys, "ZTABLE", false)
				type = ZTable
			end
		end
	elseif haskey(mankeys, "SIMPLE")
		#  SIMPLE is T if the file conforms to the Standard, and F if it does not (Sect. 4.4.1.1). The primary
		#  HDU of a file that does not conform is a Conform HDU, if its other mandatory keywords conform, which
		#  its verify! method checks.
		simple = mankeys["SIMPLE"]
		simple isa Bool ||
			throw(ArgumentError("SIMPLE must be a logical, T or F, but its value is $(repr(simple))."))
		if !simple
			type = Conform
		elseif get(mankeys, "GROUPS", false) === true &&
		   haskey(mankeys, "NAXIS1") && mankeys["NAXIS1"] == 0
			type = Random
		else
			type = Primary
		end
	else
		error("Unknown HDU")
	end
	type
end

function typeofhdu(data::U, mankeys::Dict{S, V}) where
{U <: Union{AbstractArray, Tuple, NamedTuple, Missing},
	S <: AbstractString, V <: ValueType}

	type = Primary
	if !ismissing(data)
		type = typeofhdu(data)
	end
	if !isempty(mankeys)
		type = typeofhdu(mankeys)
	end
	type
end
#=
function compressed(type::Type{<:AbstractHDU}, mankeys::Dict{S, V}) where
	{S<:AbstractString, V<:ValueType}
	if type == Bintable
		if get(mankeys, "ZIMAGE", false)
			type = ZImage
		elseif get(mankeys, "ZTABLE", false)
			type = ZTable
		end
	end
	type
end
=#
basetype(T) = Base.typename(T).wrapper

parsestring(value) = value isa String ? parsenumber(value) : value

####    Array-like Functions

datatype(data::AbstractArray) = eltype(data)
datadims(data::AbstractArray) = ndims(data)
datasize(data::AbstractArray) = size(data)
databytes(data::AbstractArray) = eltype(data)*length(data)
datalength(data::AbstractArray) = length(data)

datadims(mankeys::Dict) = mankeys["NAXIS"]

function datasize(mankeys::Dict, start::Integer = 1)
	#  Determine the shape of the array
	N = get(mankeys, "NAXIS", 0)
	N > 0 ? Tuple(mankeys["NAXIS$j"] for j ∈ start:N) : ()
end

function datalength(mankeys::Dict, start::Integer = 1)
	#   Calculate the number of elements in the array
	N = get(mankeys, "NAXIS", 0)
	G, P = get(mankeys, "GCOUNT", 1), get(mankeys, "PCOUNT", 0)
	N > 0 ? G * (P + prod(datasize(mankeys, start))) : 0
end

datatype(cards::Cards) = BITS2TYPE[get(cards, "BITPIX", 32)]
datadims(cards::Cards) = get(cards, "NAXIS", 0)

function datasize(cards::Cards, start::Integer = 1)
	#  Determine the shape of the array
	N = datadims(cards)
	N > 0 ? Tuple(cards["NAXIS$j"] for j ∈ start:N) : ()
end

function databytes(cards::Cards, start::Integer = 1)
	#  Calculate the number of bytes of data
	N, G, P = cards["NAXIS"], get(cards, "GCOUNT", 1), get(cards, "PCOUNT", 0)
	N > 0 ? sizeof(datatype(cards)) * G * (P + prod(datasize(cards, start))) : 0
end

function datalength(cards::Cards, start::Integer = 1)
	#  Calculate the number of elements in the array
	N, G, P = cards["NAXIS"], get(cards, "GCOUNT", 1), get(cards, "PCOUNT", 0)
	N > 0 ? G * (P + prod(datasize(cards, start))) : 0
end

####    Generic IO Functions

#  The number of bytes that are left to read in `io`, or the largest integer if they are not known.
unreadbytes(io::IOBuffer) = bytesavailable(io)
unreadbytes(io::IOStream) = filesize(io) - position(io)
unreadbytes(io::IO) = typemax(Int)

"""
	readbytes(io, n)

Read the `n` bytes of the data of an HDU. An error says that the file is shorter than the header says if
it has fewer bytes, instead of the data failing to match the shape of the array.
"""
function readbytes(io::IO, n::Integer)
	short(m) = ArgumentError("The data of the HDU is $n bytes, as its header says, but the file has " *
		"only $m of them.")
	n > unreadbytes(io) && throw(short(unreadbytes(io)))
	bytes = read(io, n)
	length(bytes) < n && throw(short(length(bytes)))
	bytes
end



function padblock(io::IO, format::DataFormat, pad::UInt8 = 0x00)
	#  Pad remaining data block to BLOCKLEN length (2880 bytes)
	N = format.leng*sizeof(format.type)
	nbloks = div(N, BLOCKLEN, RoundUp)
	Base.write(io, fill(pad, nbloks*BLOCKLEN-N))
end

####    Reserved Keywords
#=
function parsegeneral(cards::Cards)
	date = get(cards, "DATE", missing)
	orign = get(cards, "ORIGIN", missing)
	xtend = get(cards, "EXTEND", missing)
	blokd = get(cards, "BLOCKED", missing)
end

function parseobservatory(cards::Cards)
	datobs = get(cards, "DATE-OBS", missing)
	# datxxx = get(cards, "DATExxxx", missing)
	telscp = get(cards, "TELESCOP", missing)
	instru = get(cards, "INSTRUME", missing)
	obsrvr = get(cards, "OBSERVER", missing)
	object = get(cards, "OBJECT", missing)
end

function parsebiblio(cards::Cards)
	author = get(cards, "AUTHOR", missing)
	refern = get(cards, "REFERENC", missing)
end

function parseextension(cards::Cards)
	xname  = get(cards, "EXTNAME", missing)
	xver   = get(cards, "EXTVER", missing)
	xlevel = get(cards, "EXTLEVEL", missing)
	nherit = get(cards, "INHERIT", missing)
end

function parsechecksums(card::Cards)
	datsum = get(cards, "DATASUM", missing)
	chksum = get(cards, "CHECKSUM", missing)
end

function parsewcs(cards::Cards)
end
=#

####    Dictionary key behaviour functions for Cards

function Base.haskey(cards::Cards, key::AbstractString)
	for card in cards
		if uppercase(card.key) == uppercase(key)
			return true
		end
	end
	false
end

"""
    joinvalue(cards, j)

Return the value of the card at index `j`. The value of a continued string is the value of the
card joined with the CONTINUE cards that follow it.
"""
joinvalue(cards::Cards, j::Integer) =
	basetype(typename(cards[j])) == Value && continued(cards[j]) ?
	joincards(@view cards[j:end]).value : cards[j].value

"""
    units(card)
    units(cards, key)

Return the units of a card, or of the first card of a list of cards with the keyword, which are
`nothing` if the value has no units. The units are not part of the value.
"""
units(card::Card) = card.units

function units(cards::Cards, key::AbstractString)
	for card in cards
		if uppercase(card.key) == uppercase(key)
			return card.units
		end
	end
	throw(KeyError(key))
end

function Base.getindex(cards::Cards, key::AbstractString)
	for (j, card) in enumerate(cards)
		if uppercase(card.key) == uppercase(key)
			return joinvalue(cards, j)
		end
	end
	throw(KeyError(key))
end

function Base.get(cards::Cards, key::AbstractString, default = nothing)
	value = default
	for (j, card) in enumerate(cards)
		if uppercase(card.key) == uppercase(key)
			value = joinvalue(cards, j)
			break
		end
	end
	value
end

"""
    get(cards, key, default)
    get(cards, keys, defaults)

Return the value of the first card with the keyword `key`, or `default` if there is no such card.
With a list of keys, return the tuple of the values of the first cards with the keywords, in the order
of the keys, where the default of a keyword that is not found is the default at the same position. The
types of the values are the types of the cards, and not the types of the defaults. The value of a
continued string is the joined string. See [`getall`](@ref) for the values of all the cards with a
keyword.
"""
function Base.get(cards::Cards, keys::Union{AbstractArray, Tuple},
	defaults::Union{AbstractArray, Tuple})

	length(keys) == length(defaults) ||
		throw(DimensionMismatch("The keys and the defaults have different lengths."))
	values = Any[defaults...]
	for (j, key) in enumerate(keys)
		k = Base.findfirst(key, cards)
		ismissing(k) || (values[j] = joinvalue(cards, k))
	end
	(values...,)
end

function Base.findfirst(key::AbstractString, cards::Cards)
	for (j, card) in enumerate(cards)
		if uppercase(card.key) == uppercase(key)
			return j
		end
	end
	missing
end

"""
    findall(key, cards)

Return the indexes of all the cards with the keyword `key`, in the order of the header. The indexes
are empty if there is no such card.
"""
function Base.findall(key::AbstractString, cards::Cards)
	upkey = uppercase(key)
	[j for (j, card) in enumerate(cards) if uppercase(card.key) == upkey]
end

"""
    getall(cards, key)
    getall(cards, keys)

Return the values of all the cards with the keyword `key`, in the order of the header, e.g., the
values of the `COMMENT` or `HISTORY` cards, which are the vector of the values, or an empty vector if
there is no such card. With a list of keys, return the tuple of the vectors of the keys. The value of
a continued string is the joined string, and the `CONTINUE` cards of the string are not values.
"""
getall(cards::Cards, key::AbstractString) = [joinvalue(cards, j) for j in Base.findall(key, cards)]
getall(cards::Cards, keys::Union{AbstractArray, Tuple}) = Tuple(getall(cards, key) for key in keys)

"""
    setvalue!(cards, key, value; <keywords>)

Replace the value of the first card with the keyword `key`. A string that does not fit on a card
is split into the cards of a long string, and the CONTINUE cards of a string that is replaced
are removed. The keywords, i.e., `fixed`, `append`, `slash`, `lpad`, `rpad`, `upad`, `truncate`,
and `splitat`, are those of `setvalue!(card, value)`, where the default of a layout keyword is the
layout of the card. The cards are always replaced, which is the way to split the value again.
"""
function setvalue!(cards::Cards, key::AbstractString, value::ValueInput; kwds...)

	j = Base.findfirst(key, cards)
	ismissing(j) && throw(KeyError(key))
	#  The cards of the old value are the card and the CONTINUE cards that continue its string.
	n = j
	while n < length(cards) && continued(cards[n]) && basetype(typename(cards[n+1])) == Continue
		n += 1
	end
	new = setvalue!(cards[j], value; kwds...)
	splice!(cards, j:n, new isa Card ? [new] : new)
	cards
end

#  Setting the value that the cards have leaves the cards as they are, including the pieces
#  of a long string.
function Base.setindex!(cards::Cards, value::ValueInput, key::AbstractString)
	j = Base.findfirst(key, cards)
	ismissing(j) && throw(KeyError(key))
	old = joinvalue(cards, j)
	same = old isa AbstractString && value isa AbstractString && trimvalue(old) == trimvalue(value)
	same || setvalue!(cards, key, value)
	return
end

function Base.popat!(cards::Cards, key::AbstractString, default=Card())
    card = try
        Base.popat!(cards, Base.findfirst(key, cards))
    catch
        default
    end
    card
end

####   Dictionary key behaviour functions for NameTuples

Base.haskey(data::NamedTuple, key::AbstractString) = haskey(data, Symbol(key))
Base.getindex(data::NamedTuple, key::AbstractString) = data[Symbol(key)]

function Base.get(data::NamedTuple, key::AbstractString, default = nothing)
	get(data, Symbol(key), nothing)
end

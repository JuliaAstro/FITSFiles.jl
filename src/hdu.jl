#=   Improvements

 * tighten function argument types

 =#

####    HDU type    ####

abstract type AbstractHDU end

#  Primary HDU
"""
	Primary header-data unit (HDU)

A Primary HDU consists of a vector of cards and optionally a multidimensional
array (<=999 dimensions). The Primary HDU is the first HDU in a vector of HDUs.
"""
struct Primary <: AbstractHDU end

"""
	Random header-data unit (HDU)

A Random HDU consists of a vector of cards and optionally a vector of records
containing a list of parameters followed by a multidimensional array. The
Random HDU is the first HDU in a vector of HDUs.
"""
struct Random <: AbstractHDU end

#  Standard HDU Extensions
"""
	Image header-data unit (HDU)

An Image HDU consists of a vector of cards and optionally a multidimensional array
(<=999 dimensions).
"""
struct Image <: AbstractHDU end
"""
	Table header-data unit (HDU)

A Table HDU consists of a vector of cards and optionally a 2-dimensional array
of ASCII data structured as vector of records.
"""
struct Table <: AbstractHDU end
"""
	Bintable header-data unit (HDU)

A Bintable HDU consists of a vector of cards and optionally a 2-dimensional
array of binary data structured as a vector of records.
"""
struct Bintable <: AbstractHDU end
struct ZImage <: AbstractHDU end
struct ZTable <: AbstractHDU end

#  Conforming HDU Extensions
struct Conform <: AbstractHDU end
struct IUEImage <: AbstractHDU end
struct A3DTable <: AbstractHDU end
struct Foreign <: AbstractHDU end
struct Dump <: AbstractHDU end

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
- `scale::Bool=true`: apply the scale and zero keywords to the data

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

const MISSTYPE = (UInt8, Int16, Int32, Int64)
#  The unsigned integers and the signed bytes are stored as the integers of the same size with an offset in
#  BZERO (Table 11 of the standard): the type of the array => the type of the physical values and BZERO.
const OFFSETTYPE = Dict(Int16 => (UInt16, 2^15), Int32 => (UInt32, 2^31), Int64 => (UInt64, UInt64(2)^63),
	UInt8 => (Int8, -2^7))
#  The type of the array of the physical type, which is the key of OFFSETTYPE
const RAWTYPE = Dict(physical => raw for (raw, (physical, _)) in OFFSETTYPE)
const OUTTYPE  = Dict(
    UInt8 => Float32, Int16 => Float32, Int32 => Float64, Int64 => Float64,
    Float32 => Float32, Float64 => Float64)

    #  Combine XTENSION values in card.jl and hdu.jl. The trailing spaces of a value are not
    #  significant, so the keys are not padded.
#  The XTENSION value is padded to 8 characters.
const XTENSIONLENGTH = 8
#  The maximum number of fields of a table (Sects. 7.2.1 and 7.3.1)
const MAXFIELDS = 999
const XTENSIONTYPE = Dict("IMAGE" => Image, "TABLE" => Table, "BINTABLE" => Bintable)

const MANDATORYKEYS = (
	#  Mandatory keys, except THEAP (see Table C.1)
	"END", "SIMPLE", "XTENSION", "BITPIX", "NAXIS", "GROUPS", "PCOUNT",
	"GCOUNT", "THEAP", "TFIELDS", "TFORM", "TBCOL", "ZIMAGE", "ZTABLE",
	"ZBITPIX", "ZNAXIS", "ZPCOUNT", "ZFORM", "ZCTYP", "ZCMPTYPE", "ZTILELEN")

const RESERVEDKEYS = (
	#  General keys
	"DATE", "DATE-OBS", "ORIGIN", "AUTHOR", "REFERENC",
	"OBJECT", "OBSERVER", "INHERIT", "CHECKSUM", "DATASUM", "EXTNAME",
	"EXTVER", "EXTLEVEL", "EQUINOX", "EPOCH", "BLOCKED", "EXTEND", "TELESCOP",
	"INSTRUME",
	#  Random field keys
	"PTYPE", "PSCAL", "PZERO",
	#  Image field keys
	"BSCALE", "BZERO", "BUNIT", "BLANK", "DATAMAX", "DATAMIN",
	#  World-coordinate and time keys that are integers
	"WCSAXES", "MJDREFI", "JDREFI",
	#  Table field keys
	"TFIELDS", "TFORM", "TBCOL", "TSCAL", "TZERO", "TNULL", "TTYPE", "TUNIT",
	"TDISP", "TDMAX", "TDMIN", "TLMAX", "TLMIN",
	#  Bintable field keys, except THEAP
	"TFIELDS", "TFORM", "TSCAL", "TSCAL", "TZERO", "TNULL", "TTYPE", "TUNIT",
	"TDISP", "TDIM", "TDMAX", "TDMIN", "TLMAX", "TLMIN",
	#  ZImage field keys
	"ZTILE", "ZNAME", "ZVAL", "ZMASKCMP", "ZQUANTIZ", "ZDITHER0", "ZSIMPLE",
	"ZEXTEND", "ZBLOCKED", "ZTENSION", "ZPCOUNT", "ZGCOUNT", "ZBLANK", "ZHECKSUM",
	"ZDATASUM",
	#  ZTable field keys
	"FZTILELN", "FZALGOR", "FZALG", "ZTHEAP", "ZHECKSUM", "ZDATASUM")

#  Check for header missing END card

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
	kards  = verify!(type, kards, format, mankeys)
	fields = FieldFormat(type, format, reskeys, data)
	kards  = createcards!(type, format, fields, kards; kwds...)
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
	kards  = verify!(type, kards, format, mankeys)
	fields = FieldFormat(type, format, reskeys, data; kwds...)
	kards  = createcards!(type, format, fields, kards; kwds...)
	if typeof(data) <: Tuple
		data = (; [Symbol(fields[j].name) => data[j] for j ∈ 1:format.param]...,
			data = data[end])
	end

	HDU{type}(kards, data)
end

"""
	info(hdu::HDU)

Briefly describe the header-data unit.
"""
function info(hdu::HDU, n::Integer = 0)
	cards = getfield(hdu, :cards)
	N = cards["NAXIS"]
	typ = rpad(typeofhdu(hdu), INFOTYPELEN)
	nam = rpad(haskey(cards, "EXTNAME") ? cards["EXTNAME"] : "", INFONAMELEN)
	ver = lpad(haskey(cards, "EXTVERS") ? cards["EXTVER"] : "1", INFOVERSLEN)
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
	nam = rpad(haskey(cards, "EXTNAME") ? cards["EXTNAME"] : "", INFONAMELEN)
	ver = lpad(haskey(cards, "EXTVERS") ? cards["EXTVER"] : "1", INFOVERSLEN)
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
is read from another stream is read at once.

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
stored values, and is written as it is.

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
    block = read(io, BLOCKLEN)
    while !lastblok
        for j=1:N
            card = parse(Card, String(block[M*(j-1)+1:M*j]),
                         isempty(cards) ? nothing : cards[end]; strict, units)
            if typename(card) == End
                lastblok = true
                break
            end
            push!(cards, card)
        end
        if lastblok
            break
        end
        block = read(io, BLOCKLEN)
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
    verify!(type, cards, mankeys, reskeys)

Verify the values of the mandatory and reserved keywords of a header, `mankeys` and `reskeys`, before
the data format is created from them. Return the cards. A verify! method of an HDU type corrects the cards and the
mandatory keywords, `mankeys`, when it is possible, and otherwise raises an error that names
the keyword and its value. The generic method raises an error if the value of a keyword that
must be an integer is not (see [`verifyinteger`](@ref)), and warns if the XTENSION value is
not padded.

The verify! methods that also have a data format argument are for the HDU types that create
the format from data and then correct the header to match the data.
"""
function verify!(::Type{<:AbstractHDU}, cards::Cards, mankeys::AbstractDict, reskeys::AbstractDict)
	#  The integer keywords that are common to all HDUs: BITPIX, NAXIS, NAXISn, PCOUNT, and GCOUNT (Sects. 4.4.1.1,
	#  4.4.1.2, and 6.1.1) are mandatory, and EXTVER and EXTLEVEL (Sect. 4.4.2.6), WCSAXES, with an optional alternate
	#  version letter (Sect. 8.2), and MJDREFI and JDREFI (Sect. 9.2.2) are reserved. The integer keywords of one
	#  type of HDU, e.g., TFIELDS or BLANK, are verified by the verify! method of that type.
	verifyinteger(mankeys, r"^(BITPIX|NAXIS\d*|PCOUNT|GCOUNT)$")
	verifyinteger(reskeys, r"^(EXTVER|EXTLEVEL|WCSAXES[A-Z]?|MJDREFI|JDREFI)$")
	#  The descriptive keywords of Sects. 4.4.2.1 to 4.4.2.3 are character strings, and the dates are dates.
	verifystring(reskeys, r"^(ORIGIN|TELESCOP|INSTRUME|OBSERVER|OBJECT|AUTHOR|REFERENC|EXTNAME|CHECKSUM|DATASUM)$")
	verifydate(reskeys, r"^DATE")
	verifyxtension!(cards)
end

"""
	verifyinteger(keys, pattern)

Raise an `ArgumentError` that names the keyword and its value if the value of a keyword of the dictionary
`keys` that matches the regular expression `pattern` is not an integer, e.g., NAXIS1 = 2.0 or PCOUNT = 'two'.
`keys` is the dictionary of the mandatory keywords, `mankeys`, or of the reserved keywords, `reskeys`, of a
header (see `MANDATORYKEYS` and `RESERVEDKEYS`), and a verify! method calls `verifyinteger` once for each. A
floating-point value, even of a whole number, is not an integer, and the size of the data cannot be determined
from it, so the HDU cannot be read. The values of other keywords are not checked.
"""
function verifyinteger(keys::AbstractDict, pattern::Regex)
	for (key, value) in keys
		occursin(pattern, key) || continue
		value isa Integer && !(value isa Bool) && continue
		throw(ArgumentError("$key must be an integer, but its value is $(repr(value))."))
	end
	nothing
end

"""
	verifynumber(keys, pattern)

Raise an `ArgumentError` that names the keyword and its value if the value of a keyword of the dictionary
`keys` that matches `pattern` is not a real number, e.g., BSCALE = 'two'. A value of an integer type is a
number, since a keyword of a floating-point number can be written without a decimal point. The array cannot
be scaled by a value that is not a number, so the HDU cannot be read.
"""
function verifynumber(keys::AbstractDict, pattern::Regex)
	for (key, value) in keys
		occursin(pattern, key) || continue
		value isa Real && !(value isa Bool) && continue
		throw(ArgumentError("$key must be a number, but its value is $(repr(value))."))
	end
	nothing
end

"""
	verifyfloat(keys, pattern)

Warn if the value of a keyword of the dictionary `keys` that matches `pattern` is an integer, when the
standard requires a floating-point number, e.g., DATAMIN = 0. A value that is not a number is not checked
(see [`verifynumber`](@ref)). The value is read as it is.
"""
function verifyfloat(keys::AbstractDict, pattern::Regex)
	for (key, value) in keys
		occursin(pattern, key) && value isa Integer && !(value isa Bool) &&
			@warn "$key must be a floating-point number, but its value is the integer $value. It is read as it is."
	end
	nothing
end

"""
	verifystring(keys, pattern)

Warn if the value of a keyword of the dictionary `keys` that matches `pattern` is not a character string.
The value is read and written as it is.
"""
function verifystring(keys::AbstractDict, pattern::Regex)
	for (key, value) in keys
		occursin(pattern, key) && !(value isa AbstractString) &&
			@warn "$key must be a character string, but its value is $(repr(value)). It is read as it is."
	end
	nothing
end

"""
	verifylogical(keys, pattern)

Warn if the value of a keyword of the dictionary `keys` that matches `pattern` is not a logical, T or F.
The value is read and written as it is.
"""
function verifylogical(keys::AbstractDict, pattern::Regex)
	for (key, value) in keys
		occursin(pattern, key) && !(value isa Bool) &&
			@warn "$key must be a logical, T or F, but its value is $(repr(value)). It is read as it is."
	end
	nothing
end

#  Is `text` a date of the form YYYY-MM-DD, YYYY-MM-DDThh:mm:ss[.sss...], or, before 2000, DD/MM/YY (Sect. 4.4.2.1)?
function isdatestring(text::AbstractString)
	m = match(r"^(\d{4})-(\d{2})-(\d{2})(?:T(\d{2}):(\d{2}):(\d{2})(?:\.\d+)?)?$", text)
	if !isnothing(m)
		year, month, day = parse.(Int, m.captures[1:3])
		time = isnothing(m[4]) ? (0, 0, 0) : parse.(Int, m.captures[4:6])
		return isdate(year, month, day) && time[1] < 24 && time[2] < 60 && time[3] < 61
	end
	m = match(r"^(\d{2})/(\d{2})/(\d{2})$", text)
	isnothing(m) ? false : isdate(1900 + parse(Int, m[3]), parse(Int, m[2]), parse(Int, m[1]))
end

function isdate(year::Integer, month::Integer, day::Integer)
	leap = year % 4 == 0 && (year % 100 != 0 || year % 400 == 0)
	ndays = (31, leap ? 29 : 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31)
	1 <= month <= 12 && 1 <= day <= ndays[month]
end

"""
	verifydate(keys, pattern)

Warn if the value of a keyword of the dictionary `keys` that matches `pattern` is not a date of the form
`YYYY-MM-DD` or `YYYY-MM-DDThh:mm:ss[.sss...]`, or `DD/MM/YY` for a date before 2000 (Sect. 4.4.2.1 of the
standard). The value is read and written as it is.
"""
function verifydate(keys::AbstractDict, pattern::Regex)
	for (key, value) in keys
		occursin(pattern, key) || continue
		value isa AbstractString && isdatestring(strip(value)) && continue
		@warn "$key must be a date of the form YYYY-MM-DD[Thh:mm:ss[.sss]] (Sect. 4.4.2.1), but its value is " *
			"$(repr(value)). It is read as it is."
	end
	nothing
end

"""
	verifyunit(keys, pattern)

Warn if the value of a keyword of the dictionary `keys` that matches `pattern` is a character string that is
not a units string (Sect. 4.3 of the standard). An empty string is not checked. The value is read and written
as it is.
"""
function verifyunit(keys::AbstractDict, pattern::Regex)
	for (key, value) in keys
		occursin(pattern, key) && value isa AbstractString && !isempty(strip(value)) &&
			isnothing(parseunit(Unitful, value)) &&
			@warn "$key must be a units string (Sect. 4.3), but its value is $(repr(value)). It is read as it is."
	end
	nothing
end

"""
	verifyvalue(keys, key, allowed, requirement)

Raise an `ArgumentError` that names the keyword and its value if the keyword `key` is in the dictionary
`keys`, of the mandatory keywords, and its value is not in `allowed`, e.g., a range or a tuple of values.
`requirement` describes the allowed values for the message, e.g., "the integer 0". A keyword that is not in
`keys` is not verified, since the header of an HDU that is created without cards has no keywords. The
value is an integer, which `verifyinteger` verifies first.
"""
function verifyvalue(keys::AbstractDict, key::AbstractString, allowed, requirement::AbstractString)
	haskey(keys, key) && !(keys[key] in allowed) &&
		throw(ArgumentError("$key must be $requirement, but its value is $(repr(keys[key]))."))
	nothing
end

#  The requirement of the value of BITPIX of the data types of an array (Table 8)
verifybitpix(mankeys::AbstractDict) = verifyvalue(mankeys, "BITPIX", BITPIXVALUES,
	"one of $(join(BITPIXVALUES[1:end-1], ", ")), or $(BITPIXVALUES[end])")

#  The structure of a table extension, ASCII or binary, which is an array of bytes with NAXIS = 2 axes, the
#  length of a row and the number of rows (Sects. 7.2.1 and 7.3.1)
function verifyrows(mankeys::AbstractDict)
	verifyvalue(mankeys, "BITPIX", 8:8, "the integer 8")
	verifyvalue(mankeys, "NAXIS", 2:2, "the integer 2")
	verifyaxes(mankeys)
end

"""
	verifyaxes(mankeys; first = 1)

Verify the NAXISn keywords of an HDU, from the index `first` to NAXIS, in the dictionary `mankeys` of the
mandatory keywords. It is an error, since the size of the data cannot be determined, if NAXISn is missing for
an n from `first` to NAXIS, or if it is negative. It is a warning, since the extra keywords are not used, if
NAXISn is present for an n greater than NAXIS. A header with no NAXIS is not verified. `first` is 2 for random
groups, where NAXIS1 is 0 (Sects. 4.4.1.1, 6.1.1, 7.1.1, 7.2.1, and 7.3.1).
"""
function verifyaxes(mankeys::AbstractDict; first::Integer = 1)
	N = get(mankeys, "NAXIS", nothing)
	isnothing(N) && return nothing
	for j = first:N
		haskey(mankeys, "NAXIS$j") || throw(ArgumentError("NAXIS$j is missing, but NAXIS is $N."))
		verifyvalue(mankeys, "NAXIS$j", 0:typemax(Int), "non-negative")
	end
	for key in sort!(collect(keys(mankeys)))
		m = match(r"^NAXIS(\d+)$", key)
		!isnothing(m) && Base.parse(Int, m[1]) > max(N, 0) && @warn "$key is beyond NAXIS $N, and is not used."
	end
	nothing
end

"""
	verifyfields!(cards, mankeys; columns = false)

Verify the keywords that describe the fields of a table extension, and return the cards unchanged
(Sects. 7.2.1 and 7.3.1 of the standard). It is an error, since the fields cannot be read, if TFIELDS
is negative, if TFORMn is missing for an n from 1 to TFIELDS, or, for an ASCII table (`columns = true`),
if TBCOLn is missing or less than 1, since the first column of a row is numbered 1. It is a warning,
since the extra keywords are not used, if TFIELDS is more than 999, the maximum, or if TFORMn or TBCOLn
is present for an n greater than TFIELDS. A header with no TFIELDS is not verified.
"""
function verifyfields!(cards::Cards, mankeys::AbstractDict; columns::Bool = false)
	N = get(mankeys, "TFIELDS", nothing)
	isnothing(N) && return cards
	N < 0 && throw(ArgumentError("TFIELDS must be non-negative, but its value is $N."))
	N > MAXFIELDS && @warn "TFIELDS $N is more than the maximum of $MAXFIELDS."
	for j = 1:N
		haskey(mankeys, "TFORM$j") || throw(ArgumentError("TFORM$j is missing, but TFIELDS is $N."))
		if columns
			haskey(mankeys, "TBCOL$j") || throw(ArgumentError("TBCOL$j is missing, but TFIELDS is $N."))
			mankeys["TBCOL$j"] >= 1 || throw(ArgumentError(
				"TBCOL$j must be at least 1, the first column of a row, but its value is $(mankeys["TBCOL$j"])."))
		end
	end
	for key in sort!(collect(keys(mankeys)))
		m = match(r"^(TFORM|TBCOL)(\d+)$", key)
		!isnothing(m) && Base.parse(Int, m[2]) > N && (columns || m[1] == "TFORM") &&
			@warn "$key is beyond TFIELDS $N, and is not used."
	end
	cards
end

"""
	verifyheap!(cards, mankeys)

Warn if THEAP of a binary table is outside of the range that the standard allows (Sect. 7.3.2), and
return the cards unchanged. The heap starts THEAP bytes after the start of the main data table, so THEAP
cannot be less than NAXIS1*NAXIS2 or more than that plus PCOUNT, the bytes of the gap and the heap.
"""
function verifyheap!(cards::Cards, mankeys::AbstractDict)
	haskey(mankeys, "THEAP") || return cards
	heap = mankeys["THEAP"]
	table = get(mankeys, "NAXIS1", 0) * get(mankeys, "NAXIS2", 0)
	if heap < table
		@warn "THEAP $heap is less than NAXIS1*NAXIS2, $table, and the heap overlaps the table."
	elseif heap > table + get(mankeys, "PCOUNT", 0)
		@warn "THEAP $heap is more than NAXIS1*NAXIS2 + PCOUNT, $(table + get(mankeys, "PCOUNT", 0)), and the heap is past the data."
	end
	cards
end

"""
	verifyxtension!(cards)

Warn if the value of the XTENSION card is not padded to 8 characters, as the standard requires,
and return the cards unchanged. A file may have the value written without the padding, e.g.,
`'TABLE'`, which is read without error, since the trailing spaces of a string are not significant,
and the file is written as it was read, so the card is not changed. The width of the value is the
width of the string on the card, and not the value.
"""
function verifyxtension!(cards::Cards)
	j = Base.findfirst("XTENSION", cards)
	ismissing(j) && return cards
	card = cards[j]
	value, format = card.value, card.format
	if value isa AbstractString && rstrip(uppercase(value)) in XTENSION_VALUES && format.vbeg > 0 &&
		format.vend - format.vbeg - 1 < XTENSIONLENGTH
		@warn "The XTENSION value '$value' is not padded to $XTENSIONLENGTH characters."
	end
	cards
end

"""
	verifyprimary(cards, mankeys)

Warn if the header of a primary HDU does not begin with SIMPLE, BITPIX, NAXIS, and the NAXISn keywords, in
that order and with no other keyword between them (Sect. 4.4.1.1 of the standard), or if the values of
these keywords are not in fixed format (Sect. 4.4.1), and return the cards unchanged. The file is read and
written as it is, so the cards are not reordered or reformatted. The NAXIS value of `mankeys` must be
valid, as `verifyarray` checks.
"""
function verifyprimary(cards::Cards, mankeys::AbstractDict)
	#  A header that is being created does not have the keywords yet, and is arranged when it is created.
	haskey(mankeys, "SIMPLE") || return cards
	required = vcat(["SIMPLE", "BITPIX", "NAXIS"], ["NAXIS$j" for j = 1:get(mankeys, "NAXIS", 0)])
	verifyorder(cards, required)
	verifyfixed(cards, required)
end

"""
	verifyorder(cards, required)

Warn at the first of the first cards that is not the keyword in the same place of `required`, and return the
cards unchanged (see [`verifyprimary`](@ref)). The keywords `section` and `names` are the section of the standard and
the names of the keywords that the warning gives.
"""
function verifyorder(cards::Cards, required::AbstractVector{<:AbstractString};
	section::AbstractString = "Sect. 4.4.1.1", names::AbstractString = "SIMPLE, BITPIX, NAXIS, and the NAXISn")

	for (j, key) in enumerate(required)
		found = j <= length(cards) ? uppercase(cards[j].key) : "END"
		if found != key
			found = isempty(found) ? "a blank card" : found
			@warn "Keyword $j of the header is $found, but the Standard requires $key ($section): " *
				"$names come first, in order, with no other keyword between them. The cards are not reordered."
			break
		end
	end
	cards
end

"""
	verifyfixed(cards, required)

Warn if the value of a card of the keywords `required` is not in fixed format, and return the cards unchanged
(see [`verifyprimary`](@ref)).
"""
function verifyfixed(cards::Cards, required::AbstractVector{<:AbstractString})
	free = unique([uppercase(card.key) for card in cards if uppercase(card.key) in required && !card.format.fixd])
	isempty(free) || @warn "The value of $(join(free, ", ")) is not in fixed format (Sect. 4.4.1): " *
		"a fixed-format value is right-justified in bytes 11 to 30, and a string begins in byte 11. " *
		"The cards are not changed."
	cards
end

"""
	verifyshape!(cards, mankeys, format; first = 1)

Correct BITPIX and the NAXIS keywords of `cards` to match the data format `format`, and return
the cards. `first` is the index of the first NAXISn keyword that describes the data, which is 2
for random groups, where NAXIS1 is 0.
"""
function verifyshape!(cards::Cards, mankeys::AbstractDict, format::DataFormat; first::Integer = 1)
	if haskey(mankeys, "BITPIX") && format.type != BITS2TYPE[mankeys["BITPIX"]]
		setindex!(cards, TYPE2BITS[format.type], "BITPIX")
		@warn "BITPIX set to $(TYPE2BITS[format.type])."
	end
	if haskey(mankeys, "NAXIS1") && format.shape != datasize(cards, first)
		N = length(format.shape) + first - 1
		setindex!(cards, N, "NAXIS")
		first == 2 && setindex!(cards, 0, "NAXIS1")
		for j = first:N setindex!(cards, format.shape[j-first+1], "NAXIS$j") end
		@warn "NAXIS$(first:N) set to $(format.shape)"
	end
	cards
end

"""
	verifycounts!(cards, mankeys, format)

Correct PCOUNT and GCOUNT of `cards` to match the data format `format`, and return the cards.
"""
function verifycounts!(cards::Cards, mankeys::AbstractDict, format::DataFormat)
	for (key, value) in (("PCOUNT", format.param), ("GCOUNT", format.group))
		if haskey(mankeys, key) && value != mankeys[key]
			setindex!(cards, value, key)
			@warn "$key set to $value"
		end
	end
	cards
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

"""
    scaled(data, scale, zero)

Return `zero + scale*data`. The type of the result is the promotion of the types of `data`,
`scale` and `zero` (a Float32 for 32-bit integer data and a Float32 `scale`, say), but the
operands are converted to at least a Float64 before the multiplication and the addition, which
`muladd` fuses into a single rounding where the hardware allows it. A Float32 product would
otherwise round the stored integers to 24 bits (e.g., a `UInt32` stored as `Int32` with `TZERO`
2147483648 and a Float32 `TSCAL` of 1).
"""
function scaled(data, scale, zero)
	T = promote_type(typeof(scale), typeof(zero), nonmissingtype(eltype(data)))
	W = promote_type(T, Float64)
	#  An undefined value stays undefined
	f(x) = ismissing(x) ? missing : T(muladd(W(scale), W(x), W(zero)))
	f.(data)
end

"""
    setmissing(data, miss)

Return `data` with `missing` in place of the raw values equal to `miss`, the value of the BLANK or
TNULLn keyword (Sects. 4.4.2.5 and 7.3.2 of the standard). The comparison is made before any scaling.
The result has the element type `Union{T, Missing}`, whether or not a value is equal to `miss`, and
`data` itself is returned when `miss` is `nothing`.
"""
setmissing(data, ::Nothing) = data
setmissing(value::Real, miss::Integer) = value == miss ? missing : value
function setmissing(data::AbstractArray{T}, miss::Integer) where T
	out = Array{Union{T, Missing}}(data)
	out[data .== miss] .= missing
	out
end

"""
    unsetmissing(data, miss, type)

Return `data` with `miss` in place of `missing`, as raw values of `type`: the inverse of
[`setmissing`](@ref). Data of a floating-point `type` has no BLANK or TNULLn keyword, and the undefined
value is `NaN` (Sect. 4.4.2.5). It is an `ArgumentError` if `data` has a `missing` value but no `miss`
is given for an integer `type`.
"""
unsetmissing(data, miss, type::Type) = data
function unsetmissing(data::AbstractArray{Union{T, Missing}}, miss, type::Type) where T
	any(ismissing, data) || return type.(data)
	type.(coalesce.(data, undefinedvalue(type, miss)))
end
function unsetmissing(value::Missing, miss, type::Type)
	undefinedvalue(type, miss)
end

function undefinedvalue(type::Type{<:AbstractFloat}, miss)
	type(NaN)
end
function undefinedvalue(type::Type, miss)
	isnothing(miss) && throw(ArgumentError(
		"missing values cannot be written without a BLANK or TNULLn keyword"))
	type(miss)
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
		elseif get(mankeys, "GROUPS", false) == true &&
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

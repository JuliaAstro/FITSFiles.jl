####    Verify functions that are common to the HDUs

#  The verify functions of one type of HDU are in the file of that type of HDU in src/hdu

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
	#  The level of an extension is 1 for the highest level, and the levels of the extensions below it have higher values
	#  (Sect. 4.4.2.6)
	level = get(reskeys, "EXTLEVEL", 1)
	level isa Integer && level < 1 && @problem "EXTLEVEL must be 1 or more, with 1 the highest level (Sect. 4.4.2.6), " *
		"but its value is $level. It is read as it is."
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
			@problem "$key must be a floating-point number, but its value is the integer $value. It is read as it is."
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
			@problem "$key must be a character string, but its value is $(repr(value)). It is read as it is."
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
			@problem "$key must be a logical, T or F, but its value is $(repr(value)). It is read as it is."
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
		@problem "$key must be a date of the form YYYY-MM-DD[Thh:mm:ss[.sss]] (Sect. 4.4.2.1), but its value is " *
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
			@problem "$key must be a units string (Sect. 4.3), but its value is $(repr(value)). It is read as it is."
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

"""
	verifyaxes(mankeys)

Verify the NAXISn keywords of an HDU, from NAXIS1 to NAXIS, in the dictionary `mankeys` of the
mandatory keywords. It is an error, since the size of the data cannot be determined, if NAXISn is missing for
an n from 1 to NAXIS, or if it is negative. It is a warning, since the extra keywords are not used, if
NAXISn is present for an n greater than NAXIS. A header with no NAXIS is not verified. Random groups, whose
NAXIS1 is 0, have their own method (Sects. 4.4.1.1, 7.1.1, 7.2.1, and 7.3.1).
"""
function verifyaxes(mankeys::AbstractDict)
	N = get(mankeys, "NAXIS", nothing)
	isnothing(N) && return nothing
	for j = 1:N
		haskey(mankeys, "NAXIS$j") || throw(ArgumentError("NAXIS$j is missing, but NAXIS is $N."))
		verifyvalue(mankeys, "NAXIS$j", 0:typemax(Int), "non-negative")
	end
	for key in sort!(collect(keys(mankeys)))
		m = match(r"^NAXIS(\d+)$", key)
		!isnothing(m) && Base.parse(Int, m[1]) > max(N, 0) && @problem "$key is beyond NAXIS $N, and is not used."
	end
	nothing
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
		@problem "The XTENSION value '$value' is not padded to $XTENSIONLENGTH characters."
	end
	cards
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
			@problem "Keyword $j of the header is $found, but the Standard requires $key ($section): " *
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
	isempty(free) || @problem "The value of $(join(free, ", ")) is not in fixed format (Sect. 4.4.1): " *
		"a fixed-format value is right-justified in bytes 11 to 30, and a string begins in byte 11. " *
		"The cards are not changed."
	cards
end

"""
	verifyshape!(cards, mankeys, format)

Correct BITPIX and the NAXIS keywords of `cards` to match the data format `format`, and return
the cards. The data are described by NAXIS1 and the keywords after it. A keyword that the cards do not have, e.g.,
NAXIS when they have NAXIS1, is added. Random groups, whose NAXIS1 is 0, have their own method.
"""
function verifyshape!(cards::Cards, mankeys::AbstractDict, format::DataFormat)
	if haskey(mankeys, "BITPIX") && format.type != BITS2TYPE[mankeys["BITPIX"]]
		setindex!(cards, TYPE2BITS[format.type], "BITPIX")
		@warn "BITPIX set to $(TYPE2BITS[format.type])."
	end
	N = length(format.shape)
	if haskey(mankeys, "NAXIS1") && (get(mankeys, "NAXIS", nothing) != N ||
		any(j -> get(mankeys, "NAXIS$j", nothing) != format.shape[j], 1:N))

		putcard!(cards, "NAXIS", N)
		for j = 1:N putcard!(cards, "NAXIS$j", format.shape[j]) end
		@warn "NAXIS$(1:N) set to $(format.shape)"
	end
	cards
end

#  Set the card of the keyword to the value, and add the card if the cards do not have the keyword
putcard!(cards::Cards, key::AbstractString, value) = haskey(cards, key) ? setindex!(cards, value, key) : push!(cards, Card(key, value))

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

#  Verify the keywords of the cards that are given with the data of an HDU that is made, so that a value that cannot be used is
#  the error of a read, and not a MethodError. The mandatory keywords of the first card, SIMPLE and XTENSION, are not verified,
#  since the header is arranged when it is made (see `createcards!`). Only the HDUs of an array, which verify their keywords
#  when they are read, are verified.
verifycards!(::Type, cards::Cards, mankeys::AbstractDict, reskeys::AbstractDict, format::DataFormat) = cards
#  The verification of the keywords of the cards of an HDU of the type `type` that is made, which a type that verifies them defines (see
#  the files of Primary, Image, and Random), with the keywords of the first card that are made from the data left out.
function verifycardkeys(type::Type, cards::Cards, mankeys::AbstractDict, reskeys::AbstractDict)
	keys = filter(pair -> first(pair) ∉ ("SIMPLE", "XTENSION"), mankeys)
	verify!(type, cards, keys, reskeys)
end

#  The byte that fills the last data block after the data, and what it is called, and the section of the standard: zeros, except
#  for the ASCII spaces of an ASCII table
fillrule(::Type{<:AbstractHDU}) = (0x00, "zeros", "Sect. 3.3.2")

"""
	verifyfill(io, type, pos, nbytes)

Warn if the fill of the last data block after the `nbytes` bytes of the data of an HDU of the type `type`, which begin at
the position `pos` of `io`, is not what the standard says: all bits zero, or ASCII spaces for an ASCII table (Sects. 3.3.2,
6.2, 7.2.3, and 7.3.3). The data are read as they are, but the fill is not kept, and is written as it should be. A last
block that is not filled, which is a file that ends after the data, is not verified. The position of `io` is not kept.
"""
function verifyfill(io::IO, type::Type{<:AbstractHDU}, pos::Integer, nbytes::Integer)
	nfill = BLOCKLEN*cld(nbytes, BLOCKLEN) - nbytes
	nfill == 0 && return nothing
	byte, name, section = fillrule(type)
	seek(io, pos + nbytes)
	all(==(byte), read(io, nfill)) || @warn "The fill of the last data block of the HDU is not all $name ($section). The data are " *
		"read as they are, and the fill is written as $name."
	nothing
end

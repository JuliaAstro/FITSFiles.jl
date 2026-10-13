#=   Improvements

 * add HIERARCH keyword conventions
 * make 32-bit floats the default instead of 64-bit floats
 * add parsing of non-stardard formats
 * add splitting of long strings at spaces

 =#

####    Card type    ####

const CARDLENGTH::Int = 80
# const BLANKCARD::String = repeat(" ", CARDLENGTH)
const KEYLENGTH::Int = 8
# const BLANKKEY::String = repeat(" ", KEYLENGTH)
const TOKENLEN::Int = 10
const FIXEDINDEX::Int = 20  # from end of value token
const HIERINDEX::Int = 0

const EQUAL_TOKEN::String = "= "
# const HIERARCH_EQUAL_TOKEN::String = "="

const KEYWD_CHARS = "[A-Z0-9_-]"
const ASCII_CHARS = "[ -~]"
const VALUE_TOKEN = "[ A-Z0-9_-]{8}= "
const VALUE_KEY = KEYWD_CHARS*"*?"
const COMMENT_KEY = "COMMENT |HISTORY |HIERARCH| {8}"
const CONTINUE_KEY = "CONTINUE"

const VALUE_CARD = "(?!"*COMMENT_KEY*")(?="*VALUE_TOKEN*")(?<key>"*VALUE_KEY*") *= "
const CONTINUE_CARD = "(?<key>"*CONTINUE_KEY*")"*ASCII_CHARS*"{2}"
const COMMENT_CARD = "(?<key>"*COMMENT_KEY*")"*ASCII_CHARS*"{2}"

const END_IMAGE = "END"*repeat(' ', 77)

#  regex for a FITS standard compliant (FSC) keyword.
const KEY_FSC = Regex("^[A-Z0-9_-]{0," * string(KEYLENGTH) * "}\$")
const NON_KEY_TEXT = Regex("[^A-Z0-9_-]")
#  regex for any printable ASCII character excluding '='.
# const KEY_HIERARCH = Regex("^(?:HIERARCH +)?(?:^[ -<>-~]+ ?)+\$", "i")

#  regex for FSC real number substring.
const DIGITS_FSC_STR = "(\\.\\d+|\\d+(\\.\\d*)?)([DE][+-]?\\d+)?"
const DIGITS_FSC_STR_2 = "(?:\\.\\d+|\\d+(?:\\.\\d*)?)(?:[DE][+-]?\\d+)?"
const NUMBER_FSC_STR = "[+-]?" * DIGITS_FSC_STR
#  regex for non-FSC (NFSC) real number substring.
#  (NFSC allows lower case of DE for exponent, space between sign,
#  digits, exponent sign, and exponents.)
const DIGITS_NFSC_STR = "(\\.\\d+|\\d+(\\.\\d*)?) *([deDE] *[+-]? *\\d+)?"
const NUMBER_NFSC_STR = "[+-]?" * DIGITS_NFSC_STR

#  regex helps delete leading zeros from numbers to avoid evaluating
#  them as octol values.
# const NUMBER_FSC  = Regex("(?P<sign>[+-])?0*?(?P<digt>" * DIGITS_FSC_STR * ")")
const NUMBER_FSC_STR_2 = "[+-]?" * DIGITS_FSC_STR_2
const NUMBER_NFSC      = Regex("(?P<sign>[+-])? *0*?(?P<digt>" * DIGITS_NFSC_STR * ")")
const NUMBER_FORMAT    = "(?<i>\\d+)?(?:(?<p>\\.)(?<f>\\d+)?)?(?:(?<x>[DE])(?<n>[+-]?\\d+))?"

#  use in cards having the CONTINUE convention which expects a string
#  followed by an optional comment.
const STRING_FIELD_STR = "\\'(?P<strg>([ -~]+?|\\'\\'|) *?)\\'(?=\$|/| )"
const STRING_FIELD_STR_2 = "(?:[ -~]|''|)"
const COMMENT_FIELD_STR = "(?P<comm_field>(?P<sepr>/ *)(?P<comm>(.|\\n)*))"
const STRING_COMMENT = Regex("(" * STRING_FIELD_STR * ")? *" * COMMENT_FIELD_STR * "?")

#  FSC commentary card string which must contain printable ASCII
#  characters.
const ASCII_TEXT = Regex("[ -~]*\\Z")
const NON_ASCII_TEXT = Regex("[^ -~]")

#  check for a valid value & comment string. The value group returns a
#  match for a FITS string, boolean, number, and complex value,
#  otherwise it returns 'missing'. The comment field returns a match
#  when the comment separator is found, though the comment may be an
#  empty string.
#
#  The <strg> regex is not correct for all cases, but it comes pretty
#  darn close.  It appears to find the end of a string rather well,
#  but will accept strings with an odd number of single quotes,
#  instead of issuing an error.  The FITS standard appears vague on
#  this issue and only states that a string should not end with two
#  single quotes, whereas it should not end with an even number of
#  quotes to be precise.
#
#  Note that a non-greedy match is done for a string, since a greedy
#  match will find a single-quote after the comment separator
#  resulting in an incorrect match.
#=
const VALUE_FSC  = Regex(
	"(?P<valu_field> *" *
	"(?P<valu>" * STRING_FIELD_STR * "|(?P<bool>[FT])|" *
	"(?P<numr>" * NUMBER_FSC_STR * ")|(?P<cplx>\\( *" *
	"(?P<real>" * NUMBER_FSC_STR * ") *, *(?P<imag>" * NUMBER_FSC_STR * ") *\\)))? *)" *
	"(?P<comm_field>(?P<sepr>/ *)(?P<comm>[!-~][ -~]*)?)?\$")
=#
const VALUE_FSC_2 = Regex(
	"^ *" *
	"(?:" *
	"(?<strg>'(?:[ -&(-~]|''|)*?(?<ampr>&)? *')(?=\$|/| )|" *
	"(?<bool>[FT])|" *
	"(?<numr>" * NUMBER_FSC_STR_2 * ")|" *
	"(?<cplx>\\( *(?<real>" * NUMBER_FSC_STR_2 * ") *, *(?<imag>" * NUMBER_FSC_STR_2 * ") *\\))|" *
	"(?<miss> *)" *
	") *" *
	"(?<slash>/)? *" *
	"(?<units>\\[[ -~]+\\])? *" *
	"(?<comment>[!-~][ -~]*?)?(?= *\$) *\$")

const HIERARCH_FSC = Regex(
	"^ *" *
	"(?<key>[A-Z0-9 _-]*?)" *
	" *(?<equal>=) *" *
	"(?:" *
	"(?<strg>'(?:[ -~]|''|)*?')(?=\$|/| )|" *
	"(?<bool>[FT])|" *
	"(?<numr>" * NUMBER_FSC_STR_2 * ")|" *
	"(?<cplx>\\( *(?<real>" * NUMBER_FSC_STR_2 * ") *, *(?<imag>" * NUMBER_FSC_STR_2 * ") *\\))|" *
	"(?<miss> *)" *
	") *" *
	"(?<slash>/)? *" * "(?<comment>[!-~][ -~]*?)?(?= *\$) *\$")

const VALUE_NFSC = Regex(
	"(?P<valu_field> *" *
	"(?P<valu>" * STRING_FIELD_STR * "|(?P<bool>[FT])|" *
	"(?P<numr>" * NUMBER_NFSC_STR * ")|(?P<cplx>\\( *" *
	"(?P<real>" * NUMBER_NFSC_STR * ") *, *(?P<imag>" * NUMBER_NFSC_STR * ") *\\)))? *)" *
	COMMENT_FIELD_STR * "?\$")

### const RECORD_KEY_IDENTIFIER_STR = "[a-zA-Z_]\\w*"
### const RECORD_KEY_FIELD_STR = RECORD_KEY_IDENTIFIER_STR * "(\\.\\d+)?"
### const RECORD_KEY_FIELD_SPECIFIER_STR = RECORD_KEY_FIELD_STR * "(\\." * RECORD_KEY_FIELD_STR * ")*"
### const RECORD_KEY_FIELD_SPECIFIER_VALUE_STR =
###     "(?P<keyword>" * RECORD_KEY_FIELD_SPECIFIER_STR * "): +(?P<val>" * NUMBER_FSC_STR * ")"
### const RECORD_KEY_VALUE_STR = "\\'(?P<rawval>" * RECORD_KEY_FIELD_SPECIFIER_VALUE_STR * ")\\'"
### const RECORD_KEY_VALUE_COMMENT_STR = " *" * RECORD_KEY_VALUE_STR * " *(/ *(?P<comm>[ -~]*))?\$"

### const RECORD_KEY_FIELD_SPECIFIER_VALUE = Regex(RECORD_KEY_FIELD_SPECIFIER_VALUE_STR * "\$")

#  regular expression to extract the key and the field specifier from
#  a string that is being used to index into a card list that contains
#  record value keyword cards (e.g., "DPI.AXIS.1")
### const RECORD_KEY_NAME = Regex(
###    "(?P<keyword>" * RECORD_KEY_IDENTIFIER_STR * ")\\.(?P<specifier>" * RECORD_KEY_FIELD_SPECIFIER_STR * ")\$")

### const COMMENT_KEYS = ["", "COMMENT", "HISTORY", "END"]
### const SPECIAL_KEYS = vcat(COMMENT_KEYS, ["CONTINUE"])
#  values must be right padded to 8 characters
const XTENSION_VALUES = ("BINTABLE", "IMAGE", "TABLE")

#  the default value indicator may be changed if required by
#  convention (namely HIERARCH cards).
### equal_token = EQUAL_TOKEN

# struct Date
# end

ValueType = Union{AbstractString, Missing, Number, Quantity}

abstract type AbstractCardType end
abstract type CommentCardType <: AbstractCardType end

struct Continue <: AbstractCardType end
struct End <: AbstractCardType end
struct Invalid <: AbstractCardType end
struct Value{T} <: AbstractCardType where T <: ValueType end

struct Comment <: CommentCardType end
struct Hierarch{T} <: CommentCardType where T <: ValueType end
struct History <: CommentCardType end

const COMMENTKEY = Dict(""=>Comment, "COMMENT"=>Comment, "HIERARCH"=>Hierarch, "HISTORY"=>History)

"""
	CardFormat(fixd, vbeg, vend, ampr, slsh, ubeg, uend, cbeg, cend)

Create a card format descriptor.
"""
mutable struct CardFormat
	#  The CardFormat descriptor provides a compact method to format a card by
	#  storing the begin and end index of the value, separator, units, and
	#  comment as an 8-bit integer.
	fixd::Bool
	vbeg::Union{Int8, Tuple{Int8, Int8}}
	vend::Union{Int8, Tuple{Int8, Int8}}
	ampr::Int8
	slsh::Int8
	ubeg::Int8
	uend::Int8
	cbeg::Int8
	cend::Int8
	# frmt::AbstractString
	function CardFormat(fixed::Bool = true, vbeg::I = 0, vend::I = 0,
		amper::I = 0, slash::I = 0, ubeg::I = 0, uend::I = 0, cbeg::I = 0,
		cend::I = 0) where I<:Integer

		begv = typeof(vbeg) <: Tuple ? Int8.(vbeg) : Int8(vbeg)
		endv = typeof(vend) <: Tuple ? Int8.(vend) : Int8(vend)
		new(Bool(fixed), begv, endv, Int8(amper), Int8(slash),
			Int8(ubeg), Int8(uend), Int8(cbeg), Int8(cend))
	end
end

"""
	Card(type, key, value, comment, format)
	Card([key, [value, [comment]]]; <keywords>)
	Card("HIERARCH", key, [key, [value, [comment]]]; <keywords>)

Create a card type, where type is Comment, End, Hierarch, History, Invalid, or
Value{T}.

# Argments

- `key::AbstractString=""`: keyword string
- `value::U=missing`: keyword value, where U is Bool, Number, or String
- `comment::AbstractString=""`: comment string

# Keywords

- `append::Bool=false`: append CONTINUE cards for long strings (>68 characters)
- `fixed::Bool=true`: use fixed format
- `slash::Integer=32`: index of comment separator (/)
- `lpad::Integer=1`: number of spaces before comment separator
- `rpad::Integer=1`: number of spaces after comment separator
- `upad::Integer=1`: number of spaces after the units string
- `truncate::Bool=true`: truncate comment at end of card
"""
struct Card{T <: AbstractCardType}  # make value a parameter
	key::AbstractString
	value::ValueType
	comment::AbstractString
	format::CardFormat
	function Card(T, key, value, comment, format)
		new{T}(key, value, comment, format)
	end
end

function Card(key::S = "", value::V = missing, comment::S = ""; fixed::B = true,
	append::B = false, slash::I = 32, lpad::I = 1, rpad::I = 1, upad::I = 1,
	truncate::B = true) where
	{B <: Bool, I <: Integer, S <: AbstractString, V <: ValueType}

	#  Convert key to uppercase and remove trailing spaces.
	upkey = uppercase(strip(key))

	### if slash <= TOKENLEN+FIXEDINDEX
	###     error("Comment separator postion must be >$")
	### end

	#  Check for invalid characters in key, value string, and comment.
	if !is_hierarch(upkey) && occursin(NON_KEY_TEXT, upkey)
		error("Keyword contains invalid characters.")
	elseif !ismissing(value) && typeof(value) <: AbstractString && occursin(NON_ASCII_TEXT, value)
		error("Value string contains invalid characters.")
	elseif !ismissing(comment) && occursin(NON_ASCII_TEXT, comment)
		error("Comment contains invalid characters.")
	end
	#  Format card image from key, value, and comment arguments and construct Card.
	#  Card is a parametric type containing Comment, Continue, End, Hierarch, History,
	#  and Value types. Card images can be in fixed- or free-formats.
	#
	#  The Value type is parametric type of Missing, Number, and String types.
	#
	cards  = nothing
	format = CardFormat(fixed, 0, 0)
	if is_end_key(upkey)
		#  Verify END card
		type = End
		if !ismissing(value) || !isempty(comment)
			throw(ArgumentError("END keyword has no value or comment."))
		end
	elseif is_continue_key(upkey) && is_string(value)
		#  Create CONTINUE card
		type = Continue
		format = formatcard(type, value, comment; append, fixed,
			slash, lpad, rpad, upad)
	elseif is_comment_key(upkey)
		#  Create COMMENT card
		if typeof(value) <: Union{AbstractString, Missing}
			type = COMMENTKEY[upkey]
			format = CardFormat(fixed, (!ismissing(value) ?
										(1, length(value)) : (0, 0))...)
		else
			throw(ArgumentError("value is not a string."))
		end
	elseif is_valid_key(upkey) && !(typeof(value) <: AbstractString)
		#  Create Value card
		type = Value{typeof(value)}
		format = formatcard(type, value, comment; fixed, append,
			slash, lpad, rpad, upad, truncate)
	elseif is_valid_key(upkey) && is_long_string(String(value), comment, slash, lpad,
		rpad, truncate)
		#  Create a list of cards from from a long string.
		type = Value{typeof(value)}
		cards = split_card(upkey, value, comment,
			(; fixed, slash, lpad, rpad, upad, append))
		cards = [Card(t, k, v, c, f) for (t, k, v, c, f) in cards]
	elseif is_valid_key(upkey)
		#  Create Value card that is not a long string.
		type = Value{typeof(value)}
		value = format_xtension_value(upkey, value)
		format = formatcard(type, value, comment; fixed, append,
			slash, lpad, rpad, upad, truncate)
	else
		error("Invalid card")
	end

	typeof(cards) <: AbstractArray ? cards :
	Card(type, upkey, value, comment, format)
end

function Card(key::S, tokens::S, value::V, comment::S;
	fixed::B = true, slash::I = 32, lpad::I = 1, rpad::I = 1, upad::I = 1) where
{B <: Bool, I <: Integer, S <: AbstractString, V <: ValueType}

	#  Convert key to uppercase and remove trailing SPECIAL_KEYS
	upkey, uptoken = uppercase(strip(key)), uppercase(strip(tokens))

	### if slash <= TOKENLEN+FIXEDINDEX
	###     error("Comment separator postion must be >$FIXEDINDEX")
	### end

	#  Check for invalid characters in key, value string, and comment.
	if !is_hierarch(upkey) && occursin(NON_KEY_TEXT, upkey)
		error("Keyword contains invalid characters.")
	elseif !ismissing(value) && typeof(value) <: AbstractString && occursin(NON_ASCII_TEXT, value)
		error("Value string contains invalid characters.")
	elseif !ismissing(comment) && occursin(NON_ASCII_TEXT, comment)
		error("Comment contains invalid characters.")
	end

	#  Format card image from key, value, and comment arguments and construct Card.
	#  The Hierarch type is parametric type of Missing, Number, and String types.
	#
	format = CardFormat(fixed, 0, 0)

	if is_hierarch(upkey) && is_valid_key(upkey)
		type = Hierarch{typeof(value)}
		format = formatcard(type, uptoken, value, comment; fixed, slash, lpad, rpad, upad)
	else
		error("Invalid card")
	end
	Card(type, uptoken, value, comment, format)
end

#  modify card value
function setvalue!(card::Card, value::ValueType)
	type, f = typename(card), card.format
	if f.ubeg > 0
		lpad, rpad, upad = f.slsh-f.vend-1, f.ubeg-f.slsh-1, f.cbeg-f.uend-1
	else
		lpad, rpad, upad = f.slsh-f.vend-1, f.cbeg-f.slsh-1, 0
	end
	Card(type, card.key, value, card.comment,
		formatcard(type, value, card.comment;
			fixed = f.fixd, slash = f.slsh, lpad, rpad, upad))
end

#  check key type
is_end_key(key::AbstractString)      = key == "END"
is_continue_key(key::AbstractString) = key == "CONTINUE"
is_comment_key(key::AbstractString)  = haskey(COMMENTKEY, key)
### is_hierarch_key(key::AbstractString) = key == "HIERARCH"
is_valid_key(key::AbstractString) = length(key) <= KEYLENGTH && occursin(KEY_FSC, key)

function is_string(value::ValueType)
	typeof(value) <: AbstractString ? true : error("Value is not a string.")
end

function is_fixed_key(key::AbstractString)
	key in ("BITPIX", "END", "NAXIS", "SIMPLE") || !isnothing(match(r"NAXIS\d{1,3}", key))
end

function is_long_string(value::AbstractString, comment::AbstractString,
	slash::I, lpad::I, rpad::I, truncate::Bool) where I <: Integer
	#  Test for long value and comment strings. Return true if found, except in the case where
	#  the comment can be truncated, i.e., truncate == true.
	length(replace(value, "'" => "''")) > value_length(slash, lpad) ||
		(!truncate && length(comment) > comment_length(slash, rpad))
end

function is_hierarch(key::AbstractString)
	key[1:min(length(key), 8)] == "HIERARCH" ||
		(length(key) > KEYLENGTH && occursin(ASCII_TEXT, key))
end

typename(::Card{T}) where T = T

function verify(card::Card, value::ValueType)
	if card.value != value
		f = card.format
		vbeg = f.vend-(typeof(value) <: Bool ? 1 : length(string(value)))+1
		fmt = CardFormat(f.fixd, vbeg, f.vend, f.ampr, f.slsh, f.cbeg, f.cend)
		card = Card(typename(card), card.key, value, card.comment, fmt)
	end
	card
end

"""
	split_card(key, value, comment, format)

Split card having long value and comment fields into multiple cards

If length of comment field is 0 because comment separator index is too large,
then comment is deleted.  Decreasing comment separator index will allow
inclusion of comment.
"""
function split_card(key::K, value::S, comment::C, kwds) where
{K <: AbstractString, S <: AbstractString, C <: AbstractString}

	slash, lpad, rpad = kwds[:slash], kwds[:lpad], kwds[:rpad]
	vallen, comlen = value_length(slash, lpad) - 1, comment_length(slash, rpad)
	#  Calculate number of cards, adjusting for ampersand and single quotes.
	nquot = length(replace(value, "'" => "''")) - length(value)
	ncard = max(div(length(value) + nquot, vallen, RoundUp),
		comlen == 0 ? 1 : div(length(comment), comlen, RoundUp))
	#  Create arrays of card types, keywords, values, comments, and formatting keywords
	#  for each card. Ensure ampersand is appended to each value string, except last.
	types    = (Value{String}, fill(Continue, ncard-1)...)
	keys     = (key, fill("CONTINUE", ncard-1)...)
	values   = Tuple(value[j1:j2] for (j1, j2) in slices(value, vallen, ncard, true))
	comments = Tuple(comment[j1:j2] for (j1, j2) in slices(comment, comlen, ncard))
	formats  = (Tuple(formatcard(t, v, c; merge(kwds, (; append = true))...) for (t, v, c) in
		zip(types[1:(ncard-1)], values[1:(ncard-1)], comments[1:(ncard-1)]))...,
		formatcard(types[ncard], values[ncard], comments[ncard]; kwds...))

	zip(types, keys, values, comments, formats)
end

"""
	join_cards(cards)

Join CONTINUE cards to initial long string card to create a long value and comment card
"""
function join_cards(cards::AbstractArray{Card})
	value = join((c.value for c in cards))
	comment = join((c.comment for c in cards))
	cards[1].format.ampr = 0
	Card(typename(cards[1]), cards[1].key, value, comment, cards[1].format)
end

####  Format Card  ####

function formatcard(::Type{Value{S}}, value::S, comment::C; kwds...) where
{S <: AbstractString, C <: AbstractString}
	#   Create CardFormat for string type
	format = CardFormat(kwds[:fixed])
	vlen = length(value)
	#   Account for single quotes and ending ampersand in string length
	singl, amper = count("'", value), kwds[:append] ? 1 : 0
	vend = vlen+singl+amper+2
	format.vbeg, format.vend = Int8(1), Int8(vend)
	#   Specify ampersand position
	if kwds[:append]
		format.ampr = Int8(max(2, vend-1))
	end
	#   Format comment, if necessary
	formatcomment!(comment, vend, format; kwds...)
end

function formatcard(::Type{Value{V}}, value::V, comment::C; kwds...) where
{V <: ValueType, C <: AbstractString}

	#  An undefined value has no units: `unit(missing)` is `missing`, not `NoUnits`.
	units = ismissing(value) || unit(value) === NoUnits ? missing : string(unit(value))
	#  Create appropriate CardFormat type
	format = CardFormat(kwds[:fixed])
	fmt = string(ustrip(value))
	vlen = typeof(value) <: Bool ? 1 : length(fmt)
	vend = max(FIXEDINDEX, vlen)
	format.vbeg, format.vend = Int8(max(1, FIXEDINDEX-vlen+1)), Int8(vend)
	# format.frmt = fmt
	#   Format comment, if necessary
	formatcomment!(comment, vend, format; units, kwds...)
end

function formatcard(::Type{Value{V}}, value::V, comment::C; kwds...) where
{V <: Complex, C <: AbstractString}

	units = unit(value) === NoUnits ? missing : string(unit(value))
	#  Create appropriate CardFormat type
	format = CardFormat(false)
	rlen, ilen = length(string(real(value))), length(string(imag(value)))
	vend = 1+rlen+2+ilen
	format.vbeg, format.vend = Int8.((2, 2+rlen+2)), Int8.((1+rlen+2, vend))
	# format.frmt = fmt
	#   Format comment, if necessary
	formatcomment!(comment, vend, format; units, kwds...)
end

function formatcard(::Type{Continue}, value::S, comment::C; kwds...) where
{S <: AbstractString, C <: AbstractString}

	#  Format CONTINUE record
	#  data: fixed, amper, slash, lpad, rpad, truncate
	formatcard(Value{AbstractString}, value, comment; kwds...)
end

function formatcard(::Type{Hierarch{V}}, token::S, value::V, comment::C; kwds...) where
{S <: AbstractString, V <: ValueType, C <: AbstractString}
	format = CardFormat(kwds[:fixed])
	fmt = string(value)
	vlen = length(token) + 3 + (typeof(value) <: Bool ? 1 : length(fmt))
	#  Use ampersand for '=' index
	ampr = length(token) + 2
	vend = HIERINDEX+vlen
	format.vbeg, format.vend, format.ampr = Int8(0), Int8(vend), Int8(ampr)
	# format.frmt = fmt
	#  Format comment, if necessary
	formatcomment!(comment, vend, format; kwds...)
end

function formatcomment!(comment::S, vend::I, format::F; units = missing,
	kwds...) where {S <: AbstractString, I <: Integer, F <: CardFormat}

	#  Left padding has priority over the slash index.
	padl, padr, padu = kwds[:lpad], kwds[:rpad], kwds[:upad]
	slash = (kwds[:slash]-TOKENLEN) <= vend+padl+1 ? vend+padl+1 : kwds[:slash]-TOKENLEN
	#  Prepend units to comment
	if !ismissing(units)
		ubeg, uend = slash+padr+1, slash+padr+2+length(units)
		format.slsh = Int8(slash)
		format.ubeg, format.uend = Int8(ubeg), Int8(uend)
	end
	#  Add comment
	if !isempty(comment)
		cndx = format.uend > 0 ? format.uend+padu : slash+padr
		cbeg, cend = cndx+1, cndx+length(comment)
		format.slsh = Int8(slash)
		format.cbeg, format.cend = Int8(cbeg), Int8(cend)
	end
	format
end

function value_length(slash::I, lpad::I)::Integer where I <: Integer
	#  Calculate length of value based comment separator index and padding.
	#  First 2 is for value indicator. Second 2 is single quotes.
	((slash-lpad) > CARDLENGTH ? CARDLENGTH : slash-lpad-1) - (TOKENLEN+2)
end

function comment_length(slash::I, rpad::I)::Integer where I <: Integer
	#  Calculate length of comment using the comment separator index and padding.
	(slash+rpad) >= CARDLENGTH ? 0 : CARDLENGTH - (slash+rpad)
end

rpad_key(key::AbstractString, n::Integer = 0) = rpad(key, KEYLENGTH + n)

function slices(value::S, slen::I, ncard::I, single::B = false) where
{S <: AbstractString, I <: Integer, B <: Bool}
	vals = Array{Tuple{Integer, Integer}}(undef, ncard)
	j1, j2, vlen = 1, slen, length(value)
	for j ∈ 1:ncard
		val = value[j1:min(j2, vlen)]
		#  Adjust length of string for single quotes
		j2 = min(j2 - (single ? count("'", val) : 0), vlen)
		vals[j] = (j1, min(j2, vlen))
		j1, j2 = min(j2 + 1, vlen + 1), j2 + slen
	end
	vals
end

#  Format special XTENSION values, pad to 8 characters
function format_xtension_value(key::AbstractString, value::AbstractString)
	(key == "XTENSION" && any(contains(s, uppercase(value)) for s in XTENSION_VALUES)) ?
	rpad(uppercase(value), 8) : value
end

#  Format String value for card
function stringvalue(value::S, format::F) where {S <: AbstractString, F <: CardFormat}
	#  Replace strings with single quotes with two single quotes.
	#  Append ampersand to value field, if necessary
	vlen, ampr = length(value), format.ampr
	"'" * rpad(rpad(replace(value, "'" => "''"), ampr-2)*(ampr > 0 ? "&" : ""), vlen-2) * "'"
end

####  Format Card Image  ####

function Base.show(io::IO, cards::Vector{Card{<:Any}})
	print(io, join(Tuple(repr(card) for card in cards), "\n"))
end

function Base.show(io::IO, card::Card)
	print(io, format_card(basetype(typename(card)), card.key, card.value,
		card.comment, card.format))
end

#  Format End card using only keyword.
function format_card(::Type{End}, key::K, value::V, comment::C,
	format::F) where {K <: AbstractString, V <: ValueType, C <: AbstractString,
	F <: CardFormat}

	rpad_image(key)
end

#  Format Comment card using only keyword and value.
function format_card(::Type{Comment}, key::K, value::V, comment::C,
	format::F) where {K <: AbstractString, V <: Union{Missing, AbstractString},
	C <: AbstractString, F <: CardFormat}

	rpad_image(rpad_key(key) * (ismissing(value) ? "" : value))
end

#  Ensure Comment card value is only a string.
function format_card(::Type{Comment}, key::K, value::N, comment::C,
	format::F) where {K <: AbstractString, N <: Number, C <: AbstractString,
	F <: CardFormat}

	error("Value is not a string.")
end

#  Format Continue card value by adding ampersand to end of string.
function format_card(::Type{Continue}, key::K, value::V, comment::C,
	format::F) where {K <: AbstractString, V <: AbstractString, C <: AbstractString,
	F <: CardFormat}

	rpad_image(key, stringvalue(value, format), "", comment, format)
end

function format_card(::Type{Continue}, key::K, value::V, comment::C,
	format::F) where {K <: AbstractString, V <: Union{Missing, Number},
	C <: AbstractString, F <: CardFormat}

	error("Continue contains non-string value.")
end

#  Add HIERARCH key, then format value and comment fields
function format_card(::Type{Hierarch}, key::K, value::V, comment::C,
	format::F) where {K <: AbstractString, V <: ValueType, C <: AbstractString,
	F <: CardFormat}

	valu = rpad(key, format.ampr-1) * "=" * lpad(string(value), format.vend-format.ampr)
	padl = repeat(" ", max(0, (format.slsh-1) - format.vend))
	slash = format.slsh > 0 ? "/" : " "
	padr = repeat(" ", max(0, (format.cbeg-1) - format.slsh))
	rpad_image("HIERARCH " * valu * padl * slash * padr * comment)
end

#  Format History card using only keyword and value.
function format_card(::Type{History}, key::K, value::V, comment::C,
	format::F) where {K <: AbstractString, V <: Union{AbstractString, Missing},
	C <: AbstractString, F <: CardFormat}

	rpad_image(rpad_key(key) * (ismissing(value) ? "" : value))
end

#  Ensure History card value is only a string.
function format_card(::Type{History}, key::K, value::N, comment::C,
	format::F) where {K <: AbstractString, N <: Number, C <: AbstractString,
	F <: CardFormat}

	error("Value is not a string.")
end

#  Format Invalid card
function format_card(::Type{Invalid}, key::K, value::V, comment::C,
	format::F) where {K <: AbstractString, V <: AbstractString, C <: AbstractString,
	F <: CardFormat}

	rpad_key(key)*value
end

#  Format Value card for missing value.
function format_card(::Type{Value}, key::K, value::M, comment::C,
	format::F) where {K <: AbstractString, M <: Missing, C <: AbstractString,
	F <: CardFormat}

	rpad_image(key, "", "", comment, format)
end

#  Format Value card for string value.
function format_card(::Type{Value}, key::K, value::V, comment::C,
	format::F) where {K <: AbstractString, V <: AbstractString, C <: AbstractString,
	F <: CardFormat}

	#  Fixed format strings begin at index 11
	rpad_image(key, stringvalue(value, format), "", comment, format)
end

#  Format Value card for boolean value.
function format_card(::Type{Value}, key::K, value::V, comment::C,
	format::F) where {K <: AbstractString, V <: Bool, C <: AbstractString,
	F <: CardFormat}

	#  Fixed format boolean value is at index 30
	padlen = FIXEDINDEX - 1
	#  If fixed format, pad value string
	value = (format.fixd ? repeat(" ", padlen) : "") * (value == true ? "T" : "F")
	rpad_image(key, value, "", comment, format)
end

#  Format Value card for integer value.
function format_card(::Type{Value}, key::K, value::I, comment::C,
	format::F) where {K <: AbstractString,
	I <: Union{Integer, Quantity{<:Integer, <:Any, <:Any}},
	C <: AbstractString, F <: CardFormat}

	value, units = ustrip(value), string(unit(value))
	#  Fixed format integer value ends at index 30
	padlen = max(0, FIXEDINDEX - (format.vend-format.vbeg+1))
	#  If fixed format, pad value string.
	strval = (format.fixd ? repeat(" ", padlen) : "") * string(value)
	rpad_image(key, strval, units, comment, format)
end

#  Format Value card for 32-bit float value.
function format_card(::Type{Value}, key::K, value::V, comment::C,
	format::F) where {K <: AbstractString,
	V <: Union{Float32, Quantity{Float32, <:Any, <:Any}},
	C <: AbstractString, F <: CardFormat}

	#  Fixed format float value ends at index 30
	#  Replace (lowercase) 'e' and 'f' with (uppercase) 'E'
	value, units = ustrip(value), string(unit(value))
	value = replace(string(value), "f" => "E", "e" => "E")
	padlen = max(0, FIXEDINDEX - length(value))
	#  If fixed format, pad value string.
	value = (format.fixd ? repeat(" ", padlen) : "") * value
	rpad_image(key, value, units, comment, format)
end

#  Format Value card for non-32-bit float values.
function format_card(::Type{Value}, key::K, value::V, comment::C,
	format::F) where {K <: AbstractString,
	V <: Union{AbstractFloat, Quantity{<:AbstractFloat, <:Any, <:Any}},
	C <: AbstractString, F <: CardFormat}

	#  Fixed format float value ends at index 30
	#  Replace (lowercase) 'e' with (uppercase) 'D'.
	value, units = ustrip(value), string(unit(value))
	value = replace(string(value), "e" => "D")
	#  Truncate mantissa, so value contains 20 characters.
	if format.fixd && length(value) > FIXEDINDEX
		n = findfirst("D", value)[1]
		value = value[1:(n-2)] * value[n:end]
	end
	padlen = max(0, FIXEDINDEX - length(value))
	#  If fixed format, pad value string.
	value = (format.fixd ? repeat(" ", padlen) : "") * value
	rpad_image(key, value, units, comment, format)
end

#  Format Value card for complex integer value.
function format_card(::Type{Value}, key::K, value::V, comment::C,
	format::F) where {K <: AbstractString,
	V <: Union{Complex{<:Integer}, Quantity{<:Complex{<:Integer}, <:Any, <:Any}},
	C <: AbstractString, F <: CardFormat}

	#   Fixed format complex values do not exist.
	#   ???  Can there be spaces between the paratheses?
	value, units = ustrip(value), string(unit(value))
	value = "($(string(real(value))), $(string(imag(value))))"
	rpad_image(key, value, units, comment, format)
end

#  Format Value card for complex 32-bit float value.
function format_card(::Type{Value}, key::K, value::V, comment::C,
	format::F) where {K <: AbstractString,
	V <: Union{Complex{Float32}, Quantity{Complex{Float32}, <:Any, <:Any}},
	C <: AbstractString, F <: CardFormat}

	#  Fixed format complex values do not exist.
	#  Replace (lowercase) 'e' and 'f' with (uppercase) 'E'.
	value, units = ustrip(value), string(unit(value))
	real_ = replace(string(real(value)), "f" => "E", "e" => "E")
	imag_ = replace(string(imag(value)), "f" => "E", "e" => "E")
	#  Add paretheses.
	value = "($real_, $imag_)"
	rpad_image(key, value, units, comment, format)
end

#  Format Value card for all other complex float values.
function format_card(::Type{Value}, key::K, value::V, comment::C,
	format::F) where {K <: AbstractString,
	V <: Union{Complex{<:AbstractFloat},
		Quantity{<:Complex{<:AbstractFloat}, <:Any, <:Any}},
	C <: AbstractString, F <: CardFormat}

	#  Fixed format complex values do no exist.
	#  Replace (lowercase) 'e' with (uppercase) 'D'.
	value, units = ustrip(value), string(unit(value))
	real_ = replace(string(real(value)), "e" => "D")
	imag_ = replace(string(imag(value)), "e" => "D")
	#  Add paretheses
	value = "($real_, $imag_)"
	rpad_image(key, value, units, comment, format)
end

#  Format card for key, value, and comment arguments
function rpad_image(key::K, value::V, units::U, comment::C, format::F) where
{K <: AbstractString, V <: AbstractString, U <: AbstractString,
	C <: AbstractString, F <: CardFormat}

	#  Ensure value and comment are properly padded.
	equal = key == "CONTINUE" ? "  " : EQUAL_TOKEN
	if typeof(format.vend) <: Tuple
		valu = rpad(value, max(0, (format.vend[2]+1 > CARDLENGTH ?
		CARDLENGTH : format.vend[2]) - 2))
		padl = repeat(" ", max(0, (format.slsh-1) - (format.vend[2]+1)))
	else
		valu = rpad(value, max(0, (format.vend > CARDLENGTH ?
		CARDLENGTH : format.vend)))
		padl = repeat(" ", max(0, (format.slsh-1) - format.vend))
	end
	slash = format.slsh > 0 ? "/" : " "
	if format.ubeg > 0
		padr = repeat(" ", max(0, format.ubeg-1 - format.slsh))
		unts = "[$units]"
		padu = repeat(" ", max(0, format.cbeg-1 - format.uend))
	else
		padr = repeat(" ", max(0, format.cbeg-1 - format.slsh))
		unts, padu = "", ""
	end
	rpad_image(rpad_key(key) * equal * valu * padl * slash * padr *
			   unts * padu * comment)
end

#  Format card to 80 characters by either padding or truncating length.
function rpad_image(card::AbstractString)
	length(card) < CARDLENGTH ? rpad(card, CARDLENGTH) : card[1:CARDLENGTH]
end

#  Format Date value

###  Parse functions

#  orphaned CONTINUE cards become COMMENT cards.

"""
    Base.parse(::Type{Card}, image::AbstractString)

Parse 80 character card image from string buffer.
"""
function Base.parse(::Type{Card}, image::AbstractString)
	#
	#  !!! Currently, checks are for 'strict' standard
	#
	#  Parse Card image for keys, values, and comments. Construct Card.
	#
	#  Card is a parametric type containing Comment, Continue, End, Hierarch, History, and
	#  Value types. The Hierarch and Value types are parametric types of Missing, Number, and
	#  String types.
	#
	card = Card()
	if length(image) == CARDLENGTH
		if image == END_IMAGE
			card = Card(End, "END", missing, "", CardFormat())
		elseif (m = match(Regex("^"*VALUE_CARD*"\$"), image[1:TOKENLEN])) !== nothing
			value, comment, format = parse_value_comment(Value, image[(TOKENLEN+1):end])
			card = Card(Value{typeof(value)}, m[:key], value, comment, format)
		elseif (m = match(Regex("^"*COMMENT_CARD*"\$"), image[1:TOKENLEN])) !== nothing
			comment = image[(KEYLENGTH+1):end]
			if m[:key] == "HIERARCH"
				key, value, comment, format =
					parse_value_comment(Hierarch, image[TOKENLEN:end])
				card = Card(Hierarch{typeof(value)}, key, value, comment, format)
			else
				card = Card(m[:key] == "HISTORY " ? History : Comment, rstrip(m[:key]),
					rstrip(comment), "", CardFormat(true, 1, length(comment)))
			end
		elseif (m = match(Regex("^"*CONTINUE_CARD*"\$"), image[1:TOKENLEN])) !== nothing
			value, comment, format =
				parse_value_comment(Value, image[(TOKENLEN+1):end])
			card = Card(Continue, m[:key], value, comment, format)
		else
			card = Card(Invalid, rstrip(image[1:8]), image[(KEYLENGTH+1):end],
				"", CardFormat())
		end
	else
		card = Card(Invalid, rstrip(image[1:8]), image[(KEYLENGTH+1):end],
			"", CardFormat())
	end
	card
end

#  implement joincards() function. This functionality may need to be moved to hdu.jl

const NUMBER_FORMAT_STR = "(?<i>\\d+)?(?:(?<p>\\.)(?<f>\\d*))?(?:(?<x>[DE])(?<n>[+-]?\\d+))?"

const NUMBER_FORMAT_RE = Regex(NUMBER_FORMAT_STR)

function named_offsets(match::RegexMatch)
	(; (Symbol.(keys(match)) .=> match.offsets[1:length(keys(match))])...)
end

function value_type(valus::RegexMatch)
	types = (strg = String, bool = Bool, numr = Real, cplx = Complex, miss = Missing)
	keys  = (:strg, :bool, :numr, :cplx, :miss)
	basetype(Tuple(types[k] for k in keys if valus[k] !== nothing)[1])
end

function parse_value_comment(::Type{Value}, image::AbstractString)
	valus = match(VALUE_FSC_2, image)
	offsets = named_offsets(valus)
	value, format = parse_value(value_type(valus), valus, offsets)
	units, comment, format = parse_comment!(format, valus, offsets)
	(value*units, String(comment), format)
end

function parse_value(::Type{String}, valus::RegexMatch,
	offsets::NamedTuple)::Tuple{String, CardFormat}

	format = CardFormat()
	value = string(valus[:strg])
	#  vbeg and vend include the the single quotes.
	vbeg, vend, ampr = offsets[:strg], offsets[:strg]+length(value)-1, offsets[:ampr]
	format.fixd = vbeg == 1 ? true : false
	format.vbeg, format.vend, format.ampr = Int8(vbeg), Int8(vend), Int8(ampr)
	value = replace(value[2:((ampr>0 ? ampr : vend)-vbeg)], "''" => "'")
	(value, format)
end

function parse_value(::Type{Bool}, valus::RegexMatch,
	offsets::NamedTuple)::Tuple{Bool, CardFormat}

	format = CardFormat()
	value = valus[:bool] == "T" ? true : false
	format.fixd = offsets[:bool] == FIXEDINDEX ? true : false
	format.vbeg, format.vend = Int8(offsets[:bool]), Int8(offsets[:bool])
	(value, format)
end

function parse_value(::Type{Real}, valus::RegexMatch,
	offsets::NamedTuple)::Tuple{Real, CardFormat}

	format = CardFormat()
	value = parse_number(valus[:numr])
	numr, nlen = offsets[:numr], length(valus[:numr])
	format.fixd = (numr+nlen-1) == FIXEDINDEX ? true : false
	format.vbeg, format.vend = Int8(numr), Int8(numr+nlen-1)
	# format.frmt = valus[:numr]
	(value, format)
end

function parse_value(::Type{Complex}, valus::RegexMatch,
	offsets::NamedTuple)::Tuple{Complex, CardFormat}

	format = CardFormat()
	value = parse_complex(valus[:real], valus[:imag])
	real_, imag_ = offsets[:real], offsets[:imag]
	rlen, ilen = length(string(real(value))), length(string(imag(value)))
	format.fixd = false
	format.vbeg, format.vend = Int8.((real_, real_+rlen+2)), Int8.((real_+rlen-1, real_+rlen+2+ilen-1))
	# format.frmt = valus[:cplx]
	(value, format)
end

function parse_value(::Type{Missing}, valus::RegexMatch,
	offsets::NamedTuple)::Tuple{Missing, CardFormat}

	format = CardFormat()
	(missing, format)
end

function parse_value_comment(::Type{Hierarch}, image::AbstractString)
	values = match(HIERARCH_FSC, image)
	offsets = named_offsets(values)

	format = CardFormat(false, offsets[:key], 0, offsets[:equal])
	key = uppercase(values[:key])
	if !isnothing(values[:strg])
		value = string(values[:strg])
		format.vend = Int8(offsets[:strg]+length(value)-1)
	elseif !isnothing(values[:bool])
		value = values[:bool] == "T" ? true : false
		format.vend = Int8(offsets[:bool])
	elseif !isnothing(values[:numr])
		value = parse_number(values[:numr])
		format.vend = Int8(offsets[:numr]+length(values[:numr])-1)
		# format.frmt = values[:numr]
	elseif !isnothing(values[:cplx])
		value = parse_complex(values[:real], values[:imag])
		### real_, imag_ = offsets[:real], offsets[:imag]
		### rlen, ilen = length(values[:real]), length(values[:imag])
		### format.vbeg, format.vend = Int8.((real_, imag_)), Int8.((real_+rlen-1, imag_+ilen-1))
		format.vend = Int8(offsets[:cplx]+length(values[:cplx]))
		# format.frmt = values[:cplx]
	else
		value = missing
	end

	units, comment, format = parse_comment!(format, values, offsets)
	(key, value*units, comment, format)
end

#=
function parsevalue!(::Type{AbstractString}, format::F, values::N, offsets::N) where
	{F<:CardFormat, N<:NamedTuple}
	format = CardFormat()
	value = string(values[:strg])
	vbeg, vend = offsets[:strg], offsets[:strg]+length(value)-1
	format.vbeg, format.vend, format.ampr = Int8(vbeg), Int8(vend), Int8(offsets[:ampr])
	value = replace(value[2:vend-1-(offsets[:ampr] > 0 ? 1 : 0)], "''" => "'")
	(value, format)
end
=#
function parse_comment!(format::F, values::R, offsets::N) where
{F <: CardFormat, R <: RegexMatch, N <: NamedTuple}

	units = any(!isnothing(values[k]) for k in (:numr, :cplx, :bool)) ?
			NoUnits : ""
	comment = ""
	if !isnothing(values[:slash])
		format.slsh = Int8(offsets[:slash])
		#=
		if !isnothing(values[:units])
			if !isnothing(values[:numr]) || !isnothing(values[:cplx])
				units = uparse(replace(values[:units][2:(end-1)],
					unit_conversions...))
			else
				units = ""
			end
			ubeg, ulen = offsets[:units], length(values[:units])
			format.ubeg, format.uend = Int8(ubeg), Int8(ubeg+ulen-1)
		end
		=#
		if !isnothing(values[:comment])
			comment = values[:comment]
			cbeg, clen = offsets[:comment], length(comment)
			format.cbeg, format.cend = Int8(cbeg), Int8(cbeg+clen-1)
		end
	end
	(units, comment, format)
end

"""
	parse_number(real::AbstractString)

Determine the type of a number as a Float32, Float64, or Integer
"""
function parse_number(real::AbstractString)
	if occursin('D', real)
		value = parse(Float64, replace(real, "D" => "e"))
	elseif occursin('E', real) || occursin('.', real)
		#  Parse at full precision, then narrow to Float32 only when the
		#  narrowed value represents the written decimal exactly as well as a
		#  Float64 does.
		value64 = parse(Float64, replace(real, "E" => "e"))
		value32 = Float32(value64)
		value = Float64(value32) == value64 ? value32 : value64
	else
		value = try
			parse(Int64, real)
		catch _
			parse(Int128, real)
		end
	end
	value
end

"""
	least_float_type(real::Union{Real, Nothing})

Convert an integer the minimum float type of Float32, Float64, and BigFloat.
"""
function least_float_type(value::Union{Real, Nothing})
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

function parse_complex(real::S, imag::S) where S <: AbstractString
	if occursin("D", real) || occursin("D", imag)
		real_, imag_ = replace(real, "D" => "e"), replace(imag, "D" => "e")
		value = parse(ComplexF64, "$(real_) + $(imag_)im")
	elseif occursin("E", real) || occursin("E", imag)
		real_, imag_ = replace(real, "E" => "f"), replace(imag, "E" => "f")
		value = parse(ComplexF32, "$(real) + $(imag)im")
	elseif occursin(".", real) || occursin(".", imag)
		value = parse(ComplexF64, "$(real) + $(imag)im")
	else
		value = try
			parse(Complex{Int64}, "$(real) + $(imag)im")
		catch _
			parse(Complex{Int128}, "$(real) + $(imag)im")
		end
	end
	value
end

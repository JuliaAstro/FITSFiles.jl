###  Parse functions

"""
    Base.parse(::Type{Card}, image::AbstractString; strict = true, units = true)

Parse 80 character card image from string buffer. A number with a lower case exponent letter
(d or e) is not allowed by the standard, so it is an invalid card, unless `strict` is false.
The units of a number, i.e., a unit string in square brackets at the beginning of the comment,
are the units of the value, unless `units` is false or the keyword is mandatory.
"""
function Base.parse(::Type{Card}, image::AbstractString; strict::Bool = true, units::Bool = true)
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
		key = rstrip(image[1:KEYLENGTH])
		if image == END_IMAGE
			card = Card(End, "END", missing, "", CardFormat())
		elseif (m = match(Regex("^"*VALUE_CARD*"\$"), image[1:TOKENLEN])) !== nothing
			#  The mandatory keywords have no units.
			parsed = parse_value_comment(Value, image[(TOKENLEN+1):end]; strict,
				units = units && !is_fixed_key(key))
			card = isnothing(parsed) ?
				Card(Invalid, key, image[(KEYLENGTH+1):end], "", CardFormat()) :
				Card(Value{typeof(parsed[1])}, m[:key], parsed...)
		elseif (m = match(Regex("^"*COMMENT_CARD*"\$"), image[1:TOKENLEN])) !== nothing
			comment = image[(KEYLENGTH+1):end]
			#  A HIERARCH card without a value is commentary text.
			hier = m[:key] == "HIERARCH" && image[KEYLENGTH+1] == ' ' ?
				parse_value_comment(Hierarch, image[TOKENLEN:end]; strict, units) : nothing
			if !isnothing(hier)
				card = Card(Hierarch{typeof(hier[2])}, hier...)
			else
				card = Card(m[:key] == "HISTORY " ? History : Comment, rstrip(m[:key]),
					rstrip(comment), "", CardFormat(true, 1, length(comment)))
			end
		elseif (m = match(Regex("^"*CONTINUE_CARD*"\$"), image[1:TOKENLEN])) !== nothing
			parsed = parse_value_comment(Value, image[(TOKENLEN+1):end]; strict, units = false)
			card = isnothing(parsed) ?
				Card(Invalid, key, image[(KEYLENGTH+1):end], "", CardFormat()) :
				Card(Continue, m[:key], parsed...)
		elseif image[(KEYLENGTH+1):TOKENLEN] != EQUAL_TOKEN && key != "END" &&
			!isempty(key) && !occursin(NON_KEY_TEXT, key)
			#  A record without a value indicator is commentary text (Sect. 4.1.2.3).
			comment = image[(KEYLENGTH+1):end]
			card = Card(Comment, key, rstrip(comment), "", CardFormat(true, 1, length(comment)))
		else
			card = Card(Invalid, rstrip(image[1:8]), image[(KEYLENGTH+1):end],
				"", CardFormat())
		end
	else
		card = Card(Invalid, rstrip(first(image, KEYLENGTH)),
			image[(min(end, KEYLENGTH)+1):end], "", CardFormat())
	end
	card
end

#  A CONTINUE card continues a string only if the preceding card ends with an ampersand.
continued(card::Card) = basetype(typename(card)) in (Value, Continue) && card.format.ampr > 0

"""
    Base.parse(::Type{Card}, image::AbstractString, previous; strict = true, units = true)

Parse 80 character card image that follows the card `previous`, or `nothing`. A CONTINUE
card that does not continue a string is commentary text.
"""
function Base.parse(::Type{Card}, image::AbstractString, previous; strict::Bool = true,
	units::Bool = true)
	card = parse(Card, image; strict, units)
	if typename(card) == Continue && !(!isnothing(previous) && continued(previous))
		card = Card(Comment, "CONTINUE", rstrip(image[(KEYLENGTH+1):end]), "",
			CardFormat(true, 1, length(image) - KEYLENGTH))
	end
	card
end

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

#  A value field is malformed if it does not match, or if text follows the value without a
#  comment separator.
ismalformed(valus::Union{RegexMatch, Nothing}) =
	isnothing(valus) || (!isnothing(valus[:comment]) && isnothing(valus[:slash]))

function parse_value_comment(::Type{Value}, image::AbstractString; strict::Bool = true,
	units::Bool = true)
	valus = match(strict ? VALUE_FSC_2 : VALUE_LOWER, image)
	ismalformed(valus) && return nothing
	offsets = named_offsets(valus)
	value, format = parse_value(value_type(valus), valus, offsets)
	unit, comment, format = parse_comment!(format, valus, offsets; units)
	(value, unit, String(comment), format)
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
	#  Trailing spaces are not significant, except in a string that continues. The spaces are
	#  restored by the value field when the card is written.
	(ampr == 0 ? trimvalue(value) : value, format)
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
	format.vfmt = realfmt(valus[:numr])
	(value, format)
end

function parse_value(::Type{Complex}, valus::RegexMatch,
	offsets::NamedTuple)::Tuple{Complex, CardFormat}

	format = CardFormat()
	value = parse_complex(valus[:real], valus[:imag])
	cplx, clen = offsets[:cplx], length(valus[:cplx])
	format.fixd = false
	format.vbeg, format.vend = Int8(cplx), Int8(cplx+clen-1)
	format.vfmt = complexfmt(valus[:cplx])
	(value, format)
end

function parse_value(::Type{Missing}, valus::RegexMatch,
	offsets::NamedTuple)::Tuple{Missing, CardFormat}

	format = CardFormat()
	(missing, format)
end

function parse_value_comment(::Type{Hierarch}, image::AbstractString; strict::Bool = true,
	units::Bool = true)
	values = match(strict ? HIERARCH_FSC : HIERARCH_LOWER, image)
	ismalformed(values) && return nothing
	offsets = named_offsets(values)

	format = CardFormat(false, offsets[:key], 0, offsets[:equal])
	key = uppercase(values[:key])
	if !isnothing(values[:strg])
		strg = string(values[:strg])
		format.vend = Int8(offsets[:strg]+length(strg)-1)
		value = replace(strg[2:(end-1)], "''" => "'")
	elseif !isnothing(values[:bool])
		value = values[:bool] == "T" ? true : false
		format.vend = Int8(offsets[:bool])
	elseif !isnothing(values[:numr])
		value = parse_number(values[:numr])
		format.vend = Int8(offsets[:numr]+length(values[:numr])-1)
		format.vfmt = realfmt(values[:numr])
	elseif !isnothing(values[:cplx])
		value = parse_complex(values[:real], values[:imag])
		format.vend = Int8(offsets[:cplx]+length(values[:cplx])-1)
		format.vfmt = complexfmt(values[:cplx])
	else
		value = missing
		format.vend = Int8(offsets[:equal])
	end

	unit, comment, format = parse_comment!(format, values, offsets; units)
	(key, value, unit, comment, format)
end

function parse_comment!(format::F, values::R, offsets::N; units::Bool = true) where
{F <: CardFormat, R <: RegexMatch, N <: NamedTuple}

	unit = nothing
	comment = ""
	if !isnothing(values[:slash])
		format.slsh = Int8(offsets[:slash])
		if !isnothing(values[:comment])
			comment = values[:comment]
			cbeg, clen = offsets[:comment], length(comment)
			format.cbeg, format.cend = Int8(cbeg), Int8(cbeg+clen-1)
			#  The units of a number are in square brackets at the beginning of the comment
			#  (Sect. 4.3.2). Text that is not a unit string, or has a scale factor, is a comment.
			m = units && (!isnothing(values[:numr]) || !isnothing(values[:cplx])) ?
				match(r"^\[([^\]]*)\]( *)", comment) : nothing
			parsed = isnothing(m) ? nothing : parseunit(m[1])
			if parsed isa Unitful.Units
				unit, comment = parsed, comment[(length(m.match)+1):end]
				format.ubeg, format.uend = Int8(cbeg), Int8(cbeg+length(m.match)-length(m[2])-1)
				format.ufmt = unitstyle(m[1])
				format.cbeg, format.cend = isempty(comment) ? (Int8(0), Int8(0)) :
					(Int8(cbeg+length(m.match)), Int8(cbeg+clen-1))
			end
		end
	end
	(unit, comment, format)
end

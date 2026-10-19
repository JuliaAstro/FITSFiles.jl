####  Format Card  ####

function layout_card(::Type{Value{S}}, value::S, comment::C; kwds...) where
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

function layout_card(::Type{Value{V}}, value::V, comment::C; kwds...) where
{V <: ValueType, C <: AbstractString}

	#  Create appropriate CardFormat type
	format = CardFormat(kwds[:fixed])
	format.vfmt, format.ufmt = get(kwds, :vfmt, ""), get(kwds, :ufmt, "")
	if isempty(format.vfmt)
		vlen = typeof(value) <: Bool ? 1 : length(string(value))
		vend = max(FIXEDINDEX, vlen)
		format.vbeg, format.vend = Int8(max(1, FIXEDINDEX-vlen+1)), Int8(vend)
	else
		#  The number has a printf format, and is in fixed-format or begins at the beginning index.
		vlen = length(printfmt(format.vfmt, value))
		vbeg = format.fixd ? max(1, FIXEDINDEX-vlen+1) : get(kwds, :vbeg, 1)
		vend = format.fixd ? max(FIXEDINDEX, vlen) : vbeg+vlen-1
		format.vbeg, format.vend = Int8(vbeg), Int8(vend)
	end
	#   Format comment, if necessary
	formatcomment!(comment, vend, format; kwds...)
end

function layout_card(::Type{Value{V}}, value::V, comment::C; kwds...) where
{V <: Complex, C <: AbstractString}

	#  Create appropriate CardFormat type
	format = CardFormat(false)
	format.vfmt, format.ufmt = get(kwds, :vfmt, ""), get(kwds, :ufmt, "")
	if isempty(format.vfmt)
		rlen, ilen = length(string(real(value))), length(string(imag(value)))
		vend = 1+rlen+2+ilen
		format.vbeg, format.vend = Int8(2), Int8(vend+1)
	else
		vbeg = get(kwds, :vbeg, 1)
		vend = vbeg+length(printfmt(format.vfmt, value))-1
		format.vbeg, format.vend = Int8(vbeg), Int8(vend)
	end
	#   Format comment, if necessary
	formatcomment!(comment, vend, format; kwds...)
end

function layout_card(::Type{Continue}, value::S, comment::C; kwds...) where
{S <: AbstractString, C <: AbstractString}

	#  Format CONTINUE record
	#  data: fixed, amper, slash, lpad, rpad, truncate
	layout_card(Value{AbstractString}, value, comment; kwds...)
end

function layout_card(::Type{Hierarch{V}}, token::S, value::V, comment::C; kwds...) where
{S <: AbstractString, V <: ValueType, C <: AbstractString}
	format = CardFormat(kwds[:fixed])
	format.vfmt, format.ufmt = get(kwds, :vfmt, ""), get(kwds, :ufmt, "")
	#  Use ampersand for '=' index
	ampr = length(token) + 2
	vlen = ampr + 1 + length(isempty(format.vfmt) ? value_image(value) : printfmt(format.vfmt, value))
	vend = HIERINDEX+vlen
	#  The keyword, value, and equal sign must fit on the card after "HIERARCH ".
	vend > CARDLENGTH - KEYLENGTH - 1 &&
		throw(ArgumentError("HIERARCH keyword and value do not fit on the card."))
	format.vbeg, format.vend, format.ampr = Int8(0), Int8(vend), Int8(ampr)
	#  Format comment, if necessary
	formatcomment!(comment, vend, format; last = CARDLENGTH - KEYLENGTH - 1, kwds...)
end

#  Free-format value field of a HIERARCH card: strings are quoted, logicals are T or F,
#  and floats use an E (single precision) or D (double precision) exponent.
function value_image(value::ValueType)
	if ismissing(value)
		""
	elseif value isa AbstractString
		"'" * replace(value, "'" => "''") * "'"
	elseif value isa Bool
		value ? "T" : "F"
	elseif value isa Complex
		"(" * value_image(real(value)) * ", " * value_image(imag(value)) * ")"
	elseif value isa Float32
		replace(string(value), "f" => "E", "e" => "E")
	elseif value isa AbstractFloat
		replace(string(value), "e" => "D")
	else
		string(value)
	end
end

#  The units and the comment must fit on the card, i.e., end at or before the last position, which
#  is counted from the first position of the value field, i.e., byte 11. A comment that does not fit
#  is truncated, or is an error if `truncate` is false, and a separator that is not on the card
#  has no comment.
function formatcomment!(comment::S, vend::I, format::F; units = missing, last::Integer =
	CARDLENGTH - TOKENLEN, kwds...) where {S <: AbstractString, I <: Integer, F <: CardFormat}

	#  Left padding has priority over the slash index.
	padl, padr, padu = kwds[:lpad], kwds[:rpad], kwds[:upad]
	slash = (kwds[:slash]-TOKENLEN) <= vend+padl+1 ? vend+padl+1 : kwds[:slash]-TOKENLEN
	#  Prepend units to comment
	if !ismissing(units)
		ubeg, uend = slash+padr+1, slash+padr+2+length(units)
		uend > last && throw(ArgumentError("Units do not fit on the card."))
		format.slsh = Int8(slash)
		format.ubeg, format.uend = Int8(ubeg), Int8(uend)
	end
	#  Add comment
	if !isempty(comment)
		cndx = format.uend > 0 ? format.uend+padu : slash+padr
		cbeg, cend = cndx+1, cndx+length(comment)
		if cend > last
			get(kwds, :truncate, true) || throw(ArgumentError("Comment does not fit on the card."))
			cend = last
		end
		if cbeg <= cend
			format.slsh = Int8(slash)
			format.cbeg, format.cend = Int8(cbeg), Int8(cend)
		end
	end
	format
end

#  The comment that is on the card, i.e., that is not truncated by the format.
fitcomment(comment::AbstractString, format::CardFormat) =
	format.cbeg == 0 ? "" : first(comment, format.cend - format.cbeg + 1)

function value_length(slash::I, lpad::I)::Integer where I <: Integer
	#  Calculate length of value based comment separator index and padding.
	#  First 2 is for value indicator. Second 2 is single quotes.
	((slash-lpad) > CARDLENGTH ? CARDLENGTH : slash-lpad-1) - (TOKENLEN+2)
end

function comment_length(slash::I, rpad::I)::Integer where I <: Integer
	#  Calculate length of comment using the comment separator index and padding.
	(slash+rpad) >= CARDLENGTH ? 0 : CARDLENGTH - (slash+rpad)
end

#  The key is padded by the number of characters, since a control character has no width.
rpad_key(key::AbstractString, n::Integer = 0) = key * " "^max(0, KEYLENGTH + n - length(key))

#  Format String value for card
function stringvalue(value::S, format::F) where {S <: AbstractString, F <: CardFormat}
	#  Replace strings with single quotes with two single quotes.
	#  Append ampersand to value field, if necessary.
	#  Pad the string to the width of the value field, which restores the spaces that are not
	#  part of the string, i.e., the spaces following the ampersand and preceding the string
	#  in free-format.
	vbeg, vend, ampr = format.vbeg, format.vend, format.ampr
	strg = rpad(replace(value, "'" => "''"), ampr-vbeg-1) * (ampr > 0 ? "&" : "")
	repeat(" ", max(0, vbeg-1)) * "'" * rpad(strg, vend-vbeg-1) * "'"
end

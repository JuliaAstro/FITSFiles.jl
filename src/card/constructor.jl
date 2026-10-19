function Card(key::K = "", value::V = missing, comment::C = ""; fixed::B = true,
	append::B = false, slash::I = 32, lpad::I = 1, rpad::I = 1, upad::I = 1,
	truncate::B = true, warn::B = true, splitat::Union{Char, Nothing} = ' ') where
	{B <: Bool, I <: Integer, K <: AbstractString, V <: ValueInput, C <: AbstractString}

	#  Convert key to uppercase and remove trailing spaces.
	upkey = uppercase(strip(key))
	#  Mandatory keywords are always in fixed format.
	fixed = fixed || is_fixed_key(upkey)

	#  A keyword that is longer than 8 characters is the tokens of a HIERARCH keyword.
	if length(upkey) > KEYLENGTH
		tokens = replace(upkey, r"^HIERARCH +" => "")
		warn && @warn "Keyword is longer than $KEYLENGTH characters, so a HIERARCH card is created." key=upkey
		return Card("HIERARCH", tokens, value, comment; fixed, slash, lpad, rpad, upad)
	end

	#  The units of a quantity are not part of the value.
	value, units = splitunits(value)
	is_supported(value) || throw(ArgumentError("Value type $(typeof(value)) is not supported."))

	#  Check for invalid characters in key, value string, and comment.
	if !is_hierarch(upkey) && occursin(NON_KEY_TEXT, upkey)
		throw(ArgumentError("Keyword contains invalid characters."))
	elseif !ismissing(value) && typeof(value) <: AbstractString && occursin(NON_ASCII_TEXT, value)
		throw(ArgumentError("Value string contains invalid characters."))
	elseif !ismissing(comment) && occursin(NON_ASCII_TEXT, comment)
		throw(ArgumentError("Comment contains invalid characters."))
	elseif value isa Number && !isfinite(value)
		throw(DomainError(value, "Value is not finite."))
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
	elseif is_continue_key(upkey)
		#  Create CONTINUE card, whose value is a string
		value isa AbstractString || throw(ArgumentError("Value is not a string."))
		type = Continue
		format = layout_card(type, value, comment; append, fixed,
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
		format = layout_card(type, value, comment; fixed, append,
			slash, lpad, rpad, upad, truncate, units = unitstring(units))
	elseif is_valid_key(upkey) &&
		(splitslash = long_string_slash(String(value), comment, slash, lpad, rpad, truncate)) !== nothing
		#  Create a list of cards from from a long string.
		type = Value{typeof(value)}
		cards = split_card(upkey, value, comment,
			(; fixed, slash = splitslash[1], slash2 = splitslash[2], lpad, rpad, upad, append, splitat))
		cards = [Card(t, k, v, c, f) for (t, k, v, c, f) in cards]
	else
		#  Create Value card that is not a long string. The key is valid, because the
		#  characters of the key are checked above and a long key is a HIERARCH key.
		type = Value{typeof(value)}
		value = format_xtension_value(upkey, value)
		format = layout_card(type, value, comment; fixed, append,
			slash, lpad, rpad, upad, truncate, units = unitstring(units))
	end

	typeof(cards) <: AbstractArray && return cards
	#  The comment of a commentary card is not on the card.
	type <: Union{Comment, History} || (comment = fitcomment(comment, format))
	Card(type, upkey, value, units, comment, format)
end

function Card(key::K, tokens::T, value::V, comment::C;
	fixed::B = true, slash::I = 32, lpad::I = 1, rpad::I = 1, upad::I = 1) where
{B <: Bool, I <: Integer, K <: AbstractString, T <: AbstractString, V <: ValueInput,
	C <: AbstractString}

	#  Convert key to uppercase and remove trailing SPECIAL_KEYS
	upkey, uptoken = uppercase(strip(key)), uppercase(strip(tokens))
	#  The units of a quantity are not part of the value.
	value, units = splitunits(value)
	is_supported(value) || throw(ArgumentError("Value type $(typeof(value)) is not supported."))

	#  Check for invalid characters in key, value string, and comment.
	if !is_hierarch(upkey) && occursin(NON_KEY_TEXT, upkey)
		throw(ArgumentError("Keyword contains invalid characters."))
	elseif !ismissing(value) && typeof(value) <: AbstractString && occursin(NON_ASCII_TEXT, value)
		throw(ArgumentError("Value string contains invalid characters."))
	elseif !ismissing(comment) && occursin(NON_ASCII_TEXT, comment)
		throw(ArgumentError("Comment contains invalid characters."))
	elseif value isa Number && !isfinite(value)
		throw(DomainError(value, "Value is not finite."))
	end

	#  Format card image from key, value, and comment arguments and construct Card.
	#  The Hierarch type is parametric type of Missing, Number, and String types.
	#
	format = CardFormat(fixed, 0, 0)

	if is_hierarch(upkey) && is_valid_key(upkey)
		if !occursin(HIERARCH_TOKENS, uptoken)
			throw(ArgumentError("HIERARCH keyword contains invalid characters."))
		end
		type = Hierarch{typeof(value)}
		format = layout_card(type, uptoken, value, comment; fixed, slash, lpad, rpad, upad,
			units = unitstring(units))
	else
		throw(ArgumentError("Invalid card"))
	end
	Card(type, uptoken, value, units, fitcomment(comment, format), format)
end

#  check key type
is_end_key(key::AbstractString)      = key == "END"
is_continue_key(key::AbstractString) = key == "CONTINUE"
is_comment_key(key::AbstractString)  = haskey(COMMENTKEY, key)
is_valid_key(key::AbstractString) = length(key) <= KEYLENGTH && occursin(KEY_FSC, key)

#  The types of a value that are written as a FITS value: a string, a logical, an integer, a real
#  float, or a complex number of integers or floats.
is_supported(value::Missing) = true
is_supported(value::Union{AbstractString, Bool, Integer, AbstractFloat}) = true
is_supported(value::Complex{T}) where T = T !== Bool && (T <: Integer || T <: AbstractFloat)
is_supported(value) = false

function is_fixed_key(key::AbstractString)
	key in ("SIMPLE", "XTENSION", "BITPIX", "NAXIS", "PCOUNT", "GCOUNT", "END") ||
		occursin(r"^NAXIS\d{1,3}$", key)
end

#  The indexes of the comment separators of the first card and of the CONTINUE cards of a long
#  string, or nothing if the string and the comment are on one card. A string that fits on a card is
#  not split, and moves the comment to the right, if the string passes the comment separator. The
#  comment is truncated, if it does not fit on the card and `truncate` is true, and otherwise is
#  continued on the CONTINUE cards of the string, where the comment begins at the comment separator.
#  A string that does not fit on a card is split at the comment separator, or at the end of the
#  card if there is no comment.
function long_string_slash(value::AbstractString, comment::AbstractString,
	slash::I, lpad::I, rpad::I, truncate::Bool) where I <: Integer

	vlen = length(replace(value, "'" => "''"))
	if vlen <= value_length(slash, lpad)
		(truncate || length(comment) <= comment_length(slash, rpad)) ? nothing : (slash, slash)
	elseif vlen <= CARDLENGTH - TOKENLEN - 2
		#  The comment separator follows the string, and the continued string has an ampersand.
		next = vlen + lpad + TOKENLEN + 3
		(truncate || length(comment) <= comment_length(next, rpad)) ? nothing : (next + 1, slash)
	else
		isempty(comment) ? (CARDLENGTH + 2, CARDLENGTH + 2) : (slash, slash)
	end
end

function is_hierarch(key::AbstractString)
	key[1:min(length(key), 8)] == "HIERARCH" ||
		(length(key) > KEYLENGTH && occursin(ASCII_TEXT, key))
end

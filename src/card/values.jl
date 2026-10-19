#  Split a quantity into its value and units. A value without units has `nothing` for units.
splitunits(value::Quantity) = unit(value) === NoUnits ? (ustrip(value), nothing) :
	(ustrip(value), unit(value))
splitunits(value) = (value, nothing)

"""
	setvalue!(card, value; splitat = ' ')

Return the card with the value `value`, and the units, format, and comment of the card. A number
without units has the units of the card. A string that does not fit on the card, i.e., that
passes the comment separator, or the end of the card if there is no comment, is split into the
cards of a long string, the first card and the CONTINUE cards, which are returned as a vector.
The string and the comment are split after the last `splitat` that fits, as in the constructor
of a card.
"""
function setvalue!(card::Card, value::ValueType; splitat::Union{Char, Nothing} = ' ')
	#  The value of a commentary card is a string, and an END card has no value.
	T = basetype(typename(card))
	if T == End
		ismissing(value) || throw(ArgumentError("END keyword has no value."))
		return card
	elseif T == Continue ? !(value isa AbstractString) :
		T in (Comment, History) && !(value isa Union{AbstractString, Missing})
		throw(ArgumentError("value is not a string."))
	end
	value = value isa AbstractString ? format_xtension_value(card.key, value) : value
	#  The units of a quantity are not part of the value. A number without units has the units of
	#  the card, whereas a value of another type has none.
	value, units = splitunits(value)
	is_supported(value) || throw(ArgumentError("Value type $(typeof(value)) is not supported."))
	if isnothing(units) && value isa Union{Real, Complex} && !(value isa Bool)
		units = card.units
	end
	#  The trailing spaces of a string are not significant.
	same = (card.value isa AbstractString && value isa AbstractString ?
		trimvalue(card.value) == trimvalue(value) : card.value === value) &&
		isequal(card.units, units)
	if !same
		f, T = card.format, basetype(typename(card))
		if T in (Value, Hierarch)
			#  The type of the card follows the type of the new value. The card is formatted
			#  again at the separator index of the old card, so a value that does not fit
			#  before the separator moves the separator and comment.
			type = T{typeof(value)}
			rpad = max(f.cbeg, f.ubeg) > 0 ? (f.ubeg > 0 ? f.ubeg : f.cbeg) - f.slsh - 1 : 1
			upad = f.ubeg > 0 && f.cbeg > 0 ? f.cbeg - f.uend - 1 : 1
			#  A units string at the beginning of the comment of a card that is parsed without
			#  units is replaced by the units of the new value.
			comment = card.comment
			if !isnothing(units) && f.ubeg == 0 &&
				(m = match(r"^\[[^\]]*\]( *)", comment)) !== nothing
				comment, upad = comment[(length(m.match)+1):end], length(m[1])
			end
			#  A string does not fit if it passes the separator of a card with a comment, which is not
			#  before the default index, or the end of a card without a comment. It is split into the
			#  cards of a long string.
			slash = isempty(comment) ? CARDLENGTH + 2 : max(f.slsh + TOKENLEN, 32)
			if T == Value && value isa AbstractString &&
				is_long_string(value, comment, slash, 1, rpad, true)
				cards = split_card(card.key, value, comment,
					(; fixed = f.fixd, slash, lpad = 1, rpad, upad, append = false, splitat))
				return [Card(t, k, v, c, f) for (t, k, v, c, f) in cards]
			end
			args = T == Hierarch ? (card.key,) : ()
			fmt = layout_card(type, args..., value, comment; fixed = f.fixd, append = false,
				slash = f.slsh + TOKENLEN, lpad = 1, rpad, upad, units = unitstring(units, f.ufmt),
				vfmt = keepfmt(f.vfmt, value), ufmt = f.ufmt, vbeg = f.vbeg)
			card = Card(type, card.key, value, units, fitcomment(comment, fmt), fmt)
		else
			card = Card(T, card.key, value, card.comment, f)
		end
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
	splitat = get(kwds, :splitat, nothing)
	ncard = max(nslices(value, vallen, true, splitat), nslices(comment, comlen, false, splitat))
	#  Create arrays of card types, keywords, values, comments, and formatting keywords
	#  for each card. Ensure ampersand is appended to each value string, except last.
	types    = (Value{String}, fill(Continue, ncard-1)...)
	keys     = (key, fill("CONTINUE", ncard-1)...)
	values   = Tuple(value[j1:j2] for (j1, j2) in slices(value, vallen, ncard, true, splitat))
	comments = Tuple(comment[j1:j2] for (j1, j2) in slices(comment, comlen, ncard, false, splitat))
	formats  = (Tuple(layout_card(t, v, c; merge(kwds, (; append = true))...) for (t, v, c) in
		zip(types[1:(ncard-1)], values[1:(ncard-1)], comments[1:(ncard-1)]))...,
		layout_card(types[ncard], values[ncard], comments[ncard]; kwds...))

	zip(types, keys, values, comments, formats)
end

"""
	join_cards(cards)

Join CONTINUE cards to initial long string card to create a long value and comment card.
Cards after the end of the continued string are ignored.
"""
function join_cards(cards::AbstractVector)
	#  Cards are joined while the preceding card ends with an ampersand and the next card is a
	#  CONTINUE card. An ampersand that is not followed by a CONTINUE card is the literal last
	#  character of the string (Sect. 4.2.1.2).
	n = 1
	while n < length(cards) && cards[n].format.ampr > 0 &&
		basetype(typename(cards[n+1])) == Continue
		n += 1
	end
	joined = cards[1:n]
	value = join((c.value for c in joined)) * (joined[n].format.ampr > 0 ? "&" : "")
	comment = join((c.comment for c in joined))
	format = deepcopy(cards[1].format)
	format.ampr = 0
	Card(typename(cards[1]), cards[1].key, value, comment, format)
end

#  Last index of the slice of value that begins at index j1 and has at most slen
#  characters. If single is true, the slice is limited to slen characters after each
#  single quote is doubled, and a doubled single quote is never split. If splitat is a
#  character, a slice that does not end the value ends after the last splitat that fits.
function lastndx(value::AbstractString, j1::Integer, slen::Integer, single::Bool,
	splitat::Union{Char, Nothing} = nothing)

	vlen = length(value)
	if !single
		j2 = min(j1 + slen - 1, vlen)
	else
		j2, width = j1 - 1, 0
		while j2 < vlen
			w = value[j2+1] == '\'' ? 2 : 1
			width + w > slen && break
			width, j2 = width + w, j2 + 1
		end
	end
	if !isnothing(splitat) && j2 < vlen
		k = findlast(==(splitat), value[j1:j2])
		isnothing(k) || (j2 = j1 + k - 1)
	end
	j2
end

#  Number of slices needed to hold the text.
function nslices(text::AbstractString, slen::Integer, single::Bool = true,
	splitat::Union{Char, Nothing} = nothing)

	slen <= 0 && return 1
	j1, n = 1, 0
	while j1 <= length(text)
		j2 = lastndx(text, j1, slen, single, splitat)
		j2 < j1 && throw(ArgumentError("Value string does not fit on a card."))
		j1, n = j2 + 1, n + 1
	end
	max(n, 1)
end

function slices(value::S, slen::I, ncard::I, single::B = false,
	splitat::Union{Char, Nothing} = nothing) where
{S <: AbstractString, I <: Integer, B <: Bool}
	vals = Vector{Tuple{Int, Int}}(undef, ncard)
	j1 = 1
	for j ∈ 1:ncard
		j2 = lastndx(value, j1, slen, single, splitat)
		vals[j] = (j1, j2)
		j1 = j2 + 1
	end
	vals
end

#  Remove the trailing spaces of a string value, which are not significant. The first space of
#  a string of only spaces is significant, because it is an empty string and not a null string.
trimvalue(value::AbstractString) =
	isempty(rstrip(value)) && !isempty(value) ? " " : String(rstrip(value))

#  Format special XTENSION values, pad to 8 characters
function format_xtension_value(key::AbstractString, value::AbstractString)
	(key == "XTENSION" && rstrip(uppercase(value)) in XTENSION_VALUES) ?
	rpad(rstrip(uppercase(value)), 8) : value
end

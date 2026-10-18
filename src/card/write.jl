####  Format Card Image  ####

function Base.show(io::IO, cards::Vector{Card{<:Any}})
	print(io, join(Tuple(repr(card) for card in cards), "\n"))
end

function Base.show(io::IO, card::Card)
	print(io, format_card(basetype(typename(card)), card.key, card.value, card.units,
		card.comment, card.format))
end

#  Format End card using only keyword.
function format_card(::Type{End}, key::K, value::V, units, comment::C,
	format::F) where {K <: AbstractString, V <: ValueType, C <: AbstractString,
	F <: CardFormat}

	rpad_image(key)
end

#  Format Comment card using only keyword and value.
function format_card(::Type{Comment}, key::K, value::V, units, comment::C,
	format::F) where {K <: AbstractString, V <: Union{Missing, AbstractString},
	C <: AbstractString, F <: CardFormat}

	rpad_image(rpad_key(key) * (ismissing(value) ? "" : value))
end

#  Ensure Comment card value is only a string.
function format_card(::Type{Comment}, key::K, value::N, units, comment::C,
	format::F) where {K <: AbstractString, N <: Number, C <: AbstractString,
	F <: CardFormat}

	error("Value is not a string.")
end

#  Format Continue card value by adding ampersand to end of string.
function format_card(::Type{Continue}, key::K, value::V, units, comment::C,
	format::F) where {K <: AbstractString, V <: AbstractString, C <: AbstractString,
	F <: CardFormat}

	rpad_image(key, stringvalue(value, format), "", comment, format)
end

function format_card(::Type{Continue}, key::K, value::V, units, comment::C,
	format::F) where {K <: AbstractString, V <: Union{Missing, Number},
	C <: AbstractString, F <: CardFormat}

	error("Continue contains non-string value.")
end

#  Add HIERARCH key, then format value and comment fields
function format_card(::Type{Hierarch}, key::K, value::V, units, comment::C,
	format::F) where {K <: AbstractString, V <: ValueType, C <: AbstractString,
	F <: CardFormat}

	text = lpad(isempty(format.vfmt) ? value_image(value) : printfmt(format.vfmt, value),
		format.vend-format.ampr)
	valu = rpad(key, format.ampr-1) * "=" * text
	padl = repeat(" ", max(0, (format.slsh-1) - format.vend))
	slash = format.slsh > 0 ? "/" : " "
	if format.ubeg > 0
		padr = repeat(" ", max(0, format.ubeg-1 - format.slsh))
		unts = "[$(formunit(units, format.ufmt))]"
		padu = repeat(" ", max(0, format.cbeg-1 - format.uend))
	else
		padr = repeat(" ", max(0, (format.cbeg-1) - format.slsh))
		unts, padu = "", ""
	end
	rpad_image("HIERARCH " * valu * padl * slash * padr * unts * padu * comment)
end

#  Format History card using only keyword and value.
function format_card(::Type{History}, key::K, value::V, units, comment::C,
	format::F) where {K <: AbstractString, V <: Union{AbstractString, Missing},
	C <: AbstractString, F <: CardFormat}

	rpad_image(rpad_key(key) * (ismissing(value) ? "" : value))
end

#  Ensure History card value is only a string.
function format_card(::Type{History}, key::K, value::N, units, comment::C,
	format::F) where {K <: AbstractString, N <: Number, C <: AbstractString,
	F <: CardFormat}

	error("Value is not a string.")
end

#  Format Invalid card
function format_card(::Type{Invalid}, key::K, value::V, units, comment::C,
	format::F) where {K <: AbstractString, V <: AbstractString, C <: AbstractString,
	F <: CardFormat}

	rpad_key(key)*value
end

#  Format Value card for missing value.
function format_card(::Type{Value}, key::K, value::M, units, comment::C,
	format::F) where {K <: AbstractString, M <: Missing, C <: AbstractString,
	F <: CardFormat}

	rpad_image(key, "", "", comment, format)
end

#  Format Value card for string value.
function format_card(::Type{Value}, key::K, value::V, units, comment::C,
	format::F) where {K <: AbstractString, V <: AbstractString, C <: AbstractString,
	F <: CardFormat}

	#  Fixed format strings begin at index 11
	rpad_image(key, stringvalue(value, format), "", comment, format)
end

#  Format Value card for boolean value.
function format_card(::Type{Value}, key::K, value::V, units, comment::C,
	format::F) where {K <: AbstractString, V <: Bool, C <: AbstractString,
	F <: CardFormat}

	#  Fixed format boolean value is at index 30
	padlen = FIXEDINDEX - 1
	#  If fixed format, pad value string
	value = (format.fixd ? repeat(" ", padlen) : "") * (value == true ? "T" : "F")
	rpad_image(key, value, "", comment, format)
end

#  Format Value card for integer value.
function format_card(::Type{Value}, key::K, value::I, units, comment::C,
	format::F) where {K <: AbstractString,
	I <: Integer,
	C <: AbstractString, F <: CardFormat}

	units = formunit(units, format.ufmt)
	isempty(format.vfmt) || return rpad_image(key, alignnumber(printfmt(format.vfmt, value), format),
		units, comment, format)
	#  Fixed format integer value ends at index 30
	padlen = max(0, FIXEDINDEX - (format.vend-format.vbeg+1))
	#  If fixed format, pad value string.
	strval = (format.fixd ? repeat(" ", padlen) : "") * string(value)
	rpad_image(key, strval, units, comment, format)
end

#  Format Value card for 32-bit float value.
function format_card(::Type{Value}, key::K, value::V, units, comment::C,
	format::F) where {K <: AbstractString,
	V <: Float32,
	C <: AbstractString, F <: CardFormat}

	#  Fixed format float value ends at index 30
	#  Replace (lowercase) 'e' and 'f' with (uppercase) 'E'
	units = formunit(units, format.ufmt)
	isempty(format.vfmt) || return rpad_image(key, alignnumber(printfmt(format.vfmt, value), format),
		units, comment, format)
	value = replace(string(value), "f" => "E", "e" => "E")
	padlen = max(0, FIXEDINDEX - length(value))
	#  If fixed format, pad value string.
	value = (format.fixd ? repeat(" ", padlen) : "") * value
	rpad_image(key, value, units, comment, format)
end

#  Format Value card for non-32-bit float values.
function format_card(::Type{Value}, key::K, value::V, units, comment::C,
	format::F) where {K <: AbstractString,
	V <: AbstractFloat,
	C <: AbstractString, F <: CardFormat}

	#  Fixed format float value ends at index 30
	#  Replace (lowercase) 'e' with (uppercase) 'D'.
	units = formunit(units, format.ufmt)
	isempty(format.vfmt) || return rpad_image(key, alignnumber(printfmt(format.vfmt, value), format),
		units, comment, format)
	value = replace(string(value), "e" => "D")
	#  Truncate mantissa, so value contains 20 characters.
	if format.fixd && length(value) > FIXEDINDEX
		n = something(findfirst('D', value), length(value)+1)
		value = value[1:(n-1-length(value)+FIXEDINDEX)] * value[n:end]
	end
	padlen = max(0, FIXEDINDEX - length(value))
	#  If fixed format, pad value string.
	value = (format.fixd ? repeat(" ", padlen) : "") * value
	rpad_image(key, value, units, comment, format)
end

#  Format Value card for complex integer value.
function format_card(::Type{Value}, key::K, value::V, units, comment::C,
	format::F) where {K <: AbstractString,
	V <: Complex{<:Integer},
	C <: AbstractString, F <: CardFormat}

	#   Fixed format complex values do not exist.
	#   ???  Can there be spaces between the paratheses?
	units = formunit(units, format.ufmt)
	isempty(format.vfmt) || return rpad_image(key, alignnumber(printfmt(format.vfmt, value), format),
		units, comment, format)
	value = "($(string(real(value))), $(string(imag(value))))"
	rpad_image(key, value, units, comment, format)
end

#  Format Value card for complex 32-bit float value.
function format_card(::Type{Value}, key::K, value::V, units, comment::C,
	format::F) where {K <: AbstractString,
	V <: Complex{Float32},
	C <: AbstractString, F <: CardFormat}

	#  Fixed format complex values do not exist.
	#  Replace (lowercase) 'e' and 'f' with (uppercase) 'E'.
	units = formunit(units, format.ufmt)
	isempty(format.vfmt) || return rpad_image(key, alignnumber(printfmt(format.vfmt, value), format),
		units, comment, format)
	real_ = replace(string(real(value)), "f" => "E", "e" => "E")
	imag_ = replace(string(imag(value)), "f" => "E", "e" => "E")
	#  Add paretheses.
	value = "($real_, $imag_)"
	rpad_image(key, value, units, comment, format)
end

#  Format Value card for all other complex float values.
function format_card(::Type{Value}, key::K, value::V, units, comment::C,
	format::F) where {K <: AbstractString,
	V <: Complex{<:AbstractFloat},
	C <: AbstractString, F <: CardFormat}

	#  Fixed format complex values do no exist.
	#  Replace (lowercase) 'e' with (uppercase) 'D'.
	units = formunit(units, format.ufmt)
	isempty(format.vfmt) || return rpad_image(key, alignnumber(printfmt(format.vfmt, value), format),
		units, comment, format)
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

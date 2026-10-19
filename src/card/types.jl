const ValueType = Union{AbstractString, Missing, Number}

abstract type AbstractCardType end
abstract type CommentCardType <: AbstractCardType end

struct Continue <: AbstractCardType end
struct End <: AbstractCardType end
struct Invalid <: AbstractCardType end
struct Value{T} <: AbstractCardType where T <: ValueType end

struct Comment <: CommentCardType end
struct Hierarch{T} <: CommentCardType where T <: ValueType end
struct History <: CommentCardType end

const COMMENTKEY = Dict(""=>Comment, "COMMENT"=>Comment, "HIERARCH"=>Comment, "HISTORY"=>History)

"""
	CardFormat(fixd, vbeg, vend, ampr, slsh, ubeg, uend, cbeg, cend)

Create a card format descriptor.
"""
mutable struct CardFormat
	#  The CardFormat descriptor provides a compact method to format a card by
	#  storing the begin and end index of the value, separator, units, and
	#  comment as an 8-bit integer, and the formats of the value and the units.
	fixd::Bool
	vbeg::Union{Int8, Tuple{Int8, Int8}}
	vend::Union{Int8, Tuple{Int8, Int8}}
	ampr::Int8
	slsh::Int8
	ubeg::Int8
	uend::Int8
	cbeg::Int8
	cend::Int8
	vfmt::String   # printf format of the number
	ufmt::String   # style of the units string
	function CardFormat(fixed::Bool = true, vbeg::I = 0, vend::I = 0,
		amper::I = 0, slash::I = 0, ubeg::I = 0, uend::I = 0, cbeg::I = 0,
		cend::I = 0) where I<:Integer

		begv = typeof(vbeg) <: Tuple ? Int8.(vbeg) : Int8(vbeg)
		endv = typeof(vend) <: Tuple ? Int8.(vend) : Int8(vend)
		new(Bool(fixed), begv, endv, Int8(amper), Int8(slash),
			Int8(ubeg), Int8(uend), Int8(cbeg), Int8(cend), "", "")
	end
end

"""
	Card(type, key, value, [units,] comment, format)
	Card([key, [value, [comment]]]; <keywords>)
	Card("HIERARCH", tokens, value, comment; <keywords>)

Create a card type, where type is Comment, Continue, End, Hierarch, History, Invalid, or
Value{T}.

# Arguments

- `key::AbstractString=""`: keyword string
- `value::U=missing`: keyword value, where U is Bool, Integer, AbstractFloat, a Complex number
  of integers or floats, Quantity of one of these, or String. Another type of value is an
  `ArgumentError`. The units of a Quantity are the units of the card, and are not part of the
  value.
- `tokens::AbstractString`: the tokens of a HIERARCH keyword, which are separated by spaces
- `comment::AbstractString=""`: comment string

# Keywords

- `append::Bool=false`: append an ampersand to the string value, which marks that the string is
  continued by a CONTINUE card. A string that is longer than the card (>68 characters) is
  always split into a card and CONTINUE cards, which are returned as a vector.
- `fixed::Bool=true`: use fixed format. A fixed-format number ends at byte 30, so a `Float64`
  that has more than 20 characters is written with fewer digits of the mantissa, which are
  truncated, e.g., `1.2345678901234567e-100` is written as `1.2345678901234D-100`. Use
  `fixed=false` to keep all of the digits.
- `slash::Integer=32`: index of the comment separator (/). A comment, and the units, must end at
  or before the end of the card.
- `lpad::Integer=1`: number of spaces before comment separator
- `rpad::Integer=1`: number of spaces after comment separator
- `upad::Integer=1`: number of spaces after the units string
- `truncate::Bool=true`: truncate a comment that is longer than the space at the end of the card,
  and the comment of the card is the truncated comment. If `false`, a comment that does not fit,
  and units that do not fit, are an `ArgumentError`. A comment is dropped if the comment
  separator is at the end of the card.
- `warn::Bool=true`: warn when a keyword longer than 8 characters creates a HIERARCH card
- `splitat::Union{Char, Nothing}=' '`: split a long string and its comment into the cards after
  the last character that fits, instead of splitting at any character if `nothing`
"""
struct Card{T <: AbstractCardType}
	key::AbstractString
	value::ValueType
	units::Any
	comment::AbstractString
	format::CardFormat
	function Card(T, key, value, units, comment, format)
		new{T}(key, value, units, comment, format)
	end
end

#  The units of a quantity are not part of the value of a card.
Card(T, key, value, comment::AbstractString, format::CardFormat) =
	Card(T, key, splitunits(value)..., comment, format)

typename(::Card{T}) where T = T

#  Two cards are equal if they are the same card image, i.e., a card is equal to the card that is
#  parsed from its image. A card is a scalar in a broadcast.
Base.:(==)(a::Card, b::Card) = repr(a) == repr(b)
Base.isequal(a::Card, b::Card) = a == b
Base.hash(card::Card, h::UInt) = hash(repr(card), hash(:Card, h))
Base.broadcastable(card::Card) = Ref(card)

function Base.copy(format::CardFormat)
	copied = CardFormat(format.fixd)
	copied.vbeg, copied.vend, copied.ampr, copied.slsh = format.vbeg, format.vend, format.ampr,
		format.slsh
	copied.ubeg, copied.uend, copied.cbeg, copied.cend = format.ubeg, format.uend, format.cbeg,
		format.cend
	copied.vfmt, copied.ufmt = format.vfmt, format.ufmt
	copied
end

#  The copy has its own format, since the format of a card is mutable.
Base.copy(card::Card) = Card(typename(card), card.key, card.value, card.units, card.comment,
	copy(card.format))

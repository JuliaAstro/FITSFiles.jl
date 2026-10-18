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
	Card("HIERARCH", key, [key, [value, [comment]]]; <keywords>)

Create a card type, where type is Comment, End, Hierarch, History, Invalid, or
Value{T}.

# Argments

- `key::AbstractString=""`: keyword string
- `value::U=missing`: keyword value, where U is Bool, Number, Quantity, or String. The units of
  a Quantity are the units of the card, and are not part of the value.
- `comment::AbstractString=""`: comment string

# Keywords

- `append::Bool=false`: append CONTINUE cards for long strings (>68 characters)
- `fixed::Bool=true`: use fixed format
- `slash::Integer=32`: index of comment separator (/)
- `lpad::Integer=1`: number of spaces before comment separator
- `rpad::Integer=1`: number of spaces after comment separator
- `upad::Integer=1`: number of spaces after the units string
- `truncate::Bool=true`: truncate comment at end of card
- `warn::Bool=true`: warn when a keyword longer than 8 characters creates a HIERARCH card
"""
struct Card{T <: AbstractCardType}  # make value a parameter
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

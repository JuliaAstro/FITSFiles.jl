####    Scaling and the undefined values of the arrays of the HDUs

#  These functions are of the values of an array, and not of an HDU: each type of HDU that has an array of numbers, i.e., the primary
#  HDU, the IMAGE extension, and random groups, has its own field type and its own functions of the scale of the array, which
#  use them

const MISSTYPE = (UInt8, Int16, Int32, Int64)
#  The unsigned integers and the signed bytes are stored as the integers of the same size with an offset in
#  BZERO (Table 11 of the standard): the type of the array => the type of the physical values and BZERO.
const OFFSETTYPE = Dict(Int16 => (UInt16, 2^15), Int32 => (UInt32, 2^31), Int64 => (UInt64, UInt64(2)^63),
	UInt8 => (Int8, -2^7))
#  The type of the array of the physical type, which is the key of OFFSETTYPE
const RAWTYPE = Dict(physical => raw for (raw, (physical, _)) in OFFSETTYPE)
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

#  The type of the physical values of an array of the stored type `type` that has the offset BZERO of Table 11 of
#  the standard and the default BSCALE, i.e., a UInt16 for an Int16 and a BZERO of 32768, or nothing.
function offsettype(type::Type, scale::Real, zero::Real)
    haskey(OFFSETTYPE, type) && scale == 1 && zero == OFFSETTYPE[type][2] ? OFFSETTYPE[type][1] : nothing
end

#  The value of the other type of the offset convention: the stored value for the physical value, and the physical
#  value for the stored value. The offset is a flip of the most significant bit.
offsetvalue(::Missing, ::Type) = missing
function offsetvalue(x::Integer, ::Type{T}) where T<:Integer
    U = unsigned(typeof(x))
    reinterpret(T, reinterpret(U, x) ⊻ (one(U) << (8sizeof(U) - 1)))
end

#  An N-dimensional array of zeros of the type of BITPIX, or missing if the data has no axes.
zerosarray(format::DataFormat) = length(format.shape) > 0 ? zeros(format.type, format.shape) : missing

#  The physical values of the stored values `data` of the type `type`, which are scaled, or the values of the offset convention of Table 11
#  of the standard.
function physical(data, type::Type, scale::Real, zero::Real)
    T = offsettype(type, scale, zero)
    isnothing(T) ? scaled(data, scale, zero) : offsetvalue.(data, T)
end

#  The stored value of a physical value, which is (value - BZERO)/BSCALE (Eq. 3 of the standard), rounded to the
#  nearest integer for integer data of the type `type`. An undefined value, which is missing, or NaN for integer data that has a BLANK,
#  `miss`, is missing. The stored value is checked, if `check` is true, by applying the scale and the zero to it, with muladd, which
#  must give the physical value again: exactly for integer data, whose stored value is rounded, and to the precision
#  of the type for floating-point data. A value that cannot be stored without a change is an error.
#  The keywords of the scale and the zero, which are named in an error, are BSCALE and BZERO unless `keys` are given.
storedvalue(::Missing, type::Type, scale::Real, zero::Real, miss, check::Bool = true; keys = ("BSCALE", "BZERO")) = missing
function storedvalue(x::Real, type::Type, scale::Real, zero::Real, miss, check::Bool = true; keys = ("BSCALE", "BZERO"))
    if isnan(x)
        type <: AbstractFloat && return type(x)
        isnothing(miss) && throw(ArgumentError(
            "NaN cannot be written as integer data that does not have a BLANK keyword."))
        return missing
    end
    scale == 0 && throw(ArgumentError(
        "The values cannot be written as stored values, since $(keys[1]) is 0."))
    W = promote_type(typeof(scale), typeof(zero), Float64)
    value = (W(x) - W(zero)) / W(scale)
    if type <: AbstractFloat
        stored = type(value)
    else
        rounded = round(value)
        typemin(type) <= rounded <= typemax(type) || throw(ArgumentError(
            "The value $x is not in the range of the $type data that $(keys[1]) $scale and $(keys[2]) " *
            "$zero describe: its stored value $rounded is not from $(typemin(type)) to $(typemax(type))."))
        stored = type(rounded)
    end
    if check && isfinite(x)
        #  The physical value of the stored value, in the type of the value, as the data are read
        again = muladd(W(scale), W(stored), W(zero))
        again = x isa AbstractFloat ? typeof(x)(again) : again
        same = type <: AbstractFloat ? isapprox(again, x; rtol = eps(type)) : again == x
        same || throw(ArgumentError(
            "The value $x cannot be stored as $type data with $(keys[1]) $scale and $(keys[2]) $zero: " *
            "the nearest stored value, $stored, is the value $again. Use check = false to write the stored value."))
    end
    stored
end

#  The stored values of the data, which are the values of the type `type` of the HDU (BITPIX): the data that are the
#  physical values of the offset convention of Table 11 are the stored values with the offset, and the data of
#  another type are the physical values that are read with the scale and the zero, so they are inverted. The data of the
#  type of the HDU are the stored values, even when the scale and the zero are not 1 and 0, i.e., they were read unscaled, unless the
#  array is a `ScaledArray`, which is the physical values of floating-point stored values.
function storedvalues(data::AbstractArray, type::Type, scale::Real, zero::Real, miss; check::Bool = true)
    kind = nonmissingtype(eltype(data))
    offset = offsettype(type, scale, zero)
    if !isnothing(offset) && kind == offset
        offsetvalue.(data, type)
    elseif data isa ScaledArray
        #  The data are the physical values of the scale and the zero that they have, which are those of the header
        (data.scale, data.zero) == (scale, zero) || throw(ArgumentError("The scale and the zero of the data, " *
            "$(data.scale) and $(data.zero), are not the BSCALE and the BZERO of the header, $scale and $zero."))
        map(x -> storedvalue(x, type, scale, zero, miss, check), data)
    elseif kind != type
        map(x -> storedvalue(x, type, scale, zero, miss, check), data)
    else
        data
    end
end

#  Set the card of the key to the value of the scale or the zero of the data, which the header has, if it is not the default value
#  and the header does not have it. A value that the header has and is not the value of the data is set, with a warning.
function setscalecard!(cards::Cards, key::AbstractString, value::Number, default::Number)
    if haskey(cards, key)
        cards[key] == value || (cards[key] = value; @warn "$key set to $value, the value of the scale of the data.")
    elseif value != default
        push!(cards, Card(key, value))
    end
    cards
end

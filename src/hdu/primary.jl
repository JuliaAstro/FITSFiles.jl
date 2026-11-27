####    Primary HDU functions

"""
	Primary header-data unit (HDU)

A Primary HDU consists of a vector of cards and optionally a multidimensional
array (<=999 dimensions). The Primary HDU is the first HDU in a vector of HDUs.
"""
struct Primary <: AbstractHDU end

#  The data of a Primary HDU are an array of numbers, or are missing, and its header begins with SIMPLE = T
fromdata(::Type{Primary}, data) = ismissing(data) || nonmissingtype(eltype(data)) <: Real
frommandatory(::Type{Primary}, mankeys) = !haskey(mankeys, "XTENSION") && get(mankeys, "SIMPLE", nothing) === true
registerhdu!(Primary)

#  The mandatory and reserved keywords of the HDU (see `getreservedkeys`)
union!(MANDATORYKEYS, ["SIMPLE"])
union!(RESERVEDKEYS, ["EXTEND", "BLOCKED", "BSCALE", "BZERO", "BUNIT", "BLANK", "DATAMAX", "DATAMIN"])

#  The keywords of the cards that are given with the data of an HDU that is made are verified (see `verifycardkeys`)
verifycards!(::Type{Primary}, cards::Cards, mankeys::AbstractDict, reskeys::AbstractDict, format::DataFormat) =
    verifycardkeys(Primary, cards, mankeys, reskeys)

function verify!(::Type{Primary}, cards::Cards, mankeys::AbstractDict, reskeys::AbstractDict)
    cards = invoke(verify!, Tuple{Type{<:AbstractHDU}, Cards, AbstractDict, AbstractDict}, Primary, cards,
        mankeys, reskeys)
    verifyarray(Primary, mankeys, reskeys)
    #  BITPIX and NAXIS describe the data, so the data cannot be read without them (Sect. 4.4.1.1). A header that is being
    #  created does not have the keywords yet, and is arranged when it is created.
    for key in ("BITPIX", "NAXIS")
        !haskey(mankeys, "SIMPLE") || haskey(mankeys, key) || throw(ArgumentError(
            "$key is missing, but it is a mandatory keyword of the primary header (Sect. 4.4.1.1)."))
    end
    verifyprimarykeys(reskeys)
    verifygroups(mankeys)
    verifyprimary(cards, mankeys)
end

#  The signature of random groups is GROUPS of T and NAXIS1 of 0 (Sect. 6.1.1). A header that has one of them and not the other
#  is not random groups, and is read as a primary array, whose data are the NAXISn, and not the groups of PCOUNT parameters
#  and an array, so PCOUNT and GCOUNT are not used.
function verifygroups(mankeys::AbstractDict)
    verifylogical(mankeys, r"^GROUPS$")
    naxis1 = get(mankeys, "NAXIS1", nothing)
    if get(mankeys, "GROUPS", nothing) === true && naxis1 != 0
        @warn "GROUPS is T, which says that the HDU has random groups, but NAXIS1 is $(isnothing(naxis1) ? "absent" : naxis1), " *
            "and not 0 (Sect. 6.1.1), so it is read as a primary array, and PCOUNT and GCOUNT are not used."
    elseif get(mankeys, "GROUPS", nothing) === false && naxis1 == 0 && get(mankeys, "NAXIS", 0) > 1
        @warn "NAXIS1 is 0, which is the signature of random groups, but GROUPS is F (Sect. 6.1.1), so it is read as a primary " *
            "array without data, and PCOUNT and GCOUNT are not used."
    end
end

#  A primary array has the NAXISn values, and not the PCOUNT parameters and the GCOUNT groups of an extension or of random
#  groups, which the primary header does not have (Sect. 4.4.1.1).
function DataFormat(::Type{Primary}, data::Missing, mankeys::Dict{S, V}) where
    {S<:AbstractString, V<:ValueType}

    type  = BITS2TYPE[get(mankeys, "BITPIX", 32)]
    shape = datasize(mankeys, 1)
    leng  = isempty(shape) ? 0 : prod(shape)
    DataFormat(type, leng, shape, 0, 1, 0)
end

#  The keywords that are in the primary header only (Sects. 4.4.2.1 and 4.4.2.6, and App. K): EXTEND and BLOCKED are
#  logicals, and INHERIT must not appear.
function verifyprimarykeys(reskeys::AbstractDict)
    verifylogical(reskeys, r"^(EXTEND|BLOCKED)$")
    haskey(reskeys, "INHERIT") && @warn "INHERIT must not appear in the primary header (Appendix K). It is read as it is."
end

function verify!(::Type{Primary}, cards::Cards, format::DataFormat,
    mankeys::AbstractDict)

    !get(mankeys, "SIMPLE", true) && @warn "Primary HDU is nonconformant."
    verifyshape!(cards, mankeys, format)
end

function createcards!(::Type{Primary}, format::DataFormat,
    fields::AbstractField, cards::Cards; kwds...)

    offsetcards!(arrangecards!(cards, ["SIMPLE" => true; shapekeys(Primary, format)]), fields)
end

"""
	verifyprimary(cards, mankeys)

Warn if the header of a primary HDU does not begin with SIMPLE, BITPIX, NAXIS, and the NAXISn keywords, in
that order and with no other keyword between them (Sect. 4.4.1.1 of the standard), or if the values of
these keywords are not in fixed format (Sect. 4.4.1), and return the cards unchanged. The file is read and
written as it is, so the cards are not reordered or reformatted. The NAXIS value of `mankeys` must be
valid, as `verifyarray` checks.
"""
function verifyprimary(cards::Cards, mankeys::AbstractDict)
	#  A header that is being created does not have the keywords yet, and is arranged when it is created.
	haskey(mankeys, "SIMPLE") || return cards
	required = vcat(["SIMPLE", "BITPIX", "NAXIS"], ["NAXIS$j" for j = 1:get(mankeys, "NAXIS", 0)])
	verifyorder(cards, required)
	verifyfixed(cards, required)
end

"""
    PrimaryField(type, zero, scale, miss, dmin, dmax)

Primary array element descriptor
"""
struct PrimaryField <: AbstractField
    "The type of the array"
    type::Type
    "The offset of the array"
    zero::AbstractFloat
    "The scale of the array"
    scale::AbstractFloat
    "The value representing a missing value"
    miss::Union{Integer, Nothing}
    "The minimum display value of the array"
    dmin::Union{AbstractFloat, Nothing}
    "The maximum display value of the array"
    dmax::Union{AbstractFloat, Nothing}
end

#  The keywords of an array, which the HDU verifies: BITPIX is one of the values of Table 8, NAXIS is from 0 to 999 and each
#  NAXISn is a non-negative integer (Sects. 4.4.1.1), and the keywords that describe the array (Sect. 4.4.2.5): BLANK is an
#  integer and only for integer data, BSCALE and BZERO are numbers, DATAMIN and DATAMAX are floating-point numbers, and BUNIT is a
#  units string.
function verifyarray(::Type{Primary}, mankeys::AbstractDict, reskeys::AbstractDict)
    verifybitpix(mankeys)
    verifyvalue(mankeys, "NAXIS", 0:MAXAXES, "an integer from 0 to $MAXAXES")
    verifyaxes(mankeys)
    verifysize(Primary, mankeys)
    verifyarraykeys(Primary, mankeys, reskeys)
end

function verifyarraykeys(::Type{Primary}, mankeys::AbstractDict, reskeys::AbstractDict)
    verifyblank(Primary, mankeys, reskeys)
    verifynumber(reskeys, r"^(BSCALE|BZERO|DATAMIN|DATAMAX)$")
    verifyfloat(reskeys, r"^(DATAMIN|DATAMAX)$")
    verifystring(reskeys, r"^BUNIT$")
    verifyunit(reskeys, r"^BUNIT$")
end

#  The BLANK keyword of an array is an integer, and is for integer data only (Sect. 4.4.2.5).
function verifyblank(::Type{Primary}, mankeys::AbstractDict, reskeys::AbstractDict)
    verifyinteger(reskeys, r"^BLANK$")
    haskey(reskeys, "BLANK") && get(mankeys, "BITPIX", 8) < 0 && @warn "BLANK is for integer data " *
        "(a positive BITPIX) only (Sect. 4.4.2.5), so it is not used."
end

#  The size of the data array, |BITPIX|/8 × NAXIS1 × ... × NAXISm bytes, is at most the largest integer, so
#  that the array can be read and indexed (Eq. 1 of the standard).
function verifysize(::Type{Primary}, mankeys::AbstractDict)
    N, bits = get(mankeys, "NAXIS", 0), get(mankeys, "BITPIX", 0)
    N < 1 && return
    sizes = [BigInt(mankeys["NAXIS$j"]) for j = 1:N]
    nbytes = abs(bits) ÷ 8 * prod(sizes)
    nbytes > typemax(Int) && throw(ArgumentError("The data array is too large: " *
        "$(abs(bits) ÷ 8) bytes × $(join(sizes, " × ")) values is more than $(typemax(Int)) bytes."))
end

function DataFormat(::Type{Primary}, data::AbstractArray, mankeys::Dict{S, V}) where
    {S<:AbstractString, V<:ValueType}

    #  The type of the stored values, which excludes the undefined (missing) ones, and is the integer of the same
    #  size for the physical types of Table 11 (e.g., an Int16 for a UInt16)
    type  = nonmissingtype(eltype(data))
    type  = storedtype(type)
    leng  = length(data)
    shape = size(data)
    param = get(mankeys, "PCOUNT", 0)
    group = get(mankeys, "GCOUNT", 1)
    heap  = 0
    DataFormat(type, leng, shape, param, group, heap)
end

function FieldFormat(::Type{Primary}, format::DataFormat, reskeys::Dict{S, V},
    data::Union{Missing, AbstractArray}) where {S<:AbstractString, V<:ValueType}

    #  The offset of the data of a physical type of Table 11 is its BZERO, if the header has none
    offset = data isa AbstractArray && haskey(RAWTYPE, nonmissingtype(eltype(data))) ?
        OFFSETTYPE[RAWTYPE[nonmissingtype(eltype(data))]][2] : 0.0f0
    zero_ = leastfloat(get(reskeys, "BZERO", offset))
    scale = leastfloat(get(reskeys, "BSCALE", 1.0f0))
    miss  = format.type in MISSTYPE ? get(reskeys, "BLANK", nothing) : nothing
    dmin  = leastfloat(get(reskeys, "DATAMIN", nothing))
    dmax  = leastfloat(get(reskeys, "DATAMAX", nothing))
    PrimaryField(format.type, zero_, scale, miss, dmin, dmax)
end

createdata(::Type{Primary}, format::DataFormat, ::PrimaryField; kwds...) = zerosarray(format)

#  The BZERO card of the offset convention, if the header does not have one.
function offsetcards!(cards::Cards, fields::PrimaryField)
    if !isnothing(offsettype(fields.type, fields.scale, fields.zero)) && !haskey(cards, "BZERO")
        push!(cards, Card("BZERO", OFFSETTYPE[fields.type][2]))
    end
    cards
end

function Base.read(io::IO, ::Type{Primary}, format::DataFormat,
    fields::PrimaryField; scale::Bool = true, kwds...)

    data = read(io, format, fields)
    scale || return data
    #  The physical values of floating-point stored values have the type of the stored values, so the array says that they are
    values = physical(data, fields.type, fields.scale, fields.zero)
    physicalfloat(fields) ? ScaledArray(values, fields.scale, fields.zero) : values
end

#  Are the physical values of the data the same type as the stored values, which are floating-point? They are if the data are not scaled
#  by a BSCALE of 1 and a BZERO of 0.
physicalfloat(fields::PrimaryField) = fields.type <: AbstractFloat && !(fields.scale == 1 && fields.zero == 0)

function Base.write(io::IO, ::Type{Primary}, data::Missing, format::DataFormat,
    fields::PrimaryField; kwds...)
end

function Base.write(io::IO, ::Type{Primary}, data::AbstractArray,
    format::DataFormat, fields::PrimaryField; kwds...)

    if format.leng > 0
        write(io, data, fields; kwds...)
        padblock(io, format)
    end
end

function Base.read(io::IO, format::DataFormat, fields::PrimaryField)

    M, N, shape = sizeof(format.type), format.leng, format.shape
    #  Or preallocate array and use read!
    data = reshape(ntoh.(
        reinterpret(format.type, readbytes(io, M*N))), shape)
    #  The undefined values are the raw ones equal to BLANK (Sect. 4.4.2.5)
    setmissing(data, fields.miss)
end

function Base.write(io::IO, data::AbstractArray, fields::PrimaryField; check::Bool = true, kwds...)
    data = storedvalues(data, fields.type, fields.scale, fields.zero, fields.miss; check)
    #  The undefined values are written as BLANK, or NaN for floating-point data
    data = unsetmissing(data, fields.miss, fields.type)
    n = Base.write(io, hton.(reshape(data, :)))
end

#  The BSCALE and BZERO cards of data that are a ScaledArray, which have the scale and the zero of the data
function scalecards!(::Type{Primary}, cards::Cards, data::ScaledArray)
    setscalecard!(cards, "BSCALE", data.scale, 1)
    setscalecard!(cards, "BZERO", data.zero, 0)
end

#  The keywords BITPIX and NAXIS, and NAXISn of the shape of the data of the primary HDU
function shapekeys(::Type{Primary}, format::DataFormat)
    required = Pair{String, Any}["BITPIX" => TYPE2BITS[format.type], "NAXIS" => length(format.shape)]
    for (j, n) in enumerate(format.shape) push!(required, "NAXIS$j" => n) end
    required
end

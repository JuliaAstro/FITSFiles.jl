####    Primary HDU functions

function verify!(::Type{Primary}, cards::Cards, mankeys::AbstractDict, reskeys::AbstractDict)
    cards = invoke(verify!, Tuple{Type{<:AbstractHDU}, Cards, AbstractDict, AbstractDict}, Primary, cards,
        mankeys, reskeys)
    verifyarray(mankeys, reskeys)
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
    fields::ImageField, cards::Cards; kwds...)

    offsetcards!(arrangecards!(cards, ["SIMPLE" => true; shapekeys(format)]), fields)
end

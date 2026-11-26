####    Primary HDU functions

function verify!(::Type{Primary}, cards::Cards, mankeys::AbstractDict, reskeys::AbstractDict)
    cards = invoke(verify!, Tuple{Type{<:AbstractHDU}, Cards, AbstractDict, AbstractDict}, Primary, cards,
        mankeys, reskeys)
    verifyarray(mankeys, reskeys)
    #  The keywords that are in the primary header only (Sects. 4.4.2.1 and 4.4.2.6, and App. K)
    verifylogical(reskeys, r"^(EXTEND|BLOCKED)$")
    haskey(reskeys, "INHERIT") && @warn "INHERIT must not appear in the primary header (Appendix K). It is read as it is."
    verifyprimary(cards, mankeys)
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

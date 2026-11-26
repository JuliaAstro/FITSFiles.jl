####    Primary HDU functions

function verify!(::Type{Primary}, cards::Cards, mankeys::AbstractDict, reskeys::AbstractDict)
    cards = invoke(verify!, Tuple{Type{<:AbstractHDU}, Cards, AbstractDict, AbstractDict}, Primary, cards,
        mankeys, reskeys)
    verifyarray(mankeys, reskeys)
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

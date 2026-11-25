####    Primary HDU functions

function verify!(::Type{Primary}, cards::Cards, format::DataFormat,
    mankeys::AbstractDict)

    !get(mankeys, "SIMPLE", true) && @warn "Primary HDU is nonconformant."
    verifyshape!(cards, mankeys, format)
end

function createcards!(::Type{Primary}, format::DataFormat,
    fields::ImageField, cards::Cards; kwds...)

    arrangecards!(cards, ["SIMPLE" => true; shapekeys(format)])
end

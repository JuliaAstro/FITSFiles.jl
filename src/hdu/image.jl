####    Image HDU functions

function verify!(::Type{Image}, cards::Cards, format::DataFormat,
    mankeys::AbstractDict)

    verifyshape!(cards, mankeys, format)
end

function createcards!(::Type{Image}, format::DataFormat,
    fields::ImageField, cards::Cards; kwds...)

    arrangecards!(cards, ["XTENSION" => "IMAGE"; shapekeys(format)])
end

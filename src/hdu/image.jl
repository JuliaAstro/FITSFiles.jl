####    Image HDU functions

function verify!(::Type{Image}, cards::Cards, mankeys::AbstractDict, reskeys::AbstractDict)
    cards = invoke(verify!, Tuple{Type{<:AbstractHDU}, Cards, AbstractDict, AbstractDict}, Image, cards,
        mankeys, reskeys)
    verifyarray(mankeys, reskeys)
    #  An IMAGE extension has a single array and no parameters (Sect. 7.1.1)
    verifyvalue(mankeys, "PCOUNT", 0:0, "the integer 0")
    verifyvalue(mankeys, "GCOUNT", 1:1, "the integer 1")
    cards
end

function verify!(::Type{Image}, cards::Cards, format::DataFormat,
    mankeys::AbstractDict)

    verifyshape!(cards, mankeys, format)
end

function createcards!(::Type{Image}, format::DataFormat,
    fields::ImageField, cards::Cards; kwds...)

    arrangecards!(cards, ["XTENSION" => "IMAGE"; shapekeys(format)])
end

####    Image HDU functions

#  The mandatory keywords of the header of an IMAGE extension, in the order that they must have (Sect. 7.1.1, Table 13)
imagekeys(mankeys::AbstractDict) =
    vcat(["XTENSION", "BITPIX", "NAXIS"], ["NAXIS$j" for j = 1:get(mankeys, "NAXIS", 0)], ["PCOUNT", "GCOUNT"])

function verify!(::Type{Image}, cards::Cards, mankeys::AbstractDict, reskeys::AbstractDict)
    #  A header that is being created does not have the keywords yet, and is arranged when it is created.
    created = !haskey(mankeys, "XTENSION")
    #  BITPIX and NAXIS describe the data, so the data cannot be read without them (Sect. 7.1.1)
    for key in ("BITPIX", "NAXIS")
        created || haskey(mankeys, key) || throw(ArgumentError(
            "$key is missing, but it is a mandatory keyword of an IMAGE extension (Sect. 7.1.1)."))
    end
    cards = invoke(verify!, Tuple{Type{<:AbstractHDU}, Cards, AbstractDict, AbstractDict}, Image, cards,
        mankeys, reskeys)
    verifyarray(mankeys, reskeys)
    #  An IMAGE extension has a single array and no parameters (Sect. 7.1.1)
    verifyvalue(mankeys, "PCOUNT", 0:0, "the integer 0")
    verifyvalue(mankeys, "GCOUNT", 1:1, "the integer 1")
    created && return cards
    #  PCOUNT and GCOUNT have the values 0 and 1, so the data can be read without them
    for (key, value) in ("PCOUNT" => 0, "GCOUNT" => 1)
        haskey(mankeys, key) || @warn "$key is missing, but it is a mandatory keyword of an IMAGE extension " *
            "(Sect. 7.1.1), and has the value $value. It is read as $value."
    end
    #  The mandatory keywords are the first keywords, in order and in fixed format (Sects. 4.4 and 7.1.1)
    #  (a keyword that is missing is warned about above, and is not in the order)
    required = filter(key -> haskey(mankeys, key), imagekeys(mankeys))
    verifyorder(cards, required; section = "Sects. 4.4.1.2 and 7.1.1",
        names = "XTENSION, BITPIX, NAXIS, the NAXISn, PCOUNT, and GCOUNT")
    verifyfixed(cards, required)
    cards
end

function verify!(::Type{Image}, cards::Cards, format::DataFormat,
    mankeys::AbstractDict)

    verifyshape!(cards, mankeys, format)
end

function createcards!(::Type{Image}, format::DataFormat,
    fields::ImageField, cards::Cards; kwds...)

    #  The mandatory keywords are XTENSION, BITPIX, NAXIS, the NAXISn, PCOUNT of 0, and GCOUNT of 1 (Sect. 7.1.1)
    offsetcards!(arrangecards!(cards, ["XTENSION" => "IMAGE"; shapekeys(format); "PCOUNT" => 0; "GCOUNT" => 1]), fields)
end

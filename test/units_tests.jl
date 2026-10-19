@testset "Units" begin
    #  the value of a card with its units.
    withunits(card) = isnothing(card.units) ? card.value : card.value * card.units

    ####    Test the ASCII FITS strings of units    ####

    #  the units are written as ASCII strings of the FITS standard, i.e., Tables 3, 4, and 5.
    for (unit, text) in ((u"m", "m"), (u"km/s", "km s-1"), (u"μm", "um"), (u"nm", "nm"), (u"Å", "Angstrom"),
                         (u"°", "deg"), (u"Ω", "Ohm"), (u"kΩ", "kOhm"), (u"arcsecond", "arcsec"),
                         (u"arcminute", "arcmin"), (u"Msun", "solMass"), (u"Lsun", "solLum"),
                         (u"Rsun", "solRad"), (u"kg*m^2/s^2", "kg m2 s-2"), (u"m^(1/2)", "m**(1/2)"),
                         (u"m^(-3/2)", "m**(-3/2)"), (u"pc", "pc"), (u"Mpc", "Mpc"), (u"Jy", "Jy"),
                         (u"mJy", "mJy"), (u"yr", "yr"), (u"hr", "h"), (u"minute", "min"), (u"d", "d"),
                         (u"ly", "lyr"), (u"mas", "mas"), (u"keV", "keV"), (u"erg", "erg"), (u"GHz", "GHz"),
                         (u"Jy/sr", "Jy sr-1"), (u"km/s/Mpc", "km Mpc-1 s-1"), (u"cm^-3", "cm-3"),
                         (u"s^-1", "s-1"), (u"AU", "AU"), (u"Gauss", "G"), (u"K", "K"), (u"rad", "rad"))
        @test FITSFiles.formunit(unit) == text
        @test isascii(FITSFiles.formunit(unit))
    end

    #  a quantity without units has an empty string.
    @test FITSFiles.formunit(Unitful.NoUnits) == ""

    #  an affine unit has no name in the FITS standard, and is an error instead of the units of its scale.
    @test_throws ArgumentError FITSFiles.formunit(u"°C")
    @test_throws "has no FITS name" FITSFiles.formunit(u"°F")
    @test_throws ArgumentError Card("KEY", 20.0 * u"°C", "c")

    ####    Test the units of a card    ####

    #  the units of a card value are written in ASCII at the beginning of the comment.
    for (value, text) in ((1.5f0 * u"km/s", "[km s-1] c"), (5 * u"°", "[deg] c"), (2.5 * u"Å", "[Angstrom] c"),
                          (3.0f0 * u"μm", "[um] c"), ((1.0f0 + 2.0f0im) * u"Ω", "[Ohm] c"),
                          (2.5 * u"erg/s/cm^2/Å", "[Angstrom-1 erg cm-2 s-1] c"),
                          (2.5f0 * u"Msun", "[solMass] c"), (1 * u"arcsecond", "[arcsec] c"))
        card = Card("KEY", value, "c")
        @test isascii(repr(card))
        @test occursin("/ $text", repr(card))
        @test parse(Card, repr(card); units = false).comment == text
        card = Card("HIERARCH", "ESO A", value, "c")
        @test isascii(repr(card))
        @test occursin("/ $text", repr(card))
        @test parse(Card, repr(card); units = false).comment == text
    end

    #  the units are written without a comment, with other padding, and when the value is set.
    @test parse(Card, repr(Card("KEY", 5 * u"°")); units = false).comment == "[deg]"
    @test parse(Card, repr(Card("KEY", 5 * u"°", "c"; upad = 3)); units = false).comment == "[deg]   c"
    @test isascii(repr(FITSFiles.setvalue!(Card("KEY", 5), 5.0f0 * u"Å")))
    @test parse(Card, repr(FITSFiles.setvalue!(Card("KEY", 5, "c"), 5.0f0 * u"Å")); units = false).comment == "[Angstrom] c"
    @test parse(Card, repr(FITSFiles.setvalue!(Card("HIERARCH", "ESO A", 5, "c"), 5.0f0 * u"°")); units = false).comment == "[deg] c"

    #  the value does not change.
    @test withunits(parse(Card, repr(Card("KEY", 1.5f0 * u"km/s", "c")))) === 1.5f0 * u"km/s"
    @test parse(Card, repr(Card("KEY", 1.5f0 * u"km/s", "c")); units = false).value === 1.5f0
    ####    Test the parsing of FITS unit strings    ####

    #  the units of the FITS standard, with the powers and the separators of Table 6.
    for (text, unit) in (("m", u"m"), ("km s-1", u"km/s"), ("km/s", u"km/s"), ("km/s/Mpc", u"km/s/Mpc"),
                         ("m2", u"m^2"), ("m**2", u"m^2"), ("m^2", u"m^2"), ("m**-2", u"m^-2"),
                         ("m-2", u"m^-2"), ("m+2", u"m^2"), ("m**(1/2)", u"m^(1/2)"), ("m^(3/2)", u"m^(3/2)"),
                         ("m**(1.5)", u"m^(3/2)"), ("m**(-1/2)", u"m^(-1/2)"), ("kg m2 s-2", u"kg*m^2/s^2"),
                         ("kg.m.s-2", u"kg*m/s^2"), ("kg*m/s**2", u"kg*m/s^2"), ("kg m s-2", u"kg*m/s^2"),
                         ("um", u"μm"), ("us", u"μs"), ("u", u"u"), ("deg", u"°"), ("arcsec", u"arcsecond"),
                         ("arcmin", u"arcminute"), ("Angstrom", u"Å"), ("Ohm", u"Ω"), ("kOhm", u"kΩ"),
                         ("h", u"hr"), ("min", u"minute"), ("d", u"d"), ("a", u"a"), ("yr", u"yr"),
                         ("solMass", u"Msun"), ("solLum", u"Lsun"), ("solRad", u"Rsun"), ("lyr", u"ly"),
                         ("pc", u"pc"), ("kpc", u"kpc"), ("Jy", u"Jy"), ("mJy", u"mJy"), ("G", u"Gauss"),
                         ("barn", u"b"), ("eV", u"eV"), ("keV", u"keV"), ("mas", u"mas"), ("Hz", u"Hz"),
                         ("GHz", u"GHz"), ("H", u"H"), ("K", u"K"), ("rad", u"rad"), ("erg", u"erg"),
                         ("erg/s/cm**2/Angstrom", u"erg/s/cm^2/Å"), ("(m/s)**2", u"m^2/s^2"),
                         ("sqrt(m)", u"m^(1/2)"), ("m (s)", u"m*s"), (" m  s ", u"m*s"),
                         ("m/s*K", u"m/s*K"), ("m/s/K", u"m/s/K"), ("h2", u"hr^2"))
        @test FITSFiles.parseunit(text) == unit
    end

    #  the units of counting that are not in Unitful.
    for (text, name) in (("pix", "pix"), ("pixel", "pix"), ("ct", "ct"), ("count", "ct"), ("ph", "ph"),
                         ("photon", "ph"), ("adu", "adu"), ("beam", "beam"), ("chan", "chan"),
                         ("bin", "bin"), ("voxel", "voxel"), ("bit", "bit"), ("byte", "byte"), ("kbit", "kbit"))
        @test FITSFiles.formunit(FITSFiles.parseunit(text)) == name
    end
    @test FITSFiles.formunit(FITSFiles.parseunit("Jy/beam")) == "beam-1 Jy"
    @test FITSFiles.formunit(FITSFiles.parseunit("ct/s")) == "ct s-1"
    @test ustrip(uconvert(FITSFiles.parseunit("bit"), 1 * FITSFiles.parseunit("byte"))) == 8
    @test_throws Unitful.DimensionError 1 * FITSFiles.parseunit("pix") + 1 * FITSFiles.parseunit("ct")

    #  a scale factor returns a quantity.
    for (text, scale, expected) in (("10**3 m", 1000.0, u"m"), ("10^-3 Jy", 0.001, u"Jy"), ("10+3 m", 1000.0, u"m"),
                                    ("10-3 s", 0.001, u"s"), ("10**3 km s-1", 1000.0, u"km/s"))
        quantity = FITSFiles.parseunit(text)
        @test ustrip(quantity) ≈ scale
        @test Unitful.unit(quantity) == expected
    end

    #  a division may begin the string, and a power may be a number in parentheses without ** or ^.
    @test FITSFiles.parseunit("/m3") == u"m^-3"
    @test FITSFiles.parseunit("/ m") == u"m^-1"
    @test FITSFiles.parseunit("/m3 s") == u"s/m^3"
    @test FITSFiles.parseunit("/(m s)") == u"m^-1*s^-1"
    @test FITSFiles.parseunit("m(2)") == u"m^2"
    @test FITSFiles.parseunit("m(-2)") == u"m^-2"
    @test FITSFiles.parseunit("m(1.5)") == u"m^(3//2)"
    @test FITSFiles.parseunit("m(3/2)") == u"m^(3//2)"
    @test FITSFiles.parseunit("J(m s)") === nothing
    @test FITSFiles.parseunit("m(3/") === nothing
    @test FITSFiles.parseunit("m (2)") === nothing

    #  a string that is not a unit string, or has an unknown unit, is nothing.
    for text in ("", " ", "foo", "m/", "/", "m**", "m-", "m 2", "m s-", "log(m)", "ln(m)", "exp(m)", "mag", "D",
                 "Sun", "c", "%", "m/s2/", "m**(1/", "m**(a)", "(m", "m)", "m s)", "10", "10**", "10**3", "m,s",
                 "m[s]", "m_s", "1 m", "m\$s", "m;s", "pc.", ".pc", "Mpc/", "m s -1", "k", "da")
        @test FITSFiles.parseunit(text) === nothing
    end

    #  the name of a unit is not a physical constant, a Julia name, or an expression.
    for text in ("h*c", "c0", "ħ", "pi", "Inf", "NaN", "e", "im", "println", "1+1", "m^2+1", "u\"m\"")
        @test FITSFiles.parseunit(text) === nothing
    end

    #  the units of the standard are written and parsed as the same units.
    for unit in (u"m", u"km/s", u"μm", u"Å", u"°", u"Ω", u"kΩ", u"arcsecond", u"arcminute", u"Msun", u"Lsun", u"Rsun",
                 u"kg*m^2/s^2", u"m^(1/2)", u"m^(-3/2)", u"pc", u"Mpc", u"Jy", u"mJy", u"yr", u"hr", u"minute", u"d",
                 u"ly", u"mas", u"keV", u"erg", u"GHz", u"Jy/sr", u"km/s/Mpc", u"cm^-3", u"s^-1", u"AU", u"Gauss", u"K",
                 u"rad", u"erg/s/cm^2/Å")
        @test FITSFiles.parseunit(FITSFiles.formunit(unit)) == unit
    end

    ####    Test the units that are read from a comment    ####

    #  the units at the beginning of the comment of a number are the units of the value.
    for (img, value, comment) in (("K       = 5 / [km s-1] a velocity", 5 * u"km/s", "a velocity"),
                                  ("K       = 5 / [km/s]", 5 * u"km/s", ""),
                                  ("K       = 1.5 / [m] c", 1.5f0 * u"m", "c"),
                                  ("K       = 1.2345678901D0 / [pc]   c", 1.2345678901 * u"pc", "c"),
                                  ("K       = (1.0, 2.0) / [Jy] c", (1.0f0 + 2.0f0im) * u"Jy", "c"),
                                  ("K       = 1200. / [s] exposure time", 1200.0f0 * u"s", "exposure time"),
                                  ("K       = 5 / [Angstrom-1 erg cm-2 s-1] flux", 5 * u"erg/s/cm^2/Å", "flux"),
                                  ("K       = 5 / [pix] c", 5 * FITSFiles.FITSUnits.pix, "c"),
                                  ("K       = 5 / [Jy/beam] c", 5 * u"Jy" / FITSFiles.FITSUnits.beam, "c"),
                                  ("K       = 5 / [deg]", 5 * u"°", ""),
                                  ("HIERARCH ESO A = 2.5 / [um] c", 2.5f0 * u"μm", "c"))
        card = parse(Card, rpad(img, 80))
        @test withunits(card) === value
        @test card.value === ustrip(value)
        @test card.units == unit(value)
        @test card.comment == comment
        @test card isa Card{<:Union{Value{typeof(ustrip(value))}, Hierarch{typeof(ustrip(value))}}}
        #  the units are written in the form of the standard and read again.
        again = parse(Card, repr(card))
        @test withunits(again) === value
        @test again.comment == comment
        @test repr(again) == repr(card)
        #  the units are not read if not asked for.
        text = parse(Card, rpad(img, 80); units = false)
        @test typeof(text.value) <: Real || typeof(text.value) <: Complex
        @test startswith(text.comment, "[")
    end

    #  the image of a card is the same, if the units are written as they were.
    for img in ("K       = 5 / [km s-1] a velocity", "K       = 5 / [m]", "K       = 5 / [m]   c",
                "K       =                  1.5 / [Jy] c", "K       = (1.0, 2.0)           / [Jy] c")
        img = rpad(img, 80)
        @test repr(parse(Card, img)) == img
    end

    #  text in the brackets that is not a unit string is a comment, and so is a scale factor.
    for img in ("K       = 5 / [see note] c", "K       = 5 / [foo] c", "K       = 5 / [] c", "K       = 5 / [ ] c",
                "K       = 5 / [10**3 m] c", "K       = 5 / [m c", "K       = 5 / m c", "K       = 5 / c [m]",
                "K       = 5 / [D]", "K       = 5 / [mag] c", "K       = 5 / [log(m)] c")
        card = parse(Card, rpad(img, 80))
        @test card.value === 5
        @test card.comment == strip(split(img, "/ ")[2])
        @test repr(card) == rpad(img, 80)
    end

    #  only the first brackets are units.
    card = parse(Card, rpad("K       = 5 / [m s] [c]", 80))
    @test (withunits(card), card.comment) === (5 * u"m*s", "[c]")

    #  the values that are not numbers, and the mandatory keywords, have no units.
    for img in ("K       = 'a string' / [m] c", "K       = T / [m] c", "K       = / [m] c", "K       = / [m]",
                "CONTINUE  'a string' / [m] c")
        card = parse(Card, rpad(img, 80))
        @test !(card.value isa Unitful.Quantity)
        @test occursin("[m]", card.comment)
        @test repr(card) == rpad(img, 80)
    end
    for img in ("NAXIS1  =                    5 / [pixel] length", "NAXIS   = 2 / [m]", "BITPIX  = 16 / [bit]",
                "PCOUNT  = 0 / [m]", "GCOUNT  = 1 / [m]")
        card = parse(Card, rpad(img, 80))
        @test !(card.value isa Unitful.Quantity)
        @test occursin("[", card.comment)
        @test repr(card) == rpad(img, 80)
    end

    #  the units of a card can be set, and are removed, with the value.
    card = parse(Card, rpad("K       = 5 / [m]   a comment", 80))
    @test withunits(FITSFiles.setvalue!(card, 7 * u"m")) === 7 * u"m"
    @test withunits(FITSFiles.setvalue!(card, 7 * u"km")) === 7 * u"km"
    @test withunits(FITSFiles.setvalue!(card, 7)) === 7 * u"m"
    @test withunits(FITSFiles.setvalue!(card, 7.5f0)) === 7.5f0 * u"m"
    @test withunits(FITSFiles.setvalue!(card, 2.0 + 1.0im)) === (2.0 + 1.0im) * u"m"
    @test FITSFiles.setvalue!(card, 5) === card
    @test repr(FITSFiles.setvalue!(card, 7)) == rpad("K       = 7 / [m]   a comment", 80)
    #  a value of another type has no units.
    for value in ("a string", true, missing)
        @test isequal(FITSFiles.setvalue!(card, value).value, value)
        @test !occursin("[m]", repr(FITSFiles.setvalue!(card, value)))
    end
    #  a card that is created has units that are kept.
    @test withunits(FITSFiles.setvalue!(Card("KEY", 5.0f0 * u"km/s", "c"), 7.5f0)) === 7.5f0 * u"km/s"
    @test occursin("[km s-1] c", repr(FITSFiles.setvalue!(Card("KEY", 5.0f0 * u"km/s", "c"), 7.5f0)))
    @test withunits(FITSFiles.setvalue!(Card("HIERARCH", "ESO A", 5.0f0 * u"km/s", "c"), 7.5f0)) === 7.5f0 * u"km/s"
    #  a card without units is not changed.
    @test FITSFiles.setvalue!(Card("KEY", 5, "c"), 7).value === 7
    @test parse(Card, repr(FITSFiles.setvalue!(card, 7 * u"km"))).comment == "a comment"
    @test FITSFiles.setvalue!(card, 7 * u"m") !== card

    #  the dictionaries of mandatory and reserved keywords have values without units.
    header(images...) = IOBuffer(rpad(join(rpad.([images...; "END"], 80)), 2880))
    cards, mankeys, reskeys = read(header("SIMPLE  =                    T", "BITPIX  =                   16",
        "NAXIS   =                    0", "BZERO   = 32768. / [adu] zero", "EXPTIME = 10. / [s] exposure"), Card)
    @test cards["BZERO"] === 32768.0f0
    @test units(cards, "BZERO") == FITSFiles.FITSUnits.adu
    @test cards["EXPTIME"] === 10.0f0
    @test units(cards, "EXPTIME") == u"s"
    @test units(cards, "NAXIS") === nothing
    @test_throws KeyError units(cards, "NONE")
    @test units(cards[4]) == FITSFiles.FITSUnits.adu
    @test reskeys["BZERO"] === 32768.0f0
    cards, mankeys, reskeys = read(header("SIMPLE  =                    T", "BZERO   = 32768. / [adu] zero"), Card; units = false)
    @test cards["BZERO"] === 32768.0f0
    @test cards[2].comment == "[adu] zero"
    hdu = read(header("SIMPLE  =                    T", "BITPIX  =                   16", "NAXIS   =                    0",
        "BZERO   = 32768. / [adu] zero"), HDU)
    @test getfield(hdu, :cards)[4].value === 32768.0f0
    @test getfield(hdu, :cards)[4].units == FITSFiles.FITSUnits.adu
    hdus = fits(header("SIMPLE  =                    T", "BITPIX  =                   16", "NAXIS   =                    0",
        "BZERO   = 32768. / [adu] zero"); units = false)
    @test getfield(hdus[1], :cards)[4].value === 32768.0f0

    ####    Test the units of a card    ####

    #  a quantity is split into the value and the units of a card, which has the type of the value.
    for (value, T) in ((1.5f0 * u"km/s", Float32), (5 * u"m", Int), (2.5 * u"Å", Float64),
                       ((1.0f0 + 2.0f0im) * u"Jy", ComplexF32))
        for card in (Card("KEY", value, "c"), Card(Value{typeof(ustrip(value))}, "KEY", value, "c", FITSFiles.CardFormat()),
                     Card("HIERARCH", "ESO A", value, "c"))
            @test card.value === ustrip(value)
            @test card.units == unit(value)
            @test units(card) == unit(value)
            @test card isa Card{<:Union{Value{T}, Hierarch{T}}}
            @test !(card.value isa Unitful.Quantity)
        end
        @test Card(Value{T}, "KEY", ustrip(value), unit(value), "c", FITSFiles.CardFormat()).units == unit(value)
    end

    #  a value without units, and a quantity without units, have no units.
    for value in (5, 1.5f0, 1.5 + 2.0im, "a string", true, missing, 5 * Unitful.NoUnits)
        card = Card("KEY", value)
        @test isnothing(card.units)
        @test isnothing(units(card))
        @test isequal(card.value, value isa Unitful.Quantity ? ustrip(value) : value)
    end
    @test isnothing(Card("KEY").units) && isnothing(Card().units) && isnothing(Card("END").units)
    @test isnothing(Card("COMMENT", "text").units) && isnothing(Card("HISTORY", "text").units)

    #  the cards of a list have the values and the units, which are not part of the values.
    cards = Card{<:Any}[Card("A", 1.5f0 * u"km/s"), Card("B", 2), Card("HIERARCH", "ESO C", 3.5 * u"m", "")]
    @test (cards["A"], cards["B"], cards["ESO C"]) === (1.5f0, 2, 3.5)
    @test (units(cards, "A"), units(cards, "B"), units(cards, "eso c")) == (u"km/s", nothing, u"m")
    @test get(cards, "A") === 1.5f0
    @test get(cards, ("A", "B", "NONE"), (0.0f0, 0, 0)) == (1.5f0, 2, 0)
    @test cards["A"] * units(cards, "A") === 1.5f0 * u"km/s"

    #  the unit of a string is cached, including a string that is not a unit string, and the cache is bounded.
    @testset "parseunit cache" begin
        empty!(FITSFiles.PARSEUNIT_CACHE)
        unit = FITSFiles.parseunit("km/s")
        @test FITSFiles.PARSEUNIT_CACHE["km/s"] === unit && FITSFiles.parseunit(" km/s ") === unit
        @test FITSFiles.parseunit("foo") === nothing && haskey(FITSFiles.PARSEUNIT_CACHE, "foo")
        @test FITSFiles.parseunit("foo") === nothing
        @test FITSFiles.parseunit("km/s") == u"km/s"
        for i in 1:(FITSFiles.PARSEUNIT_CACHE_SIZE + 5)
            @test FITSFiles.parseunit("m$(i)") == u"m"^i
        end
        @test length(FITSFiles.PARSEUNIT_CACHE) <= FITSFiles.PARSEUNIT_CACHE_SIZE
        @test FITSFiles.parseunit("km/s") == u"km/s"
    end

    #  the caches of the units are used by several threads at once.
    @testset "threads" begin
        names = ["m", "s", "kg", "Hz", "J", "W", "K", "mol", "rad", "deg", "arcsec", "Jy", "pc", "AU", "eV", "erg", "km", "Mpc"]
        texts = [a * "/" * b for a in names for b in names if a != b]
        empty!(FITSFiles.UNIT_CACHE); empty!(FITSFiles.PARSEUNIT_CACHE)
        units = Vector{Any}(undef, length(texts))
        Threads.@threads for i in eachindex(texts)
            units[i] = FITSFiles.parseunit(texts[i])
        end
        @test all(!isnothing, units)
        @test all(i -> units[i] == FITSFiles.parseunit(texts[i]), eachindex(texts))
        @test FITSFiles.unitname("km") == FITSFiles.parseunit("km") && isnothing(FITSFiles.unitname("foo"))
        @test haskey(FITSFiles.UNIT_CACHE, "foo") && isnothing(FITSFiles.UNIT_CACHE["foo"])
    end

end

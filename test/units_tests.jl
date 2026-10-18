@testset "Units" begin
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
        @test parse(Card, repr(card)).comment == text
        card = Card("HIERARCH", "ESO A", value, "c")
        @test isascii(repr(card))
        @test occursin("/ $text", repr(card))
        @test parse(Card, repr(card)).comment == text
    end

    #  the units are written without a comment, with other padding, and when the value is set.
    @test parse(Card, repr(Card("KEY", 5 * u"°"))).comment == "[deg]"
    @test parse(Card, repr(Card("KEY", 5 * u"°", "c"; upad = 3))).comment == "[deg]   c"
    @test isascii(repr(FITSFiles.setvalue!(Card("KEY", 5), 5.0f0 * u"Å")))
    @test parse(Card, repr(FITSFiles.setvalue!(Card("KEY", 5, "c"), 5.0f0 * u"Å"))).comment == "[Angstrom] c"
    @test parse(Card, repr(FITSFiles.setvalue!(Card("HIERARCH", "ESO A", 5, "c"), 5.0f0 * u"°"))).comment == "[deg] c"

    #  the value does not change.
    @test parse(Card, repr(Card("KEY", 1.5f0 * u"km/s", "c"))).value == 1.5f0
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

    #  a string that is not a unit string, or has an unknown unit, is nothing.
    for text in ("", " ", "foo", "m/", "/m", "m**", "m-", "m 2", "m s-", "log(m)", "ln(m)", "exp(m)", "mag", "D",
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

end

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
end

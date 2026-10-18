@testset "Format" begin
    ####    Test the formats of the value and the units of a card    ####

    #  a card that is read is written as it was read, whatever the format of its numbers.
    for img in ("EXPTIME =                 10.0 / [s] exposure", "EXPTIME =                  10. / [s] exposure",
                "EXPTIME = 10 / [s] exposure", "X       =              1.0E+03 / c", "X       =                1.0E3 / c",
                "X       =                1000.0 / c", "X       =               0.0100 / c", "X       =                  010 / c",
                "X       =                 +5.5 / c", "X       =                 1.50 / c", "X       =               -1.5E-05",
                "X       =            -1.5E-5 / c", "X       =              1.5D+10", "X       =              1.5D10",
                "X       =                  -10", "X       =                  +10", "X       = 5.",
                "X       = 0007.5 / c", "X       = 1.2345678901D+05 / [Jy] c", "X       =                    5   /    c",
                "X       = (1.5, 2.5) / c", "X       = (1.5,2.5)", "X       = ( 1.5 , 2.5 ) / c", "X       = (1.5E+03, -2.5E-03)",
                "X       = (1, 2)", "X       =         (1.5, 2.5) / c", "X       = (1.5D3, 2.5D3) / [Jy] c",
                "X       = 'a string' / c", "X       = T / c", "X       =  / c", "X       = 5 / [km s-1] velocity",
                "X       = 5 / [km/s] velocity", "X       = 5 / [km s^-1] velocity", "X       = 5 / [m**2]", "X       = 5 / [m2 s-1]",
                "X       = 5 / [kg.m/s**2] c", "X       = 5 / [kg.m.s-2] c", "X       = 5 / [m s]",
                "HIERARCH ESO A = 1.5 / c", "HIERARCH ESO A =   1.50 / [m] c", "HIERARCH ESO A = 1.0E+03", "HIERARCH ESO A = 1.5E3",
                "HIERARCH ESO A = (1.5, 2.5)", "HIERARCH ESO A = 010 / c", "HIERARCH ESO A = 'string'", "HIERARCH ESO A = T")
        img = rpad(img, 80)
        @test repr(parse(Card, img)) == img
        @test repr(parse(Card, img; units = false)) == img
    end

    #  the format of the number is the printf format of its text, and the position aligns it.
    for (img, vfmt) in (("X       =                 10.0", "%.1f"), ("X       =                  10.", "%#.0f"),
                        ("X       = 10", "%d"), ("X       =              1.0E+03", "%.1E"), ("X       =                1.0E3", "%.1E|-"),
                        ("X       =               0.0100", "%.4f"), ("X       =                  010", "%03d"),
                        ("X       =                 +5.5", "%+.1f"), ("X       = 1.2345678901D+05", "%.10e"),
                        ("X       =              -1.5E-05", "%.1E"), ("X       =               0007.5", "%06.1f"),
                        ("X       = (1.5, 2.5)", "(%.1f, %.1f)"), ("X       = (1,2)", "(%d,%d)"),
                        ("X       =         (1.5E3, 2.5E3)", "(%.1E, %.1E)|-"), ("X       = ( 1.5 , 2.5 )", "( %.1f , %.1f )"),
                        ("HIERARCH ESO A =   1.50 / c", "%.2f"), ("HIERARCH ESO A = (1.5, 2.5)", "(%.1f, %.1f)"))
        card = parse(Card, rpad(img, 80))
        @test card.format.vfmt == vfmt
    end
    #  the format has no spaces before the number, and no width, except zeros before the number.
    for img in ("X       =                 10.0", "X       = 10", "X       =              1.0E+03", "X       = (1.5, 2.5)")
        @test !startswith(parse(Card, rpad(img, 80)).format.vfmt, " ")
    end
    @test isempty(parse(Card, rpad("X       = 'a string'", 80)).format.vfmt)
    @test isempty(parse(Card, rpad("X       = T", 80)).format.vfmt)
    @test isempty(parse(Card, rpad("X       =", 80)).format.vfmt)
    @test isempty(Card("X", 1.5f0).format.vfmt) && isempty(Card("X", 1.5f0 * Unitful.m).format.ufmt)

    #  the format is kept when a value is set, if the kind of the value is the same.
    card = parse(Card, rpad("X       =                 1.50 / [km/s] c", 80))
    @test repr(FITSFiles.setvalue!(card, 12.25f0)) == rpad("X       =                12.25 / [km/s] c", 80)
    @test repr(FITSFiles.setvalue!(card, 3)) == rpad("X       =                 3.00 / [km/s] c", 80)
    @test repr(FITSFiles.setvalue!(card, 1.5e10)) == rpad("X       =       15000000000.00 / [km/s] c", 80)
    @test repr(FITSFiles.setvalue!(card, 2.5f0 * Unitful.m)) == rpad("X       =                 2.50 / [m] c", 80)
    @test repr(FITSFiles.setvalue!(card, "text")) == rpad("X       = 'text' / c", 80)[1:80] ||
          startswith(repr(FITSFiles.setvalue!(card, "text")), "X       = 'text'")
    card = parse(Card, rpad("X       =                  010 / c", 80))
    @test repr(FITSFiles.setvalue!(card, 7)) == rpad("X       =                  007 / c", 80)
    @test FITSFiles.setvalue!(card, 7).format.vfmt == card.format.vfmt
    @test isempty(FITSFiles.setvalue!(card, 7.5).format.vfmt)
    card = parse(Card, rpad("X       = (1.5, 2.5) / c", 80))
    @test repr(FITSFiles.setvalue!(card, 3.0f0 + 4.0f0im)) == rpad("X       = (3.0, 4.0) / c", 80)
    @test isempty(FITSFiles.setvalue!(card, 3.0f0).format.vfmt)
    @test isempty(FITSFiles.setvalue!(card, 3).format.vfmt)
    card = parse(Card, rpad("X       = 5 / c", 80))
    @test isempty(FITSFiles.setvalue!(card, true).format.vfmt)
    @test isempty(FITSFiles.setvalue!(card, missing).format.vfmt)
    card = parse(Card, rpad("HIERARCH ESO A = 1.50 / c", 80))
    @test repr(FITSFiles.setvalue!(card, 2.5f0)) == rpad("HIERARCH ESO A = 2.50 / c", 80)

    #  a number that is not standard is written in the standard form.
    @test repr(parse(Card, rpad("X       = 1.0e3 / c", 80); strict = false)) == rpad("X       = 1.0E3 / c", 80)
    @test repr(parse(Card, rpad("X       = 1.5d+03 / c", 80); strict = false)) == rpad("X       = 1.5D+03 / c", 80)

    #  the formats that printf cannot write are written in the nearest format.
    @test repr(parse(Card, rpad("X       = .5 / c", 80))) == rpad("X       = 0.5 / c", 80)
    @test repr(parse(Card, rpad("X       = 1.5E+3 / c", 80))) == rpad("X       = 1.5E+03 / c", 80)
    @test repr(parse(Card, rpad("X       = 1.5E03 / c", 80))) == rpad("X       = 1.5E+03 / c", 80)

    ####    Test the styles of the units    ####

    #  the style of the units is the separator, the division, and the power.
    for (text, ufmt) in (("km s-1", " -d"), ("km/s", " /d"), ("km s^-1", " -^"), ("m**2", " -*"), ("m2", " -d"), ("kg.m.s-2", ".-d"),
                         ("kg*m/s**2", "*/*"), ("kg.m/s^2", "./^"), ("m", " -d"), ("Jy/beam", " /d"))
        @test FITSFiles.unitstyle(text) == ufmt
    end
    #  the units are written in the style.
    for (unit, ufmt, text) in ((u"km/s", " -d", "km s-1"), (u"km/s", " /d", "km/s"), (u"km/s", " -^", "km s^-1"),
                               (u"m^2", " -*", "m**2"), (u"m^2", " -d", "m2"), (u"m^2", " -^", "m^2"),
                               (u"kg*m/s^2", ".-d", "kg.m.s-2"), (u"kg*m/s^2", "*/*", "kg*m/s**2"),
                               (u"kg*m/s^2", " /d", "kg m/s2"), (u"Jy/sr", " /d", "Jy/sr"), (u"s^-1", " /d", "s-1"),
                               (u"m^(1/2)", " -^", "m**(1/2)"), (u"m", "*/*", "m"))
        @test FITSFiles.formunit(unit, ufmt) == text
    end
    @test FITSFiles.formunit(u"km/s") == FITSFiles.formunit(u"km/s", "") == FITSFiles.formunit(u"km/s", " -d")
    @test FITSFiles.formunit(nothing, " /d") == ""
    @test_throws ArgumentError FITSFiles.formunit(u"°C", " /d")
    #  the style of the units of a card is kept when the value is set.
    card = parse(Card, rpad("X       = 5 / [km/s] c", 80))
    @test card.format.ufmt == " /d"
    @test repr(FITSFiles.setvalue!(card, 7)) == rpad("X       = 7 / [km/s] c", 80)
    @test repr(FITSFiles.setvalue!(card, 7 * u"m/s")) == rpad("X       = 7 / [m/s] c", 80)
end

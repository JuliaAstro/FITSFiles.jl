@testset "DynamicQuantities" begin
    parse_(text) = FITSFiles.parseunit(DQ, text)
    image(text) = rpad(text, 80)

    @testset "extension" begin
        @test !isnothing(Base.get_extension(FITSFiles, :DynamicQuantitiesExt))
    end

    @testset "parse units" begin
        for (text, expected) in (("m", 1.0 * DQ.u"m"), ("km/s", 1e3 * DQ.u"m/s"),
            ("Mpc", 3.0856775814913673e22 * DQ.u"m"), ("uJy", 1e-32 * DQ.u"kg/s^2"),
            ("kg m2 s-2", 1.0 * DQ.u"J"), ("erg/(cm2 s)", 1e-3 * DQ.u"kg/s^3"),
            ("pix", 1.0 * DQ.u"m/m"), ("ct/s", 1.0 * DQ.u"s^-1"), ("kyr", 3.15576e10 * DQ.u"s"),
            ("Ohm", 1.0 * DQ.u"Ω"), ("G", 1e-4 * DQ.u"kg/s^2/A"), ("a", 3.15576e7 * DQ.u"s"))
            parsed = parse_(text)
            @test FITSFiles.isunit(parsed)
            @test DQ.dimension(parsed) isa DQ.SymbolicDimensions
            @test DQ.ustrip(DQ.uexpand(parsed)) ≈ DQ.ustrip(expected)
            @test DQ.dimension(DQ.uexpand(parsed)) == DQ.dimension(expected)
        end
        @test isnothing(parse_("foo")) && isnothing(parse_("m2/"))
        #  a scale factor is not a unit
        @test !FITSFiles.isunit(parse_("10**3 m")) && DQ.ustrip(parse_("10**3 m")) == 1000
        #  the units of the backends are cached apart
        @test FITSFiles.parseunit("km/s") isa Unitful.Units && FITSFiles.parseunit(Unitful, "km/s") == u"km/s"
        @test parse_("km/s") === parse_("km/s")
    end

    @testset "units of Table 4" begin
        @test DQ.uexpand(parse_("solMass")) ≈ 1.98840987e30 * DQ.us"kg" rtol = 1e-6
        @test DQ.uexpand(parse_("byte")) == 8 * DQ.uexpand(DQ.Quantity(1.0, DQ.SymbolicDimensions{DQ.FRInt32}(; bit = 1)))
        @test DQ.dimension(parse_("ct")) != DQ.dimension(parse_("ph"))
        @test DQ.uexpand(parse_("lx")) ≈ DQ.uexpand(parse_("lm/m2"))
        @test DQ.uexpand(parse_("D")) ≈ (1e-29 / 3) * DQ.us"C" * DQ.us"m"
    end

    @testset "write units" begin
        for (text, written) in (("km/s", "km s-1"), ("m", "m"), ("kg m2 s-2", "m2 kg s-2"), ("Ohm", "Ohm"),
            ("G", "G"), ("uJy", "uJy"), ("m**(1/2)", "m**(1/2)"), ("pix", "pix"))
            @test FITSFiles.formunit(parse_(text)) == written
        end
        @test FITSFiles.formunit(parse_("km/s"), " /d") == "km/s"
        @test FITSFiles.formunit(parse_("m2 Ohm"), ".-^") == "m^2.Ohm"
        @test_throws ArgumentError FITSFiles.formunit(10.0 * parse_("m"))
    end

    @testset "cards" begin
        card = parse(Card, image("TEMP    =                 1.50 / [km/s] velocity"); units = DQ)
        @test card.value === 1.5f0 && card.comment == "velocity"
        @test card.units isa DQ.AbstractQuantity && card.units == parse_("km/s")
        @test string(card) == image("TEMP    =                 1.50 / [km/s] velocity")
        #  the default units are Unitful, and false has none
        @test parse(Card, image("TEMP    =                 1.50 / [km/s] velocity")).units isa Unitful.Units
        @test isnothing(parse(Card, image("TEMP    =                 1.50 / [km/s] velocity"); units = false).units)
        #  a mandatory keyword has no units
        @test isnothing(parse(Card, image("BITPIX  =                   16 / [km/s] bits"); units = DQ).units)
        #  a string is not a number
        @test isnothing(parse(Card, image("NAME    = 'abc' / [km/s] name"); units = DQ).units)

        #  a card is made from a quantity
        card = Card("SPEED", 2.5 * DQ.sym_uparse("km/s"), "speed")
        @test card.value === 2.5 && card.units == parse_("km/s")
        @test string(card) == image("SPEED   =                  2.5 / [km s-1] speed")
        @test isnothing(Card("PLAIN", 2.5 * DQ.sym_uparse("m/m"), "").units) == false
        @test_throws ArgumentError Card("BAD", :symbol, "")
    end

    @testset "HDU" begin
        text = join(image.(["SIMPLE  =                    T", "BITPIX  =                    8",
            "NAXIS   =                    0", "EXPTIME =                 30.0 / [s] exposure", "END"]))
        hdu = read(IOBuffer(text * " "^(2880 - 400)), HDU; units = DQ)
        @test units(hdu.cards, "EXPTIME") == parse_("s")
        hdu = read(IOBuffer(text * " "^(2880 - 400)), HDU)
        @test units(hdu.cards, "EXPTIME") == u"s"
    end
end

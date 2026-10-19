@testset "Card numbers" begin
    ###  Regression tests: numbers  ###

    #  a floating-point number is a Float32 only if no precision is lost.
    @test FITSFiles.parse_number("1.489") === 1.489f0
    @test FITSFiles.parse_number("-99.9") === -99.9f0
    @test FITSFiles.parse_number("1.5E-5") === 1.5f-5
    @test FITSFiles.parse_number("1E5") === 1.0f5
    @test FITSFiles.parse_number("1234567.891") === 1234567.891
    @test FITSFiles.parse_number("12345678901.5") === 12345678901.5
    @test FITSFiles.parse_number("1.23456789012E5") === 1.23456789012e5
    @test FITSFiles.parse_number("1.0E50") === 1.0e50
    @test FITSFiles.parse_number("1.0D5") === 1.0e5
    @test FITSFiles.parse_number("123") === 123
    @test parse(Card, rpad("KEY     =          1234567.891", 80)).value === 1234567.891

    #  complex numbers with E exponents are single precision.
    @test parse(Card, rpad("KEY     = (1.0E3, -2.0E1)", 80)).value === 1000.0f0 - 20.0f0im

    #  a complex number has the smallest type that holds both of its parts.
    @test FITSFiles.parse_complex("123", "45") === Complex(123, 45)
    @test FITSFiles.parse_complex("1.5", "-2.5") === 1.5f0 - 2.5f0im
    @test FITSFiles.parse_complex("1.5", "2") === 1.5f0 + 2.0f0im
    @test FITSFiles.parse_complex("1.0D3", "2.0") === 1000.0 + 2.0im
    @test FITSFiles.parse_complex("1.23456789012E0", "1.0E0") === 1.23456789012 + 1.0im
    @test FITSFiles.parse_complex("1.0E3", "1.0E50") === 1000.0 + 1.0e50im

    #  non-finite values cannot be represented.
    for value in (NaN, Inf, -Inf, NaN32, Inf32, complex(1.0, NaN))
        @test_throws "Value is not finite." Card("KEY", value)
        @test_throws "Value is not finite." Card("HIERARCH", "ESO A", value, "")
    end

    #  a long Float64 without an exponent is truncated to fit the fixed-format field.
    card = Card("KEY", -0.00012345678901234567)
    @test repr(card) == rpad("KEY     = -0.00012345678901234", 80)
    @test parse(Card, repr(card)).value === -0.00012345678901234
    #  a long exponent form is truncated by the excess length, not by one character.
    card = Card("KEY", -1.2345678901234567e-100)
    @test repr(card) == rpad("KEY     = -1.234567890123D-100", 80)
    @test parse(Card, repr(card)).value === -1.234567890123e-100

    ###  Regression tests: large integers  ###

    #  an integer has the smallest type that holds it.
    @test FITSFiles.parse_number("9223372036854775807") === typemax(Int64)
    @test FITSFiles.parse_number("9223372036854775808") === Int128(typemax(Int64)) + 1
    @test FITSFiles.parse_number("-170141183460469231731687303715884105728") === typemin(Int128)
    @test FITSFiles.parse_number("170141183460469231731687303715884105728") ==
          big(typemax(Int128)) + 1
    @test FITSFiles.parse_number("170141183460469231731687303715884105728") isa BigInt
    @test FITSFiles.parse_number("-12345678901234567890123456789012345678901234567890") ==
          -big"12345678901234567890123456789012345678901234567890"

    #  a card with an integer that does not fit in 128 bits is read and written.
    img = rpad("KEY     = 12345678901234567890123456789012345678901234567890 / a comment", 80)
    card = parse(Card, img)
    @test card.value == big"12345678901234567890123456789012345678901234567890"
    @test card.comment == "a comment"
    @test parse(Card, repr(card)).value == card.value
    @test parse(Card, repr(Card("KEY", big(10)^60))).value == big(10)^60

    #  a complex number can have large integer parts.
    @test FITSFiles.parse_complex("12345678901234567890123456789012345678901234567890", "1") ==
          complex(big"12345678901234567890123456789012345678901234567890", 1)
    #  A mantissa with more than one integer digit is written with all of its digits, since the
    #  exponent form has one digit before the decimal point.
    @testset "exponent precision" begin
        for (text, vfmt) in (("56.53E+13", "%.3E"), ("33.65D-31", "%.3e|-"), ("-99E+15", "%.1E"), ("0.5E3", "%.1E|-"),
            (".5E3", "%.1E|-"), ("1.500E3", "%.3E|-"), ("0.00E0", "%.2E|-"), ("12E3", "%.1E|-"), ("123.456E+10", "%.5E"),
            ("0012.5D1", "%08.2e|-"), ("1.5E+3", "%.1E"))
            @test FITSFiles.realfmt(text) == vfmt
        end
        for text in ("56.53E+13", "33.65D-31", "-99E+15", "-16D+1", "123.456E+10", "99.99999E-5", "0012.5D1", "-52.25D-8",
            "66.55D+25", "-68.24D+35", "12E3", "999.9E-9")
            value = FITSFiles.parse_number(text)
            written = FITSFiles.printfmt(FITSFiles.realfmt(text), value)
            @test FITSFiles.parse_number(written) == value
            @test FITSFiles.parse_number(FITSFiles.printfmt(FITSFiles.complexfmt("(" * text * ", " * text * ")"), complex(value, value))[2:(end-1)] |>
                  x -> first(split(x, ",")) |> strip) == value
        end
    end

    #  The parts of a complex number are integers only if both are integers, and otherwise floats that hold the
    #  integer parts exactly.
    @testset "complex parts" begin
        @test FITSFiles.parse_complex("1", "2") === Complex(1, 2)
        @test FITSFiles.parse_complex("1.5", "2.5") === ComplexF32(1.5, 2.5)
        @test FITSFiles.parse_complex("1", "2.5") === ComplexF32(1, 2.5)
        @test FITSFiles.parse_complex("1.5D0", "2") === ComplexF64(1.5, 2)
        @test FITSFiles.parse_complex("756478251", "121.804") === ComplexF64(756478251, 121.804f0)
        @test real(FITSFiles.parse_complex("756478251", "121.804")) == 756478251
        @test FITSFiles.parse_complex("2.5", "3847950226") isa ComplexF64
        @test FITSFiles.parse_complex("16777216", "1.5") isa ComplexF32
        @test FITSFiles.parse_complex("16777217", "1.5") isa ComplexF64
        @test real(FITSFiles.parse_complex("9007199254740993", "1.5")) == 9007199254740993
        @test FITSFiles.parse_complex("9007199254740993", "1.5") isa Complex{BigFloat}
        @test FITSFiles.parse_complex("12345678901234567890123456789012345678901234567890", "1") isa Complex{BigInt}
        @test FITSFiles.parse_complex("123456789012345678901234567890", "1") isa Complex{Int128}
        for image in ("KEY     = (756478251, 121.804)", "KEY     = (+3847950226 ,-348.731) / c",
            "HIERARCH ESO A = (756478251, 121.804)")
            card = parse(Card, rpad(image, 80))
            @test real(card.value) == parse(Int, match(r"\(\+?(\d+)", image)[1])
            @test repr(card) == rpad(image, 80)
        end
    end

end

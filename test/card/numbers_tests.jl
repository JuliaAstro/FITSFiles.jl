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
end

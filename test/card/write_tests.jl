@testset "Card write" begin
    format = FITSFiles.CardFormat()
    image(T, key, value) = FITSFiles.format_card(T, key, value, "", "", format)

    @testset "show" begin
        cards = Card{<:Any}[Card("ABC", 1, "a"), Card("COMMENT", "text")]
        @test sprint(show, cards) == repr(cards[1]) * "\n" * repr(cards[2])
        @test sprint(show, Card{<:Any}[Card("ABC", 1)]) == repr(Card("ABC", 1))
    end

    @testset "Comment and History" begin
        @test image(FITSFiles.Comment, "COMMENT", "text") == rpad("COMMENT text", 80)
        @test image(FITSFiles.Comment, "COMMENT", missing) == rpad("COMMENT", 80)
        @test image(FITSFiles.History, "HISTORY", "text") == rpad("HISTORY text", 80)
        @test image(FITSFiles.History, "HISTORY", missing) == rpad("HISTORY", 80)
        @test_throws "Value is not a string." image(FITSFiles.Comment, "COMMENT", 1)
        @test_throws "Value is not a string." image(FITSFiles.Comment, "COMMENT", 1.5)
        @test_throws "Value is not a string." image(FITSFiles.History, "HISTORY", 1)
        @test_throws "Value is not a string." image(FITSFiles.History, "HISTORY", 1.5)
    end

    @testset "Continue" begin
        @test image(FITSFiles.Continue, "CONTINUE", "ab") == rpad("CONTINUE  'ab'", 80)
        @test_throws "Continue contains non-string value." image(FITSFiles.Continue, "CONTINUE", 1)
        @test_throws "Continue contains non-string value." image(FITSFiles.Continue, "CONTINUE", missing)
    end
    @testset "equality, hash, copy, and broadcast" begin
        a, b = Card("KEY", 1, "a comment"), Card("KEY", 1, "a comment")
        @test a == b && isequal(a, b) && hash(a) == hash(b)
        @test a != Card("KEY", 2, "a comment") && a != Card("KEY", 1, "another comment")
        @test a != Card("KEY", 1, "a comment"; fixed = false) && a != Card("KEY", 1.0, "a comment")
        @test length(Set([a, b, Card("KEY", 2)])) == 2
        @test Dict(a => 1)[b] == 1
        #  a card is equal to the card that is parsed from its image.
        for card in (a, Card("KEY", "string", "c"), Card("KEY", 1.5f0 * Unitful.m, "c"), Card("COMMENT", "text"),
            Card("HIERARCH", "ESO A", 2.5, "c"), Card("KEY", missing), Card("KEY", 1 + 2im))
            @test parse(Card, repr(card)) == card
        end
        @test Card("COMMENT", "a") != Card("HISTORY", "a")
        #  a copy is equal, and has its own format.
        c = copy(a)
        @test c == a && c !== a && c.format !== a.format && c.format.cend == a.format.cend
        c.format.slsh = 0
        @test a.format.slsh != 0 && c != a
        copied = copy(parse(Card, rpad("KEY     = 1.50 / [km/s] c", 80)))
        @test repr(copied) == rpad("KEY     = 1.50 / [km/s] c", 80) && copied.units == Unitful.km / Unitful.s
        @test copied.format.vfmt == "%.2f" && copied.format.ufmt == parse(Card, rpad("KEY     = 1.50 / [km/s] c", 80)).format.ufmt
        #  a card is a scalar in a broadcast.
        @test (a .== [a, Card("KEY", 2)]) == [true, false]
        @test ([a, b] .== a) == [true, true]
        @test length(collect(zip([a, b], fill(a, 2)))) == 2
        @test string.(Card("KEY", 1), [1, 2]) == [repr(Card("KEY", 1)) * "1", repr(Card("KEY", 1)) * "2"]
    end

    @testset "exponent letter" begin
        @test repr(Card("FREQ", 2.2710000001e11)) == rpad("FREQ    =      2.2710000001D11", 80)
        @test repr(Card("FREQ", 2.2710000001e11; exponent='E')) == rpad("FREQ    =      2.2710000001E11", 80)
        @test parse(Card, repr(Card("FREQ", 2.2710000001e11; exponent='E'))).value == 2.2710000001e11
        @test repr(Card("TINY", 1.2345678901234567e-100; exponent='E')) ==
            rpad("TINY    = 1.2345678901234E-100", 80)
        @test startswith(repr(Card("CPLX", 1.0e20 + 2.0im; exponent='E')), "CPLX    = (1.0E20, 2.0)")
        @test_throws "The exponent letter is 'D' or 'E', not 'Q'." Card("X", 1.0; exponent='Q')
    end

end

@testset "Header" begin
    ####    Test the values of continued strings    ####

    header(images...) = IOBuffer(rpad(join(rpad.([images...; "END"], 80)), 2880))
    cards, mankeys, reskeys = read(header(
        "SIMPLE  =                    T",
        "OBJECT  = 'first part &'",
        "CONTINUE  'second part&'",
        "CONTINUE  'third part' / the comment",
        "KEY2    = 'single'",
        "KEY3    = 'abc&'",
        "KEY4    =                    1",
        "TELESCOP= 'a long &'",
        "CONTINUE  'name'",
        "CONTINUE  'orphan'"), Card)

    #  the cards are not joined.
    @test length(cards) == 10
    @test cards[2].value == "first part "
    @test cards[3].value == "second part"
    @test FITSFiles.typename(cards[end]) == Comment

    #  the value of a continued string is the value of the joined cards.
    joined = "first part second partthird part"
    @test cards["OBJECT"] == joined
    @test cards["object"] == joined
    @test get(cards, "OBJECT") == joined
    @test get(cards, "OBJECT", "default") == joined
    @test get(cards, ("OBJECT", "KEY2", "NONE"), ("a", "b", "c")) == (joined, "single", "c")
    @test cards["TELESCOP"] == "a long name"

    #  the values of other cards are not changed.
    @test cards["KEY2"] == "single"
    @test cards["KEY4"] == 1
    @test cards["SIMPLE"] == true
    @test get(cards, "NONE", "default") == "default"
    @test_throws KeyError cards["NONE"]

    #  an ampersand that is not followed by a CONTINUE card is part of the string.
    @test cards["KEY3"] == "abc&"

    #  the value of a card is the value of the card, unless it is a continued string.
    @test FITSFiles.joinvalue(cards, 2) == joined
    @test FITSFiles.joinvalue(cards, 3) == "second part"
    @test FITSFiles.joinvalue(cards, 5) == "single"
    @test FITSFiles.joinvalue(cards, 7) == 1

    #  the dictionaries of mandatory and reserved keywords have the joined values.
    @test reskeys["TELESCOP"] == "a long name"
    @test mankeys["SIMPLE"] == true
    @test ismissing(mankeys["END"])
    @test FITSFiles.get_reserved_keys(cards)[2]["TELESCOP"] == "a long name"
    @test !haskey(FITSFiles.get_reserved_keys(cards)[1], "END")

    #  a mandatory keyword that is a continued string.
    cards2, mankeys2, _ = read(header("XTENSION= 'BIN&'", "CONTINUE  'TABLE'"), Card)
    @test mankeys2["XTENSION"] == "BINTABLE"
    @test length(cards2) == 2

    #  the values of cards that are not continued are not joined with the following cards.
    cards3 = Card{<:Any}[Card("KEY", "a"), Card("COMMENT", "b")]
    @test cards3["KEY"] == "a"
    ####    Test that the header reader is strict or not    ####

    images = ["SIMPLE  =                    T", "BITPIX  =                   16", "NAXIS   =                    0",
              "BZERO   = 1.0e1", "EXPTIME = 1.5d0 / seconds", "HIERARCH ESO A = 2.5e0"]

    #  the default is strict, so a lower case exponent letter is an invalid card.
    cards, mankeys, reskeys = read(header(images...), Card)
    @test FITSFiles.typename.(cards[4:5]) == [Invalid, Invalid]
    @test FITSFiles.typename(cards[6]) == Comment
    cards, mankeys, reskeys = read(header(images...), Card; strict = true)
    @test FITSFiles.typename.(cards[4:5]) == [Invalid, Invalid]

    #  the numbers are read if the parsing is not strict.
    cards, mankeys, reskeys = read(header(images...), Card; strict = false)
    @test cards["BZERO"] == 10.0f0
    @test cards["EXPTIME"] == 1.5
    @test cards["ESO A"] == 2.5f0
    @test reskeys["BZERO"] == 10.0f0
    @test cards[5].comment == "seconds"
    @test FITSFiles.typename.(cards[4:6]) == [Value{Float32}, Value{Float64}, Hierarch{Float32}]

    #  the HDUs and the FITS file are read if the parsing is not strict.
    hdu = read(header(images...), HDU; strict = false)
    @test getfield(hdu, :cards)[4].value === 10.0f0
    hdus = fits(header(images...); strict = false)
    @test length(hdus) == 1
    @test getfield(hdus[1], :cards)[5].value === 1.5

end

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

    #  the keywords of the card are the keywords of the list.
    comment = "a comment that is continued on the next card"
    list = Card{<:Any}[Card("OBJECT", "old", comment), Card("COMMENT", "b")]
    FITSFiles.setvalue!(list, "OBJECT", repeat("a", 60))
    @test length(list) == 2 && list[1].comment == "a com"
    list = Card{<:Any}[Card("OBJECT", "old", comment), Card("COMMENT", "b")]
    FITSFiles.setvalue!(list, "OBJECT", repeat("a", 60); truncate = false)
    @test length(list) > 2 && list["OBJECT"] == repeat("a", 60)
    ####    Test that the header reader is strict or not    ####

    images = ["SIMPLE  =                    T", "BITPIX  =                   16", "NAXIS   =                    0",
              "BZERO   = 1.0e1", "EXPTIME = 1.5d0 / seconds", "HIERARCH ESO A = 2.5e0"]

    #  the default is strict, so a lower case exponent letter is an invalid card, including a HIERARCH card.
    cards, mankeys, reskeys = read(header(images...), Card)
    @test FITSFiles.typename.(cards[4:5]) == [Invalid, Invalid]
    @test FITSFiles.typename(cards[6]) == Invalid
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

    ####    Test the replacement of the value of a list of cards    ####

    chain(text; kwds...) = collect(Card("OBJECT", text, "the object"; kwds...))
    long = "The quick brown fox jumps over the lazy dog while the weather stays cloudy overnight with a low"
    images(cards) = [rpad(rstrip(repr(c)), 80) for c in cards]

    #  a string that does not fit replaces the card with the cards of a long string, in the same place.
    cards = Card{<:Any}[Card("SIMPLE", true), Card("OBJECT", "old", "the object"), Card("EXPTIME", 10.0f0)]
    cards["OBJECT"] = long
    @test length(cards) > 4
    @test cards[1].key == "SIMPLE" && cards[end].key == "EXPTIME" && cards[end].value === 10.0f0
    @test [c.key for c in cards[2:end-1]] == ["OBJECT"; fill("CONTINUE", length(cards)-3)]
    @test cards["OBJECT"] == long
    @test FITSFiles.setvalue!(cards, "OBJECT", long) === cards

    #  a card that is a string or a number replaces the cards of the string that is continued.
    for value in ("short", 5, 1.5f0, missing, true)
        cards = Card{<:Any}[Card("SIMPLE", true); chain(long); Card("EXPTIME", 10.0f0)]
        n = length(cards)
        cards["OBJECT"] = value
        @test length(cards) == 3
        @test [c.key for c in cards] == ["SIMPLE", "OBJECT", "EXPTIME"]
        @test isequal(cards["OBJECT"], value)
        @test cards["EXPTIME"] === 10.0f0
    end
    cards = Card{<:Any}[Card("SIMPLE", true); chain(long); Card("EXPTIME", 10.0f0)]
    cards["OBJECT"] = "another " * long
    @test [c.key for c in cards][[1, end]] == ["SIMPLE", "EXPTIME"]
    @test count(c -> c.key == "CONTINUE", cards) == length(cards) - 3
    @test cards["OBJECT"] == "another " * long

    #  a string that is the last card of the list, or the only one, is replaced.
    cards = Card{<:Any}[chain(long)...]
    cards["OBJECT"] = "short"
    @test length(cards) == 1 && cards["OBJECT"] == "short"
    cards = Card{<:Any}[Card("OBJECT", "old", "c")]
    cards["OBJECT"] = long
    @test cards["OBJECT"] == long && length(cards) > 1 && cards[end].key == "CONTINUE"

    #  setting the value that the cards have leaves the cards as they are, including their pieces.
    cards = Card{<:Any}[Card("SIMPLE", true); chain(long; splitat = nothing); Card("EXPTIME", 10.0f0)]
    before = images(cards)
    cards["OBJECT"] = long
    @test images(cards) == before
    cards["OBJECT"] = long * "   "
    @test images(cards) == before
    cards["EXPTIME"] = 10.0f0
    @test images(cards) == before
    #  setvalue! replaces the cards, which splits the string again.
    FITSFiles.setvalue!(cards, "OBJECT", long)
    @test images(cards) != before
    @test cards["OBJECT"] == long
    @test length(cards) == length(before) - length(chain(long; splitat = nothing)) + length(chain(long)) &&
          cards[1].key == "SIMPLE" && cards[end].key == "EXPTIME"
    FITSFiles.setvalue!(cards, "OBJECT", long; splitat = nothing)
    @test images(cards) == before

    #  a keyword that is not in the list is an error, and other keywords are not changed.
    @test_throws KeyError (cards["NONE"] = long)
    @test_throws KeyError FITSFiles.setvalue!(cards, "NONE", long)
    @test images(cards) == before
    cards["object"] = "short"
    @test cards["OBJECT"] == "short" && length(cards) == 3

end

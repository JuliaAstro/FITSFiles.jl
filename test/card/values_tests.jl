@testset "Card values" begin
    ###  Regression tests: long strings with single quotes  ###

    #  a long string consisting of single quotes keeps all of its characters.
    for n in (1, 2, 17, 40, 100), value in (repeat("'", n), "a" * repeat("'", n), repeat("'a", n))
        cards = Card("KEY", value, "")
        cards = cards isa AbstractArray ? cards : [cards]
        #  every card fits, and no doubled single quote is split between cards.
        images = [repr(c) for c in cards]
        @test all(length(image) == 80 for image in images)
        @test FITSFiles.join_cards(cards).value == value
        @test FITSFiles.join_cards([parse(Card, image) for image in images]).value == value
    end

    ###  Regression tests: literal ampersand  ###

    #  an ampersand that is not followed by a CONTINUE card is part of the string.
    card = parse(Card, rpad("KEY     = 'AT&T&' / c", 80))
    @test card.value == "AT&T"
    @test FITSFiles.join_cards([card]).value == "AT&T&"
    @test repr(FITSFiles.join_cards([card]).format.ampr) == "0"
    @test card.format.ampr > 0

    #  an ampersand followed by a CONTINUE card joins the strings.
    cards = [parse(Card, rpad("KEY     = 'first &'", 80)),
             parse(Card, rpad("CONTINUE  'second&'", 80)),
             parse(Card, rpad("CONTINUE  'third'", 80))]
    @test FITSFiles.join_cards(cards).value == "first secondthird"
    @test cards[1].format.ampr > 0

    #  only CONTINUE cards continue a string.
    for next in ("KEY2    = 'second'", "KEY2    =                    5", "COMMENT second", "HISTORY second")
        cards = [parse(Card, rpad("KEY     = 'first &'", 80)), parse(Card, rpad(next, 80))]
        @test FITSFiles.join_cards(cards).value == "first &"
    end

    #  the last ampersand is literal if the string ends with it, and later cards are ignored.
    cards = [parse(Card, rpad("KEY     = 'first &'", 80)),
             parse(Card, rpad("CONTINUE  'second&'", 80))]
    @test FITSFiles.join_cards(cards).value == "first second&"
    cards = [parse(Card, rpad("KEY     = 'first'", 80)),
             parse(Card, rpad("CONTINUE  'second'", 80))]
    @test FITSFiles.join_cards(cards).value == "first"

    ###  Regression tests: setvalue!  ###

    #  setvalue! replaces the value and keeps the format of the separator, units, and comment.
    card = Card("KEY", 5, "a comment")
    verified = FITSFiles.setvalue!(card, 7)
    @test verified.value == 7
    @test (verified.format.slsh, verified.format.cbeg, verified.format.cend) ==
          (card.format.slsh, card.format.cbeg, card.format.cend)
    @test repr(verified) == repr(Card("KEY", 7, "a comment"))
    @test FITSFiles.setvalue!(card, 5) === card
    @test FITSFiles.typename(FITSFiles.setvalue!(card, 5.0)) == Value{Float64}

    #  setvalue! changes the type of the card to the type of the new value.
    for value in (7, 7.5f0, 7.5, true, "abc", missing, 7 + 2im)
        verified = FITSFiles.setvalue!(card, value)
        @test isequal(verified.value, value)
        @test FITSFiles.typename(verified) == Value{typeof(value)}
        @test repr(verified) == repr(Card("KEY", value, "a comment"))
    end

    #  setvalue! moves the comment when the new value is longer than the old value.
    for value in (1.2345678901234567 + 1.2345678901234567im, 123456789012345678901234,
                  12345678901234567890123456789012345678901234567890)
        verified = FITSFiles.setvalue!(card, value)
        parsed = parse(Card, repr(verified))
        @test length(repr(verified)) == 80
        @test parsed.value == value
        @test parsed.comment == "a comment"
        @test verified.format.cbeg > last(verified.format.vend)
        @test verified.format.slsh > last(verified.format.vend)
    end
    verified = FITSFiles.setvalue!(Card("KEY", 5.0f0 * Unitful.m, "a comment"), 1.2345678901234567 * Unitful.m)
    @test parse(Card, repr(verified)).comment == "a comment"
    @test parse(Card, repr(verified)).value == 1.2345678901234567
    @test parse(Card, repr(verified)).units == Unitful.m

    #  setvalue! keeps the spacing of a card that was parsed from an image.
    card = parse(Card, rpad("KEY     =                    5   /    a comment", 80))
    @test repr(FITSFiles.setvalue!(card, 7)) == rpad("KEY     =                    7   /    a comment", 80)

    #  setvalue! works with undefined values.
    undef = Card("KEY", missing, "a comment")
    @test FITSFiles.setvalue!(undef, missing) === undef
    @test repr(FITSFiles.setvalue!(undef, 5)) == repr(Card("KEY", 5, "a comment"))
    @test FITSFiles.typename(FITSFiles.setvalue!(undef, 5)) == Value{Int}

    #  setvalue! keeps the type of other cards.
    hier = Card("HIERARCH", "ESO A", 1, "a comment")
    @test FITSFiles.typename(FITSFiles.setvalue!(hier, 2.5)) == Hierarch{Float64}
    @test FITSFiles.typename(FITSFiles.setvalue!(hier, 1)) == Hierarch{Int}

    card = Card("KEY", 5.0f0 * Unitful.m, "a comment")
    verified = FITSFiles.setvalue!(card, 7.0f0 * Unitful.m)
    @test (verified.format.ubeg, verified.format.uend) == (card.format.ubeg, card.format.uend)

    #  assigning a value to a keyword of a list of cards may change the type of the value.
    cards = Card{<:Any}[Card("KEY", 5, "a comment"), Card("OTHER", 1)]
    for value in (7.5f0, "abc", true, missing)
        cards["KEY"] = value
        @test isequal(cards[1].value, value)
        @test repr(cards[1]) == repr(Card("KEY", value, "a comment"))
    end
    @test cards[2].value == 1
    @test_throws KeyError cards["NONE"] = 1

    ###  Regression tests: units in the comment of a parsed card  ###

    #  setting a value with units on a parsed card does not repeat the units in the comment.
    card = parse(Card, rpad("KEY     =                    5 / [m]   a comment", 80))
    card2 = FITSFiles.setvalue!(card, 7.5f0 * Unitful.m)
    @test repr(card2) == rpad("KEY     =                  7.5 / [m]   a comment", 80)
    @test card2.comment == "a comment"
    @test (card2.format.ubeg, card2.format.uend) != (0, 0)
    @test parse(Card, repr(card2)).comment == "a comment"
    @test parse(Card, repr(card2); units = false).comment == "[m]   a comment"

    #  the units of the new value replace the units of the card.
    card2 = FITSFiles.setvalue!(parse(Card, rpad("KEY     = 5 / [km] a comment", 80)), 7.5f0 * Unitful.m)
    @test parse(Card, repr(card2); units = false).comment == "[m] a comment"

    #  a comment of only units keeps the units.
    card2 = FITSFiles.setvalue!(parse(Card, rpad("KEY     = 5 / [m]", 80)), 7.5f0 * Unitful.m)
    @test parse(Card, repr(card2); units = false).comment == "[m]"

    #  a card that is parsed without units has the units in the comment, which the units of a
    #  new value replace.
    card2 = FITSFiles.setvalue!(parse(Card, rpad("KEY     = 5 / [m]   a comment", 80); units = false), 7.5f0 * Unitful.m)
    @test parse(Card, repr(card2); units = false).comment == "[m]   a comment"
    @test parse(Card, repr(card2)).value === 7.5f0
    @test parse(Card, repr(card2)).units == Unitful.m

    #  a number without units has the units of the card, which are written as before.
    card2 = FITSFiles.setvalue!(card, 7)
    @test (card2.value, card2.units) === (7, Unitful.m)
    @test (parse(Card, repr(card2)).value, parse(Card, repr(card2)).units) === (7, Unitful.m)
    @test parse(Card, repr(card2); units = false).comment == "[m]   a comment"
    @test repr(card2) == rpad("KEY     =                    7 / [m]   a comment", 80)
    card = Card("KEY", 5.0f0 * Unitful.m, "a comment"; upad = 3)
    @test repr(FITSFiles.setvalue!(card, 7.5f0 * Unitful.m)) ==
          repr(Card("KEY", 7.5f0 * Unitful.m, "a comment"; upad = 3))

    #  HIERARCH cards are treated the same way.
    card = parse(Card, rpad("HIERARCH ESO A = 5 / [m]  a comment", 80))
    card2 = FITSFiles.setvalue!(card, 7.5f0 * Unitful.m)
    @test (card2.value, card2.units, card2.comment) == (7.5f0, Unitful.m, "a comment")
    @test parse(Card, repr(card2); units = false).comment == "[m]  a comment"

    ###  Regression tests: XTENSION value is padded when it is set  ###

    #  an XTENSION value is padded to 8 characters when it is set.
    card = Card("XTENSION", "IMAGE")
    for (value, padded) in (("TABLE", "TABLE   "), ("table", "TABLE   "), ("BINTABLE", "BINTABLE"),
                            ("IMAGE", "IMAGE   "))
        card2 = FITSFiles.setvalue!(card, value)
        @test card2.value == padded
        @test repr(card2) == repr(Card("XTENSION", value))
        @test repr(card2) == rpad("XTENSION= '$padded'", 80)
    end

    #  a value that is the same after it is padded does not change the card.
    @test FITSFiles.setvalue!(card, "IMAGE") === card
    @test FITSFiles.setvalue!(card, "image") === card
    card = parse(Card, rpad("XTENSION= 'IMAGE   '           / a comment", 80))
    @test FITSFiles.setvalue!(card, "IMAGE") === card
    @test repr(FITSFiles.setvalue!(card, "TABLE")) == rpad("XTENSION= 'TABLE   '           / a comment", 80)

    #  other keywords and other values are not padded.
    @test FITSFiles.setvalue!(Card("KEY", "a"), "TABLE").value == "TABLE"
    @test FITSFiles.setvalue!(Card("HIERARCH", "ESO A", "a", ""), "TABLE").value == "TABLE"
    @test FITSFiles.setvalue!(Card("XTENSION", "IMAGE"), "FOO").value == "FOO"

    ###  Regression tests: XTENSION values of the standard types are 8 characters  ###

    #  the IMAGE, TABLE, and BINTABLE values are padded to exactly 8 characters, whatever their padding.
    for (value, padded) in (("IMAGE", "IMAGE   "), ("image", "IMAGE   "), ("IMAGE ", "IMAGE   "),
                            ("IMAGE   ", "IMAGE   "), ("IMAGE      ", "IMAGE   "), ("Table  ", "TABLE   "),
                            ("TABLE", "TABLE   "), ("BINTABLE", "BINTABLE"), ("bintable ", "BINTABLE"),
                            ("BINTABLE   ", "BINTABLE"))
        card = Card("XTENSION", value)
        @test card.value == padded
        @test repr(card) == rpad("XTENSION= '$padded'", 80)
        @test repr(FITSFiles.setvalue!(Card("XTENSION", "FOO"), value)) == repr(card)
    end

    #  other values are not changed.
    for value in ("FOO", "I", "", " IMAGE", "IMAGES", "A3DTABLE", "BIN")
        @test Card("XTENSION", value).value == value
    end
    ###  Regression tests: long strings are split at a character  ###

    text = "The quick brown fox jumps over the lazy dog while the weather stays cloudy overnight with a low of twenty one"
    comment = "a comment about the observation of the object in the sky tonight"

    #  by default the value and the comment are split after the last space that fits.
    cards = collect(Card("OBJECT", text, comment))
    @test [rstrip(repr(c)) for c in cards] == [
        "OBJECT  = 'The quick brown &'  / a comment about the observation of the object",
        "CONTINUE  'fox jumps over &'   / in the sky tonight",
        "CONTINUE  'the lazy dog &'",
        "CONTINUE  'while the &'",
        "CONTINUE  'weather stays &'",
        "CONTINUE  'cloudy overnight &'",
        "CONTINUE  'with a low of &'",
        "CONTINUE  'twenty one'"]
    @test all(endswith(c.value, " ") for c in cards[1:end-1])
    @test !endswith(cards[end].value, " ")
    pieces = filter(!isempty, [c.comment for c in cards])
    @test all(endswith(c, " ") for c in pieces[1:end-1])
    @test all(length(repr(c)) == 80 for c in cards)
    @test FITSFiles.join_cards(cards).value == text
    @test join(c.comment for c in cards) == comment

    #  the value is split at any character if splitat is nothing, as before.
    cards = collect(Card("OBJECT", text, comment; splitat = nothing))
    @test [rstrip(repr(c)) for c in cards][1:3] == [
        "OBJECT  = 'The quick brown f&' / a comment about the observation of the object i",
        "CONTINUE  'ox jumps over the&' / n the sky tonight",
        "CONTINUE  ' lazy dog while t&'"]
    @test FITSFiles.join_cards(cards).value == text
    @test join(c.comment for c in cards) == comment

    #  the value is split after another character.
    commas = replace(text, " " => ",")
    cards = collect(Card("OBJECT", commas, ""; splitat = ','))
    @test all(endswith(c.value, ",") for c in cards[1:end-1])
    @test all(length(c.value) <= 67 for c in cards) && length(cards) > 1
    @test FITSFiles.join_cards(cards).value == commas
    @test collect(Card("OBJECT", text, ""; splitat = ','))[1].value != "The quick brown "

    #  a word that is longer than the card is split where it fits.
    long = "short " * repeat("x", 90) * " end"
    cards = collect(Card("OBJECT", long, ""))
    @test cards[1].value == "short "
    @test all(c.value == repeat("x", length(cards[2].value)) for c in cards[2:(end-1)]) && length(cards[2].value) > 17
    @test FITSFiles.join_cards(cards).value == long

    #  the split keeps the single quotes together, the spaces at the ends, and the long values.
    for value in (repeat("It's O'Hara's ", 6), " " * text, text * " ", replace(text, " " => "   "), repeat("'", 70),
                  repeat("' ", 40), repeat("ab ", 60), "a " * repeat("b", 50) * " c " * repeat("d", 50))
        for splitat in (' ', nothing, ',')
            cards = collect(Card("OBJECT", value, comment; splitat))
            @test FITSFiles.join_cards(cards).value == value
            @test join(c.comment for c in cards) == comment
            @test all(length(repr(c)) == 80 for c in cards)
            @test all(count("'", repr(c)) % 2 == 0 for c in cards)
        end
    end

    #  a string that fits on a card is not split, and a card that is read is not split again.
    @test Card("OBJECT", "a short string", "a comment") isa Card
    for img in (rstrip(repr(c)) for c in Card("OBJECT", text, comment; splitat = nothing))
        card = parse(Card, rpad(img, 80), nothing)
        @test rstrip(repr(card)) == img
    end
    images = [rpad(rstrip(repr(c)), 80) for c in Card("OBJECT", text, comment; splitat = nothing)]
    parsed = Card{<:Any}[parse(Card, images[1])]
    for img in images[2:end]
        push!(parsed, parse(Card, img, parsed[end]))
    end
    @test [repr(c) for c in parsed] == images
    @test FITSFiles.join_cards(parsed).value == text

    #  the lengths of the slices and the number of slices follow the same rule.
    for slen in (5, 10, 17, 30), splitat in (' ', nothing)
        n = FITSFiles.nslices(text, slen, true, splitat)
        @test length(FITSFiles.slices(text, slen, n, true, splitat)) == n
        @test last(last(FITSFiles.slices(text, slen, n, true, splitat))) == length(text)
    end

    ###  Regression tests: setvalue! splits a long string  ###

    text = "The quick brown fox jumps over the lazy dog while the weather stays cloudy overnight with a low of twenty one"
    img(s) = rpad(s, 80)

    #  a string that passes the separator of a card with a comment is split into the cards of a long string.
    card = parse(Card, img("OBJECT  = 'old' / the object"))
    cards = FITSFiles.setvalue!(card, text)
    @test cards isa Vector
    @test [FITSFiles.typename(c) for c in cards] == [Value{String}; fill(Continue, length(cards)-1)]
    @test [c.key for c in cards] == ["OBJECT"; fill("CONTINUE", length(cards)-1)]
    @test rstrip(repr(cards[1])) == "OBJECT  = 'The quick brown &'  / the object"
    @test rstrip(repr(cards[2])) == "CONTINUE  'fox jumps over &'"
    @test all(endswith(c.value, " ") for c in cards[1:end-1])
    @test all(length(repr(c)) == 80 for c in cards)
    @test FITSFiles.join_cards(cards).value == text
    @test cards[1].comment == "the object"

    #  the string and the comment are split at any character if splitat is nothing, or after another character.
    cards = FITSFiles.setvalue!(card, text; splitat = nothing)
    @test cards[1].value == "The quick brown f"
    @test FITSFiles.join_cards(cards).value == text
    cards = FITSFiles.setvalue!(card, replace(text, " " => ","); splitat = ',')
    @test cards[1].value == "The,quick,brown,"
    @test FITSFiles.join_cards(cards).value == replace(text, " " => ",")
    cards = FITSFiles.setvalue!(parse(Card, img("OBJECT  = 'old' / " * join(fill("long comment", 4), " "))), text)
    @test join(c.comment for c in cards) == join(fill("long comment", 4), " ")
    @test all(endswith(c.comment, " ") for c in filter(c -> !isempty(c.comment), cards)[1:end-1])

    #  a string that fits is not split, and a string without a comment fits until the end of the card.
    @test FITSFiles.setvalue!(card, "a short string") isa Card
    @test FITSFiles.setvalue!(card, "a short string").value == "a short string"
    card0 = parse(Card, img("OBJECT  = 'old'"))
    @test FITSFiles.setvalue!(card0, repeat("word ", 12)) isa Card
    @test length(rstrip(repr(FITSFiles.setvalue!(card0, repeat("word ", 12))))) == 72
    cards = FITSFiles.setvalue!(card0, repeat("word ", 30))
    @test length(cards) == 3
    @test rstrip(repr(cards[1])) == "OBJECT  = '" * repeat("word ", 13) * "&'"
    @test FITSFiles.join_cards(cards).value == repeat("word ", 30)

    #  the separator of the card is not before the default index, and a card with a later separator keeps it.
    narrow = parse(Card, img("OBJECT  = 'old' / c"))
    @test narrow.format.slsh < 20
    @test length(repr(FITSFiles.setvalue!(narrow, repeat("a", 17)))) == 80
    @test FITSFiles.setvalue!(narrow, repeat("a", 17)) isa Card
    #  a string that fits on a card moves the comment to the right, and is not split.
    moved = FITSFiles.setvalue!(narrow, repeat("a", 30))
    @test moved isa Card && moved.comment == "c" && length(repr(moved)) == 80
    @test rstrip(repr(moved)) == "OBJECT  = '" * repeat("a", 30) * "' / c"
    wide = Card("OBJECT", "old", "c"; slash = 60)
    @test FITSFiles.setvalue!(wide, repeat("a", 40)) isa Card
    @test FITSFiles.setvalue!(wide, repeat("a", 60)) isa Card
    @test length(FITSFiles.setvalue!(wide, repeat("a", 70))) > 1
    #  the comment is truncated if it does not fit on the card, and is continued if truncate is false.
    comment = "a comment that is continued on the next card"
    card = FITSFiles.setvalue!(Card("OBJECT", "old", comment), repeat("a", 60))
    @test card isa Card && card.value == repeat("a", 60) && card.comment == "a com"
    @test card.comment == parse(Card, repr(card)).comment && length(repr(card)) == 80
    @test FITSFiles.setvalue!(Card("OBJECT", "old", comment), repeat("a", 60); truncate = true) == card
    cards = FITSFiles.setvalue!(Card("OBJECT", "old", comment), repeat("a", 60); truncate = false)
    @test length(cards) > 1 && FITSFiles.join_cards(cards).value == repeat("a", 60)
    @test FITSFiles.join_cards(cards).comment == comment
    #  a comment that fits is the same for both settings, and a number that moves the comment is truncated.
    short = Card("OBJECT", "old", "c")
    for truncate in (true, false)
        @test FITSFiles.setvalue!(short, repeat("a", 60); truncate) isa Card
        @test FITSFiles.setvalue!(short, repeat("a", 60); truncate).comment == "c"
    end
    number = Card("N", 1, "a comment that is long enough")
    @test FITSFiles.setvalue!(number, 1.2345678901234567e-100; truncate = true).comment == "a comment that is long enough"
    long = Card("N", 1, repeat("x", 47))
    @test FITSFiles.setvalue!(long, 12345678901234567890123; truncate = true).comment ==
          parse(Card, repr(FITSFiles.setvalue!(long, 12345678901234567890123))).comment
    @test_throws "Comment does not fit on the card." FITSFiles.setvalue!(long, 12345678901234567890123; truncate = false)
    #  the string is split in the same way for both settings, if it does not fit on a card.
    for truncate in (true, false)
        cards = FITSFiles.setvalue!(Card("OBJECT", "old", "c"), repeat("word ", 30); truncate)
        @test length(cards) > 1 && FITSFiles.join_cards(cards).value == repeat("word ", 30)
    end
    for value in (repeat("It's O'Hara's ", 6), " " * text, text * " ", repeat("'", 70), repeat("x", 90))
        cards = FITSFiles.setvalue!(card, value)
        @test FITSFiles.join_cards(cards).value == value
        @test all(length(repr(c)) == 80 for c in cards)
    end

    #  a number never splits, and a long string of a HIERARCH card is an error.
    @test FITSFiles.setvalue!(card, 123456789012345678901234567890123456789) isa Card
    hier = parse(Card, img("HIERARCH ESO A = 'old' / c"))
    @test FITSFiles.setvalue!(hier, "a string") isa Card
    @test_throws ArgumentError FITSFiles.setvalue!(hier, repeat("long ", 20))

    #  setvalue! on a COMMENT or HISTORY card replaces the text and keeps the type.
    @testset "setvalue! of Comment and History" begin
        for key in ("COMMENT", "HISTORY")
            card = Card(key, "old")
            new = FITSFiles.setvalue!(card, "new text")
            @test FITSFiles.typename(new) == FITSFiles.typename(card)
            @test new.key == key && new.value == "new text"
            @test repr(new) == rpad("$key new text", 80)
            #  A value that is the same except for trailing spaces is not replaced.
            @test FITSFiles.setvalue!(card, "old  ") === card
            #  A missing value gives an empty card.
            @test repr(FITSFiles.setvalue!(card, missing)) == rpad(key, 80)
        end
        @test FITSFiles.typename(FITSFiles.setvalue!(Card("COMMENT", missing), "text")) ==
            FITSFiles.typename(Card("COMMENT", "text"))
    end

    #  setvalue! of a commentary card needs a string, and an END card has no value.
    @testset "setvalue! of the wrong type" begin
        @test_throws ArgumentError FITSFiles.setvalue!(Card("COMMENT", "a"), 1.5)
        @test_throws ArgumentError FITSFiles.setvalue!(Card("HISTORY", "a"), true)
        @test_throws ArgumentError FITSFiles.setvalue!(Card("COMMENT", "a"), 1 * Unitful.m)
        continued = parse(Card, rpad("CONTINUE  'a'", 80))
        @test_throws ArgumentError FITSFiles.setvalue!(continued, 5)
        @test_throws ArgumentError FITSFiles.setvalue!(continued, missing)
        @test_throws "END keyword has no value." FITSFiles.setvalue!(Card("END"), "x")
        @test_throws ArgumentError FITSFiles.setvalue!(Card("END"), 1)
        @test FITSFiles.setvalue!(Card("END"), missing) isa Card{FITSFiles.End}
        @test repr(FITSFiles.setvalue!(Card("COMMENT", "a"), missing)) == rpad("COMMENT", 80)
    end

    #  The layout keywords of the constructor of a card are the keywords of setvalue!, and the default is the layout of the card.
    @testset "setvalue! layout keywords" begin
        show_(c) = rstrip(repr(c))
        adjacent = parse(Card, rpad("KEY     = 1.5/ c", 80))
        @test show_(FITSFiles.setvalue!(adjacent, 2.5)) == "KEY     = 2.5/ c"
        @test show_(FITSFiles.setvalue!(adjacent, 2.5; lpad = 3)) == "KEY     = 2.5   / c"
        @test show_(FITSFiles.setvalue!(adjacent, 1.5; lpad = 3)) == "KEY     = 1.5   / c"
        spaced = parse(Card, rpad("KEY     = 1.5       /   c", 80))
        @test show_(FITSFiles.setvalue!(spaced, 2.5)) == "KEY     = 2.5       /   c"
        @test show_(FITSFiles.setvalue!(spaced, 2.5; slash = 50)) == "KEY     = 2.5" * " "^36 * "/   c"
        @test show_(FITSFiles.setvalue!(spaced, 2.5; rpad = 5)) == "KEY     = 2.5       /     c"
        @test show_(FITSFiles.setvalue!(spaced, 2.5; fixed = true)) == "KEY     =                  2.5 /   c"
        @test show_(FITSFiles.setvalue!(spaced, 2.5; fixed = false)) == show_(FITSFiles.setvalue!(spaced, 2.5))
        card = Card("KEY", "abc", "a comment")
        @test show_(FITSFiles.setvalue!(card, "def")) == "KEY     = 'def'                / a comment"
        @test show_(FITSFiles.setvalue!(card, "def"; slash = 50)) == "KEY     = 'def'" * " "^34 * "/ a comment"
        @test show_(FITSFiles.setvalue!(card, "def"; append = true)) == "KEY     = 'def&'               / a comment"
        #  a layout keyword formats the card again, even if the value is the same.
        @test FITSFiles.setvalue!(card, "abc") === card
        @test FITSFiles.setvalue!(card, "abc"; slash = 50) !== card
        @test show_(FITSFiles.setvalue!(card, "abc"; slash = 50)) == "KEY     = 'abc'" * " "^34 * "/ a comment"
        @test FITSFiles.setvalue!(card, "abc"; lpad = 1) !== card && FITSFiles.setvalue!(card, "abc"; fixed = true) !== card
        #  the same keywords are the keywords of the constructor, so the card is the card that is created.
        for kw in ((; slash = 50), (; lpad = 3, slash = 20), (; rpad = 4), (; fixed = false), (; upad = 3), (; slash = 40, rpad = 2))
            @test repr(FITSFiles.setvalue!(Card("KEY", "old", "a comment"; kw...), "new value"; kw...)) ==
                  repr(Card("KEY", "new value", "a comment"; kw...))
            @test repr(FITSFiles.setvalue!(Card("KEY", 1, "a comment"; kw...), 25; kw...)) == repr(Card("KEY", 25, "a comment"; kw...))
        end
        withunits = Card("KEY", 1.5f0 * Unitful.m, "c")
        @test show_(FITSFiles.setvalue!(withunits, 2.5f0; upad = 3)) == "KEY     =                  2.5 / [m]   c"
        @test show_(FITSFiles.setvalue!(withunits, 2.5f0)) == "KEY     =                  2.5 / [m] c"
        #  the separator of the cards of a long string.
        text = repeat("word ", 20)
        cards = FITSFiles.setvalue!(Card("KEY", "a", "c"), text; slash = 50)
        @test length(cards) > 1 && all(length(repr(c)) == 80 for c in cards)
        @test FITSFiles.join_cards(cards).value == text
        @test length(FITSFiles.setvalue!(Card("KEY", "a", "c"), text; slash = 50)) <
              length(FITSFiles.setvalue!(Card("KEY", "a", "c"), text; slash = 20))
        #  the keywords of the list are the keywords of the card.
        list = Card{<:Any}[Card("KEY", "a", "c")]
        FITSFiles.setvalue!(list, "KEY", "bbb"; slash = 50, rpad = 3)
        @test show_(list[1]) == "KEY     = 'bbb'" * " "^34 * "/   c"
        @test_throws MethodError FITSFiles.setvalue!(list, "KEY", "bbb"; unknown = 1)
    end

end

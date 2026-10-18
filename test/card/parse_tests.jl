@testset "Card parse" begin
    ###  parse End Cards

    #   simple END card
    @test isequal(showfields(parse(Card,
                   "END                                                                             ")),
                  ("END", missing, "",
                   "END                                                                             "))

    #   Invalid END card
    @test isequal(typeof(parse(Card,
                   "END       a value                                                               ")),
                   Card{Invalid})

    #  parse blank keyword
    @test isequal(showfields(parse(Card,
                   "               / exposure information                                           ")),
                  ("", "       / exposure information", "",
                   "               / exposure information                                           "))

    ###  parse Blank keyword

    #  parse blank keyword without comment
    @test isequal(showfields(parse(Card,
                   "                                                                                ")),
                   ("", "", "",
                   "                                                                                "))

    #  parse blank keyword with commment
    @test isequal(showfields(parse(Card,
                   "        A comment                                                               ")),
                   ("", "A comment", "",
                   "        A comment                                                               "))

    #  parse blank keyword with apparent commment string
    @test isequal(showfields(parse(Card,
                   "                               / A comment                                      ")),
                   ("", "                       / A comment", "",
                   "                               / A comment                                      "))

    ###  parse COMMENT keyword

    #  parse blank keyword without comment
    @test isequal(showfields(parse(Card,
                   "COMMENT                                                                         ")),
                   ("COMMENT", "", "",
                   "COMMENT                                                                         "))

    #  parse blank keyword with commment
    @test isequal(showfields(parse(Card,
                   "COMMENT A comment                                                               ")),
                   ("COMMENT", "A comment", "",
                   "COMMENT A comment                                                               "))

    #  parse blank keyword with apparent commment string
    @test isequal(showfields(parse(Card,
                   "COMMENT                        / A comment                                      ")),
                   ("COMMENT", "                       / A comment", "",
                   "COMMENT                        / A comment                                      "))

    #  parse Comment Card string
    @test isequal(showfields(parse(Card,
                   "COMMENT card has no comments. / text after slash is still part of the value.    ")),
                  ("COMMENT", "card has no comments. / text after slash is still part of the value.", "",
                   "COMMENT card has no comments. / text after slash is still part of the value.    "))

    ###  parse HISTORY keyword

    #  parse blank keyword without comment
    @test isequal(showfields(parse(Card,
                   "HISTORY                                                                         ")),
                   ("HISTORY", "", "",
                   "HISTORY                                                                         "))

    #  parse blank keyword with commment
    @test isequal(showfields(parse(Card,
                   "HISTORY A comment                                                               ")),
                   ("HISTORY", "A comment", "",
                   "HISTORY A comment                                                               "))

    #  parse blank keyword with apparent commment string
    @test isequal(showfields(parse(Card,
                   "HISTORY                        / A comment                                      ")),
                   ("HISTORY", "                       / A comment", "",
                   "HISTORY                        / A comment                                      "))

    #  parse History Card with numerical value.
    @test isequal(showfields(parse(Card,
                   "HISTORY  (1, 2)                                                                 ")),
                  ("HISTORY", " (1, 2)", "",
                   "HISTORY  (1, 2)                                                                 "))

    #  parse History Card  with equal sign (=) in column >=9
    @test isequal(showfields(parse(Card,
                   "HISTORY =   (1, 2)                                                              ")),
                  ("HISTORY", "=   (1, 2)", "",
                   "HISTORY =   (1, 2)                                                              "))

    #  an undefined value card round trips through its image
    @test isequal(showfields(parse(Card,
                   "UNDEF   =                      / a comment                                      ")),
                  ("UNDEF", missing, "a comment",
                   "UNDEF   =                      / a comment                                      "))

    #  parse Value card with boolean value, fixed format
    @test isequal(showfields(parse(Card,
                   "BOOL    =                    T                                                  ")),
                  ("BOOL", true, "",
                   "BOOL    =                    T                                                  "))

    #  parse Value card with boolean value, free format
    @test parse(Card, "BOOL    = T                                                                     "
                    ).format.fixd == false

    #  parse Value card with boolean value, free format
    @test isequal(showfields(parse(Card,
                   "BOOL    = T                                                                     ")),
                  ("BOOL", true, "",
                   "BOOL    = T                                                                     "))

    #  parse Value card with boolean value and comment, fixed format
    @test isequal(showfields(parse(Card,
                   "BOOL    =                    T / a comment string                               ")),
                  ("BOOL", true, "a comment string",
                   "BOOL    =                    T / a comment string                               "))

    #  parse Value card with boolean value and comment, free format
    @test isequal(showfields(parse(Card,
                   "BOOL    = T                    / a comment string                               ")),
                  ("BOOL", true, "a comment string",
                   "BOOL    = T                    / a comment string                               "))

    #  parse Value Card with integer value fixed-format
    @test isequal(showfields(parse(Card,
                   "INTEGER =                12345                                                  ")),
                  ("INTEGER", 12345, "",
                   "INTEGER =                12345                                                  "))

    #  parse Value Card with integer value free-format
    @test parse(Card, "INTEGER = 12345                                                                 "
                    ).format.fixd == false

    #  parse Value Card with integer value free-format
    @test isequal(showfields(parse(Card,
                   "INTEGER = 12345                                                                 ")),
                  ("INTEGER", 12345, "",
                   "INTEGER = 12345                                                                 "))

    #  parse Value card with integer value and comment, fixed-format
    @test isequal(showfields(parse(Card,
                   "INTEGER =                12345 / a comment string                               ")),
                  ("INTEGER", 12345, "a comment string",
                   "INTEGER =                12345 / a comment string                               "))

    #  parse Value card with integer value and comment, free-format
    @test isequal(showfields(parse(Card,
                   "INTEGER = 12345                / a comment string                               ")),
                  ("INTEGER", 12345, "a comment string",
                   "INTEGER = 12345                / a comment string                               "))

    #  parse Value Card with big integer value
    @test isequal(showfields(parse(Card,
                   "LONG_INT= -467374636747637647347374734737437                                    ")),
                  ("LONG_INT", -467374636747637647347374734737437, "",
                   "LONG_INT= -467374636747637647347374734737437                                    "))

    #  parse Value Card with big integer value and comment
    @test isequal(showfields(parse(Card,
                   "LONG_INT= -467374636747637647347374734737437 / a comment string                 ")),
                  ("LONG_INT", -467374636747637647347374734737437, "a comment string",
                   "LONG_INT= -467374636747637647347374734737437 / a comment string                 "))

    #  create Value Card with 32-bit float value, fixed-format
    @test isequal(showfields(parse(Card,
                   "FLOAT_32=             1.2345E6                                                  ")),
                   ("FLOAT_32", 1.2345f6, "",
                   "FLOAT_32=             1.2345E6                                                  "))

    #  parse Value Card with 64-bit float value, fixed-format
    @test isequal(showfields(parse(Card,
                   "FLOAT_64=         1.2345678901                                                  ")),
                  ("FLOAT_64", 1.2345678901, "",
                   "FLOAT_64=         1.2345678901                                                  "))

    #  test Value Card with 64-bit floating point value
    @test parse(Card, "FLOAT_64= 1.2345                                                                "
                    ).format.fixd == false

    #  parse Value Card with 64-bit float value, free-format
    @test isequal(showfields(parse(Card,
                   "FLOAT_64= 1.2345678901                                                          ")),
                  ("FLOAT_64", 1.2345678901, "",
                   "FLOAT_64= 1.2345678901                                                          "))

    #  parse Value Card with 64-bit float value, fixed-format
    @test isequal(showfields(parse(Card,
                   "FLOAT_64=         1.2345678901 / a comment string                               ")),
                  ("FLOAT_64", 1.2345678901, "a comment string",
                   "FLOAT_64=         1.2345678901 / a comment string                               "))

    #  create Value Card with 64-bit float value, free-format
    @test isequal(showfields(Card("FLOAT_64", 1.2345, "a comment string"; fixed=false)),
                  ("FLOAT_64", 1.2345, "a comment string",
                   "FLOAT_64= 1.2345               / a comment string                               "))

               #  parse Value Card with 64-bit float value, free-format
    @test isequal(showfields(parse(Card,
                   "FLOAT_64= 1.2345678901         / a comment string                               ")),
                  ("FLOAT_64", 1.2345678901, "a comment string",
                   "FLOAT_64= 1.2345678901         / a comment string                               "))

    #  parse Value Card with 64-bit float value, fixed-format
    @test isequal(showfields(parse(Card,
                   "FLOAT_64=             1.2345D6                                                  ")),
                  ("FLOAT_64", 1.2345e6, "",
                   "FLOAT_64=             1.2345D6                                                  "))

    #  parse Value Card with 64-bit float value having high precision, fixed-format
    @test isequal(showfields(parse(Card,
                   "FLOAT_64=   1.23456789012345E6                                                  ")),
                  ("FLOAT_64", 1.23456789012345e6, "",
                   "FLOAT_64=   1.23456789012345E6                                                  "))

    #  parse Value Card with 64-bit float value having high exponent, fixed-format
    @test isequal(showfields(parse(Card,
                   "FLOAT_64=            1.2345E39                                                  ")),
                  ("FLOAT_64", 1.2345e39, "",
                   "FLOAT_64=            1.2345E39                                                  "))

    #  parse Value Card with complex 64-bit integer value
    @test isequal(showfields(parse(Card,
                   "CPLX_INT= (8, 9)                                                                ")),
                  ("CPLX_INT", 8 + 9im, "",
                   "CPLX_INT= (8, 9)                                                                "))

    #  parse Value Card with complex 64-bit integer value
    @test isequal(showfields(parse(Card,
                   "CPLX_INT= (8, 9)               / a comment string                               ")),
                  ("CPLX_INT", 8 + 9im, "a comment string",
                   "CPLX_INT= (8, 9)               / a comment string                               "))

    #  parse Value Card with complex 64-bit float value
    @test isequal(showfields(parse(Card,
                   "CPLX_F64= (8.1, 9.2)                                                            ")),
                  ("CPLX_F64", 8.1f0 + 9.2f0im, "",
                   "CPLX_F64= (8.1, 9.2)                                                            "))

    #  parse Value Card with complex 64-bit float value
    @test isequal(showfields(parse(Card,
                   "CPLX_F64= (8.1, 9.2)           / a comment string                               ")),
                  ("CPLX_F64", 8.1f0 + 9.2f0im, "a comment string",
                   "CPLX_F64= (8.1, 9.2)           / a comment string                               "))

    #  parse Value Card with complex 64-bit float and integer value
    @test isequal(showfields(parse(Card,
                   "CPLX_F64= (8.1, 9)                                                              ")),
                  ("CPLX_F64", 8.1f0 + 9.0f0im, "",
                   "CPLX_F64= (8.1, 9)                                                              "))

    #  parse Value Card with complex 64-bit float and integer value
    @test isequal(showfields(parse(Card,
                   "CPLX_F64= (8.1, 9)             / a comment string                               ")),
                  ("CPLX_F64", 8.1f0 + 9.0f0im, "a comment string",
                   "CPLX_F64= (8.1, 9)             / a comment string                               "))

    #  parse Value Card with complex integer and 64-bit float value
    @test isequal(showfields(parse(Card,
                   "CPLX_F64= (8, 9.2)                                                              ")),
                  ("CPLX_F64", 8.0f0 + 9.2f0im, "",
                   "CPLX_F64= (8, 9.2)                                                              "))

    #  parse Value Card with complex integer and 64-bit float value
    @test isequal(showfields(parse(Card,
                   "CPLX_F64= (8, 9.2)             / a comment string                               ")),
                  ("CPLX_F64", 8.0f0 + 9.2f0im, "a comment string",
                   "CPLX_F64= (8, 9.2)             / a comment string                               "))

    #  parse Value Card with a null string
    @test isequal(showfields(parse(Card,
                   "STRING  = ''                                                                    ")),
                  ("STRING", "", "",
                   "STRING  = ''                                                                    "))

    #  parse Value Card with an empty string, which is a single space
    @test isequal(showfields(parse(Card,
                   "STRING  = '        '                                                            ")),
                  ("STRING", " ", "",
                   "STRING  = '        '                                                            "))

    #  parse Value Card with string value
    @test isequal(showfields(parse(Card,
                   "STRING  = 'a value string'                                                      ")),
                  ("STRING", "a value string", "",
                   "STRING  = 'a value string'                                                      "))

    #  parse Value Card with string value
    @test isequal(showfields(parse(Card,
                   "STRING  = 'a value string'     / a comment string                               ")),
                  ("STRING", "a value string", "a comment string",
                   "STRING  = 'a value string'     / a comment string                               "))

    #  parse Value Card with string of <8 characters
    @test isequal(showfields(parse(Card,
                   "STRING  = '<8 ch'                                                               ")),
                  ("STRING", "<8 ch", "",
                   "STRING  = '<8 ch'                                                               "))

    #  parse String Card have a string with a single quote
    @test isequal(showfields(parse(Card,
                   "STRING  = 'Kelley O''Hara'                                                      ")),
                  ("STRING", "Kelley O'Hara", "",
                   "STRING  = 'Kelley O''Hara'                                                      "))

    #  parse String Card have a string with a single quote and comment
    @test isequal(showfields(parse(Card,
                   "STRING  = 'Kelley O''Hara'     / a comment string                               ")),
                  ("STRING", "Kelley O'Hara", "a comment string",
                   "STRING  = 'Kelley O''Hara'     / a comment string                               "))

    #  parse String Card have a string with a single quote and comment with a single quote
    @test isequal(showfields(parse(Card,
                   "STRING  = 'Kelley O''Hara'     / a comment string with single quote '           ")),
                  ("STRING", "Kelley O'Hara", "a comment string with single quote '",
                   "STRING  = 'Kelley O''Hara'     / a comment string with single quote '           "))

    #  parse String Card that truncates comment
    @test isequal(showfields(parse(Card,
                   "STRING  = '----------------------------------------------------------' / a trunc")),
                  ("STRING", "----------------------------------------------------------", "a trunc",
                   "STRING  = '----------------------------------------------------------' / a trunc"))

    #  parse Value card with no left and right padding for comment separator
    @test isequal(showfields(parse(Card,
                   "LONGCOM = '19 character string'/a comment string                                ")),
                  ("LONGCOM", "19 character string", "a comment string",
                   "LONGCOM = '19 character string'/a comment string                                "))

    #  create Value card with 4 spaces each for left and right padding for comment separator
#    @test isequal(showfields(Card("longcom", "character string", "a comment string", lpad=4, rpad=4)),
#                  ("LONGCOM", "character string", "a comment string",
#                   "LONGCOM = 'character string'    /    a comment string                           "))

    #  parse Value card with 4 spaces each for left and right padding for comment separator
    @test isequal(showfields(parse(Card,
                   "LONGCOM = 'character string'    /    a comment string                           ")),
                  ("LONGCOM", "character string", "a comment string",
                   "LONGCOM = 'character string'    /    a comment string                           "))

    #   create Value Card having lower case Bintable XTENSION
    @test isequal(showfields(Card("XTENSION", "bintable", "a comment string")),
                  ("XTENSION", "BINTABLE", "a comment string",
                   "XTENSION= 'BINTABLE'           / a comment string                               "))

     #   parse Value Card having Bintable XTENSION
    @test isequal(showfields(parse(Card,
                   "XTENSION= 'BINTABLE'           / a comment string                               ")),
                  ("XTENSION", "BINTABLE", "a comment string",
                   "XTENSION= 'BINTABLE'           / a comment string                               "))

    #  parse HIERARCH keyword and value
    #=
    @test isequal(showfields(parse(Card,
                   "HIERARCH ABC DEF GH IJKLMN = -99.9                                              ")),
                   ("ABC DEF GH IJKLMN", -99.9, "",
                   "HIERARCH ABC DEF GH IJKLMN = -99.9                                              "))
    =#

    #  parse HIERARCH keyword and value with comment

    @test isequal(showfields(parse(Card,
                   "HIERARCH ABC DEF GH IJKLM_- = -99.9 / [m] abcdef ghijklm nopqrstu vw xyzab      ")),
                  ("ABC DEF GH IJKLM_-", -99.9f0, "abcdef ghijklm nopqrstu vw xyzab",
                   "HIERARCH ABC DEF GH IJKLM_- = -99.9 / [m] abcdef ghijklm nopqrstu vw xyzab      "))
    @test parse(Card, "HIERARCH ABC DEF GH IJKLM_- = -99.9 / [m] abcdef ghijklm nopqrstu vw xyzab      ").units == Unitful.m

    ###  Regression tests: units in comments  ###

    #  a units string in the comment is not lost when a card is parsed, and is written again.
    img = rpad("EXPTIME =               1200. / [s] exposure time", 80)
    card = parse(Card, img)
    @test card.value === 1200.0f0
    @test card.units == Unitful.s
    @test card.comment == "exposure time"
    @test occursin("/ [s] exposure time", repr(card))

    img = rpad("OBJECT  = 'Cygnus X-1' / [see note] the object", 80)
    card = parse(Card, img)
    @test card.value == "Cygnus X-1"
    @test card.comment == "[see note] the object"
    @test repr(card) == img

    #  a units string written from a Quantity is read back as the units.
    card = Card("EXPTIME", 1200.0f0 * Unitful.s, "exposure time")
    @test parse(Card, repr(card)).comment == "exposure time"
    @test parse(Card, repr(card)).value === 1200.0f0
    @test parse(Card, repr(card)).units == Unitful.s
    @test parse(Card, repr(card); units = false).comment == "[s] exposure time"

    ###  Regression tests: short images  ###

    #  an image that is not 80 characters is an invalid card.
    for image in ("", "ABC", "ABCDEFGH", "ABCDEFGHI", "KEY     = 1")
        @test parse(Card, image) isa Card{Invalid}
    end
    @test parse(Card, "ABC").key == "ABC"
    @test parse(Card, "KEY     = 1").value == "= 1"

    ###  Regression tests: HIERARCH keyword and byte 9  ###

    #  a HIERARCH card requires a space in byte 9, otherwise the record is commentary.
    img = rpad("HIERARCHX ESO A = 1", 80)
    card = parse(Card, img)
    @test FITSFiles.typename(card) == Comment
    @test (card.key, card.value) == ("HIERARCH", "X ESO A = 1")
    @test repr(card) == img
    img = rpad("HIERARCH ESO A = 1", 80)
    @test FITSFiles.typename(parse(Card, img)) == Hierarch{Int}
    @test repr(parse(Card, img)) == img

    #  a HIERARCH keyword with a value indicator in bytes 9 and 10 is a value card.
    img = rpad("HIERARCH= 5 / a comment", 80)
    card = parse(Card, img)
    @test FITSFiles.typename(card) == Value{Int}
    @test (card.key, card.value, card.comment) == ("HIERARCH", 5, "a comment")

    ###  Regression tests: orphaned CONTINUE cards  ###

    #  a CONTINUE card that does not continue a string is commentary text.
    img = rpad("CONTINUE  'some text&' / a comment", 80)
    for previous in (nothing, Card("KEY", 5), Card("KEY", "no ampersand"),
                     Card("HIERARCH", "ESO A", "O&", ""), Card("COMMENT", "text"),
                     Card("KEY", "text&; "))
        card = parse(Card, img, previous)
        @test FITSFiles.typename(card) == Comment
        @test (card.key, card.value) == ("CONTINUE", "  'some text&' / a comment")
        @test repr(card) == img
    end

    #  a CONTINUE card that continues a string is a CONTINUE card.
    first_ = parse(Card, rpad("KEY     = 'first &'", 80))
    card = parse(Card, img, first_)
    @test FITSFiles.typename(card) == Continue
    @test (card.key, card.value, card.comment) == ("CONTINUE", "some text", "a comment")
    @test FITSFiles.typename(parse(Card, rpad("CONTINUE  'last'", 80), card)) == Continue

    #  a CONTINUE card that follows the last card of a continued string is commentary text.
    last_ = parse(Card, rpad("CONTINUE  'last'", 80), card)
    @test FITSFiles.typename(parse(Card, img, last_)) == Comment

    #  other cards are not changed by a previous card.
    img = rpad("KEY     = 5 / a comment", 80)
    @test repr(parse(Card, img, nothing)) == repr(parse(Card, img))

    #  reading a header converts orphaned CONTINUE cards, also across blocks.
    function header(images...)
        text = join(rpad.(images, 80)) * rpad("END", 80)
        IOBuffer(rpad(text, 2880 * cld(length(text), 2880)))
    end
    cards, _, _ = read(header("SIMPLE  =                    T", "KEY     = 'first &'",
        "CONTINUE  'second&'", "CONTINUE  'third'", "CONTINUE  'orphan'"), Card)
    @test FITSFiles.typename.(cards) ==
          [Value{Bool}, Value{String}, Continue, Continue, Comment]
    @test cards[end].key == "CONTINUE"

    images = ["SIMPLE  =                    T"; fill("", 34); "KEY     = 'first &'";
              "CONTINUE  'second'"; "CONTINUE  'orphan'"]
    cards, _, _ = read(header(images...), Card)
    @test FITSFiles.typename.(cards[36:38]) == [Value{String}, Continue, Comment]

    ###  Regression tests: records without a value indicator  ###

    #  a record without a value indicator is commentary text.
    for img in ("FOO      some text", "FOO", "FOO-BAR_1  text", "FOO      'a string'", "SIMPLE   text")
        img = rpad(img, 80)
        card = parse(Card, img)
        @test FITSFiles.typename(card) == Comment
        @test (card.key, card.value) == (rstrip(img[1:8]), rstrip(img[9:end]))
        @test repr(card) == img
    end

    #  END and records with an illegal keyword are invalid cards.
    for img in ("END       a value", "foo      some text", "A B      some text", " FOO     some text",
                "foo     = 1")
        @test parse(Card, rpad(img, 80)) isa Card{Invalid}
    end

    #  a record with a value indicator is not commentary text.
    @test FITSFiles.typename(parse(Card, rpad("FOO     = 1", 80))) == Value{Int}

    ###  Regression tests: malformed values  ###

    #  a record with a malformed value is an invalid card that keeps its text.
    for img in ("KEY     = 'unterminated", "KEY     = abc", "KEY     = (1, 2", "KEY     = 1 2 3",
                "KEY     = 1.5.5 / c", "KEY     = T F", "KEY     = 'a' 'b'", "KEY     = 'a' b",
                "KEY     = 5 6 / c", "KEY     = 1,5", "KEY     = é", "KEY     = 'é'",
                "CONTINUE  'a' b", "CONTINUE  abc", "BITPIX  = sixteen")
        img = rpad(img, 80)
        card = parse(Card, img)
        @test card isa Card{Invalid}
        @test card.key == rstrip(img[1:8])
        @test repr(card) == img
    end

    #  valid records are not changed.
    for (img, type, value, comment) in (("KEY     = 5 / a comment", Value{Int}, 5, "a comment"),
            ("KEY     = 'a b' / c / d", Value{String}, "a b", "c / d"),
            ("KEY     = 'it''s'", Value{String}, "it's", ""),
            ("KEY     = / a comment", Value{Missing}, missing, "a comment"),
            ("KEY     =", Value{Missing}, missing, ""),
            ("KEY     = T / [m] 1 2 3", Value{Bool}, true, "[m] 1 2 3"),
            ("KEY     = (1.5, 2) / c", Value{ComplexF32}, 1.5f0 + 2.0f0im, "c"),
            ("CONTINUE  'a b&' / c", Continue, "a b", "c"))
        card = parse(Card, rpad(img, 80))
        @test FITSFiles.typename(card) == type
        @test isequal(card.value, value)
        @test card.comment == comment
    end

    #  a HIERARCH record with a malformed value is commentary text.
    for img in ("HIERARCH ESO A = 'unterminated", "HIERARCH ESO A = abc", "HIERARCH ESO A = 1 2 3")
        img = rpad(img, 80)
        card = parse(Card, img)
        @test FITSFiles.typename(card) == Comment
        @test card.key == "HIERARCH"
        @test repr(card) == img
    end

    ###  Regression tests: spaces that are not part of a string value  ###

    #  the spaces after an ampersand and before the string in free-format are restored on write.
    for img in ("K       = 'abc &     ' / c", "CONTINUE  'abc &     ' / c", "K       =   'ABC' / c",
                "K       = 'abc &' / c", "K       =     'a b &  ' / c", "K       = 'it''s &   ' / c",
                "CONTINUE  'x''&   '", "K       = 'ABC   ' / c", "K       = '' / c", "K       = '   ' / c",
                "K       = '&   ' / c", "XTENSION= 'IMAGE   '           / c")
        img = rpad(img, 80)
        card = parse(Card, img)
        @test repr(card) == img
    end

    #  the value does not include the spaces that follow the ampersand.
    @test parse(Card, rpad("K       = 'abc &     ' / c", 80)).value == "abc "
    @test parse(Card, rpad("K       =   'ABC' / c", 80)).value == "ABC"

    #  a string value that is created is not changed.
    @test repr(Card("K", "abc", "c")) == rpad("K       = 'abc'                / c", 80)
    @test repr(Card("K", "O'HARA", "c"; fixed = false)) == rpad("K       = 'O''HARA'            / c", 80)

    ###  Regression tests: trailing spaces of a string value  ###

    #  the trailing spaces of a string are not significant, and the card is written as it was read.
    for (img, value) in (("K       = 'ABC   ' / c", "ABC"), ("K       = 'ABC' / c", "ABC"),
                         ("K       = '' / c", ""), ("K       = ' ' / c", " "), ("K       = '    ' / c", " "),
                         ("K       = '  ABC  ' / c", "  ABC"), ("K       =   'ABC   ' / c", "ABC"),
                         ("K       = 'A  B   ' / c", "A  B"), ("CONTINUE  'ABC   ' / c", "ABC"),
                         ("XTENSION= 'IMAGE   '           / c", "IMAGE"), ("XTENSION= 'BINTABLE'", "BINTABLE"))
        img = rpad(img, 80)
        card = parse(Card, img)
        @test card.value == value
        @test repr(card) == img
    end

    #  the trailing spaces of a string that continues are significant.
    for (img, value) in (("K       = 'abc   &' / c", "abc   "), ("CONTINUE  'abc   &   ' / c", "abc   "),
                         ("K       = ' &' / c", " "), ("K       = 'abc  &    '", "abc  "))
        card = parse(Card, rpad(img, 80))
        @test card.value == value
        @test repr(card) == rpad(img, 80)
    end

    #  the trailing spaces of a string are not significant when a value is set.
    card = parse(Card, rpad("K       = 'ABC   ' / c", 80))
    @test FITSFiles.setvalue!(card, "ABC") === card
    @test FITSFiles.setvalue!(card, "ABC  ") === card
    @test FITSFiles.setvalue!(card, "ABD").value == "ABD"
    card = parse(Card, rpad("K       = '' / c", 80))
    @test FITSFiles.setvalue!(card, "").value == ""
    @test FITSFiles.setvalue!(card, " ").value == " "
    @test FITSFiles.setvalue!(parse(Card, rpad("K       = ' ' / c", 80)), "  ").value == " "
    @test FITSFiles.setvalue!(parse(Card, rpad("K       = ' ' / c", 80)), "").value == ""

    ###  Regression tests: lower case exponent letters  ###

    #  a number with a lower case exponent letter is not allowed by the standard, so it is an invalid
    #  card, unless the parsing is not strict.
    for img in ("K       = 1.0e3", "K       = 1.0d3", "K       = 1e3", "K       = -.5d0 / c",
                "K       = (1.0e3, 2)", "K       = (1, 2.0d1) / c", "HIERARCH ESO A = 1.0e3 / c")
        img = rpad(img, 80)
        for card in (parse(Card, img), parse(Card, img; strict = true), parse(Card, img, nothing))
            @test FITSFiles.typename(card) in (Invalid, Comment)
            @test repr(card) == img
        end
    end
    @test parse(Card, rpad("K       = 1.0e3", 80)) isa Card{Invalid}
    @test FITSFiles.typename(parse(Card, rpad("HIERARCH ESO A = 1.0e3", 80))) == Comment

    #  the numbers of a card that is not strict have the types of the numbers with upper case letters.
    for (img, value) in (("K       = 1.0e3", 1000.0f0), ("K       = 1.0d3", 1000.0), ("K       = 1e3", 1000.0f0),
                         ("K       = -2.5e-3 / c", -0.0025f0), ("K       = 1.0e50", 1.0e50),
                         ("K       = .5d0", 0.5), ("K       = 5.e1", 50.0f0), ("K       = 1.5D3", 1500.0),
                         ("K       = (1.0e3, -2.0d1)", 1000.0 - 20.0im), ("K       = (1.5e0, 2.5e0) / c", 1.5f0 + 2.5f0im),
                         ("K       = (1, 2.0d1)", 1.0 + 20.0im))
        card = parse(Card, rpad(img, 80); strict = false)
        @test card.value === value
        @test card isa Card{Value{typeof(value)}}
        #  the card is written with the standard exponent letter, and is a valid card. A double precision
        #  number that is exact in single precision is read as a single precision number.
        @test !occursin(r"\d[de]", repr(card))
        @test parse(Card, repr(card)).value == value
        @test parse(Card, rpad(img, 80), nothing; strict = false).value === value
    end
    card = parse(Card, rpad("K       = 1.0e3 / a comment", 80); strict = false)
    @test card.comment == "a comment"
    card = parse(Card, rpad("HIERARCH ESO A = 1.0e3 / a comment", 80); strict = false)
    @test FITSFiles.typename(card) == Hierarch{Float32}
    @test (card.key, card.value, card.comment) == ("ESO A", 1000.0f0, "a comment")
    @test parse(Card, repr(card)).value === 1000.0f0
    @test parse(Card, rpad("HIERARCH ESO A = (1.0e3, 2.0d0)", 80); strict = false).value === 1000.0 + 2.0im

    #  numbers that follow the standard are the same, whether the parsing is strict or not.
    for img in ("K       = 5", "K       = -1.5 / c", "K       = 1.0E3", "K       = 1.0D3", "K       = (1.0E3, 2)",
                "K       = 'a string'", "K       = T", "K       =", "HIERARCH ESO A = 1.0E3 / c")
        img = rpad(img, 80)
        card, lenient = parse(Card, img), parse(Card, img; strict = false)
        @test isequal(card.value, lenient.value) && card.comment == lenient.comment
        @test FITSFiles.typename(card) == FITSFiles.typename(lenient)
        @test repr(card) == repr(lenient)
    end

    #  numbers that are not valid FORTRAN or standard numbers are invalid cards, even if not strict.
    for img in ("K       = 1 000", "K       = 1,5", "K       = 1.5.5", "K       = 1.5+3", "K       = 1.0 e3",
                "K       = 1.0e 3", "K       = 1.0ee3", "K       = + 2.1", "K       = 1.0e", "K       = e3",
                "K       = 1.0e+", "K       = 1.0f3", "K       = 1.0 d 3", "K       = (1.0e3 2)", "K       = Inf",
                "K       = NaN", "K       = 0x10")
        for strict in (true, false)
            @test parse(Card, rpad(img, 80); strict) isa Card{Invalid}
        end
    end
    #  A HIERARCH card with an empty value field has a missing value.
    @testset "HIERARCH with undefined value" begin
        for image in ("HIERARCH ESO A =", "HIERARCH ESO A =                  ")
            card = parse(Card, rpad(image, 80))
            @test FITSFiles.typename(card) == Hierarch{Missing}
            @test card.key == "ESO A" && ismissing(card.value) && isempty(card.comment)
            @test repr(card) == rpad(image, 80)
        end
        #  The comment keeps its position when the value is empty.
        for image in ("HIERARCH ESO A = / a comment", "HIERARCH ESO A =      / a comment",
            "HIERARCH ESO A     = / [m] a comment", "HIERARCH ESO A = /")
            card = parse(Card, rpad(image, 80))
            @test FITSFiles.typename(card) == Hierarch{Missing}
            @test ismissing(card.value)
            @test repr(card) == rpad(image, 80)
        end
        @test parse(Card, rpad("HIERARCH ESO A = / a comment", 80)).comment == "a comment"
    end

    #  An image with a character that is not ASCII is invalid, and does not misalign the card.
    @testset "non-ASCII image" begin
        for image in (rpad("caf\u00e9    = 1 / comment", 79), rpad("KEY     = 'caf\u00e9'", 79),
            rpad("ABC\u00e9\u00e9\u00e9\u00e9\u00e9= 1", 80), "short \u00e9")
            card = parse(Card, image)
            @test FITSFiles.typename(card) == FITSFiles.Invalid
            @test length(repr(card)) <= 80
        end
        card = parse(Card, rpad("caf\u00e9    = 1", 80))
        @test FITSFiles.typename(card) == FITSFiles.Invalid && card.key == "caf\u00e9"
        @test length(repr(card)) == 80
    end

    #  A CONTINUE card without a string is commentary text, which is written as it is read.
    @testset "CONTINUE without a string" begin
        for image in ("CONTINUE   / a comment", "CONTINUE  12", "CONTINUE  T", "CONTINUE")
            card = parse(Card, rpad(image, 80))
            @test FITSFiles.typename(card) == FITSFiles.Comment
            @test card.key == "CONTINUE"
            @test repr(card) == rpad(image, 80)
        end
        @test FITSFiles.typename(parse(Card, rpad("CONTINUE  'a'", 80))) == FITSFiles.Continue
    end

    #  A key and an image are padded by the number of characters, so a control character
    #  does not change the length of the image.
    @testset "control characters" begin
        image = "T==E=\t*_B)0,./dC\t9&,+d)"
        card = parse(Card, image * " "^(80 - length(image)))
        @test FITSFiles.typename(card) == FITSFiles.Invalid
        @test length(repr(card)) == 80
        @test FITSFiles.rpad_key("a\tb") == "a\tb" * " "^5
    end

    #  The END keyword has no value.
    @testset "END with a value" begin
        @test FITSFiles.typename(parse(Card, rpad("END", 80))) == FITSFiles.End
        @test FITSFiles.typename(parse(Card, rpad("END     = 1", 80))) == FITSFiles.Invalid
        @test FITSFiles.typename(parse(Card, rpad("END     = 'a' / c", 80))) == FITSFiles.Invalid
        @test FITSFiles.typename(parse(Card, rpad("END     abc", 80))) == FITSFiles.Invalid
    end

    #  The trailing spaces of a HIERARCH string are not significant, and are restored on write.
    @testset "HIERARCH string spaces" begin
        for (image, value) in (("HIERARCH ESO A = 'ab  ' / c", "ab"), ("HIERARCH ESO A =   '  ab' / c", "  ab"),
            ("HIERARCH ESO A = ' '", " "), ("HIERARCH ESO A = '' / c", ""),
            ("HIERARCH ESO A = 'a''b  '", "a'b"),
            ("HIERARCH ESO INS OPTI-3 ID = 'ESO#427 ' / Optical element identifier", "ESO#427"))
            card = parse(Card, rpad(image, 80))
            @test card.value == value
            @test repr(card) == rpad(image, 80)
        end
    end

    #  A doubled single quote in a HIERARCH string is never the end of the string.
    @testset "HIERARCH string quotes" begin
        for (image, value, comment) in (("HIERARCH ESO A = 'a''//b' / c", "a'//b", "c"),
            ("HIERARCH ESO A = 'x''/' / c", "x'/", "c"), ("HIERARCH ESO A = 'x''' / c", "x'", "c"),
            ("HIERARCH ESO A = 'a / b'", "a / b", ""), ("HIERARCH ESO A = '''' / c", "'", "c"))
            card = parse(Card, rpad(image, 80))
            @test card.value == value && card.comment == comment
            @test repr(card) == rpad(image, 80)
        end
        for value in ("a''//b", "x'/", "a / b", "''", "it's")
            card = Card("HIERARCH", "ESO A", value, "cm")
            @test parse(Card, repr(card)).value == value
        end
    end

end

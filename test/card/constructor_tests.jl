@testset "Card constructor" begin
    ####    Test Card    ####

    #  Create default Card
    @test isequal(showfields(Card()),
                  ("", missing, "",
                   "                                                                                "))

    ###  Create End Cards  ###

    #  END keyword
    @test isequal(showfields(Card("END")),
                  ("END", missing, "",
                   "END                                                                             "))

    #  lowercase END keyword
    @test isequal(showfields(Card("end")),
                  ("END", missing, "",
                   "END                                                                             "))

    #  Invalid END card with value
    @test_throws ArgumentError Card("END", "a value")

    #  Invalid End card with comment
    @test_throws ArgumentError Card("END", missing, "a comment")

    ###  create Comment Card

    #  creat blank keyword string without comment
    @test isequal(showfields(Card("")),
                  ("", missing, "",
                   "                                                                                "))

    #  create blank keyword with string in value argument
    @test isequal(showfields(Card("", "a comment string")),
                  ("", "a comment string", "",
                   "        a comment string                                                        "))

    #  create blank keyword with string in comment argument
    @test isequal(showfields(Card("", missing, "a comment string")),
                  ("", missing, "a comment string",
                   "                                                                                "))

    #  create blank keyword with non-string value
    @test_throws ArgumentError Card("", 123)

    #  create COMMENT keyword with no comment
    @test isequal(showfields(Card("COMMENT")),
                  ("COMMENT", missing, "",
                   "COMMENT                                                                         "))

    #  create lowercase COMMENT keyword with empty comment in comment argument
    @test isequal(showfields(Card("comment")),
                  ("COMMENT", missing, "",
                   "COMMENT                                                                         "))

    #  create COMMENT keyword with string in value argument
    @test isequal(showfields(Card("COMMENT", "a comment string")),
                  ("COMMENT", "a comment string", "",
                   "COMMENT a comment string                                                        "))

    #  create COMMENT keyword with string in comment argument
    @test isequal(showfields(Card("COMMENT", missing, "a comment string")),
                  ("COMMENT", missing, "a comment string",
                   "COMMENT                                                                         "))

    #  create COMMENT keyword with both value and comment arguments
    @test isequal(showfields(Card("COMMENT", "a value string", "a comment string")),
                  ("COMMENT", "a value string", "a comment string",
                   "COMMENT a value string                                                          "))

    #  create COMMENT keyword with non-string value
    @test_throws ArgumentError Card("COMMENT", 123)

    ###  test History Card Constructor

    #  create HISTORY keyword with no history
    @test isequal(showfields(Card("HISTORY")),
                  ("HISTORY", missing, "", "HISTORY                                                                         "))

    #  create lowercase HISTORY keyword with empty history in comment argument
    @test isequal(showfields(Card("history")),
                  ("HISTORY", missing, "", "HISTORY                                                                         "))

    #  create HISTORY keyword with history in value argument
    @test isequal(showfields(Card("HISTORY", "a history string")),
                  ("HISTORY", "a history string", "",
                   "HISTORY a history string                                                        "))

    #  create HISTORY keyword with string in comment argument
    @test isequal(showfields(Card("HISTORY", missing, "a comment string")),
                  ("HISTORY", missing, "a comment string",
                   "HISTORY                                                                         "))

    #  create HISTORY keyword with value and comment arguments
    @test isequal(showfields(Card("HISTORY", "a history string", "a comment string")),
                  ("HISTORY", "a history string", "a comment string",
                   "HISTORY a history string                                                        "))

    #  create HISTORY keyword with non-string value
    @test_throws ArgumentError Card("HISTORY", 123)

    ###  test Value Card constructor

    #  create Value Card and get its type with boolean value
    @test typeof(Card("BOOL", true)) <: Card{Value{Bool}}

    #  create Value card with undefined value
    @test isequal(showfields(Card("UNDEF", missing)),
                  ("UNDEF", missing, "",
                   "UNDEF   =                                                                       "))

    #  create Value card with undefined value and comment. An undefined value has no
    #  units, so no units field is written.
    @test isequal(showfields(Card("UNDEF", missing, "a comment")),
                  ("UNDEF", missing, "a comment",
                   "UNDEF   =                      / a comment                                      "))

    #  a units string in the comment of an undefined value card is preserved
    @test isequal(showfields(Card("UNDEF", missing, "[m] a comment")),
                  ("UNDEF", missing, "[m] a comment",
                   "UNDEF   =                      / [m] a comment                                  "))

    #  create Value card with boolean value, fixed-format
    @test isequal(showfields(Card("BOOL", false)),
                  ("BOOL", false, "",
                   "BOOL    =                    F                                                  "))

    #  create Value card with boolean value, fixed-format
    @test isequal(showfields(Card("BOOL", true)),
                  ("BOOL", true, "",
                   "BOOL    =                    T                                                  "))

    #  create Value card with boolean value, fixed-format
    @test isequal(showfields(Card("BOOL", true; fixed=true)),
                  ("BOOL", true, "",
                   "BOOL    =                    T                                                  "))

    #  create Value card with boolean value, free-format
    @test isequal(showfields(Card("BOOL", true, fixed=false)),
                  ("BOOL", true, "",
                   "BOOL    = T                                                                     "))

    #  create Value card with boolean value and comment, fixed format
    @test isequal(showfields(Card("BOOL", true, "a comment string")),
                  ("BOOL", true, "a comment string",
                   "BOOL    =                    T / a comment string                               "))

    #  create Value card with boolean value and comment, free-format
    @test isequal(showfields(Card("BOOL", true, "a comment string", fixed=false)),
                  ("BOOL", true, "a comment string",
                   "BOOL    = T                    / a comment string                               "))

    #  get type of Value Card with integer value
    @test typeof(Card("INTEGER", 12345)) <: Card{Value{Int64}}

    #  create Value card with integer value, fixed-format
    @test isequal(showfields(Card("INTEGER", 12345)),
                  ("INTEGER", 12345, "",
                   "INTEGER =                12345                                                  "))

    #  create Value card with integer fixed value, test fixed format = true
    @test isequal(showfields(Card("INTEGER", 12345; fixed=true)),
                  ("INTEGER", 12345, "",
                   "INTEGER =                12345                                                  "))

    #  create Value card with integer free value, test free format = false
    @test isequal(showfields(Card("INTEGER", 12345; fixed=false)),
                  ("INTEGER", 12345, "",
                   "INTEGER = 12345                                                                 "))

    #  create Value card with integer value and comment, fixed-format
    @test isequal(showfields(Card("INTEGER", 12345, "a comment string")),
                  ("INTEGER", 12345, "a comment string",
                   "INTEGER =                12345 / a comment string                               "))

    #  create Value card with integer value and comment, free-format
    @test isequal(showfields(Card("INTEGER", 12345, "a comment string", fixed=false)),
                  ("INTEGER", 12345, "a comment string",
                   "INTEGER = 12345                / a comment string                               "))

    #  test type of Value Card with long integer value
    @test typeof(Card("LONG_INT", -467374636747637647347374734737437)) <: Card{Value{Int128}}

    #  creat Value Card with long integer value, fixed-format
    @test isequal(showfields(Card("LONG_INT", -467374636747637647347374734737437)),
                  ("LONG_INT", -467374636747637647347374734737437, "",
                   "LONG_INT= -467374636747637647347374734737437                                    "))

    #  create Value Card with long integer value and comment, fixed-format
    @test isequal(showfields(Card("LONG_INT", -467374636747637647347374734737437, "a comment string")),
                  ("LONG_INT", -467374636747637647347374734737437, "a comment string",
                   "LONG_INT= -467374636747637647347374734737437 / a comment string                 "))

    #  Note: Fixed point keyword values will be parsed as 64-bit floating point numbers. It is not
     #  possible to distinquish between 32-bit and 64-bit floating point numbers.

    #  type of Value Card with 32-bit float value
    @test typeof(Card("FLOAT_32", 1.2345f0)) <: Card{Value{Float32}}

    #  create Value Card with 32-bit float value, fixed-format
    @test isequal(showfields(Card("FLOAT_32", 1.2345f0)),
                  ("FLOAT_32", 1.2345f0, "",
                   "FLOAT_32=               1.2345                                                  "))

    #  create Value card with 32-bit float fixed value, test fixed format = true
    @test isequal(showfields(Card("FLOAT_32", 1.2345f0; fixed=true)),
                  ("FLOAT_32", 1.2345f0, "",
                   "FLOAT_32=               1.2345                                                  "))

    #  create Value card with 32-bit float fixed value, test fixed format = true
    @test isequal(showfields(Card("FLOAT_32", 1.2345f0; fixed=false)),
                  ("FLOAT_32", 1.2345f0, "",
                   "FLOAT_32= 1.2345                                                                "))

    #  create Value Card with 32-bit float value and comment, fixed-format
    @test isequal(showfields(Card("FLOAT_32", 1.2345f0, "a comment string")),
                  ("FLOAT_32", 1.2345f0, "a comment string",
                   "FLOAT_32=               1.2345 / a comment string                               "))

    #  create Value Card with 32-bit float value and comment, free-format
    @test isequal(showfields(Card("FLOAT_32", 1.2345f0, "a comment string"; fixed=false)),
                  ("FLOAT_32", 1.2345f0, "a comment string",
                   "FLOAT_32= 1.2345               / a comment string                               "))

    #  create Value Card with 32-bit float value, fixed-format
    @test isequal(showfields(Card("FLOAT_32", 1.2345f6)),
                  ("FLOAT_32", 1.2345f6, "",
                   "FLOAT_32=             1.2345E6                                                  "))

    #  test typeof Value Card with 64-bit float value
    @test typeof(Card("FLOAT_64", 1.2345)) <: Card{Value{Float64}}

    #  create Value Card with 64-bit float value, fixed-format
    @test isequal(showfields(Card("FLOAT_64", 1.2345)),
                  ("FLOAT_64", 1.2345, "",
                   "FLOAT_64=               1.2345                                                  "))

    #  create Value Card with 64-bit float value, fixed-format
    @test isequal(showfields(Card("FLOAT_64", 1.2345; fixed=true)),
                  ("FLOAT_64", 1.2345, "",
                   "FLOAT_64=               1.2345                                                  "))

    #  create Value Card with 64-bit float value, free-format
    @test isequal(showfields(Card("FLOAT_64", 1.2345; fixed=false)),
                  ("FLOAT_64", 1.2345, "",
                   "FLOAT_64= 1.2345                                                                "))

    #  create Value Card with 64-bit float value, fixed-format
    @test isequal(showfields(Card("FLOAT_64", 1.2345, "a comment string")),
                  ("FLOAT_64", 1.2345, "a comment string",
                   "FLOAT_64=               1.2345 / a comment string                               "))

    #  create Value Card with 64-bit float value, fixed-format
    @test isequal(showfields(Card("FLOAT_64", 1.2345e6)),
                  ("FLOAT_64", 1.2345e6, "",
                   "FLOAT_64=             1.2345D6                                                  "))

    #  test Value Card with complex 64-bit integer value
    @test typeof(Card("CPLX_INT", 8 + 9im)) <: Card{Value{Complex{Int64}}}

    #  test Value Card with complex 64-bit integer value free format
    @test Card("CPLX_INT", 8 + 9im).format.fixd == false

    #  create Value Card with complex 64-bit integer value
    @test isequal(showfields(Card("CPLX_INT", 8 + 9im)),
                  ("CPLX_INT", 8 + 9im, "",
                   "CPLX_INT= (8, 9)                                                                "))

    #  create Value Card with complex 64-bit integer value
    @test isequal(showfields(Card("CPLX_INT", 8 + 9im, "a comment string")),
                  ("CPLX_INT", 8 + 9im, "a comment string",
                   "CPLX_INT= (8, 9)               / a comment string                               "))

    #  test Value Card with complex 32-bit float value
    @test typeof(Card("CPLX_F32", 8.1f0 + 9.2f0im)) <: Card{Value{Complex{Float32}}}

    #  test Value Card with complex 32-bit float value free format
    @test Card("CPLX_F32", 8.1f0 + 9.2f0im).format.fixd == false

    #  create Value Card with complex 32-bit float value
    @test isequal(showfields(Card("CPLX_F32", 8.1f0 + 9.2f0im)),
                  ("CPLX_F32", 8.1f0 + 9.2f0im, "",
                   "CPLX_F32= (8.1, 9.2)                                                            "))

    #  create Value Card with complex 32-bit float value
    @test isequal(showfields(Card("CPLX_F32", 8.1f0 + 9.2f0im, "a comment string")),
                  ("CPLX_F32", 8.1f0 + 9.2f0im, "a comment string",
                   "CPLX_F32= (8.1, 9.2)           / a comment string                               "))

    #  test Value Card with complex 64-bit float value
    @test typeof(Card("CPLX_F64", 8.1 + 9.2im)) <: Card{Value{Complex{Float64}}}

    #  test Value Card with complex 64-bit float value free format
    @test Card("CPLX_F64", 8.1 + 9.2im).format.fixd == false

    #  create Value Card with complex 64-bit float value
    @test isequal(showfields(Card("CPLX_F64", 8.1 + 9.2im)),
                  ("CPLX_F64", 8.1 + 9.2im, "",
                   "CPLX_F64= (8.1, 9.2)                                                            "))

    #  create Value Card with complex 64-bit float value
    @test isequal(showfields(Card("CPLX_F64", 8.1 + 9.2im, "a comment string")),
                  ("CPLX_F64", 8.1 + 9.2im, "a comment string",
                   "CPLX_F64= (8.1, 9.2)           / a comment string                               "))

    #  test Value Card with complex 32-bit float and integer value
    @test typeof(Card("CPLX_F32", 8.1f0 + 9im)) <: Card{Value{Complex{Float32}}}

    #  test Value Card with complex 32-bit float and integer value free format
    @test Card("CPLX_F32", 8.1f0 + 9im).format.fixd == false

    #  create Value Card with complex 32-bit float value
    @test isequal(showfields(Card("CPLX_F32", 8.1f0 + 9im)),
                  ("CPLX_F32", 8.1f0 + 9.0f0im, "",
                   "CPLX_F32= (8.1, 9.0)                                                            "))

    #  create Value Card with complex 32-bit float value
    @test isequal(showfields(Card("CPLX_F32", 8.1f0 + 9im, "a comment string")),
                  ("CPLX_F32", 8.1f0 + 9.0f0im, "a comment string",
                   "CPLX_F32= (8.1, 9.0)           / a comment string                               "))

    #  test Value Card with complex 64-bit float and integer value
    @test typeof(Card("CPLX_F64", 8.1 + 9im)) <: Card{Value{Complex{Float64}}}

    #  test Value Card with complex 64-bit float and integer value free format
    @test Card("CPLX_F64", 8.1 + 9im).format.fixd == false

    #  create Value Card with complex 64-bit float and integer value
    @test isequal(showfields(Card("CPLX_F64", 8.1 + 9im)),
                  ("CPLX_F64", 8.1 + 9.0im, "",
                   "CPLX_F64= (8.1, 9.0)                                                            "))

    #  create Value Card with complex 64-bit float and integer value
    @test isequal(showfields(Card("CPLX_F64", 8.1 + 9im, "a comment string")),
                  ("CPLX_F64", 8.1 + 9.0im, "a comment string",
                   "CPLX_F64= (8.1, 9.0)           / a comment string                               "))

    #  test Value Card with complex integer and 64-bit float value
    @test typeof(Card("CPLX_F64", 8 + 9.2im)) <: Card{Value{Complex{Float64}}}

    #  test Value Card with complex integer and 64-bit float value free format
    @test Card("CPLX_F64", 8 + 9.2im).format.fixd == false

    #  create Value Card with complex integer and 64-bit float value
    @test isequal(showfields(Card("CPLX_F64", 8 + 9.2im)),
                  ("CPLX_F64", 8.0 + 9.2im, "",
                   "CPLX_F64= (8.0, 9.2)                                                            "))

    #  create Value Card with complex integer and 64-bit float value
    @test isequal(showfields(Card("CPLX_F64", 8 + 9.2im, "a comment string")),
                  ("CPLX_F64", 8.0 + 9.2im, "a comment string",
                   "CPLX_F64= (8.0, 9.2)           / a comment string                               "))

    ###  Test String Card constructor

    #  type of Value Card with string value
    @test typeof(Card("STRING", "a value string")) <: Card{Value{String}}

    #  create Value Card with a null string
    @test isequal(showfields(Card("STRING", "")),
                  ("STRING", "", "",
                   "STRING  = ''                                                                    "))

    #  create Value Card with an empty string
    @test isequal(showfields(Card("STRING", "        ")),
                  ("STRING", "        ", "",
                   "STRING  = '        '                                                            "))

    #  create Value Card with a string value
    @test isequal(showfields(Card("STRING", "a value string")),
                  ("STRING", "a value string", "",
                   "STRING  = 'a value string'                                                      "))

    #  create Value Card with a string value
    @test isequal(showfields(Card("STRING", "a value string", "a comment string")),
                  ("STRING", "a value string", "a comment string",
                   "STRING  = 'a value string'     / a comment string                               "))

    #  create String Card with string of <8 characters
    @test isequal(showfields(Card("STRING", "<8 ch")),
                  ("STRING", "<8 ch", "",
                   "STRING  = '<8 ch'                                                               "))

    #  create String Card having string with single quote
    @test isequal(showfields(Card("STRING", "Kelley O'Hara")),
                  ("STRING", "Kelley O'Hara", "",
                   "STRING  = 'Kelley O''Hara'                                                      "))

    #  create String Card having string with a single quote and comment
    @test isequal(showfields(Card("STRING", "Kelley O'Hara", "a comment string")),
                  ("STRING", "Kelley O'Hara", "a comment string",
                   "STRING  = 'Kelley O''Hara'     / a comment string                               "))

    #  create String Card having string with a single quote and comment with a single quote
    @test isequal(showfields(Card("STRING", "Kelley O'Hara", "a comment string with single quote '")),
                  ("STRING", "Kelley O'Hara", "a comment string with single quote '",
                   "STRING  = 'Kelley O''Hara'     / a comment string with single quote '           "))

    #  create String Card that truncates comment
    @test isequal(showfields(Card("STRING", repeat("-", 58), "a truncated comment", slash=72, truncate=true)),
                  ("STRING", "----------------------------------------------------------", "a trunc",
                   "STRING  = '----------------------------------------------------------' / a trunc"))

    #  create Value card with no left and right padding for comment separator
    @test isequal(showfields(Card("longcom", "19 character string","a comment string", lpad=0, rpad=0)),
                  ("LONGCOM", "19 character string", "a comment string",
                   "LONGCOM = '19 character string'/a comment string                                "))

    ###  test Continue Card constructor

    #  CONTINUE keyword without value and comment arguments
    @test_throws "Value is not a string." Card("CONTINUE")

    #  CONTINUE keyword without comment argument
    @test isequal(showfields(Card("continue", "part of a long string")),
                  ("CONTINUE", "part of a long string", "",
                   "CONTINUE  'part of a long string'                                               "))

    #  CONTINUE keyword with comment argument
    @test isequal(showfields(Card("continue", "part of a long string", "with comment")),
                  ("CONTINUE", "part of a long string", "with comment",
                   "CONTINUE  'part of a long string' / with comment                                "))

    #  test continue Card with equals in value.

    #  test that final continue Card removes ampersand from long comments.

    ###  test Value Card with long strings and comments

    #  test long string value.

    #  test long string value with multiple long words.

    #  test long string representation.

    #  test long string from file.

    #  test word on long string that is too long.

    #  test long string value using fromstring.
    #  type of String Card having string with multiple single quotes with CONTINUE cards in fixed-format
    card = Card("longcom", repeat("Kelley O'Hara ", 4), repeat("long comment ", 6), slash=43, lpad=1, splitat=nothing)
    @test isequal(showfields(card[1]),
                  ("LONGCOM", "Kelley O'Hara Kelley O'Har", "long comment long comment long comme",
                   "LONGCOM = 'Kelley O''Hara Kelley O''Har&' / long comment long comment long comme"))
    @test isequal(showfields(card[2]),
                  ("CONTINUE", "a Kelley O'Hara Kelley O'H", "nt long comment long comment long co",
                   "CONTINUE  'a Kelley O''Hara Kelley O''H&' / nt long comment long comment long co"))
    @test isequal(showfields(card[3]),
                  ("CONTINUE", "ara ", "mment ",
                   "CONTINUE  'ara '                          / mment                               "))

    #  type of String Card having string with multiple single quotes with CONTINUE cards in free-format
    card = Card("longcom", repeat("Kelley O'Hara ", 4), repeat("long comment ", 10), slash=42,
                lpad=1, fixed=false, splitat=nothing)
    @test isequal(showfields(card[1]),
                  ("LONGCOM", "Kelley O'Hara Kelley O'Ha", "long comment long comment long commen",
                   "LONGCOM = 'Kelley O''Hara Kelley O''Ha&' / long comment long comment long commen"))
    @test isequal(showfields(card[2]),
                  ("CONTINUE", "ra Kelley O'Hara Kelley O", "t long comment long comment long comm",
                   "CONTINUE  'ra Kelley O''Hara Kelley O&'  / t long comment long comment long comm"))
    @test isequal(showfields(card[3]),
                  ("CONTINUE", "'Hara ", "ent long comment long comment long co",
                   "CONTINUE  '''Hara &'                     / ent long comment long comment long co"))
    @test isequal(showfields(card[4]),
                  ("CONTINUE", "", "mment long comment ",
                   "CONTINUE  ''                             / mment long comment                   "))

    #  Value Card with long string creates CONTINUE cards
    card = Card("abc", repeat("long string value ", 10), repeat("long comment ", 10), slash=51, splitat=nothing)
    @test isequal(showfields(card[1]),
                  ("ABC", "long string value long string value ", "long comment long comment lo",
                   "ABC     = 'long string value long string value &' / long comment long comment lo"))
    @test isequal(showfields(card[2]),
                  ("CONTINUE", "long string value long string value ", "ng comment long comment long",
                   "CONTINUE  'long string value long string value &' / ng comment long comment long"))
    @test isequal(showfields(card[3]),
                  ("CONTINUE", "long string value long string value ", " comment long comment long c",
                   "CONTINUE  'long string value long string value &' /  comment long comment long c"))
    @test isequal(showfields(card[4]),
                  ("CONTINUE", "long string value long string value ", "omment long comment long com",
                   "CONTINUE  'long string value long string value &' / omment long comment long com"))
    @test isequal(showfields(card[5]),
                  ("CONTINUE", "long string value long string value ", "ment long comment ",
                   "CONTINUE  'long string value long string value '  / ment long comment           "))

    #  Value Card with multiple long words
    card = Card("WHATEVER", "SuperCalibrationParameters_XXXX_YYYY_ZZZZZ_KK_01_02_03)-AAABBBCCC.n.h5 " *
                "SuperNavigationParameters_XXXX_YYYY_ZZZZZ_KK_01_02_03)-AAABBBCCC.n.xml", slash=85, splitat=nothing)
    @test isequal(showfields(card[1]),
                  ("WHATEVER", "SuperCalibrationParameters_XXXX_YYYY_ZZZZZ_KK_01_02_03)-AAABBBCCC.n", "",
                   "WHATEVER= 'SuperCalibrationParameters_XXXX_YYYY_ZZZZZ_KK_01_02_03)-AAABBBCCC.n&'"))
    @test isequal(showfields(card[2]),
                  ("CONTINUE", ".h5 SuperNavigationParameters_XXXX_YYYY_ZZZZZ_KK_01_02_03)-AAABBBCC", "",
                   "CONTINUE  '.h5 SuperNavigationParameters_XXXX_YYYY_ZZZZZ_KK_01_02_03)-AAABBBCC&'"))
    @test isequal(showfields(card[3]),
                  ("CONTINUE", "C.n.xml", "",
                   "CONTINUE  'C.n.xml'                                                             "))

    #  Value Card with comment longer than value string
    card = Card("longcom", repeat("long string value ", 6), repeat("long comment ", 10), slash=51, splitat=nothing)
    @test isequal(showfields(card[1]),
                  ("LONGCOM", "long string value long string value ", "long comment long comment lo",
                   "LONGCOM = 'long string value long string value &' / long comment long comment lo"))
    @test isequal(showfields(card[2]),
                  ("CONTINUE", "long string value long string value ", "ng comment long comment long",
                   "CONTINUE  'long string value long string value &' / ng comment long comment long"))
    @test isequal(showfields(card[3]),
                  ("CONTINUE", "long string value long string value ", " comment long comment long c",
                   "CONTINUE  'long string value long string value &' /  comment long comment long c"))
    @test isequal(showfields(card[4]),
                  ("CONTINUE", "", "omment long comment long com",
                   "CONTINUE  '&'                                     / omment long comment long com"))
    @test isequal(showfields(card[5]),
                  ("CONTINUE", "", "ment long comment ",
                   "CONTINUE  ''                                      / ment long comment           "))

    ###  test Mandatory keywords

    #   create Value Card having Bintable XTENSION
    @test isequal(showfields(Card("XTENSION", "BINTABLE", "a comment string")),
                  ("XTENSION", "BINTABLE", "a comment string",
                   "XTENSION= 'BINTABLE'           / a comment string                               "))

    #   create Value Card having Image XTENSION
    @test isequal(showfields(Card("XTENSION", "IMAGE", "a comment string")),
                  ("XTENSION", "IMAGE   ", "a comment string",
                   "XTENSION= 'IMAGE   '           / a comment string                               "))

    #   parse Value Card hving Image XTENSION

    #   create Value Card having Table XTENSION
    @test isequal(showfields(Card("XTENSION", "TABLE", "a comment string")),
                  ("XTENSION", "TABLE   ", "a comment string",
                   "XTENSION= 'TABLE   '           / a comment string                               "))

    #   parse Value Card having Table XTENSION

    #  create HIERARCH keyword and value
    @test isequal(showfields(Card("HIERARCH", "abc def gh ijklmn", -99.9, "")),
                  ("ABC DEF GH IJKLMN", -99.9, "",
                   "HIERARCH ABC DEF GH IJKLMN = -99.9                                              "))

    #  create HIERARCH keyword and value with comment
    @test isequal(showfields(Card("HIERARCH", "abc def gh ijklmn_-", -99.9, "[m] abcdef ghijklm nopqrstu vw xyzab")),
                  ("ABC DEF GH IJKLMN_-", -99.9, "[m] abcdef ghijklm nopqrstu vw xyzab",
                   "HIERARCH ABC DEF GH IJKLMN_- = -99.9 / [m] abcdef ghijklm nopqrstu vw xyzab     "))

    #  test HIERARCH Card with abbreviated value indicator.

    #  test HIERARCH Card with whitespace keyword.

    #  test HIERARCH Card with mixed case.

    #  test that a fixed HIERARCH Card remains that card.

    #  test Card constructor for long keywords with warning.

    #  HIERARCH keyword implied by long keyword
    @test isequal(showfields(Card("abc def gh ijklmn", -99.9, "[m] abcdef ghijklm nopqrstu vw xyzab"; warn = false)),
                  ("ABC DEF GH IJKLMN", -99.9, "[m] abcdef ghijklm nopqrstu vw xyzab",
                   "HIERARCH ABC DEF GH IJKLMN = -99.9 / [m] abcdef ghijklm nopqrstu vw xyzab       "))

    ###  Regression tests: HIERARCH cards  ###

    #  a HIERARCH card without a value is commentary text and round trips.
    img = rpad("HIERARCH ESO TEL some commentary text", 80)
    card = parse(Card, img)
    @test FITSFiles.typename(card) == Comment
    @test card.key == "HIERARCH"
    @test repr(card) == img

    #  a HIERARCH string value is unquoted and unescaped when parsed, and its trailing spaces are not significant.
    img = rpad("HIERARCH ESO INS OPTI-3 ID = 'ESO#427 ' / Optical element", 80)
    card = parse(Card, img)
    @test (card.key, card.value, card.comment) ==
          ("ESO INS OPTI-3 ID", "ESO#427", "Optical element")
    @test repr(card) == img
    @test parse(Card, rpad("HIERARCH ESO A = 'O''HARA'", 80)).value == "O'HARA"

    #  HIERARCH values are written as FITS values: quoted strings, T or F, E and D exponents.
    @test repr(Card("HIERARCH", "ESO A B", "abc", "")) ==
          rpad("HIERARCH ESO A B = 'abc'", 80)
    @test repr(Card("HIERARCH", "ESO A B", "O'HARA", "")) ==
          rpad("HIERARCH ESO A B = 'O''HARA'", 80)
    @test repr(Card("HIERARCH", "ESO A B", true, "")) == rpad("HIERARCH ESO A B = T", 80)
    @test repr(Card("HIERARCH", "ESO A B", false, "")) == rpad("HIERARCH ESO A B = F", 80)
    @test repr(Card("HIERARCH", "ESO A B", 1.5f-5, "")) == rpad("HIERARCH ESO A B = 1.5E-5", 80)
    @test repr(Card("HIERARCH", "ESO A B", 1.5e-5, "")) == rpad("HIERARCH ESO A B = 1.5D-5", 80)
    @test repr(Card("HIERARCH", "ESO A B", 12, "")) == rpad("HIERARCH ESO A B = 12", 80)
    @test repr(Card("HIERARCH", "ESO A B", 1.5 + 2.5im, "")) ==
          rpad("HIERARCH ESO A B = (1.5, 2.5)", 80)

    #  HIERARCH values round trip through their images.
    for value in ("a string", "O'HARA", true, false, 12, 1.5f0, 2.5e-10, 1.0 - 2.0im, 3 + 4im)
        card = Card("HIERARCH", "ESO TEL FOCU SCALE", value, "a comment")
        parsed = parse(Card, repr(card))
        @test parsed.value == value
        @test parsed.comment == "a comment"
        @test repr(parsed) == repr(card)
    end

    #  HIERARCH tokens may only contain characters that are legal in a keyword.
    @test_throws "HIERARCH keyword contains invalid characters." Card("HIERARCH", "ESO a=b", 1, "")
    @test_throws "HIERARCH keyword contains invalid characters." Card("HIERARCH", "ESO A/B", 1, "")
    @test_throws "HIERARCH keyword contains invalid characters." Card("HIERARCH", "", 1, "")
    @test_throws "HIERARCH keyword contains invalid characters." Card("HIERARCH", "ESO 'A", 1, "")

    ###  Regression tests: string types  ###

    #  the key, tokens, value, and comment may be different string types.
    @test repr(Card(SubString("xKEY", 2), 1, SubString("xa comment", 2))) ==
          rpad("KEY     =                    1 / a comment", 80)
    @test repr(Card(SubString("xKEY", 2), "a string", "a comment")) ==
          repr(Card("KEY", "a string", "a comment"))
    @test repr(Card("HIERARCH", SubString("xESO A", 2), 1, SubString("xa comment", 2))) ==
          repr(Card("HIERARCH", "ESO A", 1, "a comment"))
    @test repr(Card(SubString("xHIERARCH", 2), "ESO A", 1, SubString("xa comment", 2))) ==
          repr(Card("HIERARCH", "ESO A", 1, "a comment"))

    ###  Regression tests: mandatory keywords  ###

    #  mandatory keywords are in fixed format even if free format is requested.
    for key in ("BITPIX", "NAXIS", "NAXIS1", "NAXIS999", "PCOUNT", "GCOUNT")
        @test repr(Card(key, 5; fixed = false)) == repr(Card(key, 5; fixed = true))
        @test repr(Card(lowercase(key), 5; fixed = false)) == repr(Card(key, 5))
    end
    @test repr(Card("SIMPLE", true; fixed = false)) == repr(Card("SIMPLE", true))
    @test repr(Card("XTENSION", "IMAGE"; fixed = false)) == repr(Card("XTENSION", "IMAGE"))
    @test repr(Card("NAXIS1", 5; fixed = false)) == rpad("NAXIS1  =                    5", 80)

    #  other keywords keep the requested format.
    for key in ("XNAXIS1", "NAXIS1X", "NAXISX", "OBJECT")
        @test repr(Card(key, 5; fixed = false)) == rpad(rpad(key, 8) * "= 5", 80)
    end
    @test repr(Card("OBJECT", "x"; fixed = false)) == rpad("OBJECT  = 'x'", 80)

    ###  Regression tests: units of HIERARCH values  ###

    #  a HIERARCH card writes the units of a Quantity at the beginning of the comment.
    card = Card("HIERARCH", "ESO TEL SCALE", 1.489f0 * Unitful.m, "a comment")
    @test occursin("/ [m] a comment", repr(card))
    @test occursin("ESO TEL SCALE = 1.489 ", repr(card))
    parsed = parse(Card, repr(card))
    @test (parsed.value, parsed.units, parsed.comment) == (1.489f0, Unitful.m, "a comment")
    @test repr(parsed) == repr(card)

    #  the units are written without a comment, and a value without units has no units field.
    card = Card("HIERARCH", "ESO TEL SCALE", 5 * Unitful.s, "")
    @test parse(Card, repr(card)).comment == ""
    @test parse(Card, repr(card)).value === 5
    @test parse(Card, repr(card)).units == Unitful.s
    @test parse(Card, repr(card); units = false).comment == "[s]"
    @test repr(Card("HIERARCH", "ESO TEL SCALE", 5, "a comment")) ==
          rpad("HIERARCH ESO TEL SCALE = 5    / a comment", 80)

    #  a value that is set with units writes the units.
    card = FITSFiles.setvalue!(Card("HIERARCH", "ESO A", 5, "a comment"), 2.5f0 * Unitful.m)
    @test parse(Card, repr(card)).comment == "a comment"
    @test parse(Card, repr(card)).value === 2.5f0
    @test parse(Card, repr(card)).units == Unitful.m

    ###  Regression tests: HIERARCH keyword and value that do not fit  ###

    #  a HIERARCH keyword and value that end in the last column are written, and anything longer
    #  is an error instead of a truncated card.
    for n in (60, 61)
        card = Card("HIERARCH", "ESO A", repeat("x", n), "")
        parsed = parse(Card, repr(card))
        @test parsed.value == repeat("x", n)
        @test FITSFiles.typename(parsed) == Hierarch{String}
    end
    @test length(rstrip(repr(Card("HIERARCH", "ESO A", repeat("x", 61), "")))) == 80
    @test_throws ArgumentError Card("HIERARCH", "ESO A", repeat("x", 62), "")
    @test_throws ArgumentError Card("HIERARCH", "ESO A", repeat("x", 62), "a comment")
    @test_throws ArgumentError Card("HIERARCH", repeat("ABC ", 20), 1, "")
    @test_throws ArgumentError Card("HIERARCH", "ESO A", repeat("''", 31), "")
    @test_throws ArgumentError Card("HIERARCH", "ESO A", big(10)^70, "")
    @test_throws "HIERARCH keyword and value do not fit on the card." Card("HIERARCH", "ESO A", repeat("x", 62), "")

    #  setting a value that does not fit is an error, and the card is not changed.
    card = Card("HIERARCH", "ESO A", "short", "a comment")
    @test_throws ArgumentError FITSFiles.setvalue!(card, repeat("x", 62))
    @test card.value == "short"
    @test FITSFiles.setvalue!(card, repeat("x", 61)).value == repeat("x", 61)

    ###  Regression tests: long keywords imply HIERARCH  ###

    #  a keyword that is longer than 8 characters creates a HIERARCH card.
    for key in ("abc def gh ijklmn", "ABCDEFGHI", "ESO TEL FOCU SCALE", "hierarch eso a", "HIERARCH  ESO A")
        card = Card(key, 1.5f0, "a comment"; warn = false)
        tokens = uppercase(replace(key, r"^(?i)hierarch +" => ""))
        @test FITSFiles.typename(card) == Hierarch{Float32}
        @test card.key == tokens
        @test repr(card) == repr(Card("HIERARCH", tokens, 1.5f0, "a comment"))
    end
    @test repr(Card("ESO TEL A B", "a string"; warn = false)) == repr(Card("HIERARCH", "ESO TEL A B", "a string", ""))
    @test repr(Card("ESO TEL A B", 5.0f0 * Unitful.m, "a comment"; warn = false)) ==
          repr(Card("HIERARCH", "ESO TEL A B", 5.0f0 * Unitful.m, "a comment"))
    @test parse(Card, repr(Card("ABCDEFGHI", 5; warn = false))).value == 5

    #  a keyword of 8 characters or fewer is not a HIERARCH keyword.
    @test FITSFiles.typename(Card("ABCDEFGH", 1)) == Value{Int}
    @test_throws "Keyword contains invalid characters." Card("ABC DEF", 1)

    #  the tokens of a HIERARCH keyword must be legal, and the card must fit.
    @test_throws "HIERARCH keyword contains invalid characters." Card("abc+ def ghijklm", 1; warn = false)
    @test_throws "HIERARCH keyword contains invalid characters." Card("ABC=DEF GHIJKLM", 1; warn = false)
    @test_throws ArgumentError Card(repeat("ABCDEFGH ", 9), 1; warn = false)

    #  a warning is emitted when a long keyword creates a HIERARCH card, unless it is silenced.
    @test_logs (:warn, r"longer than 8 characters.*HIERARCH") Card("ABCDEFGHI", 5)
    @test_logs (:warn, r"longer than 8 characters") Card("abc def gh ijklmn", 5, "a comment")
    @test_logs Card("ABCDEFGHI", 5; warn = false)
    @test_logs Card("ABCDEFGHI", 5, "a comment"; warn = false)
    @test repr(Card("ABCDEFGHI", 5; warn = false)) == repr(Card("HIERARCH", "ABCDEFGHI", 5, ""))

    #  no warning is emitted for other keywords or for an explicit HIERARCH card.
    @test_logs Card("ABCDEFGH", 5)
    @test_logs Card("HIERARCH", "ABCDEFGHI", 5, "")

    #  test Card constructor allowing illegal characters in the keyword, but creates a HIERARCH keyword.
    # @test show(Card("abc+", 9)) == rpad_card("HIERARCH abc+ =                    9")

    #  test fixable non-standard FITS card will keep the original format
    # card = fromstring(Card(), "abc     = +  2.1   e + 12")
    # @test card.value == 2100000000000.0
    # @test show(card) == "ABC     =             +2.1E+12"

    #  test fixable non-standard FITS card for non-parsable card: its value will be assumed
    #  to be a string and everything after the first slash will be a comment.
    # card = fromstring(Card(), "no_quote=  this card's value has no quotes / let's also try the comment")
    # @test show(card) == "NO_QUOTE= 'this card''s value has no quotes' / let's also try the comment       "

    #  test undefined value using string input.
    # show(fromstring(Card(), "ABC     =    ")) == rpad_card("ABC     =")

    #  test that leading zeros are not removed from floats.

    #  test mis-located equal sign.

    #  test equal up to column 10.

    #  test to verify invalid equal sign.

    #  test to fix invalid equal sign.

    #  test raw keyword
    #  Invalid characters are rejected in the value string and the comment.
    @testset "invalid characters" begin
        @test_throws "Value string contains invalid characters." Card("ABC", "caf\u00e9")
        @test_throws "Value string contains invalid characters." Card("ABC", "a\nb", "c")
        @test_throws "Comment contains invalid characters." Card("ABC", 1, "caf\u00e9")
        @test_throws "Comment contains invalid characters." Card("ABC", "x", "caf\u00e9")
        @test_throws "Keyword contains invalid characters." Card("A\x01", "ESO A", 1, "")
        @test_throws "Value string contains invalid characters." Card("HIERARCH", "ESO A", "caf\u00e9", "")
        @test_throws "Comment contains invalid characters." Card("HIERARCH", "ESO A", 1, "caf\u00e9")
        @test_throws "Invalid card" Card("ABC", "ESO A", 1, "")
    end

    #  A HIERARCH keyword with a string only is a commentary card, not a HIERARCH card.
    @testset "HIERARCH commentary" begin
        card = Card("HIERARCH", "some text")
        @test FITSFiles.typename(card) == FITSFiles.Comment
        @test card.key == "HIERARCH" && card.value == "some text"
        @test repr(parse(Card, repr(card))) == repr(card)
        @test FITSFiles.typename(Card("HIERARCH")) == FITSFiles.Comment
    end

    #  A comment that does not fit on the card is truncated, and the card has the comment of its image.
    @testset "comment longer than the card" begin
        for n in (47, 48, 60, 100, 120, 300), value in (1, 2.5f0, "str", true, missing, 1 + 2im)
            card = Card("KEY", value, repeat("x", n))
            @test length(repr(card)) == 80
            @test card.comment == parse(Card, repr(card)).comment
            @test card.format.cend <= 70
        end
        card = Card("HIERARCH", "ESO A", 1, repeat("y", 200))
        @test length(repr(card)) == 80 && card.comment == parse(Card, repr(card)).comment
        card = Card("KEY", 1.5f0 * Unitful.km / Unitful.s, repeat("x", 100))
        @test length(repr(card)) == 80 && card.units == Unitful.km / Unitful.s
        @test card.comment == parse(Card, repr(card)).comment
        #  The comment is not on the card when the separator is at the end of the card.
        @test Card("KEY", 1, "a comment"; slash = 75).comment == "a co"
        for slash in (80, 200)
            card = Card("KEY", 1, "a comment"; slash)
            @test length(repr(card)) == 80 && isempty(card.comment) && card.format.slsh == 0
        end
        #  truncate = false is an error when the comment does not fit.
        @test_throws "Comment does not fit on the card." Card("KEY", 1, repeat("x", 60); truncate = false)
        @test_throws "Comment does not fit on the card." Card("KEY", 1, "a comment"; slash = 80, truncate = false)
        @test length(repr(Card("KEY", 1, repeat("x", 47); truncate = false))) == 80
        #  Units must fit on the card.
        @test_throws "Units do not fit on the card." Card("KEY", 1.5 * Unitful.km / Unitful.s, "c"; slash = 75)
        #  setvalue! truncates the comment too.
        card = FITSFiles.setvalue!(Card("KEY", 1, repeat("x", 47)), 12345678901234567890123)
        @test length(repr(card)) == 80 && card.comment == parse(Card, repr(card)).comment
    end

    #  A value that cannot be written as a FITS value is an error, and not a card that cannot be written.
    @testset "unsupported value types" begin
        for value in (1//2, pi, Complex(1//2, 1), (1//2) * Unitful.m, Complex(true, false), Rational(1, 3))
            @test_throws "is not supported." Card("KEY", value)
            @test_throws "is not supported." Card("HIERARCH", "ESO A", value, "")
            @test_throws "is not supported." Card("KEY", value, "comment"; fixed = false)
            @test_throws "is not supported." FITSFiles.setvalue!(Card("KEY", 1), value)
        end
        #  The other types of numbers are written and read as the same value.
        for value in (Float16(1.5), big(1.5), UInt8(7), UInt64(2)^63, Int128(10)^30, big(10)^40, Complex(Float16(1), Float16(2)),
            Complex(UInt8(1), UInt8(2)), 2.5f0 * Unitful.m)
            card = Card("KEY", value, "c")
            image = repr(card)
            @test length(image) == 80
            @test FITSFiles.typename(parse(Card, image)) != FITSFiles.Invalid
            @test parse(Card, image).value == ustrip(value)
        end
    end

    #  The key and the comment of a card are Strings, even if they are another type of string.
    @testset "String key and comment" begin
        card = Card(SubString("xxABCDxx", 3, 6), 1, SubString("a comment here", 3, 9))
        @test card.key isa String && card.comment isa String
        @test card.key == "ABCD" && card.comment == "comment"
        card = Card("HIERARCH", SubString("xxESO Axx", 3, 7), 1, SubString("a comment", 3, 9))
        @test card.key isa String && card.comment isa String && card.key == "ESO A"
        for card in (parse(Card, rpad("KEY     = 1 / c", 80)), parse(Card, rpad("COMMENT text", 80)),
            parse(Card, rpad("HIERARCH ESO A = 1 / c", 80)), parse(Card, rpad("END", 80)), parse(Card, "short"))
            @test card.key isa String && card.comment isa String
        end
    end

    #  The constructors raise an ArgumentError for an argument that cannot be a card, and a DomainError for a
    #  number that is not finite.
    @testset "error types" begin
        for (f, message) in (
            (() -> Card("ABC DEF", 1), "Keyword contains invalid characters."),
            (() -> Card("ABC", "caf\u00e9"), "Value string contains invalid characters."),
            (() -> Card("ABC", 1, "caf\u00e9"), "Comment contains invalid characters."),
            (() -> Card("A\x01", "ESO A", 1, ""), "Keyword contains invalid characters."),
            (() -> Card("HIERARCH", "ESO A", "caf\u00e9", ""), "Value string contains invalid characters."),
            (() -> Card("HIERARCH", "ESO A", 1, "caf\u00e9"), "Comment contains invalid characters."),
            (() -> Card("HIERARCH", "ESO a=b", 1, ""), "HIERARCH keyword contains invalid characters."),
            (() -> Card("ABC", "ESO A", 1, ""), "Invalid card"),
            (() -> Card("CONTINUE", 1), "Value is not a string."),
            (() -> Card("CONTINUE"), "Value is not a string."),
            (() -> Card("COMMENT", 1), "value is not a string."),
            (() -> Card("END", 1), "END keyword has no value or comment."),
            (() -> Card("ABC", 1//2), "is not supported."),
            (() -> Card("HIERARCH", "ESO A", repeat("x", 62), ""), "do not fit on the card."),
            (() -> Card("ABC", 1, repeat("x", 60); truncate = false), "Comment does not fit on the card."),
            (() -> FITSFiles.setvalue!(Card("COMMENT", "a"), 1), "value is not a string."),
            (() -> FITSFiles.setvalue!(Card("END"), 1), "END keyword has no value."),
            (() -> FITSFiles.format_card(FITSFiles.Comment, "COMMENT", 1, "", "", FITSFiles.CardFormat()), "Value is not a string."),
            (() -> FITSFiles.format_card(FITSFiles.History, "HISTORY", 1, "", "", FITSFiles.CardFormat()), "Value is not a string."),
            (() -> FITSFiles.format_card(FITSFiles.Continue, "CONTINUE", 1, "", "", FITSFiles.CardFormat()), "Continue contains non-string value."))
            @test_throws ArgumentError f()
            @test_throws message f()
        end
        for value in (NaN, Inf, -Inf, NaN32, Inf32, complex(NaN, 1.0))
            @test_throws DomainError Card("ABC", value)
            @test_throws "Value is not finite." Card("HIERARCH", "ESO A", value, "")
            @test_throws DomainError Card("HIERARCH", "ESO A", value, "")
        end
        #  No error of the card is a bare ErrorException.
        for f in (() -> Card("ABC DEF", 1), () -> Card("ABC", NaN), () -> Card("CONTINUE", 1))
            err = try f() catch e; e end
            @test !(err isa ErrorException)
        end
    end

end

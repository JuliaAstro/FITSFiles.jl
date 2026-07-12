@testset "Card" begin
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

    #  parse blank keyword
    @test isequal(showfields(parse(Card,
                   "               / exposure information                                           ")),
                  ("", "       / exposure information", "",
                   "               / exposure information                                           "))

    #  create blank keyword with non-string value
    @test_throws ArgumentError Card("", 123)

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

    ###  test Value Card constructor

    #  create Value Card and get its type with boolean value
    @test typeof(Card("BOOL", true)) <: Card{Value{Bool}}
    
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

    #  parse Value card with boolean value, fixed format
    @test isequal(showfields(parse(Card,
                   "BOOL    =                    T                                                  ")),
                  ("BOOL", true, "",
                   "BOOL    =                    T                                                  "))

    #  create Value card with boolean value, free-format
    @test isequal(showfields(Card("BOOL", true, fixed=false)),
                  ("BOOL", true, "",
                   "BOOL    = T                                                                     "))

    #  parse Value card with boolean value, free format
    @test parse(Card, "BOOL    = T                                                                     "
                    ).format.fixd == false

    #  parse Value card with boolean value, free format
    @test isequal(showfields(parse(Card,
                   "BOOL    = T                                                                     ")),
                  ("BOOL", true, "",
                   "BOOL    = T                                                                     "))

    #  create Value card with boolean value and comment, fixed format
    @test isequal(showfields(Card("BOOL", true, "a comment string")),
                  ("BOOL", true, "a comment string",
                   "BOOL    =                    T / a comment string                               "))
 
    #  parse Value card with boolean value and comment, fixed format
    @test isequal(showfields(parse(Card,
                   "BOOL    =                    T / a comment string                               ")),
                  ("BOOL", true, "a comment string",
                   "BOOL    =                    T / a comment string                               "))

    #  create Value card with boolean value and comment, free-format
    @test isequal(showfields(Card("BOOL", true, "a comment string", fixed=false)),
                  ("BOOL", true, "a comment string",
                   "BOOL    = T                    / a comment string                               "))

    #  parse Value card with boolean value and comment, free format
    @test isequal(showfields(parse(Card,
                   "BOOL    = T                    / a comment string                               ")),
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

    #  parse Value Card with integer value fixed-format
    @test isequal(showfields(parse(Card,
                   "INTEGER =                12345                                                  ")),
                  ("INTEGER", 12345, "",
                   "INTEGER =                12345                                                  "))

    #  create Value card with integer free value, test free format = false
    @test isequal(showfields(Card("INTEGER", 12345; fixed=false)),
                  ("INTEGER", 12345, "",
                   "INTEGER = 12345                                                                 "))

    #  parse Value Card with integer value free-format
    @test parse(Card, "INTEGER = 12345                                                                 "
                    ).format.fixd == false

    #  parse Value Card with integer value free-format
    @test isequal(showfields(parse(Card,
                   "INTEGER = 12345                                                                 ")),
                  ("INTEGER", 12345, "",
                   "INTEGER = 12345                                                                 "))

    #  create Value card with integer value and comment, fixed-format
    @test isequal(showfields(Card("INTEGER", 12345, "a comment string")),
                  ("INTEGER", 12345, "a comment string",
                   "INTEGER =                12345 / a comment string                               "))

    #  parse Value card with integer value and comment, fixed-format
    @test isequal(showfields(parse(Card,
                   "INTEGER =                12345 / a comment string                               ")),
                  ("INTEGER", 12345, "a comment string",
                   "INTEGER =                12345 / a comment string                               "))

    #  create Value card with integer value and comment, free-format
    @test isequal(showfields(Card("INTEGER", 12345, "a comment string", fixed=false)),
                  ("INTEGER", 12345, "a comment string",
                   "INTEGER = 12345                / a comment string                               "))

    #  parse Value card with integer value and comment, free-format
    @test isequal(showfields(parse(Card,
                   "INTEGER = 12345                / a comment string                               ")),
                  ("INTEGER", 12345, "a comment string",
                   "INTEGER = 12345                / a comment string                               "))

    #  test type of Value Card with long integer value
    @test typeof(Card("LONG_INT", -467374636747637647347374734737437)) <: Card{Value{Int128}}
    
    #  creat Value Card with long integer value, fixed-format
    @test isequal(showfields(Card("LONG_INT", -467374636747637647347374734737437)),
                  ("LONG_INT", -467374636747637647347374734737437, "",
                   "LONG_INT= -467374636747637647347374734737437                                    "))

    #  parse Value Card with big integer value
    @test isequal(showfields(parse(Card,
                   "LONG_INT= -467374636747637647347374734737437                                    ")),
                  ("LONG_INT", -467374636747637647347374734737437, "",
                   "LONG_INT= -467374636747637647347374734737437                                    "))

    #  create Value Card with long integer value and comment, fixed-format
    @test isequal(showfields(Card("LONG_INT", -467374636747637647347374734737437, "a comment string")),
                  ("LONG_INT", -467374636747637647347374734737437, "a comment string",
                   "LONG_INT= -467374636747637647347374734737437 / a comment string                 "))

    #  parse Value Card with big integer value and comment
    @test isequal(showfields(parse(Card,
                   "LONG_INT= -467374636747637647347374734737437 / a comment string                 ")),
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

    #  create Value Card with 32-bit float value, fixed-format
    @test isequal(showfields(parse(Card,
                   "FLOAT_32=             1.2345E6                                                  ")),
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

    #  parse Value Card with 64-bit float value, fixed-format
    @test isequal(showfields(parse(Card,
                   "FLOAT_64=         1.2345678901                                                  ")),
                  ("FLOAT_64", 1.2345678901, "",
                   "FLOAT_64=         1.2345678901                                                  "))

    #  create Value Card with 64-bit float value, free-format
    @test isequal(showfields(Card("FLOAT_64", 1.2345; fixed=false)),
                  ("FLOAT_64", 1.2345, "",
                   "FLOAT_64= 1.2345                                                                "))

    #  test Value Card with 64-bit floating point value
    @test parse(Card, "FLOAT_64= 1.2345                                                                "
                    ).format.fixd == false
           
    #  parse Value Card with 64-bit float value, free-format
    @test isequal(showfields(parse(Card,
                   "FLOAT_64= 1.2345678901                                                          ")),
                  ("FLOAT_64", 1.2345678901, "",
                   "FLOAT_64= 1.2345678901                                                          "))

    #  create Value Card with 64-bit float value, fixed-format
    @test isequal(showfields(Card("FLOAT_64", 1.2345, "a comment string")),
                  ("FLOAT_64", 1.2345, "a comment string",
                   "FLOAT_64=               1.2345 / a comment string                               "))

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

    #  create Value Card with 64-bit float value, fixed-format
    @test isequal(showfields(Card("FLOAT_64", 1.2345e6)),
                  ("FLOAT_64", 1.2345e6, "",
                   "FLOAT_64=             1.2345D6                                                  "))

    #  parse Value Card with 64-bit float value, fixed-format
    @test isequal(showfields(parse(Card,
                   "FLOAT_64=             1.2345D6                                                  ")),
                  ("FLOAT_64", 1.2345e6, "",
                   "FLOAT_64=             1.2345D6                                                  "))

    #  parse Value Card with 64-bit float value having high precision, fixed-format
    @test isequal(showfields(parse(Card,
                   "FLOAT_64=   1.23456789012345E6                                                  ")),
                  ("FLOAT_64", 1.23456789012345e6, "",
                   "FLOAT_64=   1.23456789012345D6                                                  "))

    #  parse Value Card with 64-bit float value having high exponent, fixed-format
    @test isequal(showfields(parse(Card,
                   "FLOAT_64=            1.2345E39                                                  ")),
                  ("FLOAT_64", 1.2345e39, "",
                   "FLOAT_64=            1.2345D39                                                  "))

    #  test Value Card with complex 64-bit integer value
    @test typeof(Card("CPLX_INT", 8 + 9im)) <: Card{Value{Complex{Int64}}}

    #  test Value Card with complex 64-bit integer value free format
    @test Card("CPLX_INT", 8 + 9im).format.fixd == false

    #  create Value Card with complex 64-bit integer value
    @test isequal(showfields(Card("CPLX_INT", 8 + 9im)),
                  ("CPLX_INT", 8 + 9im, "",
                   "CPLX_INT= (8, 9)                                                                "))

    #  parse Value Card with complex 64-bit integer value
    @test isequal(showfields(parse(Card,
                   "CPLX_INT= (8, 9)                                                                ")),
                  ("CPLX_INT", 8 + 9im, "",
                   "CPLX_INT= (8, 9)                                                                "))

    #  create Value Card with complex 64-bit integer value
    @test isequal(showfields(Card("CPLX_INT", 8 + 9im, "a comment string")),
                  ("CPLX_INT", 8 + 9im, "a comment string",
                   "CPLX_INT= (8, 9)               / a comment string                               "))

    #  parse Value Card with complex 64-bit integer value
    @test isequal(showfields(parse(Card,
                   "CPLX_INT= (8, 9)               / a comment string                               ")),
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

    #  parse Value Card with complex 64-bit float value
    @test isequal(showfields(parse(Card,
                   "CPLX_F64= (8.1, 9.2)                                                            ")),
                  ("CPLX_F64", 8.1 + 9.2im, "",
                   "CPLX_F64= (8.1, 9.2)                                                            "))

    #  create Value Card with complex 64-bit float value
    @test isequal(showfields(Card("CPLX_F64", 8.1 + 9.2im, "a comment string")),
                  ("CPLX_F64", 8.1 + 9.2im, "a comment string",
                   "CPLX_F64= (8.1, 9.2)           / a comment string                               "))

    #  parse Value Card with complex 64-bit float value
    @test isequal(showfields(parse(Card,
                   "CPLX_F64= (8.1, 9.2)           / a comment string                               ")),
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

    #  parse Value Card with complex 64-bit float and integer value
    @test isequal(showfields(parse(Card,
                   "CPLX_F64= (8.1, 9)                                                              ")),
                  ("CPLX_F64", 8.1 + 9.0im, "",
                   "CPLX_F64= (8.1, 9.0)                                                            "))

    #  create Value Card with complex 64-bit float and integer value
    @test isequal(showfields(Card("CPLX_F64", 8.1 + 9im, "a comment string")),
                  ("CPLX_F64", 8.1 + 9.0im, "a comment string",
                   "CPLX_F64= (8.1, 9.0)           / a comment string                               "))

    #  parse Value Card with complex 64-bit float and integer value
    @test isequal(showfields(parse(Card,
                   "CPLX_F64= (8.1, 9)             / a comment string                               ")),
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

    #  parse Value Card with complex integer and 64-bit float value
    @test isequal(showfields(parse(Card,
                   "CPLX_F64= (8, 9.2)                                                              ")),
                  ("CPLX_F64", 8.0 + 9.2im, "",
                   "CPLX_F64= (8.0, 9.2)                                                            "))

    #  create Value Card with complex integer and 64-bit float value
    @test isequal(showfields(Card("CPLX_F64", 8 + 9.2im, "a comment string")),
                  ("CPLX_F64", 8.0 + 9.2im, "a comment string",
                   "CPLX_F64= (8.0, 9.2)           / a comment string                               "))

    #  parse Value Card with complex integer and 64-bit float value
    @test isequal(showfields(parse(Card,
                   "CPLX_F64= (8, 9.2)             / a comment string                               ")),
                  ("CPLX_F64", 8.0 + 9.2im, "a comment string",
                   "CPLX_F64= (8.0, 9.2)           / a comment string                               "))

    ###  Test String Card constructor

    #  type of Value Card with string value
    @test typeof(Card("STRING", "a value string")) <: Card{Value{String}}
    
    #  create Value Card with a null string
    @test isequal(showfields(Card("STRING", "")),
                  ("STRING", "", "",
                   "STRING  = ''                                                                    "))

    #  parse Value Card with a null string
    @test isequal(showfields(parse(Card,
                   "STRING  = ''                                                                    ")),
                  ("STRING", "", "",
                   "STRING  = ''                                                                    "))

    #  create Value Card with an empty string
    @test isequal(showfields(Card("STRING", "        ")),
                  ("STRING", "        ", "",
                   "STRING  = '        '                                                            "))

    #  parse Value Card with an empty string
    @test isequal(showfields(parse(Card,
                   "STRING  = '        '                                                            ")),
                  ("STRING", "        ", "",
                   "STRING  = '        '                                                            "))

    #  create Value Card with a string value
    @test isequal(showfields(Card("STRING", "a value string")),
                  ("STRING", "a value string", "",
                   "STRING  = 'a value string'                                                      "))

    #  parse Value Card with string value
    @test isequal(showfields(parse(Card,
                   "STRING  = 'a value string'                                                      ")),
                  ("STRING", "a value string", "",
                   "STRING  = 'a value string'                                                      "))

    #  create Value Card with a string value
    @test isequal(showfields(Card("STRING", "a value string", "a comment string")),
                  ("STRING", "a value string", "a comment string",
                   "STRING  = 'a value string'     / a comment string                               "))

    #  parse Value Card with string value
    @test isequal(showfields(parse(Card,
                   "STRING  = 'a value string'     / a comment string                               ")),
                  ("STRING", "a value string", "a comment string",
                   "STRING  = 'a value string'     / a comment string                               "))

    #  create String Card with string of <8 characters
    @test isequal(showfields(Card("STRING", "<8 ch")),
                  ("STRING", "<8 ch", "",
                   "STRING  = '<8 ch'                                                               "))

    #  parse Value Card with string of <8 characters
    @test isequal(showfields(parse(Card,
                   "STRING  = '<8 ch'                                                               ")),
                  ("STRING", "<8 ch", "",
                   "STRING  = '<8 ch'                                                               "))

    #  create String Card having string with single quote
    @test isequal(showfields(Card("STRING", "Kelley O'Hara")),
                  ("STRING", "Kelley O'Hara", "",
                   "STRING  = 'Kelley O''Hara'                                                      "))

    #  parse String Card have a string with a single quote
    @test isequal(showfields(parse(Card,
                   "STRING  = 'Kelley O''Hara'                                                      ")),
                  ("STRING", "Kelley O'Hara", "",
                   "STRING  = 'Kelley O''Hara'                                                      "))

    #  create String Card having string with a single quote and comment
    @test isequal(showfields(Card("STRING", "Kelley O'Hara", "a comment string")),
                  ("STRING", "Kelley O'Hara", "a comment string",
                   "STRING  = 'Kelley O''Hara'     / a comment string                               "))

    #  parse String Card have a string with a single quote and comment
    @test isequal(showfields(parse(Card,
                   "STRING  = 'Kelley O''Hara'     / a comment string                               ")),
                  ("STRING", "Kelley O'Hara", "a comment string",
                   "STRING  = 'Kelley O''Hara'     / a comment string                               "))

    #  create String Card having string with a single quote and comment with a single quote
    @test isequal(showfields(Card("STRING", "Kelley O'Hara", "a comment string with single quote '")),
                  ("STRING", "Kelley O'Hara", "a comment string with single quote '",
                   "STRING  = 'Kelley O''Hara'     / a comment string with single quote '           "))

    #  parse String Card have a string with a single quote and comment with a single quote
    @test isequal(showfields(parse(Card,
                   "STRING  = 'Kelley O''Hara'     / a comment string with single quote '           ")),
                  ("STRING", "Kelley O'Hara", "a comment string with single quote '",
                   "STRING  = 'Kelley O''Hara'     / a comment string with single quote '           "))

    #  create String Card that truncates comment
    @test isequal(showfields(Card("STRING", repeat("-", 58), "a truncated comment", slash=72, truncate=true)),
                  ("STRING", "----------------------------------------------------------", "a truncated comment",
                   "STRING  = '----------------------------------------------------------' / a trunc"))

    #  parse String Card that truncates comment
    @test isequal(showfields(parse(Card,
                   "STRING  = '----------------------------------------------------------' / a trunc")),
                  ("STRING", "----------------------------------------------------------", "a trunc",
                   "STRING  = '----------------------------------------------------------' / a trunc"))

    #  create Value card with no left and right padding for comment separator
    @test isequal(showfields(Card("longcom", "19 character string","a comment string", lpad=0, rpad=0)),
                  ("LONGCOM", "19 character string", "a comment string",
                   "LONGCOM = '19 character string'/a comment string                                "))

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
    card = Card("longcom", repeat("Kelley O'Hara ", 4), repeat("long comment ", 6), slash=43, lpad=1)
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
                lpad=1, fixed=false)
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
    card = Card("abc", repeat("long string value ", 10), repeat("long comment ", 10), slash=51)
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
                "SuperNavigationParameters_XXXX_YYYY_ZZZZZ_KK_01_02_03)-AAABBBCCC.n.xml", slash=85)
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
    card = Card("longcom", repeat("long string value ", 6), repeat("long comment ", 10), slash=51)
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

    #   create Value Card having lower case Bintable XTENSION
    @test isequal(showfields(Card("XTENSION", "bintable", "a comment string")),
                  ("XTENSION", "BINTABLE", "a comment string",
                   "XTENSION= 'BINTABLE'           / a comment string                               "))
 
     #   parse Value Card having Bintable XTENSION
    @test isequal(showfields(parse(Card,
                   "XTENSION= 'BINTABLE'           / a comment string                               ")),
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
    
    #  parse HIERARCH keyword and value
    #=
    @test isequal(showfields(parse(Card,
                   "HIERARCH ABC DEF GH IJKLMN = -99.9                                              ")),
                   ("ABC DEF GH IJKLMN", -99.9, "",
                   "HIERARCH ABC DEF GH IJKLMN = -99.9                                              "))
    =#
    
    #  create HIERARCH keyword and value with comment
    @test isequal(showfields(Card("HIERARCH", "abc def gh ijklmn_-", -99.9, "[m] abcdef ghijklm nopqrstu vw xyzab")),
                  ("ABC DEF GH IJKLMN_-", -99.9, "[m] abcdef ghijklm nopqrstu vw xyzab",
                   "HIERARCH ABC DEF GH IJKLMN_- = -99.9 / [m] abcdef ghijklm nopqrstu vw xyzab     "))
    
    #  parse HIERARCH keyword and value with comment
    
    @test isequal(showfields(parse(Card,
                   "HIERARCH ABC DEF GH IJKLM_- = -99.9 / [m] abcdef ghijklm nopqrstu vw xyzab      ")),
                  ("ABC DEF GH IJKLM_-", -99.9f0, "[m] abcdef ghijklm nopqrstu vw xyzab",
                   "HIERARCH ABC DEF GH IJKLM_- = -99.9 / [m] abcdef ghijklm nopqrstu vw xyzab      "))
    
    
    #  test HIERARCH Card with abbreviated value indicator.

    #  test HIERARCH Card with whitespace keyword.

    #  test HIERARCH Card with mixed case.

    #  test that a fixed HIERARCH Card remains that card.

    #  test Card constructor for long keywords with warning.

    #  HIERARCH keyword implied by long keyword
    ### @test isequal(showfields(Card("abc def gh ijklmn", -99.9, "[m] abcdef ghijklm nopqrstu vw xyzab")),
    ###              ("ABC DEF GH IJKLMN", -99.9, "[m] abcdef ghijklm nopqrstu vw xyzab",
    ###               "HIERARCH ABC DEF GH IJKLMN = -99.9 / [m] abcdef ghijklm nopqrstu vw xyzab       "))

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

end

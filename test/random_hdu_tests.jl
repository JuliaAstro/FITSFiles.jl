@testset "Random HDU" begin

    #  test Random (specific HDU) type
    hdu = HDU(Random)

    @test isequal(showfields.(hdu.cards),
                  [("SIMPLE", true, "",
                    "SIMPLE  =                    T                                                  "),
                   ("BITPIX", 32, "",
                    "BITPIX  =                   32                                                  "),
                   ("NAXIS", 1, "",
                    "NAXIS   =                    1                                                  "),
                   ("NAXIS1", 0, "",
                    "NAXIS1  =                    0                                                  "),
                   ("GROUPS", true, "",
                    "GROUPS  =                    T                                                  "),
                   ("PCOUNT", 0, "",
                    "PCOUNT  =                    0                                                  "),
                   ("GCOUNT", 0, "",
                    "GCOUNT  =                    0                                                  ")])

    @test ismissing(hdu.data)

    #  test Random type with data being an array of tuples
    data = [
       (par1=1.0f0, par2=1.0f0, par3=1.0f0,
        data=Float32[1 1 1; 2 2 2;;; 3 3 3; 4 4 4;;; 5 5 5; 6 6 6;;; 7 7 7; 8 8 8]),
       (par1=2.0f0, par2=2.0f0, par3=2.0f0,
        data=Float32[2 2 2; 3 3 3;;; 4 4 4; 5 5 5;;; 6 6 6; 7 7 7;;; 8 8 8; 9 9 9]),
       (par1=3.0f0, par2=3.0f0, par3=3.0f0,
        data=Float32[3 3 3; 4 4 4;;; 5 5 5; 6 6 6;;; 7 7 7; 8 8 8;;; 9 9 9; 10 10 10])]
    hdu = HDU(Random, data)

    @test isequal(showfields.(hdu.cards),
                  [("SIMPLE", true, "",
                    "SIMPLE  =                    T                                                  "),
                   ("BITPIX", -32, "",
                    "BITPIX  =                  -32                                                  "),
                   ("NAXIS", 4, "",
                    "NAXIS   =                    4                                                  "),
                   ("NAXIS1", 0, "",
                    "NAXIS1  =                    0                                                  "),
                   ("NAXIS2", 2, "",
                    "NAXIS2  =                    2                                                  "),
                   ("NAXIS3", 3, "",
                    "NAXIS3  =                    3                                                  "),
                   ("NAXIS4", 4, "",
                    "NAXIS4  =                    4                                                  "),
                   ("GROUPS", true, "",
                    "GROUPS  =                    T                                                  "),
                   ("PCOUNT", 3, "",
                    "PCOUNT  =                    3                                                  "),
                   ("GCOUNT", 3, "",
                    "GCOUNT  =                    3                                                  "),
                   ("PTYPE1", "par1", "",
                    "PTYPE1  = 'par1'                                                                "),
                   ("PTYPE2", "par2", "",
                    "PTYPE2  = 'par2'                                                                "),
                   ("PTYPE3", "par3", "",
                    "PTYPE3  = 'par3'                                                                ")])

    @test ((length(data[1])-1) == 3 && ndims(hdu.data[1][:data]) == 3 &&
           size(hdu.data[1][:data]) == (2, 3, 4) && eltype(hdu.data[1][:data]) == Float32)

    #  test Random type with data being a tuple of arrays
    data = (; par1=Float32[1, 2, 3, 4, 5], par2=Float32[1, 2, 3, 4, 5], par3=Float32[1, 2, 3, 4, 5],
              data=Float32[
              1 1; 2 2; 3 3; 4 4; 5 5;;; 1 1; 2 2; 3 3; 4 4; 5 5;;; 1 1; 2 2; 3 3; 4 4; 5 5;;;;
              1 1; 2 2; 3 3; 4 4; 5 5;;; 1 1; 2 2; 3 3; 4 4; 5 5;;; 1 1; 2 2; 3 3; 4 4; 5 5;;;;
              1 1; 2 2; 3 3; 4 4; 5 5;;; 1 1; 2 2; 3 3; 4 4; 5 5;;; 1 1; 2 2; 3 3; 4 4; 5 5;;;;
              1 1; 2 2; 3 3; 4 4; 5 5;;; 1 1; 2 2; 3 3; 4 4; 5 5;;; 1 1; 2 2; 3 3; 4 4; 5 5])

    hdu = HDU(Random, data)

    @test isequal(showfields.(hdu.cards),
                  [("SIMPLE", true, "",
                    "SIMPLE  =                    T                                                  "),
                   ("BITPIX", -32, "",
                    "BITPIX  =                  -32                                                  "),
                   ("NAXIS", 4, "",
                    "NAXIS   =                    4                                                  "),
                   ("NAXIS1", 0, "",
                    "NAXIS1  =                    0                                                  "),
                   ("NAXIS2", 2, "",
                    "NAXIS2  =                    2                                                  "),
                   ("NAXIS3", 3, "",
                    "NAXIS3  =                    3                                                  "),
                   ("NAXIS4", 4, "",
                    "NAXIS4  =                    4                                                  "),
                   ("GROUPS", true, "",
                    "GROUPS  =                    T                                                  "),
                   ("PCOUNT", 3, "",
                    "PCOUNT  =                    3                                                  "),
                   ("GCOUNT", 5, "",
                    "GCOUNT  =                    5                                                  "),
                   ("PTYPE1", "par1", "",
                    "PTYPE1  = 'par1'                                                                "),
                   ("PTYPE2", "par2", "",
                    "PTYPE2  = 'par2'                                                                "),
                   ("PTYPE3", "par3", "",
                    "PTYPE3  = 'par3'                                                                ")])

    @test (length(data) == 4 && ndims(hdu.data[:data]) == 4 &&
           size(hdu.data[:data]) == (5, 2, 3, 4) && eltype(hdu.data[:data]) == Float32)

    #  test Random type with cards
    cards = [Card("SIMPLE", true),
             Card("BITPIX", -32),
             Card("NAXIS", 4),
             Card("NAXIS1", 0),
             Card("NAXIS2", 2),
             Card("NAXIS3", 3),
             Card("NAXIS4", 4),
             Card("GROUPS", true),
             Card("PCOUNT", 3),
             Card("GCOUNT", 3)]
    hdu = HDU(cards)

    @test isequal(showfields.(hdu.cards),
                  [("SIMPLE", true, "",
                    "SIMPLE  =                    T                                                  "),
                   ("BITPIX", -32, "",
                    "BITPIX  =                  -32                                                  "),
                   ("NAXIS", 4, "",
                    "NAXIS   =                    4                                                  "),
                   ("NAXIS1", 0, "",
                    "NAXIS1  =                    0                                                  "),
                   ("NAXIS2", 2, "",
                    "NAXIS2  =                    2                                                  "),
                    ("NAXIS3", 3, "",
                    "NAXIS3  =                    3                                                  "),
                   ("NAXIS4", 4, "",
                    "NAXIS4  =                    4                                                  "),
                   ("GROUPS", true, "",
                    "GROUPS  =                    T                                                  "),
                    ("PCOUNT", 3, "",
                    "PCOUNT  =                    3                                                  "),
                   ("GCOUNT", 3, "",
                    "GCOUNT  =                    3                                                  "),
                   ("PTYPE1", "param1", "",
                    "PTYPE1  = 'param1'                                                              "),
                   ("PTYPE2", "param2", "",
                    "PTYPE2  = 'param2'                                                              "),
                   ("PTYPE3", "param3", "",
                    "PTYPE3  = 'param3'                                                              ")])

    @test (ndims(hdu.data[:data]) == 4 && size(hdu.data[:data]) == (3, 2, 3, 4) &&
        eltype(hdu.data[:data]) == Float32)

    #  test Random type with data being a tuple of arrays and cards
    data = (Float32[1, 2, 3, 4, 5], Float32[1, 2, 3, 4, 5], Float32[1, 2, 3, 4, 5],
              Float32[
              1 1; 2 2; 3 3; 4 4; 5 5;;; 1 1; 2 2; 3 3; 4 4; 5 5;;; 1 1; 2 2; 3 3; 4 4; 5 5;;;;
              1 1; 2 2; 3 3; 4 4; 5 5;;; 1 1; 2 2; 3 3; 4 4; 5 5;;; 1 1; 2 2; 3 3; 4 4; 5 5;;;;
              1 1; 2 2; 3 3; 4 4; 5 5;;; 1 1; 2 2; 3 3; 4 4; 5 5;;; 1 1; 2 2; 3 3; 4 4; 5 5;;;;
              1 1; 2 2; 3 3; 4 4; 5 5;;; 1 1; 2 2; 3 3; 4 4; 5 5;;; 1 1; 2 2; 3 3; 4 4; 5 5])
    cards = [Card("SIMPLE", true),
        Card("BITPIX", -32),
        Card("NAXIS", 4),
        Card("NAXIS1", 0),
        Card("NAXIS2", 2),
        Card("NAXIS3", 3),
        Card("NAXIS4", 4),
        Card("GROUPS", true),
        Card("PCOUNT", 3),
        Card("GCOUNT", 5),
        Card("PTYPE1", "PARAM1"),
        Card("PTYPE2", "PARAM2"),
        Card("PTYPE3", "PARAM3")]
    hdu = HDU(Random, data, cards)

    @test isequal(showfields.(hdu.cards),
                  [("SIMPLE", true, "",
                    "SIMPLE  =                    T                                                  "),
                   ("BITPIX", -32, "",
                    "BITPIX  =                  -32                                                  "),
                   ("NAXIS", 4, "",
                    "NAXIS   =                    4                                                  "),
                   ("NAXIS1", 0, "",
                    "NAXIS1  =                    0                                                  "),
                   ("NAXIS2", 2, "",
                    "NAXIS2  =                    2                                                  "),
                   ("NAXIS3", 3, "",
                    "NAXIS3  =                    3                                                  "),
                   ("NAXIS4", 4, "",
                    "NAXIS4  =                    4                                                  "),
                   ("GROUPS", true, "",
                    "GROUPS  =                    T                                                  "),
                   ("PCOUNT", 3, "",
                    "PCOUNT  =                    3                                                  "),
                   ("GCOUNT", 5, "",
                    "GCOUNT  =                    5                                                  "),
                   ("PTYPE1", "PARAM1", "",
                    "PTYPE1  = 'PARAM1'                                                              "),
                   ("PTYPE2", "PARAM2", "",
                    "PTYPE2  = 'PARAM2'                                                              "),
                   ("PTYPE3", "PARAM3", "",
                    "PTYPE3  = 'PARAM3'                                                              ")])

    @test (length(data) == 4 && ndims(hdu.data[:data]) == 4 &&
           size(hdu.data[:data]) == (5, 2, 3, 4) && eltype(hdu.data[:data]) == Float32)

    #  test Random type with data being a tuple of arrays and inconsistent cards

    data = (Float32[1, 2, 3, 4, 5], Float32[1, 2, 3, 4, 5], Float32[1, 2, 3, 4, 5],
              Float32[
              1 1; 2 2; 3 3; 4 4; 5 5;;; 1 1; 2 2; 3 3; 4 4; 5 5;;; 1 1; 2 2; 3 3; 4 4; 5 5;;;;
              1 1; 2 2; 3 3; 4 4; 5 5;;; 1 1; 2 2; 3 3; 4 4; 5 5;;; 1 1; 2 2; 3 3; 4 4; 5 5;;;;
              1 1; 2 2; 3 3; 4 4; 5 5;;; 1 1; 2 2; 3 3; 4 4; 5 5;;; 1 1; 2 2; 3 3; 4 4; 5 5;;;;
              1 1; 2 2; 3 3; 4 4; 5 5;;; 1 1; 2 2; 3 3; 4 4; 5 5;;; 1 1; 2 2; 3 3; 4 4; 5 5])
    cards = [Card("SIMPLE", true),
        Card("BITPIX", 32),
        Card("NAXIS", 3),
        Card("NAXIS1", 0),
        Card("NAXIS2", 2),
        Card("NAXIS3", 3),
        Card("NAXIS4", 4),
        Card("GROUPS", false),
        Card("PCOUNT", 5),
        Card("GCOUNT", 3),
        Card("PTYPE1", "PARAM1"),
        Card("PTYPE2", "PARAM2"),
        Card("PTYPE3", "PARAM3")]
    hdu = HDU(Random, data, cards)

    @test isequal(showfields.(hdu.cards),
                  [("SIMPLE", true, "",
                    "SIMPLE  =                    T                                                  "),
                   ("BITPIX", -32, "",
                    "BITPIX  =                  -32                                                  "),
                   ("NAXIS", 4, "",
                    "NAXIS   =                    4                                                  "),
                   ("NAXIS1", 0, "",
                    "NAXIS1  =                    0                                                  "),
                   ("NAXIS2", 2, "",
                    "NAXIS2  =                    2                                                  "),
                   ("NAXIS3", 3, "",
                    "NAXIS3  =                    3                                                  "),
                   ("NAXIS4", 4, "",
                    "NAXIS4  =                    4                                                  "),
                   ("GROUPS", true, "",
                    "GROUPS  =                    T                                                  "),
                   ("PCOUNT", 3, "",
                    "PCOUNT  =                    3                                                  "),
                   ("GCOUNT", 5, "",
                    "GCOUNT  =                    5                                                  "),
                   ("PTYPE1", "PARAM1", "",
                    "PTYPE1  = 'PARAM1'                                                              "),
                   ("PTYPE2", "PARAM2", "",
                    "PTYPE2  = 'PARAM2'                                                              "),
                   ("PTYPE3", "PARAM3", "",
                    "PTYPE3  = 'PARAM3'                                                              ")])

    @test (length(data) == 4 && ndims(hdu.data[:data]) == 4 &&
           size(hdu.data[:data]) == (5, 2, 3, 4) && eltype(hdu.data[:data]) == Float32)

    #  test Random type with data being an array of records and cards
    data = [
       (1.0f0, 1.0f0, 1.0f0,
        Float32[1 1 1; 2 2 2;;; 3 3 3; 4 4 4;;; 5 5 5; 6 6 6;;; 7 7 7; 8 8 8]),
       (2.0f0, 2.0f0, 2.0f0,
        Float32[2 2 2; 3 3 3;;; 4 4 4; 5 5 5;;; 6 6 6; 7 7 7;;; 8 8 8; 9 9 9]),
       (3.0f0, 3.0f0, 3.0f0,
        Float32[3 3 3; 4 4 4;;; 5 5 5; 6 6 6;;; 7 7 7; 8 8 8;;; 9 9 9; 10 10 10])]
    cards = [Card("SIMPLE", true),
        Card("BITPIX", -32),
        Card("NAXIS", 4),
        Card("NAXIS1", 0),
        Card("NAXIS2", 2),
        Card("NAXIS3", 3),
        Card("NAXIS4", 4),
        Card("GROUPS", true),
        Card("PCOUNT", 3),
        Card("GCOUNT", 3),
        Card("PTYPE1", "PARAM1"),
        Card("PTYPE2", "PARAM2"),
        Card("PTYPE3", "PARAM3")]
    hdu = HDU(Random, data, cards)

    @test isequal(showfields.(hdu.cards),
                  [("SIMPLE", true, "",
                    "SIMPLE  =                    T                                                  "),
                   ("BITPIX", -32, "",
                    "BITPIX  =                  -32                                                  "),
                   ("NAXIS", 4, "",
                    "NAXIS   =                    4                                                  "),
                   ("NAXIS1", 0, "",
                    "NAXIS1  =                    0                                                  "),
                   ("NAXIS2", 2, "",
                    "NAXIS2  =                    2                                                  "),
                   ("NAXIS3", 3, "",
                    "NAXIS3  =                    3                                                  "),
                   ("NAXIS4", 4, "",
                    "NAXIS4  =                    4                                                  "),
                   ("GROUPS", true, "",
                    "GROUPS  =                    T                                                  "),
                   ("PCOUNT", 3, "",
                    "PCOUNT  =                    3                                                  "),
                   ("GCOUNT", 3, "",
                    "GCOUNT  =                    3                                                  "),
                   ("PTYPE1", "PARAM1", "",
                    "PTYPE1  = 'PARAM1'                                                              "),
                   ("PTYPE2", "PARAM2", "",
                    "PTYPE2  = 'PARAM2'                                                              "),
                   ("PTYPE3", "PARAM3", "",
                    "PTYPE3  = 'PARAM3'                                                              ")])

    @test ((length(data[1])-1) == 3 && ndims(hdu.data[1][:data]) == 3 &&
           size(hdu.data[1][:data]) == (2, 3, 4) && eltype(hdu.data[1][:data]) == Float32)

    #  test Random type with data being an array of records and inconsistent cards
    data = [
       (1.0f0, 1.0f0, 1.0f0,
        Float32[1 1 1; 2 2 2;;; 3 3 3; 4 4 4;;; 5 5 5; 6 6 6;;; 7 7 7; 8 8 8]),
       (2.0f0, 2.0f0, 2.0f0,
        Float32[2 2 2; 3 3 3;;; 4 4 4; 5 5 5;;; 6 6 6; 7 7 7;;; 8 8 8; 9 9 9]),
       (3.0f0, 3.0f0, 3.0f0,
        Float32[3 3 3; 4 4 4;;; 5 5 5; 6 6 6;;; 7 7 7; 8 8 8;;; 9 9 9; 10 10 10])]
    cards = [Card("SIMPLE", true),
        Card("BITPIX", 32),
        Card("NAXIS", 3),
        Card("NAXIS1", 0),
        Card("NAXIS2", 2),
        Card("NAXIS3", 3),
        Card("NAXIS4", 4),
        Card("GROUPS", false),
        Card("PCOUNT", 5),
        Card("GCOUNT", 3),
        Card("PTYPE1", "PARAM1"),
        Card("PTYPE2", "PARAM2"),
        Card("PTYPE3", "PARAM3")]
    hdu = HDU(Random, data, cards)

    @test isequal(showfields.(hdu.cards),
                  [("SIMPLE", true, "",
                    "SIMPLE  =                    T                                                  "),
                   ("BITPIX", -32, "",
                    "BITPIX  =                  -32                                                  "),
                   ("NAXIS", 4, "",
                    "NAXIS   =                    4                                                  "),
                   ("NAXIS1", 0, "",
                    "NAXIS1  =                    0                                                  "),
                   ("NAXIS2", 2, "",
                    "NAXIS2  =                    2                                                  "),
                   ("NAXIS3", 3, "",
                    "NAXIS3  =                    3                                                  "),
                   ("NAXIS4", 4, "",
                    "NAXIS4  =                    4                                                  "),
                   ("GROUPS", true, "",
                    "GROUPS  =                    T                                                  "),
                   ("PCOUNT", 3, "",
                    "PCOUNT  =                    3                                                  "),
                   ("GCOUNT", 3, "",
                    "GCOUNT  =                    3                                                  "),
                   ("PTYPE1", "PARAM1", "",
                    "PTYPE1  = 'PARAM1'                                                              "),
                   ("PTYPE2", "PARAM2", "",
                    "PTYPE2  = 'PARAM2'                                                              "),
                   ("PTYPE3", "PARAM3", "",
                    "PTYPE3  = 'PARAM3'                                                              ")])

    @test ((length(data[1])-1) == 3 && ndims(hdu.data[1][:data]) == 3 &&
           size(hdu.data[1][:data]) == (2, 3, 4) && eltype(hdu.data[1][:data]) == Float32)

    #  test Random type with data being array of records and record == false
    data = [
       (par1=1.0f0, par2=1.0f0, par3=1.0f0,
        data=Float32[1 1 1; 2 2 2;;; 3 3 3; 4 4 4;;; 5 5 5; 6 6 6;;; 7 7 7; 8 8 8]),
       (par1=2.0f0, par2=2.0f0, par3=2.0f0,
        data=Float32[2 2 2; 3 3 3;;; 4 4 4; 5 5 5;;; 6 6 6; 7 7 7;;; 8 8 8; 9 9 9]),
       (par1=3.0f0, par2=3.0f0, par3=3.0f0,
        data=Float32[3 3 3; 4 4 4;;; 5 5 5; 6 6 6;;; 7 7 7; 8 8 8;;; 9 9 9; 10 10 10])]
    seek(io, 0)
    write(io, HDU(Random, data))
    seek(io, 0)
    hdu = read(io, HDU; record=false)

    @test isequal(showfields.(hdu.cards),
                  [("SIMPLE", true, "",
                    "SIMPLE  =                    T                                                  "),
                   ("BITPIX", -32, "",
                    "BITPIX  =                  -32                                                  "),
                   ("NAXIS", 4, "",
                    "NAXIS   =                    4                                                  "),
                   ("NAXIS1", 0, "",
                    "NAXIS1  =                    0                                                  "),
                   ("NAXIS2", 2, "",
                    "NAXIS2  =                    2                                                  "),
                   ("NAXIS3", 3, "",
                    "NAXIS3  =                    3                                                  "),
                   ("NAXIS4", 4, "",
                    "NAXIS4  =                    4                                                  "),
                   ("GROUPS", true, "",
                    "GROUPS  =                    T                                                  "),
                   ("PCOUNT", 3, "",
                    "PCOUNT  =                    3                                                  "),
                   ("GCOUNT", 3, "",
                    "GCOUNT  =                    3                                                  "),
                   ("PTYPE1", "par1", "",
                    "PTYPE1  = 'par1'                                                                "),
                   ("PTYPE2", "par2", "",
                    "PTYPE2  = 'par2'                                                                "),
                   ("PTYPE3", "par3", "",
                    "PTYPE3  = 'par3'                                                                ")])

    @test (length(hdu.data) == 4 && ndims(hdu.data[:data]) == 4 &&
           size(hdu.data[:data]) == (3, 2, 3, 4) && eltype(hdu.data[:data]) == Float32)

    #  test Random type with data being array of records and record = true
    data = [
       (par1=1.0f0, par2=1.0f0, par3=1.0f0,
        data=Float32[1 1 1; 2 2 2;;; 3 3 3; 4 4 4;;; 5 5 5; 6 6 6;;; 7 7 7; 8 8 8]),
       (par1=2.0f0, par2=2.0f0, par3=2.0f0,
        data=Float32[2 2 2; 3 3 3;;; 4 4 4; 5 5 5;;; 6 6 6; 7 7 7;;; 8 8 8; 9 9 9]),
       (par1=3.0f0, par2=3.0f0, par3=3.0f0,
        data=Float32[3 3 3; 4 4 4;;; 5 5 5; 6 6 6;;; 7 7 7; 8 8 8;;; 9 9 9; 10 10 10])]
    seek(io, 0)
    write(io, HDU(Random, data))
    seek(io, 0)
    hdu = read(io, HDU; record=true)

    @test isequal(showfields.(hdu.cards),
                  [("SIMPLE", true, "",
                    "SIMPLE  =                    T                                                  "),
                   ("BITPIX", -32, "",
                    "BITPIX  =                  -32                                                  "),
                   ("NAXIS", 4, "",
                    "NAXIS   =                    4                                                  "),
                   ("NAXIS1", 0, "",
                    "NAXIS1  =                    0                                                  "),
                   ("NAXIS2", 2, "",
                    "NAXIS2  =                    2                                                  "),
                   ("NAXIS3", 3, "",
                    "NAXIS3  =                    3                                                  "),
                   ("NAXIS4", 4, "",
                    "NAXIS4  =                    4                                                  "),
                   ("GROUPS", true, "",
                    "GROUPS  =                    T                                                  "),
                   ("PCOUNT", 3, "",
                    "PCOUNT  =                    3                                                  "),
                   ("GCOUNT", 3, "",
                    "GCOUNT  =                    3                                                  "),
                   ("PTYPE1", "par1", "",
                    "PTYPE1  = 'par1'                                                                "),
                   ("PTYPE2", "par2", "",
                    "PTYPE2  = 'par2'                                                                "),
                   ("PTYPE3", "par3", "",
                    "PTYPE3  = 'par3'                                                                ")])

    @test ((length(data[1])-1) == 3 && ndims(hdu.data[1][:data]) == 3 &&
           size(hdu.data[1][:data]) == (2, 3, 4) && eltype(hdu.data[1][:data]) == Float32)

    #  test Random type with data being array of records and scale == true
    data = [
       (1.0f0, 1.0f0, 1.0f0,
        Float32[1 1 1; 2 2 2;;; 3 3 3; 4 4 4;;; 5 5 5; 6 6 6;;; 7 7 7; 8 8 8]),
       (2.0f0, 2.0f0, 2.0f0,
        Float32[2 2 2; 3 3 3;;; 4 4 4; 5 5 5;;; 6 6 6; 7 7 7;;; 8 8 8; 9 9 9]),
       (3.0f0, 3.0f0, 3.0f0,
        Float32[3 3 3; 4 4 4;;; 5 5 5; 6 6 6;;; 7 7 7; 8 8 8;;; 9 9 9; 10 10 10])]
    cards = [Card("SIMPLE", true),
        Card("BITPIX", -32),
        Card("NAXIS", 4),
        Card("NAXIS1", 0),
        Card("NAXIS2", 2),
        Card("NAXIS3", 3),
        Card("NAXIS4", 4),
        Card("GROUPS", true),
        Card("PCOUNT", 3),
        Card("GCOUNT", 3),
        Card("PTYPE1", "PARAM1"),
        Card("PZERO1", 1.0),
        Card("PSCAL1", 0.1),
        Card("PTYPE2", "PARAM2"),
        Card("PZERO2", 1.0),
        Card("PSCAL2", 0.1),
        Card("PTYPE3", "PARAM3"),
        Card("PZERO3", 1.0),
        Card("PSCAL3", 0.1)]
    seek(io, 0)
    write(io, HDU(Random, data, cards))
    seek(io, 0)
    hdu = read(io, HDU; scale=true)

    @test isequal(showfields.(hdu.cards),
                  [("SIMPLE", true, "",
                    "SIMPLE  =                    T                                                  "),
                   ("BITPIX", -32, "",
                    "BITPIX  =                  -32                                                  "),
                   ("NAXIS", 4, "",
                    "NAXIS   =                    4                                                  "),
                   ("NAXIS1", 0, "",
                    "NAXIS1  =                    0                                                  "),
                   ("NAXIS2", 2, "",
                    "NAXIS2  =                    2                                                  "),
                   ("NAXIS3", 3, "",
                    "NAXIS3  =                    3                                                  "),
                   ("NAXIS4", 4, "",
                    "NAXIS4  =                    4                                                  "),
                   ("GROUPS", true, "",
                    "GROUPS  =                    T                                                  "),
                   ("PCOUNT", 3, "",
                    "PCOUNT  =                    3                                                  "),
                   ("GCOUNT", 3, "",
                    "GCOUNT  =                    3                                                  "),
                   ("PTYPE1", "PARAM1", "",
                    "PTYPE1  = 'PARAM1'                                                              "),
                   ("PTYPE2", "PARAM2", "",
                    "PTYPE2  = 'PARAM2'                                                              "),
                   ("PTYPE3", "PARAM3", "",
                    "PTYPE3  = 'PARAM3'                                                              "),
                   ("PZERO1", 1.0f0, "",
                    "PZERO1  =                  1.0                                                  "),
                   ("PSCAL1",  0.1f0, "",
                    "PSCAL1  =                  0.1                                                  "),
                   ("PZERO2", 1.0f0, "",
                    "PZERO2  =                  1.0                                                  "),
                   ("PSCAL2",  0.1f0, "",
                    "PSCAL2  =                  0.1                                                  "),
                   ("PZERO3", 1.0f0, "",
                    "PZERO3  =                  1.0                                                  "),
                   ("PSCAL3",  0.1f0, "",
                    "PSCAL3  =                  0.1                                                  ")])

    @test (length(data[1]) == 4 && ndims(hdu.data[:data]) == 4 &&
           size(hdu.data[:data]) == (3, 2, 3, 4) && eltype(hdu.data[:data]) == Float32 &&
           all(hdu.data[:PARAM1] .== [1.1f0, 1.2f0, 1.3f0]))

    #  test Random type with data being array of records and scale == false
    data = [
       (1.0f0, 1.0f0, 1.0f0,
        Float32[1 1 1; 2 2 2;;; 3 3 3; 4 4 4;;; 5 5 5; 6 6 6;;; 7 7 7; 8 8 8]),
       (2.0f0, 2.0f0, 2.0f0,
        Float32[2 2 2; 3 3 3;;; 4 4 4; 5 5 5;;; 6 6 6; 7 7 7;;; 8 8 8; 9 9 9]),
       (3.0f0, 3.0f0, 3.0f0,
        Float32[3 3 3; 4 4 4;;; 5 5 5; 6 6 6;;; 7 7 7; 8 8 8;;; 9 9 9; 10 10 10])]
    cards = [Card("SIMPLE", true),
        Card("BITPIX", -32),
        Card("NAXIS", 4),
        Card("NAXIS1", 0),
        Card("NAXIS2", 2),
        Card("NAXIS3", 3),
        Card("NAXIS4", 4),
        Card("GROUPS", true),
        Card("PCOUNT", 3),
        Card("GCOUNT", 3),
        Card("PTYPE1", "PARAM1"),
        Card("PZERO1", 1.0),
        Card("PSCAL1", 0.1),
        Card("PTYPE2", "PARAM2"),
        Card("PZERO2", 1.0),
        Card("PSCAL2", 0.1),
        Card("PTYPE3", "PARAM3"),
        Card("PZERO3", 1.0),
        Card("PSCAL3", 0.1)]
    seek(io, 0)
    write(io, HDU(Random, data, cards))
    seek(io, 0)
    hdu = read(io, HDU; scale=false)

    @test isequal(showfields.(hdu.cards),
                  [("SIMPLE", true, "",
                    "SIMPLE  =                    T                                                  "),
                   ("BITPIX", -32, "",
                    "BITPIX  =                  -32                                                  "),
                   ("NAXIS", 4, "",
                    "NAXIS   =                    4                                                  "),
                   ("NAXIS1", 0, "",
                    "NAXIS1  =                    0                                                  "),
                   ("NAXIS2", 2, "",
                    "NAXIS2  =                    2                                                  "),
                   ("NAXIS3", 3, "",
                    "NAXIS3  =                    3                                                  "),
                   ("NAXIS4", 4, "",
                    "NAXIS4  =                    4                                                  "),
                   ("GROUPS", true, "",
                    "GROUPS  =                    T                                                  "),
                   ("PCOUNT", 3, "",
                    "PCOUNT  =                    3                                                  "),
                   ("GCOUNT", 3, "",
                    "GCOUNT  =                    3                                                  "),
                   ("PTYPE1", "PARAM1", "",
                    "PTYPE1  = 'PARAM1'                                                              "),
                   ("PTYPE2", "PARAM2", "",
                    "PTYPE2  = 'PARAM2'                                                              "),
                   ("PTYPE3", "PARAM3", "",
                    "PTYPE3  = 'PARAM3'                                                              "),
                   ("PZERO1", 1.0f0, "",
                    "PZERO1  =                  1.0                                                  "),
                   ("PSCAL1",  0.1f0, "",
                    "PSCAL1  =                  0.1                                                  "),
                   ("PZERO2", 1.0f0, "",
                    "PZERO2  =                  1.0                                                  "),
                   ("PSCAL2",  0.1f0, "",
                    "PSCAL2  =                  0.1                                                  "),
                   ("PZERO3", 1.0f0, "",
                    "PZERO3  =                  1.0                                                  "),
                   ("PSCAL3",  0.1f0, "",
                    "PSCAL3  =                  0.1                                                  ")])

    @test (length(data[1]) == 4 && ndims(hdu.data[:data]) == 4 &&
           size(hdu.data[:data]) == (3, 2, 3, 4) && eltype(hdu.data[:data]) == Float32 &&
           all(hdu.data[:PARAM1] .== [1f0, 2f0, 3f0]))

    #  test Random type with data being array of records, record == false, and lazy array
    data = [
       (par1=1.0f0, par2=1.0f0, par3=1.0f0,
        data=Float32[1 1 1; 2 2 2;;; 3 3 3; 4 4 4;;; 5 5 5; 6 6 6;;; 7 7 7; 8 8 8]),
       (par1=2.0f0, par2=2.0f0, par3=2.0f0,
        data=Float32[2 2 2; 3 3 3;;; 4 4 4; 5 5 5;;; 6 6 6; 7 7 7;;; 8 8 8; 9 9 9]),
       (par1=3.0f0, par2=3.0f0, par3=3.0f0,
        data=Float32[3 3 3; 4 4 4;;; 5 5 5; 6 6 6;;; 7 7 7; 8 8 8;;; 9 9 9; 10 10 10])]
    temppath = joinpath(tempdir(), "random_hdu.fits")
    fileio = open(temppath, "w+")
    write(fileio, HDU(Random, data))
    close(fileio)
    fileio = open(temppath)
    hdu = read(fileio, HDU; type=Random, record=false)
    close(fileio)

    @test isequal(showfields.(hdu.cards),
                  [("SIMPLE", true, "",
                    "SIMPLE  =                    T                                                  "),
                   ("BITPIX", -32, "",
                    "BITPIX  =                  -32                                                  "),
                   ("NAXIS", 4, "",
                    "NAXIS   =                    4                                                  "),
                   ("NAXIS1", 0, "",
                    "NAXIS1  =                    0                                                  "),
                   ("NAXIS2", 2, "",
                    "NAXIS2  =                    2                                                  "),
                   ("NAXIS3", 3, "",
                    "NAXIS3  =                    3                                                  "),
                   ("NAXIS4", 4, "",
                    "NAXIS4  =                    4                                                  "),
                   ("GROUPS", true, "",
                    "GROUPS  =                    T                                                  "),
                   ("PCOUNT", 3, "",
                    "PCOUNT  =                    3                                                  "),
                   ("GCOUNT", 3, "",
                    "GCOUNT  =                    3                                                  "),
                   ("PTYPE1", "par1", "",
                    "PTYPE1  = 'par1'                                                                "),
                   ("PTYPE2", "par2", "",
                    "PTYPE2  = 'par2'                                                                "),
                   ("PTYPE3", "par3", "",
                    "PTYPE3  = 'par3'                                                                ")])

    @test (length(hdu.data) == 4 && ndims(hdu.data[:data]) == 4 &&
           size(hdu.data[:data]) == (3, 2, 3, 4) && eltype(hdu.data[:data]) == Float32)

    rm(temppath)

    #  test Random type with data being array of records, record = true, and lazy array
    data = [
       (par1=1.0f0, par2=1.0f0, par3=1.0f0,
        data=Float32[1 1 1; 2 2 2;;; 3 3 3; 4 4 4;;; 5 5 5; 6 6 6;;; 7 7 7; 8 8 8]),
       (par1=2.0f0, par2=2.0f0, par3=2.0f0,
        data=Float32[2 2 2; 3 3 3;;; 4 4 4; 5 5 5;;; 6 6 6; 7 7 7;;; 8 8 8; 9 9 9]),
       (par1=3.0f0, par2=3.0f0, par3=3.0f0,
        data=Float32[3 3 3; 4 4 4;;; 5 5 5; 6 6 6;;; 7 7 7; 8 8 8;;; 9 9 9; 10 10 10])]

    temppath = joinpath(tempdir(), "random_hdu.fits")
    fileio = open(temppath, "w+")
    write(fileio, HDU(Random, data))
    close(fileio)
    fileio = open(temppath)
    hdu = read(fileio, HDU; type=Random, record=true)
    close(fileio)

    @test isequal(showfields.(hdu.cards),
                  [("SIMPLE", true, "",
                    "SIMPLE  =                    T                                                  "),
                   ("BITPIX", -32, "",
                    "BITPIX  =                  -32                                                  "),
                   ("NAXIS", 4, "",
                    "NAXIS   =                    4                                                  "),
                   ("NAXIS1", 0, "",
                    "NAXIS1  =                    0                                                  "),
                   ("NAXIS2", 2, "",
                    "NAXIS2  =                    2                                                  "),
                   ("NAXIS3", 3, "",
                    "NAXIS3  =                    3                                                  "),
                   ("NAXIS4", 4, "",
                    "NAXIS4  =                    4                                                  "),
                   ("GROUPS", true, "",
                    "GROUPS  =                    T                                                  "),
                   ("PCOUNT", 3, "",
                    "PCOUNT  =                    3                                                  "),
                   ("GCOUNT", 3, "",
                    "GCOUNT  =                    3                                                  "),
                   ("PTYPE1", "par1", "",
                    "PTYPE1  = 'par1'                                                                "),
                   ("PTYPE2", "par2", "",
                    "PTYPE2  = 'par2'                                                                "),
                   ("PTYPE3", "par3", "",
                    "PTYPE3  = 'par3'                                                                ")])

    @test ((length(data[1])-1) == 3 && ndims(hdu.data[1][:data]) == 3 &&
           size(hdu.data[1][:data]) == (2, 3, 4) && eltype(hdu.data[1][:data]) == Float32)

    rm(temppath)

    @testset "Random groups" begin

        ####    The files of random groups (Sect. 6)

        kw(key, value) = rpad(key, 8) * "= " * lpad(value, 20)
        #  The bytes of a header, which has the cards and END, and of the data, which have the fill of the last block
        function filebytes(cards, data = UInt8[]; pad = true)
            header = rpad(join(rpad.([cards; "END"], 80)), 2880 * cld(80 * (length(cards) + 1), 2880))
            fill = pad && !isempty(data) ? zeros(UInt8, cld(length(data), 2880) * 2880 - length(data)) : UInt8[]
            [collect(codeunits(header)); data; fill]
        end
        bytesof(values) = collect(reinterpret(UInt8, hton.(values)))
        #  The header of random groups of NAXIS1 = 0, the axes `axes`, `pcount` parameters, and `gcount` groups
        function grouphdr(; bitpix = 16, axes = [3], pcount = 2, gcount = 2, extra = String[], drop = String[])
            cards = vcat([kw("SIMPLE", "T"), kw("BITPIX", bitpix), kw("NAXIS", length(axes) + 1), kw("NAXIS1", 0)],
                [kw("NAXIS$(j+1)", n) for (j, n) in enumerate(axes)],
                [kw("GROUPS", "T"), kw("PCOUNT", pcount), kw("GCOUNT", gcount)], extra)
            filter(c -> !(strip(c[1:8]) in drop), cards)
        end
        reading(bytes; kwds...) = read(IOBuffer(bytes), HDU; kwds...)
        written(hdu; kwds...) = (io = IOBuffer(); write(io, hdu; kwds...); take!(io))
        #  two groups of two parameters and an array of three values: (1, 2, 10, 11, 12) and (3, 4, 20, 21, 22)
        stored = Int16[1, 2, 10, 11, 12, 3, 4, 20, 21, 22]
        groups = filebytes(grouphdr(), bytesof(stored))

        ####    The values are the physical values, and are written as the stored values (Eqs. 3 and 5)

        hdu = reading(groups)
        @test hdu isa HDU{Random}
        @test hdu.data == (param1 = Float32[1, 3], param2 = Float32[2, 4], data = Float32[10 11 12; 20 21 22])
        @test reading(groups; scale = false).data ==
            (param1 = Int16[1, 3], param2 = Int16[2, 4], data = Int16[10 11 12; 20 21 22])
        #  a file that is read is written with the same bytes, with and without the scale, and as records
        for kwds in ((;), (; scale = false), (; record = true), (; record = true, scale = false))
            @test written(reading(groups; kwds...)) == groups
        end

        scales = [kw("PSCAL1", "2.0"), kw("PZERO1", "100.0"), kw("PSCAL2", "0.5"), kw("BSCALE", "0.5"), kw("BZERO", "1.0")]
        scaledbytes = filebytes(grouphdr(extra = scales), bytesof(stored))
        scaledhdu = reading(scaledbytes)
        @test scaledhdu.data == (param1 = Float32[102, 106], param2 = Float32[1, 2],
            data = Float32[6 6.5 7; 11 11.5 12])
        for kwds in ((;), (; scale = false), (; record = true), (; record = true, scale = false))
            @test written(reading(scaledbytes; kwds...)) == scaledbytes
        end
        #  the header is as it was read
        @test getfield(scaledhdu, :cards) == getfield(reading(scaledbytes; scale = false), :cards)

        #  a value that is changed is written as its stored value
        scaledhdu.data.data[2, 3] = 7
        scaledhdu.data.param1[1] = 104
        changed = reading(written(scaledhdu); scale = false).data
        @test changed.data == Int16[10 11 12; 20 21 12] && changed.param1 == Int16[2, 3]
        #  a value that is not a stored value is an error, which names the parameter or the array and the group
        scaledhdu.data.param2[2] = 1.3
        @test_throws ArgumentError("The parameter param2 of group 2: The value 1.3 cannot be stored as Int16 data with " *
            "PSCAL2 0.5 and PZERO2 0.0: the nearest stored value, 3, is the value 1.5. Use check = false to write the " *
            "stored value.") written(scaledhdu)
        @test reading(written(scaledhdu; check = false); scale = false).data.param2 == Int16[2, 3]
        scaledhdu.data.param2[2] = 2
        scaledhdu.data.data[1, 1] = 5.3
        @test_throws ArgumentError written(scaledhdu)
        @test occursin("array data of group 1", sprint(showerror, try written(scaledhdu) catch e e end))
        #  a value that is not in the range of the type, and NaN, which has no BLANK in random groups, are errors
        scaledhdu.data.data[1, 1] = 6
        scaledhdu.data.param1[2] = 1e9
        @test_throws ArgumentError written(scaledhdu)
        scaledhdu.data.param1[2] = NaN
        @test_throws ArgumentError written(scaledhdu)
        @test_throws ArgumentError written(scaledhdu; check = false)
        #  a PSCALn of 0 cannot be inverted
        zero_ = reading(filebytes(grouphdr(extra = [kw("PSCAL2", "0.0")]), bytesof(stored)))
        @test_throws ArgumentError("The parameter param2 of group 1 cannot be written as a stored value, since its " *
            "PSCAL2 is 0.") written(zero_)
        @test written(reading(filebytes(grouphdr(extra = [kw("PSCAL2", "0.0")]), bytesof(stored)); scale = false)) ==
            filebytes(grouphdr(extra = [kw("PSCAL2", "0.0")]), bytesof(stored))

        #  the stored values of the other types: bytes, and 32- and 64-bit integers, and floating-point values
        for (bitpix, type) in ((8, UInt8), (16, Int16), (32, Int32), (64, Int64), (-32, Float32), (-64, Float64))
            values = type.([1, 2, 10, 11, 12, 3, 4, 20, 21, 22])
            bytes = filebytes(grouphdr(; bitpix), bytesof(values))
            for kwds in ((;), (; scale = false), (; record = true))
                @test written(reading(bytes; kwds...)) == bytes
            end
            @test eltype(reading(bytes; scale = false).data.data) == type
        end
        #  the floating-point values are written as they are, with NaN, whose stored value is NaN
        floats = filebytes(grouphdr(bitpix = -32), bytesof(Float32[1, NaN, 10, 11, 12, 3, 4, 20, Inf, 22]))
        @test written(reading(floats)) == floats

        ####    The array has the last name, and the names of the parameters are the keys of the data

        #  a parameter that is named data does not hide the array, and is named param<n>, with a warning that explains it
        dataname = filebytes(grouphdr(extra = [kw("PTYPE1", "'data'")]), bytesof(stored))
        renamed = r"PTYPE1 of the random groups is 'data', which is the name of the array of a group, so the parameter " *
            r"is named param1. The header is not changed."
        named = @test_logs (:warn, renamed) reading(dataname)
        @test keys(named.data) == (:param1, :param2, :data) && named.data.param1 == Float32[1, 3]
        @test named.data.data == Float32[10 11 12; 20 21 22]
        @test_logs (:warn, renamed) @test written(named) == dataname
        @test keys((@test_logs (:warn, renamed) reading(dataname; record = true)).data[1]) == (:param1, :param2, :data)
        @test_logs (:warn, renamed) (:warn, renamed) @test written(reading(dataname; record = true)) == dataname
        #  the header keeps the name, and the rename is a name for the parameter
        @test getfield(named, :cards)["PTYPE1"] == "data"
        #  the number of the parameter is the number in the name, and a name that is taken is made unique
        third = filebytes(grouphdr(pcount = 3, extra = [kw("PTYPE3", "'data'")]), bytesof(Int16[1:3; 10:12; 4:6; 20:22]))
        @test keys((@test_logs (:warn, r"is named param3") reading(third)).data) == (:param1, :param2, :param3, :data)
        taken = filebytes(grouphdr(extra = [kw("PTYPE1", "'data'"), kw("PTYPE2", "'param1'")]), bytesof(stored))
        @test keys((@test_logs (:warn, r"is named param_1") reading(taken)).data) == (:param_1, :param1, :data)
        taken = filebytes(grouphdr(extra = [kw("PTYPE1", "'data'"), kw("PTYPE2", "'param_1'")]), bytesof(stored))
        @test keys((@test_logs (:warn, r"is named param1\.") reading(taken)).data) == (:param1, :param_1, :data)
        taken = filebytes(grouphdr(pcount = 3, extra = [kw("PTYPE1", "'data'"), kw("PTYPE2", "'param1'"),
            kw("PTYPE3", "'param_1'")]), bytesof(Int16[1:3; 10:12; 4:6; 20:22]))
        @test keys((@test_logs (:warn, r"is named param__1") reading(taken)).data) == (:param__1, :param1, :param_1, :data)
        @test_logs (:warn, r"param__1") (:warn, r"param__1") @test written(reading(taken)) == taken
        #  parameters that are named data are one parameter of the first number, which is the sum of them
        twice = filebytes(grouphdr(extra = [kw("PTYPE1", "'data'"), kw("PTYPE2", "'data'")]), bytesof(stored))
        twicehdu = @test_logs (:warn, r"PTYPE1 and PTYPE2 of the random groups are 'data'.*is named param1") reading(twice)
        @test keys(twicehdu.data) == (:param1, :data) && twicehdu.data.param1 == Float32[1 2; 3 4]
        @test_logs (:warn, r"param1") @test written(twicehdu) == twice
        #  a name that is not data does not warn, and the case of the name is its own
        @test_logs reading(filebytes(grouphdr(extra = [kw("PTYPE1", "'DATA'")]), bytesof(stored)))
        @test keys(reading(filebytes(grouphdr(extra = [kw("PTYPE1", "'DATA'")]), bytesof(stored))).data) ==
            (:DATA, :param2, :data)
        #  the data that are created have the names of the data, whatever the name of the array is
        for array in (:data, :b, :values)
            columns = NamedTuple{(:a, :c, array)}((Int16[1, 3], Int16[2, 4], Int16[10 11 12; 20 21 22]))
            created = HDU(Random, columns)
            #  the data are the data of the file, and the header has the PTYPEn keywords
            @test written(created)[2881:end] == groups[2881:end]
            again = reading(written(created); scale = false)
            @test again.data == (a = Int16[1, 3], c = Int16[2, 4], data = Int16[10 11 12; 20 21 22])
            @test written(again) == written(created)
            records = [NamedTuple{(:a, :c, array)}((Int16(1), Int16(2), Int16[10, 11, 12])),
                NamedTuple{(:a, :c, array)}((Int16(3), Int16(4), Int16[20, 21, 22]))]
            @test written(HDU(Random, records)) == written(created)
        end
        #  a parameter named data, and an array with another name, which is written by position
        created = HDU(Random, (data = Int16[1, 3], b = Int16[10 11 12; 20 21 22]))
        createdbytes = @test_logs (:warn, r"PTYPE1 of the random groups is 'data'") written(created)
        @test createdbytes[2881:end] == filebytes(grouphdr(pcount = 1), bytesof(Int16[1, 10, 11, 12, 3, 20, 21, 22]))[2881:end]
        again = @test_logs (:warn, r"is named param1") reading(createdbytes; scale = false)
        @test again.data == (param1 = Int16[1, 3], data = Int16[10 11 12; 20 21 22])
        @test_logs (:warn, r"is named param1") @test written(again) == createdbytes
        #  the data are written by position, so the names of the data need not be the names of the header
        mismatched = HDU(Random, (x = Int16[1, 3], y = Int16[2, 4], z = Int16[10 11 12; 20 21 22]),
            Card{<:Any}[Card("PTYPE1", "A"), Card("PTYPE2", "B")])
        @test written(mismatched)[2881:end] == groups[2881:end]
        @test keys(reading(written(mismatched)).data) == (:A, :B, :data)
        @test written(HDU(Random, [(x = Int16(1), y = Int16(2), z = Int16[10, 11, 12]),
            (x = Int16(3), y = Int16(4), z = Int16[20, 21, 22])], Card{<:Any}[Card("PTYPE1", "A"), Card("PTYPE2", "B")]))[
            2881:end] == groups[2881:end]
        #  data of a tuple are named param1, param2, ... and data
        @test reading(written(HDU(Random, (Int16[1, 3], Int16[10 11 12; 20 21 22]))); scale = false).data ==
            (param1 = Int16[1, 3], data = Int16[10 11 12; 20 21 22])
    end

end

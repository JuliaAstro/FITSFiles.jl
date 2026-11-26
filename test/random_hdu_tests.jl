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
        #  an absent PTYPEn has the name param<n>, which is a warning if it is the name of another parameter
        clash = filebytes(grouphdr(extra = [kw("PTYPE1", "'param2'")]), bytesof(stored))
        clashed = @test_logs (:warn, r"PTYPE2 is absent, so the parameter is named param2, which is also the name of " *
            r"PTYPE1\. The parameters of the same name are one parameter, which is the sum of them \(Sect. 6.1.2\)") reading(clash)
        @test keys(clashed.data) == (:param2, :data) && clashed.data.param2 == Float32[1 2; 3 4]
        @test_logs (:warn, r"PTYPE2 is absent") @test written(clashed) == clash
        @test_logs reading(filebytes(grouphdr(extra = [kw("PTYPE1", "'param1'")]), bytesof(stored)))
        @test_logs (:warn, r"PTYPE1 is absent, so the parameter is named param1, which is also the name of PTYPE2") reading(
            filebytes(grouphdr(extra = [kw("PTYPE2", "'param1'")]), bytesof(stored)))
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
        #  data without parameters have the groups of the first axis, and not the length of the array
        noparam = HDU(Random, (b = Int16[10 11 12; 20 21 22],))
        @test noparam.cards["PCOUNT"] == 0 && noparam.cards["GCOUNT"] == 2 && noparam.cards["NAXIS2"] == 3
        @test reading(written(noparam); scale = false).data == (data = Int16[10 11 12; 20 21 22],)
        @test reading(written(HDU(Random, [(b = Int16[10 11 12],), (b = Int16[20 21 22],)])); scale = false).data.data ==
            reshape(Int16[10 11 12; 20 21 22], (2, 1, 3))
        #  the data that are created from the header have the shape of the groups, whatever the number of axes is
        for axes in ([3], [3, 2], [1], Int[])
            hdr = reading(filebytes(grouphdr(; axes, extra = String[]), bytesof(zeros(Int16, 2 * (2 + prod(axes))))))
            created = HDU(Random, missing, getfield(hdr, :cards))
            @test size(created.data.data) == (2, axes...) && size(created.data.param1) == (2,)
            @test size(HDU(Random, missing, getfield(hdr, :cards); record = true).data[1].data) == (axes...,)
        end

        ####    Parameters that have the same name are summed (Sect. 6.1.2)

        dates = [kw("PTYPE1", "'DATE'"), kw("PTYPE2", "'DATE'"), kw("PSCAL2", "0.5")]
        datebytes = filebytes(grouphdr(extra = dates), bytesof(stored))
        dated = reading(datebytes)
        @test keys(dated.data) == (:DATE, :data) && dated.data.DATE == Float32[1 1; 3 2]
        @test vec(sum(dated.data.DATE; dims = 2)) == Float32[2, 5]
        @test written(dated) == datebytes && written(reading(datebytes; record = true)) == datebytes
        @test reading(datebytes; record = true).data[2].DATE == Float32[3 2]
        @test reading(datebytes; scale = false).data.DATE == Int16[1 2; 3 4]

        ####    The parameters and the array have one type (Sect. 6.3)

        mixed = r"the parameters and the array of random groups have the same type, which is BITPIX \(Sect. 6.3\)"
        @test_throws mixed HDU(Random, (a = Float64[1, 2], data = Float32[1 2 3; 4 5 6]))
        @test_throws mixed HDU(Random, (a = Int32[1, 2], data = Int16[1 2 3; 4 5 6]))
        @test_throws mixed HDU(Random, [(a = 1.0, b = Float32[1 2 3]), (a = 2.0, b = Float32[4 5 6])])
        @test_throws mixed HDU(Random, [(a = Int16(1), b = Int16[1 2 3]), (a = 2.0, b = Int16[4 5 6])])
        @test_throws ArgumentError("The parameter a has the type Float64, but the array data has the type Float32: " *
            "the parameters and the array of random groups have the same type, which is BITPIX (Sect. 6.3). " *
            "Convert them to one type.") HDU(Random, (a = Float64[1, 2], data = Float32[1 2 3; 4 5 6]))
        #  a type that BITPIX does not have is an error
        @test_throws ArgumentError HDU(Random, (a = Float16[1, 2], data = Float16[1 2 3; 4 5 6]))
        #  the parameters have a value for each group, and the groups of records have the same size
        @test_throws ArgumentError("The parameter a must have a value for each of the 2 groups of the array data.") HDU(
            Random, (a = Int16[1, 2, 3], data = Int16[1 2 3; 4 5 6]))
        @test_throws ArgumentError HDU(Random, (a = Int16(1), data = Int16[1 2 3; 4 5 6]))
        @test_throws ArgumentError HDU(Random, (a = Int16[1, 2], data = Int16(5)))
        @test_throws ArgumentError("The array of group 2 has the size (2,), but that of group 1 has the size (3,).") HDU(
            Random, [(a = Int16(1), b = Int16[1, 2, 3]), (a = Int16(2), b = Int16[4, 5])])
        @test_throws ArgumentError("Group 2 has 3 values, but group 1 has 2: the parameters and the array of each " *
            "group are the same.") HDU(Random, [(a = Int16(1), b = Int16[1, 2, 3]),
            (a = Int16(2), c = Int16(3), b = Int16[4, 5, 6])])
        #  missing values are not of another type
        @test HDU(Random, (a = Union{Int16, Missing}[1, 2], data = Int16[1 2 3; 4 5 6])) isa HDU{Random}

        ####    The size of the data (Eq. 4)

        #  a file that has fewer bytes than the header says is an error, and an unpadded last block is not
        short = filebytes(grouphdr(), bytesof(stored)[1:14])
        @test_throws ArgumentError("The data of the HDU is 20 bytes, as its header says, but the file has only 14 of " *
            "them.") reading(short[1:2880+14])
        @test reading(filebytes(grouphdr(), bytesof(stored); pad = false)).data.data == Float32[10 11 12; 20 21 22]
        mktemp() do path, io
            write(io, groups[1:2880+14]); close(io)
            #  the data of a file are read when they are used
            @test_throws ArgumentError("The data of the HDU is 20 bytes, as its header says, but the file has only 14 " *
                "of them.") fits(path)[1].data
        end
        #  a size that is more than the largest integer is an error, and the data are not read
        toolarge = r"The random groups are too large: 2 bytes × 2 groups × \(2 parameters \+ 1099511627776 × " *
            r"1099511627776 values\) is more than 9223372036854775807 bytes."
        @test_throws toolarge reading(filebytes(grouphdr(axes = [2^40, 2^40])))
        @test_throws ArgumentError reading(filebytes(grouphdr(gcount = 2^62)))
        @test_throws ArgumentError reading(filebytes(grouphdr(pcount = 2^62, gcount = 2^62)))
        @test_throws ArgumentError reading(filebytes(grouphdr(bitpix = -64, gcount = 2^61, axes = [4])))
        #  the size that is allowed is read
        @test reading(filebytes(grouphdr(gcount = 0))).data === missing
        #  an array without elements has the parameters of the groups
        empty = reading(filebytes(grouphdr(axes = [0], gcount = 3), bytesof(Int16[1, 2, 3, 4, 5, 6]))).data
        @test size(empty.data) == (3, 0) && empty.param1 == Float32[1, 3, 5] && empty.param2 == Float32[2, 4, 6]

        ####    The mandatory keywords that give the size of the data (Sect. 6.1.1 and Table 12)

        for key in ("BITPIX", "NAXIS", "PCOUNT", "GCOUNT")
            @test_throws ArgumentError("$key is missing, but it is a mandatory keyword of random groups (Sect. 6.1.1, " *
                "Table 12).") reading(filebytes(grouphdr(drop = [key]), bytesof(stored)))
        end
        #  the header of an HDU that is created has the keywords
        @test HDU(Random, missing, Card{<:Any}[Card("GROUPS", true)]).cards["GCOUNT"] == 0
        #  random groups without a group are a header
        @test length(written(HDU(Random))) == 2880 && length(written(HDU(Random); checksum = true)) == 2880

        ####    The unsigned integers and the signed bytes of Table 11 (Sects. 5.2.5 and 6.3)

        #  the array has the offset BZERO, and each parameter has the offset PZEROn, so the physical values are the
        #  unsigned integers
        offsets = [kw("PZERO1", "32768"), kw("PZERO2", "32768"), kw("BZERO", "32768")]
        unsigned = Int16[-32768, 0, 10, 11, 12, 32767, 5, 20, 21, 22]
        offsetbytes = filebytes(grouphdr(extra = offsets), bytesof(unsigned))
        offsetdata = reading(offsetbytes).data
        @test offsetdata == (param1 = UInt16[0, 65535], param2 = UInt16[32768, 32773],
            data = UInt16[32778 32779 32780; 32788 32789 32790])
        @test eltype(offsetdata.param1) == UInt16 && eltype(offsetdata.param2) == UInt16 && eltype(offsetdata.data) == UInt16
        @test reading(offsetbytes; scale = false).data ==
            (param1 = Int16[-32768, 32767], param2 = Int16[0, 5], data = Int16[10 11 12; 20 21 22])
        records = reading(offsetbytes; record = true).data
        @test records[2] == (param1 = 0xffff, param2 = 0x8005, data = UInt16[32788, 32789, 32790])
        @test typeof(records[1].param1) == UInt16
        #  a file is written with the same bytes, with and without the scale, and as records
        for kwds in ((;), (; scale = false), (; record = true))
            @test written(reading(offsetbytes; kwds...)) == offsetbytes
        end
        #  a value that is changed is written as its stored value
        changed = reading(offsetbytes)
        changed.data.param1[1] = 100
        changed.data.data[2, 3] = 0
        @test reading(written(changed); scale = false).data ==
            (param1 = Int16[-32668, 32767], param2 = Int16[0, 5], data = Int16[10 11 12; 20 21 -32768])
        #  every type of Table 11 has its offset, and the parameters and the array are of the type of the offset
        for (bitpix, raw, physical_, offset) in ((8, UInt8, Int8, -128), (16, Int16, UInt16, 2^15),
            (32, Int32, UInt32, 2^31), (64, Int64, UInt64, UInt128(2)^63))
            values = raw.([1, 2, 10, 11, 12, 3, 4, 20, 21, 22])
            values[1] = typemin(raw)
            values[6] = typemax(raw)
            extras = [kw("PZERO1", offset), kw("PZERO2", offset), kw("BZERO", offset)]
            bytes = filebytes(grouphdr(; bitpix, extra = extras), bytesof(values))
            expected = [physical_(Int128(value) + offset) for value in values]
            offset32 = reading(bytes).data
            @test offset32 == (param1 = expected[[1, 6]], param2 = expected[[2, 7]],
                data = permutedims(reshape(expected[[3, 4, 5, 8, 9, 10]], (3, 2))))
            @test eltype(offset32.param1) == physical_ && eltype(offset32.data) == physical_
            for kwds in ((;), (; scale = false), (; record = true))
                @test written(reading(bytes; kwds...)) == bytes
            end
        end
        #  the parameters and the array have their own offsets: the other values are scaled
        arrayonly = filebytes(grouphdr(extra = [kw("BZERO", "32768")]), bytesof(unsigned))
        arraydata = reading(arrayonly).data
        @test eltype(arraydata.param1) == Float32 && eltype(arraydata.data) == UInt16
        @test arraydata.param1 == Float32[-32768, 32767] && written(reading(arrayonly)) == arrayonly
        paramonly = filebytes(grouphdr(extra = [kw("PZERO2", "32768")]), bytesof(unsigned))
        @test eltype(reading(paramonly).data.param1) == Float32 && eltype(reading(paramonly).data.param2) == UInt16
        @test eltype(reading(paramonly).data.data) == Float32 && written(reading(paramonly)) == paramonly
        #  an offset of another type, or a scale that is not 1, is a scaled value
        other = filebytes(grouphdr(bitpix = 32, extra = [kw("PZERO1", "32768"), kw("BZERO", "32768")]),
            bytesof(Int32.(unsigned)))
        @test eltype(reading(other).data.param1) == Float32 && eltype(reading(other).data.data) == Float32
        scaledoffset = filebytes(grouphdr(extra = [kw("PSCAL1", "2.0"), kw("PZERO1", "32768")]), bytesof(unsigned))
        @test reading(scaledoffset).data.param1 == Float32[-32768, 32767] .* 2 .+ 32768
        @test written(reading(scaledoffset)) == scaledoffset

        #  data of unsigned integers have the offsets in the header, which is a header that was made
        unsignedhdu = HDU(Random, (a = UInt16[0, 65535], c = UInt16[1, 2], data = UInt16[1 2 3; 4 5 6]))
        cards = getfield(unsignedhdu, :cards)
        @test cards["BITPIX"] == 16 && cards["BZERO"] == 32768 && cards["PZERO1"] == 32768 && cards["PZERO2"] == 32768
        @test count(c -> c.key in ("BZERO", "PZERO1", "PZERO2"), cards) == 3
        unsignedbytes = written(unsignedhdu)
        @test reading(unsignedbytes; scale = false).data ==
            (a = Int16[-32768, 32767], c = Int16[-32767, -32766], data = Int16[-32767 -32766 -32765; -32764 -32763 -32762])
        @test reading(unsignedbytes).data == (a = UInt16[0, 65535], c = UInt16[1, 2], data = UInt16[1 2 3; 4 5 6])
        @test written(reading(unsignedbytes)) == unsignedbytes
        #  the same data as records, and as a tuple
        @test written(HDU(Random, [(a = UInt16(0), c = UInt16(1), data = UInt16[1, 2, 3]),
            (a = UInt16(65535), c = UInt16(2), data = UInt16[4, 5, 6])])) == unsignedbytes
        @test written(HDU(Random, (UInt16[0, 65535], UInt16[1 2 3; 4 5 6])))[2881:end] ==
            written(HDU(Random, (a = UInt16[0, 65535], data = UInt16[1 2 3; 4 5 6])))[2881:end]
        #  the cards that the header has are not added again
        withcards = HDU(Random, (a = UInt16[0, 65535], data = UInt16[1 2 3; 4 5 6]),
            Card{<:Any}[Card("BZERO", 32768), Card("PZERO1", 32768)])
        @test count(c -> c.key in ("BZERO", "PZERO1"), getfield(withcards, :cards)) == 2
        #  the parameters and the array are of one type, which may be unsigned
        @test_throws mixed HDU(Random, (a = Int16[0, 1], data = UInt16[1 2 3; 4 5 6]))
        @test_throws mixed HDU(Random, (a = UInt16[0, 1], data = Int16[1 2 3; 4 5 6]))
        @test_throws ArgumentError HDU(Random, (a = UInt16[0, 1], data = Int32[1 2 3; 4 5 6]))
        #  the unsigned data of a file are read lazily
        mktemp() do path, io
            write(io, [unsignedhdu]); close(io)
            @test fits(path)[1].data == (a = UInt16[0, 65535], c = UInt16[1, 2], data = UInt16[1 2 3; 4 5 6])
            @test eltype(fits(path; scale = false)[1].data.a) == Int16
        end

        ####    The undefined values of the array (Sect. 4.4.2.5)

        #  the elements of the array that are the stored value of BLANK are missing, and the parameters are not
        blankvalues = Int16[1, 2, 10, -32768, 12, -32768, 4, 20, 21, 22]
        blankbytes = filebytes(grouphdr(extra = [kw("BLANK", "-32768")]), bytesof(blankvalues))
        blanked = reading(blankbytes).data
        @test isequal(blanked.data, Union{Float32, Missing}[10 missing 12; 20 21 22])
        @test blanked.param1 == Float32[1, -32768] && eltype(blanked.param1) == Float32
        @test isequal(reading(blankbytes; scale = false).data.data, Union{Int16, Missing}[10 missing 12; 20 21 22])
        @test reading(blankbytes; scale = false).data.param1 == Int16[1, -32768]
        blankrecords = reading(blankbytes; record = true).data
        @test isequal(blankrecords[1].data, Union{Float32, Missing}[10, missing, 12]) && blankrecords[1].param1 == 1
        @test isequal(blankrecords[2].data, Float32[20, 21, 22]) && blankrecords[2].param1 == -32768
        #  a file with undefined values is written with the same bytes
        for kwds in ((;), (; scale = false), (; record = true))
            @test written(reading(blankbytes; kwds...)) == blankbytes
        end
        #  BLANK is a stored value, so it is the value before BZERO and BSCALE are applied
        scaledblank = filebytes(grouphdr(extra = [kw("BLANK", "-32768"), kw("BSCALE", "2.0"), kw("BZERO", "1.0")]),
            bytesof(blankvalues))
        @test isequal(reading(scaledblank).data.data, Union{Float32, Missing}[21 missing 25; 41 43 45])
        @test written(reading(scaledblank)) == scaledblank
        offsetblank = filebytes(grouphdr(extra = [kw("BLANK", "-32768"), kw("PZERO1", "32768"), kw("BZERO", "32768")]),
            bytesof(blankvalues))
        offsetblanked = reading(offsetblank).data
        @test isequal(offsetblanked.data, Union{UInt16, Missing}[32778 missing 32780; 32788 32789 32790])
        @test offsetblanked.param1 == UInt16[1 + 32768, 0] && eltype(offsetblanked.param1) == UInt16
        @test written(reading(offsetblank)) == offsetblank
        #  without BLANK the values are values
        @test reading(filebytes(grouphdr(), bytesof(blankvalues))).data.data == Float32[10 -32768 12; 20 21 22]
        #  the types of the integers that have a BLANK: bytes, and 16-, 32-, and 64-bit integers
        for (bitpix, type) in ((8, UInt8), (16, Int16), (32, Int32), (64, Int64))
            values = type.([1, 2, 10, 11, 12, 3, 4, 20, 21, 22])
            values[4] = typemin(type)
            bytes = filebytes(grouphdr(; bitpix, extra = [kw("BLANK", typemin(type))]), bytesof(values))
            @test isequal(reading(bytes; scale = false).data.data, Union{type, Missing}[10 missing 12; 20 21 22])
            @test written(reading(bytes)) == bytes
        end
        #  a value that is changed to missing, or to NaN, is written as BLANK
        undefined = reading(blankbytes)
        undefined.data.data[1, 1] = missing
        undefined.data.data[2, 3] = NaN
        @test isequal(reading(written(undefined); scale = false).data.data,
            Union{Int16, Missing}[missing missing 12; 20 21 missing])
        @test reading(written(undefined); scale = false).data.param1 == Int16[1, -32768]
        #  missing or NaN is an error if there is no BLANK, which is the value that stands for it
        noblank = reading(filebytes(grouphdr(), bytesof(blankvalues)))
        noblank.data.data[1, 1] = NaN
        @test_throws ArgumentError written(noblank)
        @test_throws ArgumentError("The array data of group 1: NaN cannot be written as integer data that does not " *
            "have a BLANK keyword.") written(noblank)
        @test_throws ArgumentError written(HDU(Random, (a = Int16[1, 2], data = Union{Int16, Missing}[1 missing 3; 4 5 6])))
        #  data that are created have BLANK if the header has it, and then the undefined values are BLANK
        madeblank = HDU(Random, (a = Int16[1, 2], data = Union{Int16, Missing}[1 missing 3; 4 5 6]),
            Card{<:Any}[Card("BLANK", -32768)])
        madeagain = reading(written(madeblank); scale = false)
        @test isequal(madeagain.data.data, Union{Int16, Missing}[1 missing 3; 4 5 6]) && madeagain.data.a == Int16[1, 2]
        @test written(madeagain) == written(madeblank)
        #  the undefined values of floating-point data are NaN, and BLANK is not used
        floatdata = HDU(Random, (a = Float32[1, 2], data = Union{Float32, Missing}[1 missing 3; 4 5 6]))
        floatagain = reading(written(floatdata)).data
        @test isnan(floatagain.data[1, 2]) && floatagain.data[2, 3] == 6 && eltype(floatagain.data) == Float32
        @test_logs (:warn, r"BLANK is for integer data \(a positive BITPIX\) only \(Sect. 4.4.2.5\), so it is not used") reading(
            filebytes(grouphdr(bitpix = -32, extra = [kw("BLANK", "5")]), bytesof(Float32.(1:10))))
        #  BLANK is an integer
        @test_throws ArgumentError("BLANK must be an integer, but its value is 2.5f0.") reading(
            filebytes(grouphdr(extra = [kw("BLANK", "2.5")]), bytesof(blankvalues)))
        #  the undefined values of a file are read lazily
        mktemp() do path, io
            write(io, blankbytes); close(io)
            @test isequal(fits(path)[1].data.data, Union{Float32, Missing}[10 missing 12; 20 21 22])
            @test isequal(fits(path; scale = false)[1].data.data, Union{Int16, Missing}[10 missing 12; 20 21 22])
        end

        ####    The keywords of the array (Sect. 4.4.2.5) and of the primary header (Sects. 4.4.2.1 and 4.4.2.6)

        withkeys(extra...) = filebytes(grouphdr(extra = collect(extra)), bytesof(stored))
        #  the scale, zero, and limits of the array are numbers, since the array cannot be read without them
        for key in ("BSCALE", "BZERO", "DATAMIN", "DATAMAX"), value in ("'two'", "T")
            @test_throws ArgumentError reading(withkeys(kw(key, value)))
        end
        @test_throws ArgumentError("BSCALE must be a number, but its value is \"two\".") reading(withkeys(kw("BSCALE", "'two'")))
        @test_throws ArgumentError("DATAMAX must be a number, but its value is true.") reading(withkeys(kw("DATAMAX", "T")))
        #  and DATAMIN and DATAMAX are floating-point numbers, which an integer is read as
        for key in ("DATAMIN", "DATAMAX")
            @test_logs (:warn, "$key must be a floating-point number, but its value is the integer 3. It is read as it is.") reading(
                withkeys(kw(key, "3")))
        end
        #  the units of the array are a units string
        @test_logs (:warn, "BUNIT must be a character string, but its value is 3. It is read as it is.") reading(
            withkeys(kw("BUNIT", "3")))
        @test_logs (:warn, "BUNIT must be a units string (Sect. 4.3), but its value is \"furlongs/fortnight^x\". It is " *
            "read as it is.") reading(withkeys(kw("BUNIT", "'furlongs/fortnight^x'")))
        @test_logs reading(withkeys(kw("DATAMIN", "0.5"), kw("DATAMAX", "1.5E2"), kw("BSCALE", "2.0"), kw("BZERO", "1"),
            kw("BUNIT", "'m/s'")))
        #  the values of the array keywords are read as they were
        keyed = reading(withkeys(kw("BSCALE", "2.0"), kw("BZERO", "1"), kw("DATAMIN", "3"))).data.data
        @test keyed == Float32[21 23 25; 41 43 45]
        #  EXTEND and BLOCKED are logicals, and INHERIT is not in a primary header
        for key in ("EXTEND", "BLOCKED")
            @test_logs (:warn, "$key must be a logical, T or F, but its value is 3. It is read as it is.") reading(
                withkeys(kw(key, "3")))
            @test_logs reading(withkeys(kw(key, "T")))
        end
        @test_logs (:warn, "INHERIT must not appear in the primary header (Appendix K). It is read as it is.") reading(
            withkeys(kw("INHERIT", "T")))
        #  the keywords that the HDUs have in common are verified, as they are for the other HDUs
        @test_logs (:warn, "ORIGIN must be a character string, but its value is 3. It is read as it is.") reading(
            withkeys(kw("ORIGIN", "3")))
        @test_logs (:warn, r"DATE must be a date of the form YYYY-MM-DD") reading(withkeys(kw("DATE", "'yesterday'")))
        @test_logs reading(withkeys(kw("DATE", "'2026-11-26'"), kw("OBJECT", "'NGC 1275'")))

        ####    The keywords of the parameters (Sect. 6.1.2)

        #  the name of a parameter is a character string, and the scale and zero are numbers, since the parameters cannot
        #  be read otherwise
        @test_throws ArgumentError("PTYPE1 must be a character string, but its value is 3.") reading(
            withkeys(kw("PTYPE1", "3")))
        @test_throws ArgumentError("PTYPE2 must be a character string, but its value is true.") reading(
            withkeys(kw("PTYPE2", "T")))
        for key in ("PSCAL1", "PZERO1", "PSCAL2", "PZERO2")
            @test_throws ArgumentError("$key must be a number, but its value is \"x\".") reading(withkeys(kw(key, "'x'")))
            @test_throws ArgumentError("$key must be a number, but its value is true.") reading(withkeys(kw(key, "T")))
        end
        #  and the values are read as they were: an integer is a number
        parameters = reading(withkeys(kw("PTYPE1", "'UU'"), kw("PSCAL1", "2.0"), kw("PZERO1", "100"), kw("PSCAL2", "3")))
        @test parameters.data == (UU = Float32[102, 106], param2 = Float32[6, 12], data = Float32[10 11 12; 20 21 22])
        @test_logs reading(withkeys(kw("PTYPE1", "'UU'"), kw("PSCAL1", "2.0"), kw("PZERO1", "100"), kw("PSCAL2", "3")))
        #  a keyword of a parameter that is not one, which is from 1 to PCOUNT, is not used, whatever its value is
        @test_logs (:warn, "PSCAL9 is beyond PCOUNT 2, and is not used.") (:warn, "PTYPE3 is beyond PCOUNT 2, and is " *
            "not used.") reading(withkeys(kw("PTYPE3", "'X'"), kw("PSCAL9", "2.0")))
        @test_logs (:warn, "PZERO4 is beyond PCOUNT 2, and is not used.") reading(withkeys(kw("PZERO4", "'x'")))
        @test_logs (:warn, "PTYPE0 is not the keyword of a parameter, which is numbered from 1, and is not used.") reading(
            withkeys(kw("PTYPE0", "'X'")))
        #  a PSCALn of 0 makes every physical value of the parameter its PZEROn, and the file is read as it is
        zeroscale = withkeys(kw("PSCAL2", "0.0"), kw("PZERO2", "5.0"))
        zerohdu = @test_logs (:warn, "PSCAL2 is 0, so every physical value of the parameter is its PZERO2, and its stored " *
            "values cannot be written from them. It is read as it is.") reading(zeroscale)
        @test zerohdu.data.param2 == Float32[5, 5]
        @test_logs (:warn, r"PSCAL2 is 0") (:warn, r"PSCAL2 is 0") @test written(reading(zeroscale; scale = false)) == zeroscale
        @test_logs reading(withkeys(kw("PSCAL2", "0.5"), kw("PZERO2", "0.0")))

        ####    The header of random groups: the order and the fixed format (Sects. 4.4.1 and 6.1.1, Table 12)

        firstcards = [kw("SIMPLE", "T"), kw("BITPIX", 16), kw("NAXIS", 2), kw("NAXIS1", 0), kw("NAXIS2", 3)]
        groupcards = [kw("GROUPS", "T"), kw("PCOUNT", 2), kw("GCOUNT", 2)]
        asfile(cards) = filebytes(cards, bytesof(stored))
        orderwarning(n, found, required) = "Keyword $n of the header is $found, but the Standard requires $required " *
            "(Sects. 4.4.1.1 and 6.1.1): SIMPLE, BITPIX, NAXIS, NAXIS1 of 0, and the NAXISn come first, in order, with no " *
            "other keyword between them. The cards are not reordered."
        #  the keywords of random groups are anywhere after the mandatory keywords, and so are the other keywords
        @test_logs reading(asfile([firstcards; groupcards]))
        @test_logs reading(asfile([firstcards; kw("OBJECT", "'x'"); groupcards[[3, 1, 2]]]))
        @test_logs reading(asfile([firstcards; groupcards[[2, 3]]; kw("OBJECT", "'x'"); groupcards[1]]))
        #  nothing is between them, and they are in order
        @test_logs (:warn, orderwarning(5, "GROUPS", "NAXIS2")) reading(
            asfile([firstcards[1:4]; groupcards[1]; firstcards[5]; groupcards[2:3]]))
        @test_logs (:warn, orderwarning(3, "OBJECT", "NAXIS")) reading(
            asfile([firstcards[1:2]; kw("OBJECT", "'x'"); firstcards[3:5]; groupcards]))
        @test_logs (:warn, orderwarning(2, "NAXIS", "BITPIX")) reading(asfile([firstcards[[1, 3, 2]]; firstcards[4:5]; groupcards]))
        @test_logs (:warn, orderwarning(1, "OBJECT", "SIMPLE")) reading(asfile([kw("OBJECT", "'x'"); firstcards; groupcards]))
        @test_logs (:warn, orderwarning(4, "NAXIS2", "NAXIS1")) reading(
            asfile([firstcards[1:3]; firstcards[5]; firstcards[4]; groupcards]))
        #  the cards are not reordered, so the file is written as it was read
        misordered = asfile([firstcards[1:4]; groupcards[1]; firstcards[5]; groupcards[2:3]])
        @test_logs (:warn, orderwarning(5, "GROUPS", "NAXIS2")) (:warn, orderwarning(5, "GROUPS", "NAXIS2")) @test written(
            reading(misordered)) == misordered
        #  the values of the mandatory keywords are in fixed format, and so are the keywords of random groups
        free = asfile([firstcards[1]; "BITPIX  = 16"; firstcards[3:5]; groupcards[1]; "PCOUNT  = 2"; groupcards[3]])
        freewarning = "The value of BITPIX, PCOUNT is not in fixed format (Sect. 4.4.1): a fixed-format value is " *
            "right-justified in bytes 11 to 30, and a string begins in byte 11. The cards are not changed."
        @test_logs (:warn, freewarning) reading(free)
        @test_logs (:warn, freewarning) (:warn, freewarning) @test written(reading(free)) == free
        @test_logs (:warn, r"The value of GROUPS is not in fixed format") reading(
            asfile([firstcards; "GROUPS  = T"; groupcards[2:3]]))
        #  a header that is being created is not verified, and is arranged when it is created
        @test_logs HDU(Random, missing, Card{<:Any}[Card("OBJECT", "x"), Card("GROUPS", true)])

        ####    SIMPLE of F is not random groups, and nor is GROUPS that is not T, unless the type is given (Sect. 6.1.1)

        simplef = asfile([kw("SIMPLE", "F"); firstcards[2:5]; groupcards])
        @test (@test_logs match_mode = :any (:warn, r"SIMPLE is F") reading(simplef)) isa HDU{Conform}
        typed = @test_logs (:warn, "Random HDU is nonconformant, since SIMPLE is F.") reading(simplef; type = Random)
        @test typed isa HDU{Random} && typed.data.data == Float32[10 11 12; 20 21 22]
        groupsf = asfile([firstcards; kw("GROUPS", "F"); groupcards[2:3]])
        @test (@test_logs match_mode = :any (:warn, r"read as a primary array") reading(groupsf)) isa HDU{Primary}
        typed = @test_logs (:warn, "GROUPS set to true") reading(groupsf; type = Random)
        @test typed isa HDU{Random} && getfield(typed, :cards)["GROUPS"] == true
        @test typed.data.data == Float32[10 11 12; 20 21 22]
        #  the header of data that are made from cards that have GROUPS of F has GROUPS of T
        madef = @test_logs (:warn, "GROUPS set to true") HDU(Random, (a = Int16[1, 3], b = Int16[2, 4],
            data = Int16[10 11 12; 20 21 22]), Card{<:Any}[Card("GROUPS", false)])
        @test getfield(madef, :cards)["GROUPS"] == true
        @test reading(written(madef); scale = false).data == (a = Int16[1, 3], b = Int16[2, 4], data = Int16[10 11 12; 20 21 22])

        ####    The lazy file of random groups reads the same

        mktemp() do path, io
            write(io, [HDU(Random, (a = Int16[1, 3], c = Int16[2, 4], data = Int16[10 11 12; 20 21 22]),
                Card{<:Any}[Card("PSCAL1", 2.0), Card("BZERO", 1.0)])]; check = false)
            close(io)
            file = fits(path)
            @test file[1].data == (a = Float32[2, 6], c = Float32[2, 4], data = Float32[11 12 13; 21 22 23])
            @test fits(path; scale = false)[1].data ==
                (a = Int16[1, 3], c = Int16[2, 4], data = Int16[10 11 12; 20 21 22])
            @test fits(path; record = true)[1].data[2] == (a = 6.0f0, c = 4.0f0, data = Float32[21, 22, 23])
        end
    end

end

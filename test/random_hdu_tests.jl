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

end

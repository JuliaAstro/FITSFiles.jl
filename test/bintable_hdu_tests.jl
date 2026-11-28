@testset "Bintable HDU" begin

    #  test Bintable (specific HDU) type
    hdu = HDU(Bintable)

    @test isequal(showfields.(hdu.cards),
                  [("XTENSION", "BINTABLE", "",
                    "XTENSION= 'BINTABLE'                                                            "),
                   ("BITPIX", 8, "",
                    "BITPIX  =                    8                                                  "),
                   ("NAXIS", 2, "",
                    "NAXIS   =                    2                                                  "),
                   ("NAXIS1", 0, "",
                    "NAXIS1  =                    0                                                  "),
                   ("NAXIS2", 0, "",
                    "NAXIS2  =                    0                                                  "),
                   ("PCOUNT", 0, "",
                    "PCOUNT  =                    0                                                  "),
                   ("GCOUNT", 1, "",
                    "GCOUNT  =                    1                                                  "),
                   ("TFIELDS", 0, "",
                    "TFIELDS =                    0                                                  ")])

    @test ismissing(hdu.data)


    #  test Bintable type with data being a tuple of arrays

    data = (; par1=[1, 2, 3],
        par2=[BitVector([1, 0, 0]), BitVector([0, 1, 0]), BitVector([1, 1, 0])],
        par3=[1f0, 2f0, 3f0],
        par4=[1.0, 2.0, 3.0],
        par5=["1.0", "2.0", "3.0"])
    hdu = HDU(data)

    @test isequal(showfields.(hdu.cards),
                  [("XTENSION", "BINTABLE", "",
                    "XTENSION= 'BINTABLE'                                                            "),
                   ("BITPIX", 8, "",
                    "BITPIX  =                    8                                                  "),
                   ("NAXIS", 2, "",
                    "NAXIS   =                    2                                                  "),
                   ("NAXIS1", 24, "",
                    "NAXIS1  =                   24                                                  "),
                   ("NAXIS2", 3, "",
                    "NAXIS2  =                    3                                                  "),
                   ("PCOUNT", 0, "",
                    "PCOUNT  =                    0                                                  "),
                   ("GCOUNT", 1, "",
                    "GCOUNT  =                    1                                                  "),
                   ("TFIELDS", 5, "",
                    "TFIELDS =                    5                                                  "),
                   ("TFORM1", "1K", "",
                    "TFORM1  = '1K'                                                                  "),
                   ("TTYPE1", "par1", "",
                    "TTYPE1  = 'par1'                                                                "),
                   ("TFORM2", "3X", "",
                    "TFORM2  = '3X'                                                                  "),
                   ("TTYPE2", "par2", "",
                    "TTYPE2  = 'par2'                                                                "),
                   ("TFORM3", "1E", "",
                    "TFORM3  = '1E'                                                                  "),
                   ("TTYPE3", "par3", "",
                    "TTYPE3  = 'par3'                                                                "),
                   ("TFORM4", "1D", "",
                    "TFORM4  = '1D'                                                                  "),
                   ("TTYPE4", "par4", "",
                    "TTYPE4  = 'par4'                                                                "),
                   ("TFORM5", "3A", "",
                    "TFORM5  = '3A'                                                                  "),
                   ("TTYPE5", "par5", "",
                    "TTYPE5  = 'par5'                                                                ")])

    @test (length(data) == 5 && size(hdu.data[1]) == (3,))

    #  test Bintable type with data being a tuple of arrays and cards
    data = (; par1=[1, 2, 3],
        par2=[BitVector([1, 0, 0]), BitVector([0, 1, 0]), BitVector([1, 1, 0])],
        par3=[1f0, 2f0, 3f0],
        par4=[1.0, 2.0, 3.0],
        par5=["1.0", "2.0", "3.0"])
    cards = [Card("TTYPE1", "PARAM1"),
             Card("TZERO1", 1.0),
             Card("TSCAL1", 0.1),
             Card("TTYPE2", "PARAM2"),
             Card("TZERO2", 1.0),
             Card("TSCAL2", 0.1),
             Card("TTYPE3", "PARAM3"),
             Card("TZERO3", 1.0),
             Card("TSCAL3", 0.1),
             Card("TTYPE4", "PARAM4"),
             Card("TZERO4", 1.0),
             Card("TSCAL4", 0.1),
             Card("TTYPE5", "PARAM5"),
             Card("TZERO5", 1.0),
             Card("TSCAL5", 0.1)]
    hdu = HDU(data, cards)

    @test isequal(showfields.(hdu.cards),
                  [("XTENSION", "BINTABLE", "",
                    "XTENSION= 'BINTABLE'                                                            "),
                   ("BITPIX", 8, "",
                    "BITPIX  =                    8                                                  "),
                   ("NAXIS", 2, "",
                    "NAXIS   =                    2                                                  "),
                   ("NAXIS1", 24, "",
                    "NAXIS1  =                   24                                                  "),
                   ("NAXIS2", 3, "",
                    "NAXIS2  =                    3                                                  "),
                   ("PCOUNT", 0, "",
                    "PCOUNT  =                    0                                                  "),
                   ("GCOUNT", 1, "",
                    "GCOUNT  =                    1                                                  "),
                   ("TFIELDS", 5, "",
                    "TFIELDS =                    5                                                  "),
                   ("TFORM1", "1K", "",
                    "TFORM1  = '1K'                                                                  "),
                   ("TTYPE1", "PARAM1", "",
                    "TTYPE1  = 'PARAM1'                                                              "),
                   ("TFORM2", "3X", "",
                    "TFORM2  = '3X'                                                                  "),
                   ("TTYPE2", "PARAM2", "",
                    "TTYPE2  = 'PARAM2'                                                              "),
                   ("TFORM3", "1E", "",
                    "TFORM3  = '1E'                                                                  "),
                   ("TTYPE3", "PARAM3", "",
                    "TTYPE3  = 'PARAM3'                                                              "),
                   ("TFORM4", "1D", "",
                    "TFORM4  = '1D'                                                                  "),
                   ("TTYPE4", "PARAM4", "",
                    "TTYPE4  = 'PARAM4'                                                              "),
                   ("TFORM5", "3A", "",
                    "TFORM5  = '3A'                                                                  "),
                   ("TTYPE5", "PARAM5", "",
                    "TTYPE5  = 'PARAM5'                                                              "),
                   ("TZERO1", 1.0, "",
                    "TZERO1  =                  1.0                                                  "),
                   ("TSCAL1", 0.1, "",
                    "TSCAL1  =                  0.1                                                  "),
                   ("TZERO2", 1.0, "",
                    "TZERO2  =                  1.0                                                  "),
                   ("TSCAL2", 0.1, "",
                    "TSCAL2  =                  0.1                                                  "),
                   ("TZERO3", 1.0, "",
                    "TZERO3  =                  1.0                                                  "),
                   ("TSCAL3", 0.1, "",
                    "TSCAL3  =                  0.1                                                  "),
                   ("TZERO4", 1.0, "",
                    "TZERO4  =                  1.0                                                  "),
                   ("TSCAL4", 0.1, "",
                    "TSCAL4  =                  0.1                                                  "),
                   ("TZERO5", 1.0, "",
                    "TZERO5  =                  1.0                                                  "),
                   ("TSCAL5", 0.1, "",
                    "TSCAL5  =                  0.1                                                  ")])

    @test (length(data) == 5 && size(hdu.data[1]) == (3,))

    #  test Bintable type with data being a tuple of arrays and inconsistent cards
    data = (; par1=[1, 2, 3],
        par2=[BitVector([1, 0, 0]), BitVector([0, 1, 0]), BitVector([1, 1, 0])],
        par3=[1f0, 2f0, 3f0],
        par4=[1.0, 2.0, 3.0],
        par5=["1.0", "2.0", "3.0"])
    cards = [Card("BITPIX", 32),
             Card("NAXIS" , 2),
             Card("NAXIS1", 108),
             Card("NAXIS2", 3),
             Card("PCOUNT", 2),
             Card("GCOUNT", 3),
             Card("TTYPE1", "PARAM1"),
             Card("TZERO1", 1.0),
             Card("TSCAL1", 0.1),
             Card("TTYPE2", "PARAM2"),
             Card("TZERO2", 1.0),
             Card("TSCAL2", 0.1),
             Card("TTYPE3", "PARAM3"),
             Card("TZERO3", 1.0),
             Card("TSCAL3", 0.1),
             Card("TTYPE4", "PARAM4"),
             Card("TZERO4", 1.0),
             Card("TSCAL4", 0.1),
             Card("TTYPE5", "PARAM5"),
             Card("TZERO5", 1.0),
             Card("TSCAL5", 0.1)]
    hdu = HDU(Bintable, data, cards)

    @test isequal(showfields.(hdu.cards),
                  [("XTENSION", "BINTABLE", "",
                    "XTENSION= 'BINTABLE'                                                            "),
                   ("BITPIX", 8, "",
                    "BITPIX  =                    8                                                  "),
                   ("NAXIS", 2, "",
                    "NAXIS   =                    2                                                  "),
                   ("NAXIS1", 24, "",
                    "NAXIS1  =                   24                                                  "),
                   ("NAXIS2", 3, "",
                    "NAXIS2  =                    3                                                  "),
                   ("PCOUNT", 0, "",
                    "PCOUNT  =                    0                                                  "),
                   ("GCOUNT", 1, "",
                    "GCOUNT  =                    1                                                  "),
                   ("TFIELDS", 5, "",
                    "TFIELDS =                    5                                                  "),
                   ("TFORM1", "1K", "",
                    "TFORM1  = '1K'                                                                  "),
                   ("TTYPE1", "PARAM1", "",
                    "TTYPE1  = 'PARAM1'                                                              "),
                   ("TFORM2", "3X", "",
                    "TFORM2  = '3X'                                                                  "),
                   ("TTYPE2", "PARAM2", "",
                    "TTYPE2  = 'PARAM2'                                                              "),
                   ("TFORM3", "1E", "",
                    "TFORM3  = '1E'                                                                  "),
                   ("TTYPE3", "PARAM3", "",
                    "TTYPE3  = 'PARAM3'                                                              "),
                   ("TFORM4", "1D", "",
                    "TFORM4  = '1D'                                                                  "),
                   ("TTYPE4", "PARAM4", "",
                    "TTYPE4  = 'PARAM4'                                                              "),
                   ("TFORM5", "3A", "",
                    "TFORM5  = '3A'                                                                  "),
                   ("TTYPE5", "PARAM5", "",
                    "TTYPE5  = 'PARAM5'                                                              "),
                   ("TZERO1", 1.0, "",
                    "TZERO1  =                  1.0                                                  "),
                   ("TSCAL1", 0.1, "",
                    "TSCAL1  =                  0.1                                                  "),
                   ("TZERO2", 1.0, "",
                    "TZERO2  =                  1.0                                                  "),
                   ("TSCAL2", 0.1, "",
                    "TSCAL2  =                  0.1                                                  "),
                   ("TZERO3", 1.0, "",
                    "TZERO3  =                  1.0                                                  "),
                   ("TSCAL3", 0.1, "",
                    "TSCAL3  =                  0.1                                                  "),
                   ("TZERO4", 1.0, "",
                    "TZERO4  =                  1.0                                                  "),
                   ("TSCAL4", 0.1, "",
                    "TSCAL4  =                  0.1                                                  "),
                   ("TZERO5", 1.0, "",
                    "TZERO5  =                  1.0                                                  "),
                   ("TSCAL5", 0.1, "",
                    "TSCAL5  =                  0.1                                                  ")])

    @test (length(data) == 5 && size(hdu.data[1]) == (3,))

    #  test Bintable type with data being an array of records
    data = [
       (par1=1, par2=BitVector([1, 0, 0]), par3=1.0f0, par4=1.0, par5="1.0"),
       (par1=2, par2=BitVector([0, 1, 0]), par3=2.0f0, par4=2.0, par5="2.0"),
       (par1=3, par2=BitVector([1, 1, 0]), par3=3.0f0, par4=3.0, par5="3.0")]
    hdu = HDU(data)

    @test isequal(showfields.(hdu.cards),
                  [("XTENSION", "BINTABLE", "",
                    "XTENSION= 'BINTABLE'                                                            "),
                   ("BITPIX", 8, "",
                    "BITPIX  =                    8                                                  "),
                   ("NAXIS", 2, "",
                    "NAXIS   =                    2                                                  "),
                   ("NAXIS1", 24, "",
                    "NAXIS1  =                   24                                                  "),
                   ("NAXIS2", 3, "",
                    "NAXIS2  =                    3                                                  "),
                   ("PCOUNT", 0, "",
                    "PCOUNT  =                    0                                                  "),
                   ("GCOUNT", 1, "",
                    "GCOUNT  =                    1                                                  "),
                   ("TFIELDS", 5, "",
                    "TFIELDS =                    5                                                  "),
                   ("TFORM1", "1K", "",
                    "TFORM1  = '1K'                                                                  "),
                   ("TTYPE1", "par1", "",
                    "TTYPE1  = 'par1'                                                                "),
                   ("TFORM2", "3X", "",
                    "TFORM2  = '3X'                                                                  "),
                   ("TTYPE2", "par2", "",
                    "TTYPE2  = 'par2'                                                                "),
                   ("TFORM3", "1E", "",
                    "TFORM3  = '1E'                                                                  "),
                   ("TTYPE3", "par3", "",
                    "TTYPE3  = 'par3'                                                                "),
                   ("TFORM4", "1D", "",
                    "TFORM4  = '1D'                                                                  "),
                   ("TTYPE4", "par4", "",
                    "TTYPE4  = 'par4'                                                                "),
                   ("TFORM5", "3A", "",
                    "TFORM5  = '3A'                                                                  "),
                   ("TTYPE5", "par5", "",
                    "TTYPE5  = 'par5'                                                                ")])

    @test (length(data[1]) == 5 && size(hdu.data) == (3,))

    #  test Bintable type with cards
    cards = [Card("XTENSION", "BINTABLE"),
             Card("BITPIX", 8),
             Card("NAXIS", 2),
             Card("NAXIS1", 24),
             Card("NAXIS2", 3),
             Card("PCOUNT", 0),
             Card("GCOUNT", 1),
             Card("TFIELDS", 5),
             Card("TFORM1", "1K"),
             Card("TTYPE1", "par1"),
             Card("TFORM2", "3X"),
             Card("TTYPE2", "par2"),
             Card("TFORM3", "1E"),
             Card("TTYPE3", "par3"),
             Card("TFORM4", "1D"),
             Card("TTYPE4", "par4"),
             Card("TFORM5", "3A"),
             Card("TTYPE5", "par5")]
    hdu = HDU(cards)

    @test isequal(showfields.(hdu.cards),
                  [("XTENSION", "BINTABLE", "",
                    "XTENSION= 'BINTABLE'                                                            "),
                   ("BITPIX", 8, "",
                    "BITPIX  =                    8                                                  "),
                   ("NAXIS", 2, "",
                    "NAXIS   =                    2                                                  "),
                   ("NAXIS1", 24, "",
                    "NAXIS1  =                   24                                                  "),
                   ("NAXIS2", 3, "",
                    "NAXIS2  =                    3                                                  "),
                   ("PCOUNT", 0, "",
                    "PCOUNT  =                    0                                                  "),
                   ("GCOUNT", 1, "",
                    "GCOUNT  =                    1                                                  "),
                   ("TFIELDS", 5, "",
                    "TFIELDS =                    5                                                  "),
                   ("TFORM1", "1K", "",
                    "TFORM1  = '1K'                                                                  "),
                   ("TTYPE1", "par1", "",
                    "TTYPE1  = 'par1'                                                                "),
                   ("TFORM2", "3X", "",
                    "TFORM2  = '3X'                                                                  "),
                   ("TTYPE2", "par2", "",
                    "TTYPE2  = 'par2'                                                                "),
                   ("TFORM3", "1E", "",
                    "TFORM3  = '1E'                                                                  "),
                   ("TTYPE3", "par3", "",
                    "TTYPE3  = 'par3'                                                                "),
                   ("TFORM4", "1D", "",
                    "TFORM4  = '1D'                                                                  "),
                   ("TTYPE4", "par4", "",
                    "TTYPE4  = 'par4'                                                                "),
                   ("TFORM5", "3A", "",
                    "TFORM5  = '3A'                                                                  "),
                   ("TTYPE5", "par5", "",
                    "TTYPE5  = 'par5'                                                                ")])

    @test (length(hdu.data) == 5 && length(hdu.data[1]) == 3)

    #  test Bintable type with data being an array of records and cards
    data = [
       (par1=1, par2=BitVector([1, 0, 0]), par3=1.0f0, par4=1.0, par5="1.0"),
       (par1=2, par2=BitVector([0, 1, 0]), par3=2.0f0, par4=2.0, par5="2.0"),
       (par1=3, par2=BitVector([1, 1, 0]), par3=3.0f0, par4=3.0, par5="3.0")]
    cards = [Card("XTENSION", "BINTABLE"),
             Card("BITPIX", 8),
             Card("NAXIS", 2),
             Card("NAXIS1", 24),
             Card("NAXIS2", 3),
             Card("PCOUNT", 0),
             Card("GCOUNT", 1),
             Card("TFIELDS", 5),
             Card("TFORM1", "1K"),
             Card("TTYPE1", "par1"),
             Card("TFORM2", "3X"),
             Card("TTYPE2", "par2"),
             Card("TFORM3", "1E"),
             Card("TTYPE3", "par3"),
             Card("TFORM4", "1D"),
             Card("TTYPE4", "par4"),
             Card("TFORM5", "3A"),
             Card("TTYPE5", "par5")]
    hdu = HDU(data, cards)

    @test isequal(showfields.(hdu.cards),
                  [("XTENSION", "BINTABLE", "",
                    "XTENSION= 'BINTABLE'                                                            "),
                   ("BITPIX", 8, "",
                    "BITPIX  =                    8                                                  "),
                   ("NAXIS", 2, "",
                    "NAXIS   =                    2                                                  "),
                   ("NAXIS1", 24, "",
                    "NAXIS1  =                   24                                                  "),
                   ("NAXIS2", 3, "",
                    "NAXIS2  =                    3                                                  "),
                   ("PCOUNT", 0, "",
                    "PCOUNT  =                    0                                                  "),
                   ("GCOUNT", 1, "",
                    "GCOUNT  =                    1                                                  "),
                   ("TFIELDS", 5, "",
                    "TFIELDS =                    5                                                  "),
                   ("TFORM1", "1K", "",
                    "TFORM1  = '1K'                                                                  "),
                   ("TTYPE1", "par1", "",
                    "TTYPE1  = 'par1'                                                                "),
                   ("TFORM2", "3X", "",
                    "TFORM2  = '3X'                                                                  "),
                   ("TTYPE2", "par2", "",
                    "TTYPE2  = 'par2'                                                                "),
                   ("TFORM3", "1E", "",
                    "TFORM3  = '1E'                                                                  "),
                   ("TTYPE3", "par3", "",
                    "TTYPE3  = 'par3'                                                                "),
                   ("TFORM4", "1D", "",
                    "TFORM4  = '1D'                                                                  "),
                   ("TTYPE4", "par4", "",
                    "TTYPE4  = 'par4'                                                                "),
                   ("TFORM5", "3A", "",
                    "TFORM5  = '3A'                                                                  "),
                   ("TTYPE5", "par5", "",
                    "TTYPE5  = 'par5'                                                                ")])

    @test (length(hdu.data[1]) == 5 && length(hdu.data) == 3)

    #  test Bintable type with data being an array of records and inconsistent cards
    data = [
       (par1=1, par2=BitVector([1, 0, 0]), par3=1.0f0, par4=1.0, par5="1.0"),
       (par1=2, par2=BitVector([0, 1, 0]), par3=2.0f0, par4=2.0, par5="2.0"),
       (par1=3, par2=BitVector([1, 1, 0]), par3=3.0f0, par4=3.0, par5="3.0")]
    cards = [Card("BITPIX", 32),
             Card("NAXIS" , 2),
             Card("NAXIS1", 108),
             Card("NAXIS2", 3),
             Card("PCOUNT", 2),
             Card("GCOUNT", 3),
             Card("TTYPE1", "PARAM1"),
             Card("TZERO1", 1.0),
             Card("TSCAL1", 0.1),
             Card("TTYPE2", "PARAM2"),
             Card("TZERO2", 1.0),
             Card("TSCAL2", 0.1),
             Card("TTYPE3", "PARAM3"),
             Card("TZERO3", 1.0),
             Card("TSCAL3", 0.1),
             Card("TTYPE4", "PARAM4"),
             Card("TZERO4", 1.0),
             Card("TSCAL4", 0.1),
             Card("TTYPE5", "PARAM5"),
             Card("TZERO5", 1.0),
             Card("TSCAL5", 0.1)]
    hdu = HDU(Bintable, data, cards)

    @test isequal(showfields.(hdu.cards),
                  [("XTENSION", "BINTABLE", "",
                    "XTENSION= 'BINTABLE'                                                            "),
                   ("BITPIX", 8, "",
                    "BITPIX  =                    8                                                  "),
                   ("NAXIS", 2, "",
                    "NAXIS   =                    2                                                  "),
                   ("NAXIS1", 24, "",
                    "NAXIS1  =                   24                                                  "),
                   ("NAXIS2", 3, "",
                    "NAXIS2  =                    3                                                  "),
                   ("PCOUNT", 0, "",
                    "PCOUNT  =                    0                                                  "),
                   ("GCOUNT", 1, "",
                    "GCOUNT  =                    1                                                  "),
                   ("TFIELDS", 5, "",
                    "TFIELDS =                    5                                                  "),
                   ("TFORM1", "1K", "",
                    "TFORM1  = '1K'                                                                  "),
                   ("TTYPE1", "PARAM1", "",
                    "TTYPE1  = 'PARAM1'                                                              "),
                   ("TFORM2", "3X", "",
                    "TFORM2  = '3X'                                                                  "),
                   ("TTYPE2", "PARAM2", "",
                    "TTYPE2  = 'PARAM2'                                                              "),
                   ("TFORM3", "1E", "",
                    "TFORM3  = '1E'                                                                  "),
                   ("TTYPE3", "PARAM3", "",
                    "TTYPE3  = 'PARAM3'                                                              "),
                   ("TFORM4", "1D", "",
                    "TFORM4  = '1D'                                                                  "),
                   ("TTYPE4", "PARAM4", "",
                    "TTYPE4  = 'PARAM4'                                                              "),
                   ("TFORM5", "3A", "",
                    "TFORM5  = '3A'                                                                  "),
                   ("TTYPE5", "PARAM5", "",
                    "TTYPE5  = 'PARAM5'                                                              "),
                   ("TZERO1", 1.0, "",
                    "TZERO1  =                  1.0                                                  "),
                   ("TSCAL1", 0.1, "",
                    "TSCAL1  =                  0.1                                                  "),
                   ("TZERO2", 1.0, "",
                    "TZERO2  =                  1.0                                                  "),
                   ("TSCAL2", 0.1, "",
                    "TSCAL2  =                  0.1                                                  "),
                   ("TZERO3", 1.0, "",
                    "TZERO3  =                  1.0                                                  "),
                   ("TSCAL3", 0.1, "",
                    "TSCAL3  =                  0.1                                                  "),
                   ("TZERO4", 1.0, "",
                    "TZERO4  =                  1.0                                                  "),
                   ("TSCAL4", 0.1, "",
                    "TSCAL4  =                  0.1                                                  "),
                   ("TZERO5", 1.0, "",
                    "TZERO5  =                  1.0                                                  "),
                   ("TSCAL5", 0.1, "",
                    "TSCAL5  =                  0.1                                                  ")])

    @test (length(data[1]) == 5 && size(hdu.data) == (3,) &&
        all([hdu.data[j][:par4] for j=1:3] .== [1.0, 2.0, 3.0]))

    #  test Bintable type with data being an array of records and scale == true
    data = [
       (par1=1, par2=BitVector([1, 0, 0]), par3=1.0f0, par4=1.0, par5="1.0"),
       (par1=2, par2=BitVector([0, 1, 0]), par3=2.0f0, par4=2.0, par5="2.0"),
       (par1=3, par2=BitVector([1, 1, 0]), par3=3.0f0, par4=3.0, par5="3.0")]
    cards = [Card("XTENSION", "BINTABLE"),
             Card("BITPIX", 8),
             Card("NAXIS", 2),
             Card("NAXIS1", 24),
             Card("NAXIS2", 3),
             Card("PCOUNT", 0),
             Card("GCOUNT", 1),
             Card("TFIELDS", 5),
             Card("TFORM1", "1K"),
             Card("TTYPE1", "par1"),
             Card("TFORM2", "3X"),
             Card("TTYPE2", "par2"),
             Card("TFORM3", "1E"),
             Card("TTYPE3", "par3"),
             Card("TFORM4", "1D"),
             Card("TTYPE4", "par4"),
             Card("TFORM5", "3A"),
             Card("TTYPE5", "par5")]
    seek(io, 0)
    write(io, HDU(data, cards); check = false)
    seek(io, 0)
    hdu = read(io, HDU; record=false, scale=true)

    @test isequal(showfields.(hdu.cards),
                  [("XTENSION", "BINTABLE", "",
                    "XTENSION= 'BINTABLE'                                                            "),
                   ("BITPIX", 8, "",
                    "BITPIX  =                    8                                                  "),
                   ("NAXIS", 2, "",
                    "NAXIS   =                    2                                                  "),
                   ("NAXIS1", 24, "",
                    "NAXIS1  =                   24                                                  "),
                   ("NAXIS2", 3, "",
                    "NAXIS2  =                    3                                                  "),
                   ("PCOUNT", 0, "",
                    "PCOUNT  =                    0                                                  "),
                   ("GCOUNT", 1, "",
                    "GCOUNT  =                    1                                                  "),
                   ("TFIELDS", 5, "",
                    "TFIELDS =                    5                                                  "),
                   ("TFORM1", "1K", "",
                    "TFORM1  = '1K'                                                                  "),
                   ("TTYPE1", "par1", "",
                    "TTYPE1  = 'par1'                                                                "),
                   ("TFORM2", "3X", "",
                    "TFORM2  = '3X'                                                                  "),
                   ("TTYPE2", "par2", "",
                    "TTYPE2  = 'par2'                                                                "),
                   ("TFORM3", "1E", "",
                    "TFORM3  = '1E'                                                                  "),
                   ("TTYPE3", "par3", "",
                    "TTYPE3  = 'par3'                                                                "),
                   ("TFORM4", "1D", "",
                    "TFORM4  = '1D'                                                                  "),
                   ("TTYPE4", "par4", "",
                    "TTYPE4  = 'par4'                                                                "),
                   ("TFORM5", "3A", "",
                    "TFORM5  = '3A'                                                                  "),
                   ("TTYPE5", "par5", "",
                    "TTYPE5  = 'par5'                                                                ")])

    @test (length(hdu.data) == 5 && length(hdu.data[:par1]) == 3 &&
        all(hdu.data[:par4] .== [1.0, 2.0, 3.0]))

    #  test Bintable type with data being an array of records and record == true
    data = [
       (par1=1, par2=BitVector([1, 0, 0]), par3=1.0f0, par4=1.0, par5="1.0"),
       (par1=2, par2=BitVector([0, 1, 0]), par3=2.0f0, par4=2.0, par5="2.0"),
       (par1=3, par2=BitVector([1, 1, 0]), par3=3.0f0, par4=3.0, par5="3.0")]
    cards = [Card("XTENSION", "BINTABLE"),
             Card("BITPIX", 8),
             Card("NAXIS", 2),
             Card("NAXIS1", 24),
             Card("NAXIS2", 3),
             Card("PCOUNT", 0),
             Card("GCOUNT", 1),
             Card("TFIELDS", 5),
             Card("TFORM1", "1K"),
             Card("TTYPE1", "par1"),
             Card("TFORM2", "3X"),
             Card("TTYPE2", "par2"),
             Card("TFORM3", "1E"),
             Card("TTYPE3", "par3"),
             Card("TFORM4", "1D"),
             Card("TTYPE4", "par4"),
             Card("TFORM5", "3A"),
             Card("TTYPE5", "par5")]
    seek(io, 0)
    write(io, HDU(data, cards); check = false)
    seek(io, 0)
    hdu = read(io, HDU; record=true, scale=true)

    @test isequal(showfields.(hdu.cards),
                  [("XTENSION", "BINTABLE", "",
                    "XTENSION= 'BINTABLE'                                                            "),
                   ("BITPIX", 8, "",
                    "BITPIX  =                    8                                                  "),
                   ("NAXIS", 2, "",
                    "NAXIS   =                    2                                                  "),
                   ("NAXIS1", 24, "",
                    "NAXIS1  =                   24                                                  "),
                   ("NAXIS2", 3, "",
                    "NAXIS2  =                    3                                                  "),
                   ("PCOUNT", 0, "",
                    "PCOUNT  =                    0                                                  "),
                   ("GCOUNT", 1, "",
                    "GCOUNT  =                    1                                                  "),
                   ("TFIELDS", 5, "",
                    "TFIELDS =                    5                                                  "),
                   ("TFORM1", "1K", "",
                    "TFORM1  = '1K'                                                                  "),
                   ("TTYPE1", "par1", "",
                    "TTYPE1  = 'par1'                                                                "),
                   ("TFORM2", "3X", "",
                    "TFORM2  = '3X'                                                                  "),
                   ("TTYPE2", "par2", "",
                    "TTYPE2  = 'par2'                                                                "),
                   ("TFORM3", "1E", "",
                    "TFORM3  = '1E'                                                                  "),
                   ("TTYPE3", "par3", "",
                    "TTYPE3  = 'par3'                                                                "),
                   ("TFORM4", "1D", "",
                    "TFORM4  = '1D'                                                                  "),
                   ("TTYPE4", "par4", "",
                    "TTYPE4  = 'par4'                                                                "),
                   ("TFORM5", "3A", "",
                    "TFORM5  = '3A'                                                                  "),
                   ("TTYPE5", "par5", "",
                    "TTYPE5  = 'par5'                                                                ")])

    @test (length(hdu.data[1]) == 5 && length(hdu.data) == 3 &&
        all([hdu.data[j][:par4] for j=1:3] .== [1.0, 2.0, 3.0]))

    #  test Bintable type with data being an array of records and scale == false
    data = [
       (par1=1, par2=BitVector([1, 0, 0]), par3=1.0f0, par4=1.0, par5="1.0"),
       (par1=2, par2=BitVector([0, 1, 0]), par3=2.0f0, par4=2.0, par5="2.0"),
       (par1=3, par2=BitVector([1, 1, 0]), par3=3.0f0, par4=3.0, par5="3.0")]
    cards = [Card("XTENSION", "BINTABLE"),
             Card("BITPIX", 8),
             Card("NAXIS", 2),
             Card("NAXIS1", 24),
             Card("NAXIS2", 3),
             Card("PCOUNT", 0),
             Card("GCOUNT", 1),
             Card("TFIELDS", 5),
             Card("TFORM1", "1K"),
             Card("TTYPE1", "par1"),
             Card("TZERO1", 1.0),
             Card("TSCAL1", 0.5),
             Card("TFORM2", "3X"),
             Card("TTYPE2", "par2"),
             Card("TZERO2", 1.0),
             Card("TSCAL2", 0.5),
             Card("TFORM3", "1E"),
             Card("TTYPE3", "par3"),
             Card("TZERO3", 1.0),
             Card("TSCAL3", 0.5),
             Card("TFORM4", "1D"),
             Card("TTYPE4", "par4"),
             Card("TZERO4", 1.0),
             Card("TSCAL4", 0.5),
             Card("TFORM5", "3A"),
             Card("TTYPE5", "par5"),
             Card("TZERO5", 1.0),
             Card("TSCAL5", 0.5)]

    seek(io, 0)
    write(io, HDU(data, cards); check = false)
    seek(io, 0)
    hdu = read(io, HDU; record=false, scale=true)

    @test isequal(showfields.(hdu.cards),
                  [("XTENSION", "BINTABLE", "",
                    "XTENSION= 'BINTABLE'                                                            "),
                   ("BITPIX", 8, "",
                    "BITPIX  =                    8                                                  "),
                   ("NAXIS", 2, "",
                    "NAXIS   =                    2                                                  "),
                   ("NAXIS1", 24, "",
                    "NAXIS1  =                   24                                                  "),
                   ("NAXIS2", 3, "",
                    "NAXIS2  =                    3                                                  "),
                   ("PCOUNT", 0, "",
                    "PCOUNT  =                    0                                                  "),
                   ("GCOUNT", 1, "",
                    "GCOUNT  =                    1                                                  "),
                   ("TFIELDS", 5, "",
                    "TFIELDS =                    5                                                  "),
                   ("TFORM1", "1K", "",
                    "TFORM1  = '1K'                                                                  "),
                   ("TTYPE1", "par1", "",
                    "TTYPE1  = 'par1'                                                                "),
                   ("TFORM2", "3X", "",
                    "TFORM2  = '3X'                                                                  "),
                   ("TTYPE2", "par2", "",
                    "TTYPE2  = 'par2'                                                                "),
                   ("TFORM3", "1E", "",
                    "TFORM3  = '1E'                                                                  "),
                   ("TTYPE3", "par3", "",
                    "TTYPE3  = 'par3'                                                                "),
                   ("TFORM4", "1D", "",
                    "TFORM4  = '1D'                                                                  "),
                   ("TTYPE4", "par4", "",
                    "TTYPE4  = 'par4'                                                                "),
                   ("TFORM5", "3A", "",
                    "TFORM5  = '3A'                                                                  "),
                   ("TTYPE5", "par5", "",
                    "TTYPE5  = 'par5'                                                                "),
                   ("TZERO1", 1.0f0, "",
                    "TZERO1  =                  1.0                                                  "),
                   ("TSCAL1", 0.5f0, "",
                    "TSCAL1  =                  0.5                                                  "),
                   ("TZERO2", 1.0f0, "",
                    "TZERO2  =                  1.0                                                  "),
                   ("TSCAL2", 0.5f0, "",
                    "TSCAL2  =                  0.5                                                  "),
                   ("TZERO3", 1.0f0, "",
                    "TZERO3  =                  1.0                                                  "),
                   ("TSCAL3", 0.5f0, "",
                    "TSCAL3  =                  0.5                                                  "),
                   ("TZERO4", 1.0f0, "",
                    "TZERO4  =                  1.0                                                  "),
                   ("TSCAL4", 0.5f0, "",
                    "TSCAL4  =                  0.5                                                  "),
                   ("TZERO5", 1.0f0, "",
                    "TZERO5  =                  1.0                                                  "),
                   ("TSCAL5", 0.5f0, "",
                    "TSCAL5  =                  0.5                                                  ")])

    #  This test is temporary fix
    @test (length(hdu.data) == 5 && length(hdu.data[:par1]) == 3 &&
        all(hdu.data[:par4] .== [1.5, 2.0, 2.5]))

    #  test Bintable type with data being an array of records and scale == false
    data = [
       (par1=1, par2=BitVector([1, 0, 0]), par3=1.0f0, par4=1.0, par5="1.0"),
       (par1=2, par2=BitVector([0, 1, 0]), par3=2.0f0, par4=2.0, par5="2.0"),
       (par1=3, par2=BitVector([1, 1, 0]), par3=3.0f0, par4=3.0, par5="3.0")]
    cards = [Card("XTENSION", "BINTABLE"),
             Card("BITPIX", 8),
             Card("NAXIS", 2),
             Card("NAXIS1", 24),
             Card("NAXIS2", 3),
             Card("PCOUNT", 0),
             Card("GCOUNT", 1),
             Card("TFIELDS", 5),
             Card("TFORM1", "1K"),
             Card("TTYPE1", "par1"),
             Card("TZERO1", 1.0),
             Card("TSCAL1", 0.1),
             Card("TFORM2", "3X"),
             Card("TTYPE2", "par2"),
             Card("TZERO2", 1.0),
             Card("TSCAL2", 0.1),
             Card("TFORM3", "1E"),
             Card("TTYPE3", "par3"),
             Card("TZERO3", 1.0),
             Card("TSCAL3", 0.1),
             Card("TFORM4", "1D"),
             Card("TTYPE4", "par4"),
             Card("TZERO4", 1.0),
             Card("TSCAL4", 0.1),
             Card("TFORM5", "3A"),
             Card("TTYPE5", "par5"),
             Card("TZERO5", 1.0),
             Card("TSCAL5", 0.1)]

    seek(io, 0)
    write(io, HDU(data, cards); check = false)
    seek(io, 0)
    hdu = read(io, HDU; record=false, scale=false)

    @test isequal(showfields.(hdu.cards),
                  [("XTENSION", "BINTABLE", "",
                    "XTENSION= 'BINTABLE'                                                            "),
                   ("BITPIX", 8, "",
                    "BITPIX  =                    8                                                  "),
                   ("NAXIS", 2, "",
                    "NAXIS   =                    2                                                  "),
                   ("NAXIS1", 24, "",
                    "NAXIS1  =                   24                                                  "),
                   ("NAXIS2", 3, "",
                    "NAXIS2  =                    3                                                  "),
                   ("PCOUNT", 0, "",
                    "PCOUNT  =                    0                                                  "),
                   ("GCOUNT", 1, "",
                    "GCOUNT  =                    1                                                  "),
                   ("TFIELDS", 5, "",
                    "TFIELDS =                    5                                                  "),
                   ("TFORM1", "1K", "",
                    "TFORM1  = '1K'                                                                  "),
                   ("TTYPE1", "par1", "",
                    "TTYPE1  = 'par1'                                                                "),
                   ("TFORM2", "3X", "",
                    "TFORM2  = '3X'                                                                  "),
                   ("TTYPE2", "par2", "",
                    "TTYPE2  = 'par2'                                                                "),
                   ("TFORM3", "1E", "",
                    "TFORM3  = '1E'                                                                  "),
                   ("TTYPE3", "par3", "",
                    "TTYPE3  = 'par3'                                                                "),
                   ("TFORM4", "1D", "",
                    "TFORM4  = '1D'                                                                  "),
                   ("TTYPE4", "par4", "",
                    "TTYPE4  = 'par4'                                                                "),
                   ("TFORM5", "3A", "",
                    "TFORM5  = '3A'                                                                  "),
                   ("TTYPE5", "par5", "",
                    "TTYPE5  = 'par5'                                                                "),
                   ("TZERO1", 1.0f0, "",
                    "TZERO1  =                  1.0                                                  "),
                   ("TSCAL1", 0.1, "",
                    "TSCAL1  =                  0.1                                                  "),
                   ("TZERO2", 1.0f0, "",
                    "TZERO2  =                  1.0                                                  "),
                   ("TSCAL2", 0.1, "",
                    "TSCAL2  =                  0.1                                                  "),
                   ("TZERO3", 1.0f0, "",
                    "TZERO3  =                  1.0                                                  "),
                   ("TSCAL3", 0.1, "",
                    "TSCAL3  =                  0.1                                                  "),
                   ("TZERO4", 1.0f0, "",
                    "TZERO4  =                  1.0                                                  "),
                   ("TSCAL4", 0.1, "",
                    "TSCAL4  =                  0.1                                                  "),
                   ("TZERO5", 1.0f0, "",
                    "TZERO5  =                  1.0                                                  "),
                   ("TSCAL5", 0.1, "",
                    "TSCAL5  =                  0.1                                                  ")])

    @test (length(hdu.data) == 5 && length(hdu.data[:par1]) == 3 &&
        all(hdu.data[:par4] .== [1.0, 2.0, 3.0]))

    #  test Bintable type with data being an array of records, record == true, and lazy array
    data = [
       (par1=1, par2=BitVector([1, 0, 0]), par3=1.0f0, par4=1.0, par5="1.0"),
       (par1=2, par2=BitVector([0, 1, 0]), par3=2.0f0, par4=2.0, par5="2.0"),
       (par1=3, par2=BitVector([1, 1, 0]), par3=3.0f0, par4=3.0, par5="3.0")]
    cards = [Card("XTENSION", "BINTABLE"),
             Card("BITPIX", 8),
             Card("NAXIS", 2),
             Card("NAXIS1", 24),
             Card("NAXIS2", 3),
             Card("PCOUNT", 0),
             Card("GCOUNT", 1),
             Card("TFIELDS", 5),
             Card("TFORM1", "1K"),
             Card("TTYPE1", "par1"),
             Card("TFORM2", "3X"),
             Card("TTYPE2", "par2"),
             Card("TFORM3", "1E"),
             Card("TTYPE3", "par3"),
             Card("TFORM4", "1D"),
             Card("TTYPE4", "par4"),
             Card("TFORM5", "3A"),
             Card("TTYPE5", "par5")]

    temppath = joinpath(tempdir(), "bintable_hdu.fits")
    fileio = open(temppath, "w+")
    write(fileio, HDU(data, cards))
    close(fileio)
    fileio = open(temppath)
    hdu = read(fileio, HDU; type=Bintable, record=true, scale=true)
    close(fileio)

    @test isequal(showfields.(hdu.cards),
                  [("XTENSION", "BINTABLE", "",
                    "XTENSION= 'BINTABLE'                                                            "),
                   ("BITPIX", 8, "",
                    "BITPIX  =                    8                                                  "),
                   ("NAXIS", 2, "",
                    "NAXIS   =                    2                                                  "),
                   ("NAXIS1", 24, "",
                    "NAXIS1  =                   24                                                  "),
                   ("NAXIS2", 3, "",
                    "NAXIS2  =                    3                                                  "),
                   ("PCOUNT", 0, "",
                    "PCOUNT  =                    0                                                  "),
                   ("GCOUNT", 1, "",
                    "GCOUNT  =                    1                                                  "),
                   ("TFIELDS", 5, "",
                    "TFIELDS =                    5                                                  "),
                   ("TFORM1", "1K", "",
                    "TFORM1  = '1K'                                                                  "),
                   ("TTYPE1", "par1", "",
                    "TTYPE1  = 'par1'                                                                "),
                   ("TFORM2", "3X", "",
                    "TFORM2  = '3X'                                                                  "),
                   ("TTYPE2", "par2", "",
                    "TTYPE2  = 'par2'                                                                "),
                   ("TFORM3", "1E", "",
                    "TFORM3  = '1E'                                                                  "),
                   ("TTYPE3", "par3", "",
                    "TTYPE3  = 'par3'                                                                "),
                   ("TFORM4", "1D", "",
                    "TFORM4  = '1D'                                                                  "),
                   ("TTYPE4", "par4", "",
                    "TTYPE4  = 'par4'                                                                "),
                   ("TFORM5", "3A", "",
                    "TFORM5  = '3A'                                                                  "),
                   ("TTYPE5", "par5", "",
                    "TTYPE5  = 'par5'                                                                ")])

    @test (length(hdu.data[1]) == 5 && length(hdu.data) == 3 &&
        all([hdu.data[j][:par4] for j=1:3] .== [1.0, 2.0, 3.0]))

    rm(temppath)

    #  Int32 columns without TSCAL/TZERO must not be rounded to Float32 (values
    #  above 2^24); the file (written by astropy) has a fixed 8J column and a
    #  variable-length PJ column holding the same values
    expected = Int32[16777214, 16777215, 16777216, 16777217, 16777275,
                     16777277, 33554433, 2000000001]
    hdus = fits(joinpath(@__DIR__, "data", "int32_large.fits"))
    @test vec(hdus[2].data[:fixed]) == expected
    @test hdus[2].data[:heap][1] == expected
    @test eltype(hdus[2].data[:heap][1]) == Int32

    #  Scaling must not round the stored integers to Float32: a UInt32 column is
    #  Int32 with TZERO = 2^31, and a Float32 TSCAL must not reduce the others
    cards = [Card("XTENSION", "BINTABLE"),
             Card("BITPIX", 8),
             Card("NAXIS", 2),
             Card("NAXIS1", 14),
             Card("NAXIS2", 2),
             Card("PCOUNT", 0),
             Card("GCOUNT", 1),
             Card("TFIELDS", 3),
             Card("TFORM1", "1J"),
             Card("TTYPE1", "UINT"),
             Card("TZERO1", 2147483648),
             Card("TFORM2", "1I"),
             Card("TTYPE2", "SCALED"),
             Card("TZERO2", 1.0f0),
             Card("TSCAL2", 0.5f0),
             Card("TFORM3", "2J"),
             Card("TTYPE3", "UINTS"),
             Card("TZERO3", 2147483648)]
    data = (UINT=Int32[-2147483602, -2147483520],
            SCALED=Int16[2, 4],
            UINTS=[Int32[-2147483602, -2147483520],
                   Int32[-2147483520, -2147483602]])
    scaled_io = IOBuffer()
    write(scaled_io, HDU(data, cards))

    seekstart(scaled_io)
    columns = read(scaled_io, HDU; record=false, scale=true).data
    #  the offset of Table 19 is an unsigned integer
    @test columns.UINT == UInt32[46, 128] && eltype(columns.UINT) === UInt32
    @test columns.SCALED == Float32[2, 3] && eltype(columns.SCALED) === Float32
    @test columns.UINTS == UInt32[46 128; 128 46] && eltype(columns.UINTS) === UInt32

    seekstart(scaled_io)
    records = read(scaled_io, HDU; record=true, scale=true).data
    @test getproperty.(records, :UINT) == UInt32[46, 128]
    @test getproperty.(records, :SCALED) == Float32[2, 3]
    @test getproperty.(records, :UINTS) == [UInt32[46, 128], UInt32[128, 46]]

    #  the helper itself
    @test FITSFiles.scaled(Int32[-2147483602], 1.0f0, 2147483648.0) == [46.0]
    @test FITSFiles.scaled(Int16[2, 4], 0.5f0, 1.0f0) == Float32[2, 3]
    @test eltype(FITSFiles.scaled(UInt8[1, 2], 1.0f0, 0.0f0)) === Float32
    @test FITSFiles.scaled(Int32(-2147483602), 1.0f0, 2147483648.0) === 46.0
    @test FITSFiles.scaled(Float32[1, 2], 2.0f0, 1.0f0) == Float32[3, 5]

    ####    Test the logical columns (Sect. 7.3.3.1)    ####

    @testset "logical columns" begin
        card(s) = rpad(s, 80)
        #  the bytes of a Bintable HDU of the cards, preceded by an empty Primary HDU
        function bintablebytes(cards, naxis1, naxis2, data; pcount = 0)
            primary = ["SIMPLE  =                    T", "BITPIX  =                    8",
                "NAXIS   =                    0", "END"]
            header = vcat(["XTENSION= 'BINTABLE'", "BITPIX  =                    8", "NAXIS   =                    2",
                "NAXIS1  = " * lpad(naxis1, 20), "NAXIS2  = " * lpad(naxis2, 20),
                "PCOUNT  = " * lpad(pcount, 20), "GCOUNT  =                    1"], cards, ["END"])
            rpad(join(card.(primary)), 2880) * rpad(join(card.(header)), 2880) *
                String(vcat(data, zeros(UInt8, 2880 - length(data))))
        end
        reread(bytes; kwds...) = (buffer = IOBuffer(bytes); read(buffer, HDU); read(buffer, HDU; kwds...))
        T, F, N = UInt8('T'), UInt8('F'), 0x00
        cards = ["TFIELDS =                    1", "TFORM1  = '1L      '", "TTYPE1  = 'flag    '"]

        #  T is true, F is false, and a 0 byte is undefined
        bytes = bintablebytes(cards, 1, 4, UInt8[T, F, N, T])
        @test isequal(reread(bytes).data.flag, [true, false, missing, true])
        @test isequal([r.flag for r in reread(bytes; record = true).data], [true, false, missing, true])

        #  a column without undefined entries has no missing values
        data = reread(bintablebytes(cards, 1, 3, UInt8[T, F, F])).data.flag
        @test data isa Vector{Bool} && data == [true, false, false]

        #  an HDU that is read is written with the same bytes
        hdu = reread(bytes)
        io = IOBuffer(); write(io, hdu)
        @test take!(io) == codeunits(bytes)[2881:end]

        #  a value is written as T or F, and missing as a 0 byte
        io = IOBuffer(); write(io, HDU(Bintable, (flag = Union{Bool, Missing}[true, false, missing],)))
        @test take!(io)[end-2879:end-2877] == UInt8[T, F, N]
        io = IOBuffer(); write(io, HDU(Bintable, [(flag = true,), (flag = false,)]))
        @test take!(io)[end-2879:end-2878] == UInt8[T, F]

        #  a bytes that is not T, F, or 0 is read as false, with a warning
        @test_logs (:warn, r"1 bytes of a logical field") reread(bintablebytes(cards, 1, 2, UInt8[T, UInt8('x')]))
        @test reread(bintablebytes(cards, 1, 2, UInt8[T, UInt8('x')])).data.flag == [true, false]

        #  a column with a repeat count has a column of values for each repeat
        cards3 = ["TFIELDS =                    1", "TFORM1  = '3L      '", "TTYPE1  = 'flags   '"]
        bytes = bintablebytes(cards3, 3, 2, UInt8[T, F, N, F, F, T])
        @test isequal(reread(bytes).data.flags, [true false missing; false false true])
        @test isequal(reread(bytes; record = true).data[1].flags, [true, false, missing])
        io = IOBuffer(); write(io, reread(bytes))
        @test take!(io) == codeunits(bytes)[2881:end]

        #  the fields and the heap are verified when an HDU is read (Sects. 7.3.1 and 7.3.2)
        @test_throws ArgumentError("TFORM2 is missing, but TFIELDS is 2.") reread(
            bintablebytes(["TFIELDS =                    2"; cards[2:3]], 1, 2, UInt8[T, F]))
        @test_throws ArgumentError r"TFIELDS must be an integer" reread(
            bintablebytes(["TFIELDS =                  1.0"; cards[2:3]], 1, 2, UInt8[T, F]))
        @test_logs (:warn, r"THEAP 1 is less than NAXIS1\*NAXIS2, 2") reread(
            bintablebytes([cards; "THEAP   =                    1"], 1, 2, UInt8[T, F, 0, 0, 0, 0]; pcount = 4))
        #  THEAP is not used if PCOUNT is 0, since there is no heap
        @test_logs (:warn, r"THEAP must not be used if PCOUNT is 0") reread(
            bintablebytes([cards; "THEAP   =                    2"], 1, 2, UInt8[T, F]))

        #  a variable-length array of logical values
        cardsp = ["TFIELDS =                    1", "TFORM1  = '1PL(3)  '", "TTYPE1  = 'flags   '"]
        descriptors = UInt8[0, 0, 0, 3, 0, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0, 3]
        bytes = bintablebytes(cardsp, 8, 2, [descriptors; UInt8[T, F, N, F, T]]; pcount = 5)
        flags = reread(bytes).data.flags
        @test isequal(flags[1], [true, false, missing]) && flags[2] == [false, true]
    end

    ####    Test the TDIMn keyword (Sect. 7.3.2)    ####

    @testset "TDIMn" begin
        #  the value is a string of the form (l,m,n...), which is read as a tuple of integers
        @test FITSFiles.parsedims("(5,4,3)", 1) === (5, 4, 3)
        @test FITSFiles.parsedims("( 4, 5 ,6 )", 1) === (4, 5, 6)
        #  a single dimension is a tuple, not an integer
        @test FITSFiles.parsedims("(3)", 1) === (3,)
        #  there is no keyword, or no value
        @test FITSFiles.parsedims(nothing, 1) === nothing
        @test FITSFiles.parsedims("", 1) === nothing
        #  a value that is not of the form is ignored, with a warning
        for value in ("3", "(3,)", "()", "(a,2)", "(-1,2)", "(3,2)x", "(1.5,2)", 5)
            @test_logs (:warn, r"TDIM2 is not") @test FITSFiles.parsedims(value, 2) === nothing
        end

        #  the value is not evaluated as code
        value = "(global tdimran = true; 3)"
        @test_logs (:warn, r"TDIM1 is not") FITSFiles.parsedims(value, 1)
        @test !isdefined(FITSFiles, :tdimran)

        #  a Bintable HDU with a TDIMn keyword is read, and written with the same bytes
        card(s) = rpad(s, 80)
        header = ["SIMPLE  =                    T", "BITPIX  =                    8", "NAXIS   =                    0", "END"]
        hdr(tdim) = ["XTENSION= 'BINTABLE'", "BITPIX  =                    8", "NAXIS   =                    2",
            "NAXIS1  =                    6", "NAXIS2  =                    1", "PCOUNT  =                    0",
            "GCOUNT  =                    1", "TFIELDS =                    1", "TFORM1  = '3I      '",
            "TTYPE1  = 'a       '", tdim, "END"]
        bytes(tdim) = rpad(join(card.(header)), 2880) * rpad(join(card.(hdr(tdim))), 2880) *
            String(zeros(UInt8, 2880))
        for (tdim, shape) in (("TDIM1   = '(3)     '", (1, 3)), ("TDIM1   = '(3,1)   '", (1, 3, 1)))
            buffer = IOBuffer(bytes(tdim)); read(buffer, HDU)
            hdu = read(buffer, HDU)
            @test hdu.data.a == zeros(Int16, shape)
            io = IOBuffer(); write(io, hdu)
            @test take!(io) == codeunits(bytes(tdim))[2881:end]
        end
        buffer = IOBuffer(bytes("TDIM1   = 'evil    '")); read(buffer, HDU)
        @test_logs (:warn, r"TDIM1 is not") read(buffer, HDU)
    end

    ####    Test the character fields (Sect. 7.3.3.1)    ####

    @testset "character fields" begin
        written(hdu) = (io = IOBuffer(); write(io, hdu); take!(io))
        reread(hdu; kwds...) = read(IOBuffer(written(hdu)), HDU; kwds...)

        #  the width of a field is the number of bytes of the longest string, so no string is cut or shifts the fields after it
        for hdu in (HDU(Bintable, (s = ["ab", "cdef", ""], n = Int16[1, 2, 3])),
                    HDU(Bintable, [(s = "ab", n = Int16(1)), (s = "cdef", n = Int16(2)), (s = "", n = Int16(3))]))
            @test hdu.cards["TFORM1"] == "4A" && hdu.cards["NAXIS1"] == 6
            again = reread(hdu)
            @test again.data.s == ["ab", "cdef", ""] && again.data.n == Int16[1, 2, 3]
            @test written(again) == written(hdu)
            #  the records have the same strings, without the spaces that fill the field
            records = reread(hdu; record = true).data
            @test [r.s for r in records] == ["ab", "cdef", ""] && [r.n for r in records] == Int16[1, 2, 3]
            @test all(r -> r.s isa String, records)
        end

        #  a string that is longer than the field is an error, since it would shift the fields after it
        hdu = HDU(Bintable, (s = ["ab", "cd"], n = Int16[1, 2]))
        hdu.data.s[2] = "cdefgh"
        @test_throws ArgumentError("The string \"cdefgh\" has 6 bytes, but the field has 2 (Sect. 7.3.3.1).") written(hdu)

        #  a string ends at the first ASCII NULL, and the characters after it are not defined
        @test FITSFiles.decodestring(UInt8['a', 'b', 0, 'x', 'y']) == "ab"
        @test FITSFiles.decodestring(UInt8[0, 'x', 'y']) == ""
        @test FITSFiles.decodestring(UInt8['a', 'b', ' ', ' ']) == "ab"
        @test FITSFiles.decodestring(UInt8['a', ' ', 'b']) == "a b"
        @test FITSFiles.padstring("ab", 4) == UInt8['a', 'b', ' ', ' ']
    end

    ####    Test the variable-length arrays (Sect. 7.3.5)    ####

    @testset "variable-length arrays" begin
        written(hdu) = (io = IOBuffer(); write(io, hdu); take!(io))
        reread(hdu; kwds...) = read(IOBuffer(written(hdu)), HDU; kwds...)
        be(type, values) = collect(reinterpret(UInt8, hton.(type.(values))))
        card(s) = rpad(s, 80)
        #  the bytes of a Bintable HDU, which has the cards after TFIELDS
        function tablebytes(cards, naxis1, naxis2, data; pcount = 0)
            header = vcat(["XTENSION= 'BINTABLE'", "BITPIX  =                    8", "NAXIS   =                    2",
                "NAXIS1  = " * lpad(naxis1, 20), "NAXIS2  = " * lpad(naxis2, 20),
                "PCOUNT  = " * lpad(pcount, 20), "GCOUNT  =                    1", "TFIELDS =                    1"], cards, ["END"])
            body = vcat(data, zeros(UInt8, mod(-length(data), 2880)))
            vcat(collect(codeunits(rpad(join(card.(header)), 2880 * cld(80 * length(header), 2880)))), body)
        end

        #  data of arrays of different lengths are variable-length arrays, whose descriptor and heap are written and read
        data = (v = [Int16[1, 2, 3], Int16[], Int16[4, 5]], n = Int16[7, 8, 9])
        hdu = HDU(Bintable, data)
        @test hdu.cards["TFORM1"] == "1PI(3)" && hdu.cards["TFORM2"] == "1I"
        @test hdu.cards["NAXIS1"] == 10 && hdu.cards["PCOUNT"] == 10
        again = reread(hdu)
        @test again.data.v == data.v && again.data.n == data.n && eltype(again.data.v) == Vector{Int16}
        @test written(again) == written(hdu)
        records = reread(hdu; record = true).data
        @test [r.v for r in records] == data.v && [r.n for r in records] == data.n
        #  the same for records, and for other types of the elements
        for values in ([Float64[1.5, 2.5], Float64[3.5]], [ComplexF32[1 + 2im], ComplexF32[3im, 4]], [UInt8[1], UInt8[2, 3, 4]],
                       [Bool[true, false], Bool[true]], [Int64[1], Int64[2, 3]])
            hdu = HDU(Bintable, [(v = values[1],), (v = values[2],)])
            @test occursin("1P", hdu.cards["TFORM1"])
            again = reread(hdu)
            @test again.data.v == values && written(again) == written(hdu)
        end
        #  arrays of the same length are a fixed-size array
        @test HDU(Bintable, (v = [Int16[1, 2], Int16[3, 4]],)).cards["TFORM1"] == "2I"

        #  the undefined values of an array are missing, with TNULLn
        header = ["TFORM1  = '1PI(3)  '", "TNULL1  =               -32768"]
        bytes = tablebytes(header, 8, 2, vcat(be(Int32, [3, 0, 2, 6]), be(Int16, [1, -32768, 3, -32768, 5])); pcount = 10)
        arrays = read(IOBuffer(bytes), HDU).data.column1
        @test isequal(arrays, [[1, missing, 3], [missing, 5]])

        #  a heap that begins after a gap (THEAP), and the arrays are written as they were read
        header = ["TFORM1  = '1PI(3)  '", "THEAP   =                   20"]
        bytes = tablebytes(header, 8, 2, vcat(be(Int32, [3, 0, 2, 6]), zeros(UInt8, 4), be(Int16, [1, 2, 3, 4, 5])); pcount = 14)
        hdu = read(IOBuffer(bytes), HDU)
        @test hdu.data.column1 == [Int16[1, 2, 3], Int16[4, 5]]
        @test written(hdu) == bytes
        #  a heap that has more bytes than the arrays have is kept, and the bytes that no array uses are written as zeros
        bytes = tablebytes(["TFORM1  = '1PI(3)  '"], 8, 2, vcat(be(Int32, [3, 0, 2, 6]), be(Int16, [1, 2, 3, 4, 5, 6, 7])); pcount = 14)
        again = reread(read(IOBuffer(bytes), HDU))
        @test again.cards["PCOUNT"] == 14 && length(written(again)) == length(bytes) && again.data.column1 == [Int16[1, 2, 3], Int16[4, 5]]
        #  the arrays have more bytes than the header leaves for the heap
        hdu = read(IOBuffer(bytes), HDU)
        hdu.data.column1[1] = Int16[1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
        @test_throws ArgumentError written(hdu)
        #  the arrays that share the storage are read, and are not written as they were
        bytes = tablebytes(["TFORM1  = '1PI(3)  '"], 8, 2, vcat(be(Int32, [3, 0, 3, 0]), be(Int16, [1, 2, 3])); pcount = 6)
        hdu = read(IOBuffer(bytes), HDU)
        @test hdu.data.column1 == [Int16[1, 2, 3], Int16[1, 2, 3]]
        @test_throws ArgumentError written(hdu)

        #  array descriptors of 64 bits (Q)
        bytes = tablebytes(["TFORM1  = '1QJ(2)  '"], 16, 2, vcat(be(Int64, [2, 0, 1, 8]), be(Int32, [10, 20, 30])); pcount = 12)
        hdu = read(IOBuffer(bytes), HDU)
        @test hdu.data.column1 == [Int32[10, 20], Int32[30]] && written(hdu) == bytes

        #  an array that is not in the heap, or has a negative length, is read as empty, with a warning (the elements are undefined)
        for descriptor in ([3, 0, 5, 1000], [3, 0, -2, 0], [3, 0, 2, -6], [3, 0, 2, 8])
            bytes = tablebytes(["TFORM1  = '1PI(3)  '"], 8, 2, vcat(be(Int32, descriptor), be(Int16, [10, 20, 30, 40, 50])); pcount = 10)
            hdu = @test_logs (:warn, r"array descriptor .* of row 2 of field column1 is not in the heap of 10 bytes") read(
                IOBuffer(bytes), HDU)
            @test hdu.data.column1 == [Int16[10, 20, 30], Int16[]]
        end
        #  an array of no elements has no storage, whatever the offset is
        bytes = tablebytes(["TFORM1  = '1PI(3)  '"], 8, 2, vcat(be(Int32, [3, 0, 0, 1000]), be(Int16, [10, 20, 30])); pcount = 6)
        @test @test_logs(read(IOBuffer(bytes), HDU)).data.column1 == [Int16[10, 20, 30], Int16[]]
    end

    ####    Test the physical values of the integer fields (Sect. 7.3.2, Table 19 and Eq. 7)    ####

    @testset "physical values" begin
        written(hdu) = (io = IOBuffer(); write(io, hdu); take!(io))
        reread(hdu; kwds...) = read(IOBuffer(written(hdu)), HDU; kwds...)

        #  the unsigned integers and the signed bytes are the integers of the same size with the offset in TZERO, and are written and read
        for (type, tform, offset, values) in ((UInt16, "1I", 2^15, UInt16[0, 1, 60000, typemax(UInt16)]),
                                              (UInt32, "1J", 2^31, UInt32[0, 5, 4000000000, typemax(UInt32)]),
                                              (UInt64, "1K", UInt64(2)^63, UInt64[0, 5, UInt64(2)^62, typemax(UInt64)]),
                                              (Int8, "1B", -2^7, Int8[-128, -1, 0, 127]))
            for hdu in (HDU(Bintable, (u = values,)), HDU(Bintable, [(u = v,) for v in values]))
                @test hdu.cards["TFORM1"] == tform && hdu.cards["TZERO1"] == offset
                again = reread(hdu)
                @test again.data.u == values && eltype(again.data.u) === type && written(again) == written(hdu)
                #  the stored values have the offset
                @test eltype(reread(hdu; scale = false).data.u) === FITSFiles.RAWTYPE[type]
                @test reread(hdu; scale = false).data.u == FITSFiles.offsetvalue.(values, FITSFiles.RAWTYPE[type])
                @test eltype(reread(hdu; record = true).data[1].u) === type
            end
            #  the arrays of the fields, and the variable-length arrays
            again = reread(HDU(Bintable, (a = [values, reverse(values)],)))
            @test again.data.a == [values reverse(values)]' && eltype(again.data.a) === type
            again = reread(HDU(Bintable, (v = [values[1:2], values],)))
            @test again.data.v == [values[1:2], values] && eltype(again.data.v) === Vector{type}
        end
        #  the undefined values are TNULLn, which is the stored value
        hdu = HDU(Bintable, (u = Union{UInt16, Missing}[5, missing],), Card{<:Any}[Card("TNULL1", -32768)])
        @test isequal(reread(hdu).data.u, Union{UInt16, Missing}[5, missing])

        #  the integers of 32 or 64 bits are exact if TSCAL is 1 and TZERO is 0, and the scaled values are at least a Float64
        for (type, value) in ((Int32, 2147483647), (Int64, 2^40 + 1))
            hdu = HDU(Bintable, (a = type[value, 3],))
            @test reread(hdu).data.a == type[value, 3] && eltype(reread(hdu).data.a) === type
            hdu = HDU(Bintable, (a = type[value, 3],), Card{<:Any}[Card("TSCAL1", 0.5f0), Card("TZERO1", 1.0f0)])
            scaled = reread(hdu).data.a
            @test eltype(scaled) === Float64 && scaled == 1.0 .+ 0.5 .* Float64.(type[value, 3])
            #  the scaled values are written as the stored values
            @test written(reread(hdu; record = true)) == written(hdu)
            @test written(reread(hdu)) == written(hdu)
        end
        #  an Int16 and a Float32 scale are a Float32
        hdu = HDU(Bintable, (a = Int16[1, 2],), Card{<:Any}[Card("TSCAL1", 0.5f0)])
        @test eltype(reread(hdu).data.a) === Float32 && reread(hdu).data.a == Float32[0.5, 1]
    end

    ####    Test the arrays of the fields that have more than one dimension (TDIMn, Sect. 7.3.2)    ####

    @testset "multi-dimensional fields" begin
        written(hdu) = (io = IOBuffer(); write(io, hdu); take!(io))
        reread(hdu; kwds...) = read(IOBuffer(written(hdu)), HDU; kwds...)
        card(s) = rpad(s, 80)
        #  the bytes of a Bintable HDU of one field that has the cards after TFIELDS
        function tablebytes(cards, naxis1, naxis2, data)
            header = vcat(["XTENSION= 'BINTABLE'", "BITPIX  =                    8", "NAXIS   =                    2",
                "NAXIS1  = " * lpad(naxis1, 20), "NAXIS2  = " * lpad(naxis2, 20),
                "PCOUNT  =                    0", "GCOUNT  =                    1", "TFIELDS =                    1"], cards, ["END"])
            vcat(collect(codeunits(rpad(join(card.(header)), 2880 * cld(80 * length(header), 2880)))),
                data, zeros(UInt8, mod(-length(data), 2880)))
        end

        #  the arrays of the cells that have more than one dimension have the dimensions in TDIMn, and are read with them: the rows are
        #  the first dimension of the column
        cells = [Float32[1 2; 3 4; 5 6], Float32[7 8; 9 10; 11 12]]
        for hdu in (HDU(Bintable, (a = cells,)), HDU(Bintable, [(a = cell,) for cell in cells]))
            @test hdu.cards["TFORM1"] == "6E" && hdu.cards["TDIM1"] == "(3,2)"
            again = reread(hdu)
            @test size(again.data.a) == (2, 3, 2) && again.data.a[1, :, :] == cells[1] && again.data.a[2, :, :] == cells[2]
            @test written(again) == written(hdu)
            records = reread(hdu; record = true).data
            @test [r.a for r in records] == cells
        end
        #  a column of two or more dimensions is the array of each row
        column = reshape(Int16.(1:12), 2, 3, 2)
        hdu = HDU(Bintable, (a = column,))
        @test hdu.cards["TFORM1"] == "6I" && hdu.cards["TDIM1"] == "(3,2)" && hdu.cards["NAXIS2"] == 2
        @test reread(hdu).data.a == column
        hdu = HDU(Bintable, (a = Int16[1 2 3; 4 5 6],))
        @test hdu.cards["TFORM1"] == "3I" && !haskey(hdu.cards, "TDIM1") && reread(hdu).data.a == Int16[1 2 3; 4 5 6]

        #  the dimensions of TDIMn hold no more elements than TFORMn has, and the elements that are not in the array are not read
        data = vcat(reinterpret(UInt8, hton.(Int16[1, 2, 3, 4, 5, 6, 7, 8])))
        bytes = tablebytes(["TFORM1  = '4I      '", "TDIM1   = '(3,1)   '"], 8, 2, data)
        hdu = read(IOBuffer(bytes), HDU)
        @test hdu.data.column1 == reshape(Int16[1, 5, 2, 6, 3, 7], 2, 3, 1)
        #  and more elements than TFORMn has are ignored with a warning
        bytes = tablebytes(["TFORM1  = '4I      '", "TDIM1   = '(3,2)   '"], 8, 2, data)
        hdu = @test_logs (:warn, r"TDIM of field column1, 3 × 2, has 6 elements, more than the 4 of its TFORM") read(IOBuffer(bytes), HDU)
        @test hdu.data.column1 == Int16[1 2 3 4; 5 6 7 8]

        #  arrays of strings, whose first dimension is the number of characters of a string
        text = collect(codeunits("abcdef" * "ghijkl"))
        bytes = tablebytes(["TFORM1  = '6A      '", "TDIM1   = '(2,3)   '"], 6, 2, text)
        strings = read(IOBuffer(bytes), HDU).data.column1
        @test strings == ["ab" "cd" "ef"; "gh" "ij" "kl"] && size(strings) == (2, 3)
        #  a single dimension is a string
        bytes = tablebytes(["TFORM1  = '6A      '", "TDIM1   = '(6)     '"], 6, 2, text)
        @test read(IOBuffer(bytes), HDU).data.column1 == ["abcdef", "ghijkl"]
        records = read(IOBuffer(tablebytes(["TFORM1  = '6A      '", "TDIM1   = '(2,3)   '"], 6, 2, text)), HDU; record = true).data
        @test records[2].column1 == ["gh", "ij", "kl"]

        #  the arrays of variable-length arrays, and of bits
        bytes = tablebytes(["TFORM1  = '1PI(6)  '", "TDIM1   = '(2,2)   '"], 8, 2,
            vcat(reinterpret(UInt8, hton.(Int32[4, 0, 6, 8])), reinterpret(UInt8, hton.(Int16[1, 2, 3, 4, 5, 6, 7, 8, 9, 10]))))
        header = replace(String(copy(bytes)), "PCOUNT  =                    0" => "PCOUNT  =                   20")
        hdu = read(IOBuffer(codeunits(header)), HDU)
        @test hdu.data.column1 == [Int16[1 3; 2 4], Int16[5 7; 6 8]]
    end

    ####    Test the verification of the header (Sects. 4.4.1.2, 7.3.1, and 7.3.2)    ####

    @testset "header verification" begin
        #  the headers that are read are not standard, so they are written with the check turned off, as they are read (see `problem`)
        written(hdu; check = false) = (io = IOBuffer(); write(io, hdu; check); take!(io))
        card(s) = rpad(s, 80)
        kw(key, value) = key * repeat(" ", 8 - length(key)) * "= " * lpad(value isa AbstractString ? "'" * rpad(value, 8) * "'" : string(value),
            value isa AbstractString ? 10 : 20)
        #  the bytes of a Bintable HDU of the keywords, which are the mandatory ones and the others, and the bytes of the table
        function tablebytes(others, data; naxis1 = 2, naxis2 = 2, tfields = 1, mandatory = nothing)
            header = something(mandatory, [kw("XTENSION", "BINTABLE"), kw("BITPIX", 8), kw("NAXIS", 2), kw("NAXIS1", naxis1),
                kw("NAXIS2", naxis2), kw("PCOUNT", 0), kw("GCOUNT", 1), kw("TFIELDS", tfields)])
            header = vcat(header, others, ["END"])
            vcat(collect(codeunits(rpad(join(card.(header)), 2880 * cld(80 * length(header), 2880)))),
                data, zeros(UInt8, mod(-length(data), 2880)))
        end
        reading(bytes) = read(IOBuffer(bytes), HDU)
        stored = collect(reinterpret(UInt8, hton.(Int16[1, 2])))
        tform = kw("TFORM1", "I")

        #  a header that conforms is read without a warning
        @test @test_logs(reading(tablebytes([tform], stored))).data.column1 == Int16[1, 2]

        #  the number of bytes of a row is the sum of the bytes of the fields (Eq. 8)
        @test_throws ArgumentError("NAXIS1 is 1, but the fields of TFORMn have 2 bytes in a row, which is the value that NAXIS1 must have " *
            "(Eq. 8, Sect. 7.3.1).") reading(tablebytes([tform], stored; naxis1 = 1))
        #  the bytes after the fields are not read, and are written as zeros
        padded = vcat(stored[1:2], UInt8[7, 7, 7, 7], stored[3:4], UInt8[8, 8, 8, 8])
        hdu = @test_logs (:warn, r"NAXIS1 is 6, but the fields of TFORMn have 2 bytes in a row") reading(
            tablebytes([tform], padded; naxis1 = 6))
        @test hdu.data.column1 == Int16[1, 2] && hdu.cards["NAXIS1"] == 6
        again = reading(written(hdu))
        @test again.data.column1 == Int16[1, 2] && again.cards["NAXIS1"] == 6
        #  the written rows have zeros after the fields
        @test written(hdu)[2881:2880 + 12] == UInt8[0, 1, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0]
        #  the fields of the sum of bytes include arrays, bits, strings, complex values, and array descriptors
        forms = ["3I", "9X", "4A", "2C", "1PJ(3)", "0PI", "1QD(2)", "0I", "0X"]
        sizes = [6, 2, 4, 16, 8, 0, 16, 0, 0]
        for (form, nbytes) in zip(forms, sizes)
            @test FITSFiles.tformbytes("TFORM1", form) == nbytes
        end
        @test FITSFiles.tformbytes("TFORM1", "B") == 1 && FITSFiles.tformbytes("TFORM1", "2M") == 32

        #  TFORMn is of the form rTa, with a data type of Table 18 in upper case
        for value in ("e", "5i", "1pj(3)", "5Z", "", "x", "3")
            @test_throws ArgumentError reading(tablebytes([kw("TFORM1", value)], stored))
        end
        err = try reading(tablebytes([kw("TFORM1", "e")], stored)) catch e e end
        @test occursin("must be upper case", err.msg) && occursin("Sect. 7.3.1", err.msg)
        err = try reading(tablebytes([kw("TFORM1", "5Z")], stored)) catch e e end
        @test occursin("data type of Table 18", err.msg) && !occursin("upper case", err.msg)
        @test_throws ArgumentError reading(tablebytes([kw("TFORM1", 5)], stored))

        #  the mandatory keywords are in order and in fixed format
        swapped = [kw("XTENSION", "BINTABLE"), kw("BITPIX", 8), kw("NAXIS", 2), kw("NAXIS2", 2), kw("NAXIS1", 2), kw("PCOUNT", 0),
            kw("GCOUNT", 1), kw("TFIELDS", 1)]
        @test_logs (:warn, r"Keyword 4 of the header is NAXIS2, but the Standard requires NAXIS1") reading(
            tablebytes([tform], stored; mandatory = swapped))
        free = [kw("XTENSION", "BINTABLE"), kw("BITPIX", 8), kw("NAXIS", 2), "NAXIS1  = 2", kw("NAXIS2", 2), kw("PCOUNT", 0),
            kw("GCOUNT", 1), kw("TFIELDS", 1)]
        @test_logs (:warn, r"The value of NAXIS1 is not in fixed format") reading(tablebytes([tform], stored; mandatory = free))
        #  PCOUNT and GCOUNT have the values 0 and 1, and BITPIX and NAXIS are needed
        nocounts = [kw("XTENSION", "BINTABLE"), kw("BITPIX", 8), kw("NAXIS", 2), kw("NAXIS1", 2), kw("NAXIS2", 2), kw("TFIELDS", 1)]
        @test_logs (:warn, r"PCOUNT is missing, but it is a mandatory keyword") (:warn, r"GCOUNT is missing") reading(
            tablebytes([tform], stored; mandatory = nocounts))
        @test_throws ArgumentError("BITPIX is missing, but it is a mandatory keyword of a BINTABLE extension (Sect. 7.3.1).") reading(
            tablebytes([tform], stored; mandatory = [kw("XTENSION", "BINTABLE"), kw("NAXIS", 0)]))
        #  the keywords of the primary header, and of the physical blocks, are not in an extension
        for key in ("EXTEND", "BLOCKED")
            @test_logs (:warn, Regex("$key must not appear in a BINTABLE extension header")) reading(
                tablebytes([tform, "$key  =                    T"], stored))
        end
        @test_logs (:warn, r"SIMPLE must not appear") reading(tablebytes([tform, "SIMPLE  =                    T"], stored))
        #  INHERIT is a logical, immediately after the mandatory keywords
        @test_logs (:warn, r"INHERIT must be the keyword immediately after the mandatory keywords, keyword 9") reading(
            tablebytes([tform, "INHERIT =                    T"], stored))
        @test @test_logs(reading(tablebytes(["INHERIT =                    T", tform], stored))).data.column1 == Int16[1, 2]
        @test_logs (:warn, r"INHERIT must be a logical") reading(tablebytes(["INHERIT =                    1", tform], stored))

        #  TSCALn and TZEROn are for the fields that are not of type A, L, or X, and TNULLn is for the fields of type B, I, J, or K
        for form in ("A", "L", "X")
            @test_logs (:warn, Regex("TSCAL1 and TZERO1 must not be used for a field of type $form")) reading(
                tablebytes([kw("TFORM1", form), kw("TSCAL1", 2.0)], UInt8[0x54, 0x46]; naxis1 = 1))
        end
        @test_logs (:warn, r"TNULL1 must not be used for a field of type E") reading(
            tablebytes([kw("TFORM1", "E"), kw("TNULL1", 5)], zeros(UInt8, 8); naxis1 = 4))
        #  and the keywords are not used for those fields
        hdu = @test_logs (:warn, r"TSCAL1 and TZERO1 must not") reading(
            tablebytes([kw("TFORM1", "L"), kw("TSCAL1", 2.0)], UInt8[0x54, 0x46]; naxis1 = 1))
        @test hdu.data.column1 == [true, false]
        for form in ("B", "I", "J", "K", "1PI(2)", "1QB(2)")
            @test_logs reading(tablebytes([kw("TFORM1", form), kw("TNULL1", 5)], zeros(UInt8, 32); naxis1 = FITSFiles.tformbytes("TFORM1", form), naxis2 = 1))
        end

        #  TTYPEn and TUNITn are character strings, TUNITn is a units string, and TDISPn is a display format of Table 20
        hdu = @test_logs (:warn, r"TTYPE1 must be a character string") reading(tablebytes([tform, kw("TTYPE1", 5)], stored))
        @test hdu.data.column1 == Int16[1, 2]
        @test_logs (:warn, r"TUNIT1 must be a character string") reading(tablebytes([tform, kw("TUNIT1", 5)], stored))
        @test_logs (:warn, r"TDISP1 must be a character string") reading(tablebytes([tform, kw("TDISP1", 5)], stored))
        @test_logs (:warn, r"TUNIT1 must be a units string") reading(tablebytes([tform, kw("TUNIT1", "bogus unit!")], stored))
        @test @test_logs(reading(tablebytes([tform, kw("TUNIT1", "km/s")], stored))).data.column1 == Int16[1, 2]
        for disp in ("I6", "I6.3", "B8.8", "O5", "Z4.2", "F8.3", "E12.4", "E12.4E3", "EN12.3", "ES12.3", "G10.2", "G10.2E2", "D12.4")
            @test_logs reading(tablebytes([tform, kw("TDISP1", disp)], stored))
        end
        for disp in ("Q9.9", "i6", "F8", "E12", "I", "A", "F8.3.1", "Iw.m", " ", "e12.4")
            isempty(strip(disp)) && continue
            @test_logs (:warn, r"TDISP1 must be a display format of Table 20") reading(tablebytes([tform, kw("TDISP1", disp)], stored))
        end
        #  the numbers
        @test_throws ArgumentError reading(tablebytes([tform, kw("TSCAL1", "two")], stored))
        @test_throws ArgumentError reading(tablebytes([tform, kw("TDMIN1", "low")], stored))
        @test @test_logs(reading(tablebytes([tform, kw("TDMIN1", 1), kw("TDMAX1", 2), kw("TLMIN1", -1), kw("TLMAX1", 3)], stored))).data.column1 == Int16[1, 2]

        #  the names of the fields are unique without regard to the case
        two = [kw("TFORM1", "I"), kw("TTYPE1", "Flux"), kw("TFORM2", "I"), kw("TTYPE2", "FLUX")]
        @test_logs (:warn, r"TTYPE2 and TTYPE1 have the same name, \"FLUX\", without regard to the case") reading(
            tablebytes(two, vcat(stored, stored); naxis1 = 4, tfields = 2))
        @test @test_logs(reading(tablebytes([kw("TFORM1", "I"), kw("TTYPE1", "Flux"), kw("TFORM2", "I"), kw("TTYPE2", "Error")],
            vcat(stored, stored); naxis1 = 4, tfields = 2))).data.Error == Int16[2, 2]
    end

    ####    Test a table that has no rows (Sect. 7.3.1)    ####

    @testset "no rows" begin
        written(hdu) = (io = IOBuffer(); write(io, hdu); take!(io))
        reread(hdu; kwds...) = read(IOBuffer(written(hdu)), HDU; kwds...)

        #  the table has no data blocks, and the data are the empty columns of the fields, which have the types of the fields
        hdu = HDU(Bintable, (a = Int16[], s = String[], u = UInt16[], f = Float64[]))
        @test hdu.cards["NAXIS2"] == 0 && hdu.cards["TFIELDS"] == 4
        again = reread(hdu)
        @test again.data isa NamedTuple && keys(again.data) == (:a, :s, :u, :f)
        @test again.data.a isa Vector{Int16} && again.data.s isa Vector{String} && again.data.u isa Vector{UInt16} &&
            again.data.f isa Vector{Float64}
        @test all(isempty, again.data) && written(again) == written(hdu)
        @test isempty(reread(hdu; record = true).data)
        #  the table of no fields has no data
        @test ismissing(HDU(Bintable).data) && ismissing(reread(HDU(Bintable)).data)
        @test written(reread(HDU(Bintable))) == written(HDU(Bintable))
    end

    ####    Test the bit arrays (Sect. 7.3.3.1)    ####

    @testset "bit arrays" begin
        #  the bits are in order from the most significant bit of the first byte, and the bits after the end are zeros
        bits = BitVector([1, 0, 1, 1, 0, 0, 0, 0, 0, 1])
        io = IOBuffer(); write(io, BitVector, bits)
        @test take!(io) == UInt8[0b10110000, 0b01000000]
        @test read(IOBuffer(UInt8[0b10110000, 0b01000000]), BitVector, 10) == bits
        @test read(IOBuffer(UInt8[0b10110000, 0b01111111]), BitVector, 10) == bits
        @test read(IOBuffer(UInt8[0xff]), BitVector, 3) == BitVector([1, 1, 1])
        @test read(IOBuffer(UInt8[]), BitVector, 0) == BitVector()
        io = IOBuffer(); write(io, BitVector, BitVector()); @test isempty(take!(io))
        for n in (1, 7, 8, 9, 16, 17, 100)
            value = BitVector(rand(Bool, n))
            io = IOBuffer(); write(io, BitVector, value)
            bytes = take!(io)
            @test length(bytes) == cld(n, 8) && read(IOBuffer(bytes), BitVector, n) == value
            @test all(j -> (bytes[(j-1) >> 3 + 1] >> (7 - (j-1) % 8)) & 1 == value[j], 1:n)
        end

        #  the bits of a field of a table, which are in order of the bytes of the file
        written(hdu) = (io = IOBuffer(); write(io, hdu); take!(io))
        hdu = HDU(Bintable, (b = [bits, falses(10)],))
        @test hdu.cards["TFORM1"] == "10X" && hdu.cards["NAXIS1"] == 2
        bytes = written(hdu)
        @test bytes[2881:2884] == UInt8[0b10110000, 0b01000000, 0, 0]
        @test read(IOBuffer(bytes), HDU).data.b == [bits, falses(10)]
        #  the bit arrays of different lengths have the length of the longest, and the bits after the end are zeros
        hdu = HDU(Bintable, (b = [BitVector([1, 0, 0, 0, 0, 0, 0, 1, 1]), BitVector([0, 1])],))
        @test hdu.cards["TFORM1"] == "9X"
        @test read(IOBuffer(written(hdu)), HDU).data.b == [BitVector([1, 0, 0, 0, 0, 0, 0, 1, 1]), BitVector([0, 1, 0, 0, 0, 0, 0, 0, 0])]
    end

    ####    Test the width of the fields that are written (Sect. 7.3.1)    ####

    @testset "width of fields" begin
        written(hdu) = (io = IOBuffer(); write(io, hdu); take!(io))
        card(s) = rpad(s, 80)
        function tablebytes(cards, naxis1, naxis2, data)
            header = vcat(["XTENSION= 'BINTABLE'", "BITPIX  =                    8", "NAXIS   =                    2",
                "NAXIS1  = " * lpad(naxis1, 20), "NAXIS2  = " * lpad(naxis2, 20), "PCOUNT  =                    0",
                "GCOUNT  =                    1", "TFIELDS =                    1"], cards, ["END"])
            vcat(collect(codeunits(rpad(join(card.(header)), 2880 * cld(80 * length(header), 2880)))),
                data, zeros(UInt8, mod(-length(data), 2880)))
        end

        #  the elements of the field that TDIMn does not use are written as zeros, so the rows have the same bytes
        data = collect(reinterpret(UInt8, hton.(Int16[1, 2, 3, 4, 5, 6, 7, 8])))
        bytes = tablebytes(["TFORM1  = '4I      '", "TDIM1   = '(3,1)   '"], 8, 2, data)
        hdu = read(IOBuffer(bytes), HDU)
        @test size(hdu.data.column1) == (2, 3, 1)
        again = written(hdu)
        @test length(again) == length(bytes) && again[2881:2880 + 16] == collect(reinterpret(UInt8, hton.(Int16[1, 2, 3, 0, 5, 6, 7, 0])))
        @test read(IOBuffer(again), HDU).data.column1 == hdu.data.column1
        #  the same for the bits, the logical values, and the array of a record
        for (form, dim, nbytes, unused) in (("10X", "(3,1)", 2, UInt8[0]), ("5L", "(2,2)", 5, UInt8[0]))
            data = form == "10X" ? UInt8[0xff, 0xff, 0xff, 0xff] : collect(codeunits("TFTFTFTFTF"))
            hdu = read(IOBuffer(tablebytes(["TFORM1  = '$form'", "TDIM1   = '$dim'"], nbytes, 2, data)), HDU)
            again = written(hdu)
            @test length(again) == 5760 && read(IOBuffer(again), HDU).data.column1 == hdu.data.column1
        end
        bytes = written(HDU(Bintable, (b = [BitVector([1, 0, 0, 0, 0, 0, 0, 1, 1]), BitVector([0, 1])], n = Int16[5, 6])))
        @test bytes[2881:2888] == UInt8[0b10000001, 0b10000000, 0, 5, 0b01000000, 0, 0, 6]

        #  an array that has more elements than the field has is an error, since it would shift the fields after it
        hdu = HDU(Bintable, (a = [Int16[1, 2, 3], Int16[4, 5, 6]], n = Int16[7, 8]))
        hdu.data.a[2] = Int16[1, 2, 3, 4]
        @test_throws ArgumentError("The array of field a has 4 elements, but the field has 3 (Sect. 7.3.1).") written(hdu)
        hdu.data.a[2] = Int16[1, 2]
        @test read(IOBuffer(written(hdu)), HDU).data.n == Int16[7, 8]
    end

    ####    Test the names of the fields (Sect. 7.3.2)    ####

    @testset "names of fields" begin
        written(hdu) = (io = IOBuffer(); write(io, hdu); take!(io))
        card(s) = rpad(s, 80)
        kw(key, value) = key * repeat(" ", 8 - length(key)) * "= " * (value isa AbstractString ? "'" * rpad(value, 8) * "'" : lpad(value, 20))
        function tablebytes(cards, naxis1, data)
            header = vcat(["XTENSION= 'BINTABLE'", kw("BITPIX", 8), kw("NAXIS", 2), kw("NAXIS1", naxis1), kw("NAXIS2", 1),
                kw("PCOUNT", 0), kw("GCOUNT", 1), kw("TFIELDS", length(cards) ÷ 2)], cards, ["END"])
            vcat(collect(codeunits(rpad(join(card.(header)), 2880 * cld(80 * length(header), 2880)))),
                data, zeros(UInt8, mod(-length(data), 2880)))
        end
        data = collect(reinterpret(UInt8, hton.(Int16[1, 2, 3])))

        #  fields that have the same name are different columns, which the data name by their positions, and an empty name is the default
        cards = [kw("TFORM1", "I"), kw("TTYPE1", "A"), kw("TFORM2", "I"), kw("TTYPE2", "A"), kw("TFORM3", "I"), kw("TTYPE3", "")]
        bytes = tablebytes(cards[[1, 2, 3, 4, 5, 6]], 6, data)
        hdu = @test_logs (:warn, r"TTYPE2 and TTYPE1 have the same name, \"A\", without regard to the case.* named A_2") read(IOBuffer(bytes), HDU)
        @test keys(hdu.data) == (:A, :A_2, :column3) && values(hdu.data) == (Int16[1], Int16[2], Int16[3])
        records = read(IOBuffer(bytes), HDU; record = true).data
        @test keys(records[1]) == (:A, :A_2, :column3) && values(records[1]) == (1, 2, 3)
        #  the columns are written as they were read
        @test written(hdu) == bytes[1:end]
        #  a name that is a repeat of a repeat
        cards3 = [kw("TFORM1", "I"), kw("TTYPE1", "A_2"), kw("TFORM2", "I"), kw("TTYPE2", "A_2"), kw("TFORM3", "I"), kw("TTYPE3", "A_2")]
        hdu = @test_logs (:warn, r"TTYPE2") (:warn, r"TTYPE3") read(IOBuffer(tablebytes(cards3, 6, data)), HDU)
        @test length(unique(keys(hdu.data))) == 3 && values(hdu.data) == (Int16[1], Int16[2], Int16[3])
    end

    ####    Test the arrays of strings (Sect. 7.3.2)    ####

    @testset "arrays of strings" begin
        written(hdu) = (io = IOBuffer(); write(io, hdu); take!(io))
        reread(hdu; kwds...) = read(IOBuffer(written(hdu)), HDU; kwds...)
        card(s) = rpad(s, 80)

        #  a column of arrays of strings has the number of bytes of the longest string as the first dimension of TDIMn
        hdu = HDU(Bintable, (s = ["ab" "cd" "ef"; "gh" "ij" "kl"],))
        @test hdu.cards["TFORM1"] == "6A" && hdu.cards["TDIM1"] == "(2,3)" && hdu.cards["NAXIS1"] == 6 && hdu.cards["NAXIS2"] == 2
        again = reread(hdu)
        @test again.data.s == ["ab" "cd" "ef"; "gh" "ij" "kl"] && written(again) == written(hdu)
        @test reread(hdu; record = true).data[2].s == ["gh", "ij", "kl"]
        #  the cells that are arrays of strings, whose strings are filled with spaces to the longest
        for hdu in (HDU(Bintable, [(s = ["a", "bcd"],), (s = ["ef", "g"],)]), HDU(Bintable, (s = [["a", "bcd"], ["ef", "g"]],)))
            @test hdu.cards["TFORM1"] == "6A" && hdu.cards["TDIM1"] == "(3,2)"
            @test reread(hdu).data.s == ["a" "bcd"; "ef" "g"]
            @test [r.s for r in reread(hdu; record = true).data] == [["a", "bcd"], ["ef", "g"]]
        end
        #  the strings of an array have the same size, and a string that is longer than the field is an error
        @test_throws ArgumentError HDU(Bintable, [(s = ["a", "b"],), (s = ["c"],)])
        hdu = HDU(Bintable, (s = ["ab" "cd"; "ef" "gh"],))
        hdu.data.s[1, 1] = "abc"
        @test_throws ArgumentError("The string \"abc\" has 3 bytes, but the field has 2 (Sect. 7.3.3.1).") written(hdu)

        #  a file of strings is written as it was read, and the strings that do not fill the field are filled with spaces
        header = ["XTENSION= 'BINTABLE'", "BITPIX  =                    8", "NAXIS   =                    2", "NAXIS1  =                    8",
            "NAXIS2  =                    1", "PCOUNT  =                    0", "GCOUNT  =                    1", "TFIELDS =                    1",
            "TFORM1  = '8A      '", "TDIM1   = '(2,3)   '", "END"]
        bytes = vcat(collect(codeunits(rpad(join(card.(header)), 2880))), collect(codeunits("ab  cd  ")), zeros(UInt8, 2880 - 8))
        hdu = read(IOBuffer(bytes), HDU)
        @test hdu.data.column1 == ["ab" "" "cd"]
        @test written(hdu) == bytes
    end

    ####    Test the types of the fields (Sects. 7.3.3 and 7.3.3.1)    ####

    @testset "types of fields" begin
        #  the data of a type that Table 18 does not have are an error that names the types, whatever the shape of the data is
        for data in (Float16[1, 2], [:a, :b], ['a', 'b'], Int128[1, 2], UInt128[1, 2], BigFloat[1, 2], Float16[1 2; 3 4],
                     [Float16[1, 2], Float16[3]], [Int128[1, 2], Int128[3, 4]])
            for hdu in (() -> HDU(Bintable, (u = data,)), () -> HDU(Bintable, [(u = x,) for x in data]))
                err = try hdu() catch e e end
                @test err isa ArgumentError && occursin("The data have the element type", err.msg)
                @test err isa ArgumentError && occursin("Table 18", err.msg) && occursin("Table 19", err.msg) && occursin("UInt16", err.msg)
            end
        end
        #  the types of Table 18 and the physical types of Table 19 are fields
        for (type, tform) in ((UInt8, "B"), (Int16, "I"), (Int32, "J"), (Int64, "K"), (Float32, "E"), (Float64, "D"), (ComplexF32, "C"),
                              (ComplexF64, "M"), (Bool, "L"), (Int8, "B"), (UInt16, "I"), (UInt32, "J"), (UInt64, "K"))
            @test HDU(Bintable, (u = type[1, 0],)).cards["TFORM1"] == "1$tform"
        end
        @test HDU(Bintable, (u = ["ab"], b = [BitVector([1, 0])])).cards["TFORM1"] == "2A"

        #  the characters of a field are ASCII text, so a string that has other characters is an error when the data are written, unless the check is turned
        #  off, where the bytes of the strings are written, and are read as they are
        for data in (["é"], ["abc", "naïve"], ["日本"])
            hdu = HDU(Bintable, (s = data,))
            err = try write(IOBuffer(), hdu) catch e e end
            @test err isa ArgumentError && occursin("are not ASCII", err.msg) && occursin("Sect. 7.3.3.1", err.msg) && occursin("check = false", err.msg)
            @test_throws ArgumentError write(IOBuffer(), HDU(Bintable, [(s = x,) for x in data]))
            @test getfield(hdu, :cards)["TFORM1"] == "$(maximum(ncodeunits, data))A"
            io = IOBuffer()
            write(io, [HDU(Primary), hdu]; check = false)
            @test @test_logs((:warn, r"not ASCII text characters"), fits(IOBuffer(take!(io)))[2].data.s) == data
        end
        @test FITSFiles.checkascii("abc ~") == "abc ~" && FITSFiles.checkascii("é"; check = false) == "é"
        @test_throws ArgumentError FITSFiles.padstring("é", 4)
        @test FITSFiles.padstring("é", 4; check = false) == [0xc3, 0xa9, 0x20, 0x20]
    end

    ####    Test the undefined complex values (Sect. 7.3.3.1)    ####

    @testset "complex values" begin
        written(hdu) = (io = IOBuffer(); write(io, hdu); take!(io))
        reread(hdu; kwds...) = read(IOBuffer(written(hdu)), HDU; kwds...)
        card(s) = rpad(s, 80)
        #  a complex value that has a NaN in either part is undefined, as a whole
        header = ["XTENSION= 'BINTABLE'", "BITPIX  =                    8", "NAXIS   =                    2", "NAXIS1  =                    8",
            "NAXIS2  =                    4", "PCOUNT  =                    0", "GCOUNT  =                    1", "TFIELDS =                    1",
            "TFORM1  = 'C       '", "END"]
        values = Float32[1, 2, NaN, 3, 4, NaN, NaN, NaN]
        bytes = vcat(collect(codeunits(rpad(join(card.(header)), 2880))), collect(reinterpret(UInt8, hton.(values))), zeros(UInt8, 2880 - 32))
        column = read(IOBuffer(bytes), HDU).data.column1
        @test isequal(column, Union{ComplexF32, Missing}[1 + 2im, missing, missing, missing])
        @test eltype(column) == Union{ComplexF32, Missing}
        #  a column that has no undefined values is not changed
        @test eltype(reread(HDU(Bintable, (c = ComplexF32[1 + 2im, 3 - 1im],))).data.c) == ComplexF32
        #  the undefined values are written as NaN, and are read as undefined, for the fields, the arrays, and the variable-length arrays
        for data in ((c = Union{ComplexF32, Missing}[1 + 2im, missing, 3im],),
                     (c = [Union{ComplexF64, Missing}[1im, missing], Union{ComplexF64, Missing}[3, 4]],),
                     (c = [Union{ComplexF64, Missing}[1im, missing], Union{ComplexF64, Missing}[3, 4, 5]],))
            hdu = HDU(Bintable, data)
            again = reread(hdu)
            @test isequal(again.data.c, reread(hdu).data.c) && written(again) == written(hdu)
            @test count(ismissing, collect(Iterators.flatten(x isa AbstractArray ? x : [x] for x in again.data.c))) == 1
        end
        hdu = HDU(Bintable, (c = Union{ComplexF32, Missing}[1 + 2im, missing],))
        @test isequal(reread(hdu).data.c, Union{ComplexF32, Missing}[1 + 2im, missing])
        @test isequal(reread(hdu; record = true).data[2].c, missing)
        #  the scale applies to the real part of the complex value, and an undefined value stays undefined
        hdu = HDU(Bintable, (c = Union{ComplexF32, Missing}[1 + 2im, missing],), Card{<:Any}[Card("TSCAL1", 2.0f0), Card("TZERO1", 1.0f0)])
        @test isequal(reread(hdu).data.c, Union{ComplexF32, Missing}[3 + 4im, missing])
    end

    ####    Test the scaled floating-point fields (Sect. 7.3.2, Eq. 7)    ####

    @testset "scaled floating-point fields" begin
        written(hdu) = (io = IOBuffer(); write(io, hdu); take!(io))
        reread(hdu; kwds...) = read(IOBuffer(written(hdu)), HDU; kwds...)
        scaledcards(scale, zero) = Card{<:Any}[Card("TSCAL1", scale), Card("TZERO1", zero)]
        be(type, values) = collect(reinterpret(UInt8, hton.(type.(values))))

        #  the physical values of the stored values of a field that is scaled are a ScaledArray, which the values do not say by their type,
        #  and the field is written as the stored values: the stored values of the file are the same after it is read and written
        for (type, tform, stored) in ((Float32, "E", [1, 2]), (Float64, "D", [1, 2]), (ComplexF32, "C", [1 + 1im, 2 - 2im]),
                                      (ComplexF64, "M", [1 + 1im, 2 - 2im]))
            hdu = HDU(Bintable, (a = type.(stored),), scaledcards(2.0f0, 1.0f0))
            @test hdu.cards["TFORM1"] == "1$tform"
            bytes = written(hdu)
            again = read(IOBuffer(bytes), HDU)
            @test again.data.a isa FITSFiles.ScaledArray && again.data.a == 1 .+ 2 .* type.(stored) && eltype(again.data.a) == type
            @test written(again) == bytes
            #  the values that are changed are inverted
            again.data.a[1] = type(5)
            @test read(IOBuffer(written(again)), HDU; scale = false).data.a == type.([2, stored[2]])
            @test read(IOBuffer(written(again)), HDU).data.a[1] == type(5)
            #  without the scale, the stored values are an array
            plain = read(IOBuffer(bytes), HDU; scale = false).data.a
            @test !(plain isa FITSFiles.ScaledArray) && plain == type.(stored)
        end
        #  the arrays of the fields, the variable-length arrays, and the records
        hdu = HDU(Bintable, (a = Float32[1 2 3; 4 5 6], v = [Float64[1, 2], Float64[3]]), Card{<:Any}[Card("TSCAL1", 0.5f0), Card("TZERO1", 2.0f0),
            Card("TSCAL2", 3.0), Card("TZERO2", -1.0)])
        bytes = written(hdu)
        again = read(IOBuffer(bytes), HDU)
        @test again.data.a isa FITSFiles.ScaledArray && size(again.data.a) == (2, 3) && again.data.a == 2 .+ 0.5 .* Float32[1 2 3; 4 5 6]
        @test all(cell -> cell isa FITSFiles.ScaledArray, again.data.v) && again.data.v == [[2.0, 5.0], [8.0]]
        @test written(again) == bytes
        records = read(IOBuffer(bytes), HDU; record = true)
        @test records.data isa FITSFiles.ScaledTable && records.data[2].a == [4.0, 4.5, 5.0] && records.data[1].v == [2.0, 5.0]
        @test written(records) == bytes
        records.data[2] = (a = Float32[10, 20, 30], v = records.data[2].v)
        @test read(IOBuffer(written(records)), HDU; scale = false).data.a == Float32[1 2 3; 16 36 56] ./ 1
        #  the data of floating-point values that are not scaled are not a ScaledArray
        @test !(reread(HDU(Bintable, (a = Float32[1, 2],))).data.a isa FITSFiles.ScaledArray)
        @test !(reread(HDU(Bintable, (a = Float32[1, 2],), scaledcards(1.0f0, 0.0f0))).data.a isa FITSFiles.ScaledArray)
        @test !(reread(HDU(Bintable, [(a = 1.0f0,)])).data.a isa FITSFiles.ScaledTable)

        #  the data that are a ScaledArray have the scale and the zero in the header, and plain values are the stored values
        hdu = HDU(Bintable, (a = FITSFiles.ScaledArray(Float32[3, 5], 2.0f0, 1.0f0), n = Int16[1, 2]))
        @test hdu.cards["TSCAL1"] == 2.0f0 && hdu.cards["TZERO1"] == 1.0f0 && !haskey(hdu.cards, "TSCAL2")
        @test reread(hdu).data.a == Float32[3, 5] && reread(hdu; scale = false).data.a == Float32[1, 2]
        hdu = HDU(Bintable, (a = Float32[1, 2],), scaledcards(2.0f0, 1.0f0))
        @test reread(hdu).data.a == Float32[3, 5] && reread(hdu; scale = false).data.a == Float32[1, 2]
        hdu = HDU(Bintable, FITSFiles.ScaledTable([(a = 3.0f0, n = Int16(1)), (a = 5.0f0, n = Int16(2))],
            Dict{Symbol, Tuple{Any, Any}}(:a => (2.0f0, 1.0f0))))
        @test hdu.cards["TSCAL1"] == 2.0f0 && reread(hdu; scale = false).data.a == Float32[1, 2]
        #  the scale and the zero of the data are those of the header
        hdu = HDU(Bintable, (a = FITSFiles.ScaledArray(Float32[3, 5], 2.0f0, 1.0f0),))
        hdu.cards["TSCAL1"] = 4.0f0
        @test_throws ArgumentError written(hdu)
        #  an undefined value is NaN
        hdu = HDU(Bintable, (a = Float32[1, NaN],), scaledcards(2.0f0, 1.0f0))
        again = reread(hdu)
        @test isnan(again.data.a[2]) && again.data.a[1] == 3
        @test isnan(reread(again).data.a[2])
        @test FITSFiles.invertscale(ComplexF32(3, 4), ComplexF32, 2.0f0, 1.0f0) == ComplexF32(1, 2)
        @test_throws ArgumentError FITSFiles.invertscale([1.0], Float32, 0.0, 1.0)
    end

    ####    Test a table that has no rows and has a heap (Sects. 7.3.1 and 7.3.5)    ####

    @testset "no rows with a heap" begin
        written(hdu) = (io = IOBuffer(); write(io, hdu); take!(io))
        card(s) = rpad(s, 80)
        function tablebytes(cards, naxis1, pcount, data)
            header = vcat(["XTENSION= 'BINTABLE'", "BITPIX  =                    8", "NAXIS   =                    2",
                "NAXIS1  = " * lpad(naxis1, 20), "NAXIS2  =                    0", "PCOUNT  = " * lpad(pcount, 20),
                "GCOUNT  =                    1", "TFIELDS =                    1"], cards, ["END"])
            vcat(collect(codeunits(rpad(join(card.(header)), 2880 * cld(80 * length(header), 2880)))),
                data, zeros(UInt8, mod(-length(data), 2880)))
        end
        #  the heap of a table that has no rows is written, and the file has the bytes that the header says
        for (cards, naxis1, pcount, form) in ((["TFORM1  = '1PI(3)  '"], 8, 6, "variable-length"), (["TFORM1  = 'I       '"], 2, 10, "fixed"),
                                              (["TFORM1  = 'I       '", "THEAP   =                    4"], 2, 10, "gap"))
            bytes = tablebytes(cards, naxis1, pcount, zeros(UInt8, pcount))
            hdu = read(IOBuffer(bytes), HDU)
            @test all(isempty, hdu.data) && hdu.cards["PCOUNT"] == pcount
            @test written(hdu) == bytes
        end
        #  a table that has no rows and no heap has no data blocks
        bytes = tablebytes(["TFORM1  = 'I       '"], 2, 0, UInt8[])
        @test length(bytes) == 2880 && written(read(IOBuffer(bytes), HDU)) == bytes
    end

    ####    Test the variable-length arrays of characters and bits (Sect. 7.3.5)    ####

    @testset "variable-length strings and bits" begin
        written(hdu) = (io = IOBuffer(); write(io, hdu); take!(io))
        be(type, values) = collect(reinterpret(UInt8, hton.(type.(values))))
        card(s) = rpad(s, 80)
        function tablebytes(cards, naxis2, pcount, data)
            header = vcat(["XTENSION= 'BINTABLE'", "BITPIX  =                    8", "NAXIS   =                    2",
                "NAXIS1  =                    8", "NAXIS2  = " * lpad(naxis2, 20), "PCOUNT  = " * lpad(pcount, 20),
                "GCOUNT  =                    1", "TFIELDS =                    1"], cards, ["END"])
            vcat(collect(codeunits(rpad(join(card.(header)), 2880 * cld(80 * length(header), 2880)))),
                data, zeros(UInt8, mod(-length(data), 2880)))
        end

        #  an array of characters is a string, whose characters are the bytes of the heap, and its length is the number of characters
        bytes = tablebytes(["TFORM1  = '1PA(4)  '"], 3, 7, vcat(be(Int32, [3, 0, 4, 3, 0, 0]), collect(codeunits("abcdefg"))))
        hdu = read(IOBuffer(bytes), HDU)
        @test hdu.data.column1 == ["abc", "defg", ""] && written(hdu) == bytes
        @test [r.column1 for r in read(IOBuffer(bytes), HDU; record = true).data] == ["abc", "defg", ""]
        #  a string that is changed is written with its length, and the heap of the header has room for the strings that are not longer
        hdu.data.column1[2] = "de"
        @test read(IOBuffer(written(hdu)), HDU).data.column1 == ["abc", "de", ""]
        hdu.data.column1[3] = "wxyz"
        @test_throws ArgumentError written(hdu)
        #  and a string that has other characters than ASCII is an error
        longer = read(IOBuffer(bytes), HDU)
        longer.data.column1[1] = "é"
        @test_throws ArgumentError written(longer)

        #  an array of bits has the number of bits as its length, whose bytes are in order from the most significant bit, and the bits
        #  after the end are zeros
        bytes = tablebytes(["TFORM1  = '1PX(16) '"], 2, 3, vcat(be(Int32, [9, 0, 7, 2]), UInt8[0xff, 0x80, 0b01010100]))
        hdu = read(IOBuffer(bytes), HDU)
        @test hdu.data.column1 == [BitVector(ones(Bool, 9)), BitVector([0, 1, 0, 1, 0, 1, 0])] && written(hdu) == bytes
        @test read(IOBuffer(bytes), HDU; record = true).data[2].column1 == BitVector([0, 1, 0, 1, 0, 1, 0])
        #  an array of bits that is longer than the heap has is an error
        hdu.data.column1[1] = BitVector(ones(Bool, 40))
        @test_throws ArgumentError written(hdu)

        #  the bytes of the arrays of the heap
        field(type) = FITSFiles.BinaryField("a", Int32, type, 1:8, 1, "", "", "", nothing, nothing, nothing, nothing, nothing, nothing, nothing, nothing)
        @test FITSFiles.heapbytes(field(String), "abc") == 3 && FITSFiles.heapbytes(field(BitVector), BitVector(ones(Bool, 9))) == 2
        @test FITSFiles.heapbytes(field(Int16), Int16[1, 2, 3]) == 6 && FITSFiles.heapbytes(field(Bool), [true, false]) == 2
        @test FITSFiles.heapbytes(field(BitVector), BitVector()) == 0
    end

    ####    Test a table that is shorter than its header says (Sects. 7.3.1 and 7.3.3.1)    ####

    @testset "size of tables" begin
        card(s) = rpad(s, 80)
        function tablebytes(naxis1, naxis2, pcount, data)
            header = ["XTENSION= 'BINTABLE'", "BITPIX  =                    8", "NAXIS   =                    2",
                "NAXIS1  = " * lpad(naxis1, 20), "NAXIS2  = " * lpad(naxis2, 20), "PCOUNT  = " * lpad(pcount, 20),
                "GCOUNT  =                    1", "TFIELDS =                    1", "TFORM1  = 'I       '", "END"]
            vcat(collect(codeunits(rpad(join(card.(header)), 2880))), data)
        end
        data = collect(reinterpret(UInt8, hton.(Int16[1, 2, 3])))
        #  a table of the bytes that the header says is read
        @test read(IOBuffer(tablebytes(2, 3, 0, data)), HDU).data.column1 == Int16[1, 2, 3]
        #  a file that ends before the table, or the heap, does is an error that says how many bytes it has, instead of an end of the file
        for (naxis2, pcount, nbytes) in ((100, 0, 200), (3, 10, 16), (10^15, 0, 2 * 10^15), (1, 10^12, 10^12 + 2))
            err = try read(IOBuffer(tablebytes(2, naxis2, pcount, data)), HDU) catch e e end
            @test err isa ArgumentError && err.msg == "The data of the HDU is $nbytes bytes, as its header says, but the file has only 6 of them."
        end
        #  and so is a table that is larger than the largest integer
        err = try read(IOBuffer(tablebytes(2^40, 2^40, 0, data)), HDU) catch e e end
        @test err isa ArgumentError && occursin("The table is too large: NAXIS1 × NAXIS2 + PCOUNT, 1099511627776 × 1099511627776 + 0 bytes", err.msg)
        @test_throws ArgumentError read(IOBuffer(tablebytes(2, 3, typemax(Int), data)), HDU)
        #  the file that is read lazily has the same error when its data are read
        mktemp() do path, io
            write(io, tablebytes(2, 100, 0, data)); close(io)
            hdu = fits(path)[1]
            err = try hdu.data.column1 catch e e end
            @test err isa ArgumentError && occursin("The data of the HDU is 200 bytes", err.msg)
        end
    end

    ####    Test the TNULLn of the fields (Sect. 7.3.2)    ####

    @testset "TNULLn range" begin
        written(hdu; check = false) = (io = IOBuffer(); write(io, hdu; check); take!(io))
        card(s) = rpad(s, 80)
        function tablebytes(cards, naxis1, data)
            header = vcat(["XTENSION= 'BINTABLE'", "BITPIX  =                    8", "NAXIS   =                    2",
                "NAXIS1  = " * lpad(naxis1, 20), "NAXIS2  =                    2", "PCOUNT  =                    0",
                "GCOUNT  =                    1", "TFIELDS =                    1"], cards, ["END"])
            vcat(collect(codeunits(rpad(join(card.(header)), 2880 * cld(80 * length(header), 2880)))), data, zeros(UInt8, mod(-length(data), 2880)))
        end
        be(type, values) = collect(reinterpret(UInt8, hton.(type.(values))))
        #  the TNULLn of a field is a value of the type of the stored values, which are an unsigned byte, or a signed integer
        for (form, type, lower, upper, nbytes) in (("B", UInt8, 0, 255, 1), ("I", Int16, -32768, 32767, 2), ("J", Int32, -2^31, 2^31 - 1, 4),
                                                   ("K", Int64, typemin(Int64), typemax(Int64), 8))
            for null in (lower, upper)
                @test_logs read(IOBuffer(tablebytes(["TFORM1  = '$form'", "TNULL1  = " * lpad(null, 20)], nbytes, be(type, [1, 2]))), HDU)
            end
        end
        for (form, type, bad, nbytes) in (("B", UInt8, [-1, 256], 1), ("I", Int16, [-32769, 32768], 2), ("J", Int32, [-2^31 - 1, 2^31], 4))
            for null in bad
                bytes = tablebytes(["TFORM1  = '$form'", "TNULL1  = " * lpad(null, 20)], nbytes, be(type, [1, 2]))
                hdu = @test_logs (:warn, Regex("TNULL1, $null, is not a value of the $type of its field")) read(IOBuffer(bytes), HDU)
                @test eltype(hdu.data.column1) <: Union{Missing, type}
                #  the table is written as it was read if it has no undefined value, and an undefined value cannot be written
                @test_logs (:warn, r"TNULL1") @test written(hdu)[1:2880] == bytes[1:2880]
                hdu.data.column1[1] = missing
                err = @test_logs (:warn, r"TNULL1") try written(hdu) catch e e end
                @test err isa ArgumentError && occursin("TNULL of field column1, $null, is not a value of the $type of the field", err.msg)
            end
        end
        #  variable-length arrays too
        header = ["TFORM1  = '1PI(3)  '", "TNULL1  =                99999"]
        header = vcat(["XTENSION= 'BINTABLE'", "BITPIX  =                    8", "NAXIS   =                    2", "NAXIS1  =                    8",
            "NAXIS2  =                    1", "PCOUNT  =                    6", "GCOUNT  =                    1", "TFIELDS =                    1"],
            header, ["END"])
        bytes = vcat(collect(codeunits(rpad(join(card.(header)), 2880))), be(Int32, [3, 0]), be(Int16, [1, 2, 3]), zeros(UInt8, 2880 - 14))
        hdu = @test_logs (:warn, r"TNULL1, 99999") read(IOBuffer(bytes), HDU)
        hdu.data.column1[1] = Union{Int16, Missing}[1, missing, 3]
        @test_throws ArgumentError Base.CoreLogging.with_logger(() -> written(hdu), Base.CoreLogging.NullLogger())
    end

    ####    Test the number of fields (Sect. 7.3.1)    ####

    @testset "number of fields" begin
        #  a table has at most 999 fields, and more than that is an error when the HDU is created
        hdu = HDU(Bintable, Tuple(fill(Int16[1, 2], 999)))
        @test hdu.cards["TFIELDS"] == 999 && hdu.cards["NAXIS1"] == 1998 && hdu.cards["NAXIS2"] == 2
        err = try HDU(Bintable, Tuple(fill(Int16[1], 1000))) catch e e end
        @test err isa ArgumentError && err.msg == "The data have 1000 fields, but a binary table has at most 999 (Sect. 7.3.1)."
        err = try HDU(Bintable, fill((a = Int16(1),), 2)) catch e e end
        @test !(err isa ArgumentError)
    end

    ####    Test the largest number of elements of the variable-length arrays (Sect. 7.3.5)    ####

    @testset "emax of arrays" begin
        written(hdu) = (io = IOBuffer(); write(io, hdu); take!(io))
        be(type, values) = collect(reinterpret(UInt8, hton.(type.(values))))
        card(s) = rpad(s, 80)
        header = ["XTENSION= 'BINTABLE'", "BITPIX  =                    8", "NAXIS   =                    2", "NAXIS1  =                    8",
            "NAXIS2  =                    2", "PCOUNT  =                   14", "GCOUNT  =                    1", "TFIELDS =                    1",
            "TFORM1  = '1PI(3)  '", "END"]
        bytes = vcat(collect(codeunits(rpad(join(card.(header)), 2880))), be(Int32, [3, 0, 2, 6]), be(Int16, [1, 2, 3, 4, 5, 0, 0]), zeros(UInt8, 2880 - 30))
        hdu = read(IOBuffer(bytes), HDU)
        #  the arrays that are not longer than emax are written without a warning
        @test @test_logs(written(hdu)) == bytes
        hdu.data.column1[2] = Int16[7, 8, 9]
        @test length(@test_logs(written(hdu))) == length(bytes) && read(IOBuffer(@test_logs(written(hdu))), HDU).data.column1[2] == Int16[7, 8, 9]
        #  an array that is longer has the emax of the header that is written set to its length, with a warning, and the header of the HDU is not changed
        hdu.data.column1[2] = Int16[1, 2, 3, 4]
        w = @test_logs (:warn, "TFORM1 set to \"1PI(4)\", since the longest array of field column1 has 4 elements, more than the largest number of " *
            "elements, 3, that its TFORM says (Sect. 7.3.5).") written(hdu)
        @test read(IOBuffer(w), HDU).cards["TFORM1"] == "1PI(4)" && read(IOBuffer(w), HDU).data.column1[2] == Int16[1, 2, 3, 4]
        @test hdu.cards["TFORM1"] == "1PI(3)"
        @test_logs((:warn, r"TFORM1 set to"), written(hdu)) == w
        #  the emax of a table that is created is the length of the longest array, and strings and bits have their own
        created = HDU(Bintable, (v = [Int16[1, 2], Int16[3, 4, 5]],))
        @test created.cards["TFORM1"] == "1PI(3)" && length(@test_logs(written(created))) == 5760
    end

    ####    Test the minimum and maximum values of the fields (Sect. 7.3.2)    ####

    @testset "minimum and maximum values" begin
        card(s) = rpad(s, 80)
        kw(key, value) = key * repeat(" ", 8 - length(key)) * "= " * (value isa AbstractString ? "'" * rpad(value, 8) * "'" : lpad(value, 20))
        function tablebytes(cards, naxis1)
            header = vcat(["XTENSION= 'BINTABLE'", kw("BITPIX", 8), kw("NAXIS", 2), kw("NAXIS1", naxis1), kw("NAXIS2", 1), kw("PCOUNT", 0),
                kw("GCOUNT", 1), kw("TFIELDS", 1)], cards, ["END"])
            vcat(collect(codeunits(rpad(join(card.(header)), 2880 * cld(80 * length(header), 2880)))), zeros(UInt8, 2880))
        end
        reading(cards, form) = read(IOBuffer(tablebytes(cards, FITSFiles.tformbytes("TFORM1", form))), HDU)
        #  the values of an integer field are integers, and those of a floating-point field are floating-point numbers
        for form in ("B", "I", "J", "K"), key in ("TDMIN1", "TDMAX1", "TLMIN1", "TLMAX1")
            @test_logs reading([kw("TFORM1", form), kw(key, 5)], form)
            @test_logs (:warn, Regex("$key must be an integer, since the values of field 1 are integers .*its value is 1.5f0")) reading(
                [kw("TFORM1", form), kw(key, 1.5f0)], form)
        end
        for form in ("E", "D"), key in ("TDMIN1", "TDMAX1", "TLMIN1", "TLMAX1")
            @test_logs reading([kw("TFORM1", form), kw(key, 2.5f0)], form)
            @test_logs (:warn, Regex("$key must be a floating-point number, since the values of field 1 are floating-point numbers .*its value is 5")) reading(
                [kw("TFORM1", form), kw(key, 5)], form)
        end
        #  the physical values of an integer field that is scaled are floating-point numbers, unless the scale is 1 and the zero is an integer
        @test_logs (:warn, r"TDMIN1 must be a floating-point number") reading([kw("TFORM1", "I"), kw("TSCAL1", 0.5f0), kw("TDMIN1", 5)], "I")
        @test_logs reading([kw("TFORM1", "I"), kw("TSCAL1", 0.5f0), kw("TDMIN1", 2.5f0)], "I")
        @test_logs reading([kw("TFORM1", "I"), kw("TZERO1", 32768), kw("TDMIN1", 5)], "I")
        @test_logs (:warn, r"TDMIN1 must be an integer") reading([kw("TFORM1", "I"), kw("TZERO1", 32768), kw("TDMIN1", 5.5f0)], "I")
        #  the other types have no minimum or maximum value to check, and the arrays of a variable-length field have the type of their elements
        for form in ("A", "L", "X", "C", "M")
            @test_logs reading([kw("TFORM1", form), kw("TDMIN1", 5)], form)
        end
        @test_logs (:warn, r"TDMIN1 must be a floating-point number") reading([kw("TFORM1", "1PE(2)"), kw("TDMIN1", 5)], "1PE(2)")
    end

    ####    Test the display formats of the fields (Sects. 7.3.2 and 7.3.4)    ####

    @testset "display formats" begin
        card(s) = rpad(s, 80)
        kw(key, value) = key * repeat(" ", 8 - length(key)) * "= " * (value isa AbstractString ? "'" * rpad(value, 8) * "'" : lpad(value, 20))
        function tablebytes(cards, naxis1)
            header = vcat(["XTENSION= 'BINTABLE'", kw("BITPIX", 8), kw("NAXIS", 2), kw("NAXIS1", naxis1), kw("NAXIS2", 1), kw("PCOUNT", 0),
                kw("GCOUNT", 1), kw("TFIELDS", 1)], cards, ["END"])
            vcat(collect(codeunits(rpad(join(card.(header)), 2880 * cld(80 * length(header), 2880)))), zeros(UInt8, 2880))
        end
        reading(form, disp) = read(IOBuffer(tablebytes([kw("TFORM1", form), kw("TDISP1", disp)], FITSFiles.tformbytes("TFORM1", form))), HDU)

        #  the formats of each type of Table 18 (Sect. 7.3.4)
        formats = Dict("A" => ["A5"], "L" => ["L1"],
            "X" => ["I6", "B8.8", "O5", "Z4.2", "F8.3", "E12.4", "D12.4", "EN12.3", "ES12.3"],
            "B" => ["I6", "B8.8", "O5", "Z4.2", "F8.3", "E12.4", "D12.4", "EN12.3", "ES12.3"],
            "I" => ["I6", "B8.8", "O5", "Z4.2", "F8.3", "E12.4", "D12.4", "EN12.3", "ES12.3"],
            "J" => ["I6", "B8.8", "O5", "Z4.2", "F8.3", "E12.4", "D12.4", "EN12.3", "ES12.3"],
            "K" => ["I6", "B8.8", "O5", "Z4.2", "F8.3", "E12.4", "D12.4", "EN12.3", "ES12.3"],
            "E" => ["F8.3", "E12.4", "E12.4E3", "D12.4", "EN12.3", "ES12.3"], "D" => ["F8.3", "E12.4", "D12.4", "EN12.3", "ES12.3"],
            "C" => ["F8.3", "E12.4", "EN12.3"], "M" => ["F8.3", "D12.4", "ES12.3"])
        for (form, disps) in formats, disp in vcat(disps, ["G10.2", "G10.2E2"])
            @test_logs reading(form, disp)
        end
        #  and the formats that the type does not have
        wrong = Dict("A" => ["I6", "F8.3", "L1"], "L" => ["A5", "I6", "F8.3"], "I" => ["A5", "L1"], "X" => ["A5", "L1"],
            "E" => ["I6", "A5", "L1", "B8.8", "O5", "Z4.2"], "D" => ["I6", "A5", "L1"], "C" => ["I6", "A5", "L1"])
        for (form, disps) in wrong, disp in disps
            @test_logs (:warn, Regex("TDISP1, \"$disp\", is not a display format for a field of type $form")) reading(form, disp)
        end
        #  a variable-length array has the formats of its elements
        @test_logs reading("1PE(2)", "F8.3")
        @test_logs (:warn, r"is not a display format for a field of type E") reading("1PE(2)", "I6")
        #  a format that is not in Table 20 is the earlier warning only
        @test_logs (:warn, r"TDISP1 must be a display format of Table 20") reading("I", "Q9.9")
    end
    ####    Test the size of the HDU, which is the bytes of a row and the rows of the header (Sect. 7.3.3)    ####

    @testset "size" begin
        #  the size is the number of bytes in a row and the number of rows, NAXIS1 and NAXIS2, which is the size of the byte array that the table is,
        #  and the rows are the number of values of a column of the data
        data = (a = Int32[1, 2, 3], b = [1.5, 2.5, 3.5], c = ["x", "y", "zz"])
        hdu = HDU(Bintable, data)
        @test size(hdu) == (14, 3) && size(hdu) == (getfield(hdu, :cards)["NAXIS1"], getfield(hdu, :cards)["NAXIS2"])
        @test size(hdu)[2] == length(data.a) && getfield(hdu, :cards)["TFIELDS"] == length(data)
        @test size(HDU(Bintable, (m = [1 2; 3 4; 5 6],))) == (16, 3) && size(HDU(Bintable, [(a = Int16(1), b = 2.5)])) == (10, 1)
        #  a table that has no rows, or no fields, or no data
        @test size(HDU(Bintable, (a = Int32[], b = Float64[]))) == (12, 0) && size(HDU(Bintable)) == (0, 0)
        #  the size of an HDU whose data are not read, which a file has, is known without reading them
        path = joinpath(mktempdir(), "size.fits")
        write(path, [HDU(Primary), HDU(Bintable, data)])
        lazy = fits(path)[2]
        @test getfield(lazy, :data) isa FITSFiles.LazyArray
        @test size(lazy) == (14, 3) && getfield(lazy, :data) isa FITSFiles.LazyArray
    end

    ####    Test the reading of the columns of fixed-width values, a chunk of rows at a time    ####

    @testset "chunked reads" begin
        #  the bytes of a field of each row are those of the row, whatever the number of rows of a chunk is, and the table is read from the position
        L, M, w, N = 7, 2, 3, 10
        table = UInt8[10j + k for k = 1:L, j = 1:N]
        io = IOBuffer(vcat(zeros(UInt8, 5), vec(table), UInt8[99, 99]))
        expected = table[M+1:M+w, :]
        for chunk in (1, L - 1, L, 2L, 2L + 1, 3L, 9L, 10L, 11L, 1 << 23)
            @test FITSFiles.fieldbytes(io, 5, L, M, w, N; chunk) == expected
        end
        @test FITSFiles.fieldbytes(io, 5, L, 0, L, N; chunk = 3L) == table && FITSFiles.fieldbytes(io, 5, L, L - 1, 1, N) == table[L:L, :]
        #  a field with no bytes, or a table with no rows, has no bytes, and does not read
        @test size(FITSFiles.fieldbytes(io, 5, L, M, 0, N)) == (0, N) && size(FITSFiles.fieldbytes(io, 5, L, M, w, 0)) == (w, 0)
        #  a file that ends before the rows do is an error
        @test_throws ArgumentError("The file has fewer bytes than the header of the HDU says.") FITSFiles.fieldbytes(
            IOBuffer(vec(table)[1:end-1]), 0, L, M, w, N)
        @test_throws ArgumentError FITSFiles.fieldbytes(IOBuffer(vec(table)[1:end-1]), 0, L, M, w, N; chunk = 2L)

        #  the values of every type of field of fixed-width values are those that were written
        n = 20
        data = (a = Int32.(1:n), b = collect(1.5:n + 0.5), c = Float32[j + k/4 for j = 1:n, k = 1:3], d = rand(Bool, n),
            e = [BitVector([isodd(j), true, j > 5, false, isodd(j >> 1), true, false, true, isodd(j)]) for j = 1:n], f = string.(1:n),
            g = [Complex(Float32(j), -j) for j = 1:n], h = UInt16.(40000:40000+n-1))
        hdu = HDU(Bintable, data)
        io = IOBuffer()
        write(io, [HDU(Primary), hdu])
        bytes = take!(io)
        read_ = fits(IOBuffer(bytes))[2].data
        @test read_.a == data.a && read_.b == data.b && read_.c == data.c && read_.d == data.d && read_.e == data.e
        @test read_.f == data.f && read_.g == data.g && read_.h == data.h
        @test fits(IOBuffer(bytes); record = true)[2].data[7] == (; (name => (column isa AbstractMatrix ? column[7, :] : column[7]) for (name, column) in pairs(data))...)

        #  a table of more bytes than a chunk of rows is read in more than one chunk, and has the values of all of the rows
        n = 301_000
        large = (a = Int32.(1:n), b = Float64.(n:-1:1), c = Float64.(1:n) ./ 7, d = Float64.(1:n) .* 3)
        hdu = HDU(Bintable, large)
        @test n * getfield(hdu, :cards)["NAXIS1"] > FITSFiles.ROWCHUNKBYTES
        io = IOBuffer()
        write(io, [HDU(Primary), hdu])
        read_ = fits(IOBuffer(take!(io)))[2].data
        @test read_.a == large.a && read_.b == large.b && read_.c == large.c && read_.d == large.d
    end

    @testset "variable-length fields" begin
        bytesof(hdus; kwds...) = (io = IOBuffer(); write(io, hdus; kwds...); take!(io))
        #  a field of the repeat count 0 is an empty field of zero bytes, which has no descriptor, so the other fields are read and written where they are
        #  in the row (Sect. 7.3.3.1): the table of a field of arrays, whose rows are the 2 bytes, 8 bytes, and 4 bytes of the fields, is changed to a row
        #  of 6 bytes that has no descriptor
        raw = bytesof([HDU(Primary), HDU(Bintable, (a = Int16[1, 2, 3], v = [Int16[1], Int16[2, 3], Int16[]], c = Int32[10, 20, 30]))])
        function replacebytes!(raw, old, new)
            i = findfirst(Vector{UInt8}(old), raw)
            raw[first(i):last(i)] = Vector{UInt8}(new)
        end
        replacebytes!(raw, "NAXIS1  =                   14", "NAXIS1  =                    6")
        replacebytes!(raw, "PCOUNT  =                    6", "PCOUNT  =                    0")
        replacebytes!(raw, "'1PI(2)'", "'0PI(2)'")
        be16(x) = reverse(reinterpret(UInt8, [Int16(x)]))
        be32(x) = reverse(reinterpret(UInt8, [Int32(x)]))
        rows = reduce(vcat, [vcat(be16(a), be32(c)) for (a, c) in ((1, 10), (2, 20), (3, 30))])
        zero = vcat(raw[1:5760], rows, zeros(UInt8, 2880 - length(rows)))
        hdus = @test_logs fits(IOBuffer(zero))
        data = hdus[2].data
        @test data.a == [1, 2, 3] && data.c == [10, 20, 30] && data.v == [Int16[], Int16[], Int16[]] && eltype(data.v) == Vector{Int16}
        @test bytesof(hdus) == zero
        records = @test_logs fits(IOBuffer(zero); record = true)[2].data
        @test records[2].a == 2 && records[2].c == 20 && records[2].v == Int16[]
        path = joinpath(mktempdir(), "zero.fits")
        write(path, zero)
        mapped = fits(path; access = :mapped)[2].data
        @test mapped.v == data.v && collect(mapped.a) == data.a && collect(mapped.c) == data.c
        #  and its arrays have no elements, so data that have elements are an error
        wrong = HDU{Bintable}(getfield(hdus[2], :cards), (a = Int16[1, 2, 3], v = [Int16[1], Int16[], Int16[]], c = Int32[10, 20, 30]))
        @test_throws ArgumentError r"Field v has the repeat count 0" write(IOBuffer(), wrong)

        #  the heap is not read: the stream is at the end of the data, and the arrays are the memory that the data have, and not the heap and
        #  copies of it
        cells = [rand(Int16, 100_000 + 10i) for i = 1:8]
        big = bytesof([HDU(Primary), HDU(Bintable, (a = Int32.(1:8), v = cells))])
        @test fits(IOBuffer(big))[2].data.v == cells
        io = IOBuffer(big)
        read(io, HDU); read(io, HDU)
        @test eof(io)
        fits(IOBuffer(big))
        @test (@allocated fits(IOBuffer(big))) < 2 * sizeof(Int16) * sum(length, cells)

        #  the keyword variable makes a field variable-length, with a P or a Q descriptor, though its arrays have the same length (Sect. 7.3.5)
        equal = (v = [Int16[1, 2, 3], Int16[4, 5, 6]], a = Int32[1, 2])
        @test getfield(HDU(Bintable, equal), :cards)["TFORM1"] == "3I"
        for (code, form) in (('P', "1PI(3)"), ('Q', "1QI(3)"), ("P", "1PI(3)"), (:Q, "1QI(3)"))
            hdu = HDU(Bintable, equal; variable = (v = code,))
            @test getfield(hdu, :cards)["TFORM1"] == form && getfield(hdu, :cards)["TFORM2"] == "1J"
            read_ = fits(IOBuffer(bytesof([HDU(Primary), hdu])))[2]
            @test getfield(read_, :cards)["TFORM1"] == form && read_.data.v == equal.v && read_.data.a == equal.a
            @test getfield(read_, :cards)["NAXIS1"] == (code in ('P', "P") ? 12 : 20)
        end
        #  the fields are named by a symbol, a string, or their number, in a named tuple or a dictionary, and the generic HDU makes it too
        for variable in (Dict(:v => 'Q'), Dict("v" => 'Q'), Dict(1 => 'Q'), (v = 'Q',))
            @test getfield(HDU(Bintable, equal; variable), :cards)["TFORM1"] == "1QI(3)"
        end
        @test getfield(HDU(equal; variable = (v = 'P',)), :cards)["TFORM1"] == "1PI(3)"
        #  the TFORMn card of the field has the descriptor when the keyword does not, which the keyword has priority over, and the data have the
        #  fields that the keyword does not name
        cards = Card{<:Any}[Card("TFORM1", "1PI(3)")]
        @test getfield(HDU(Bintable, equal, cards), :cards)["TFORM1"] == "1PI(3)"
        @test getfield(HDU(Bintable, equal, cards; variable = (v = 'Q',)), :cards)["TFORM1"] == "1QI(3)"
        @test getfield(HDU(Bintable, equal, Card{<:Any}[Card("TFORM1", "1QI(3)")]; variable = (v = 'P',)), :cards)["TFORM1"] == "1PI(3)"
        @test getfield(HDU(Bintable, equal; variable = (a = 'P',)), :cards)["TFORM1"] == "3I"
        @test getfield(HDU(Bintable, equal; variable = (a = 'P',)), :cards)["TFORM2"] == "1PJ(1)"
        @test fits(IOBuffer(bytesof([HDU(Primary), HDU(Bintable, equal, cards)])))[2].data.v == equal.v
        #  the arrays are arrays, strings, bit arrays, numbers, which are arrays of one element, and the rows of a matrix, in records too
        text = (s = ["ab", "cde"], b = [BitVector([1, 0, 1]), BitVector([0, 1, 1])], x = Int32[1, 2], m = Int16[1 2 3; 4 5 6])
        hdu = HDU(Bintable, text; variable = (s = 'P', b = 'Q', x = 'P', m = 'P'))
        @test [getfield(hdu, :cards)["TFORM$j"] for j = 1:4] == ["1PA(3)", "1QX(3)", "1PJ(1)", "1PI(3)"]
        read_ = fits(IOBuffer(bytesof([HDU(Primary), hdu])))[2].data
        @test read_.s == text.s && read_.b == text.b && read_.x == [Int32[1], Int32[2]] && read_.m == [Int16[1, 2, 3], Int16[4, 5, 6]]
        records = [(v = Int16[1, 2],), (v = Int16[3, 4],)]
        @test fits(IOBuffer(bytesof([HDU(Primary), HDU(Bintable, records; variable = (v = 'P',))])))[2].data.v == [Int16[1, 2], Int16[3, 4]]
        #  the names and the descriptors are checked, and a table of strings has no variable-length arrays of arrays of strings
        @test_throws ArgumentError("The keyword variable names the field :w, but the data have the fields :v, :a.") HDU(Bintable, equal; variable = (w = 'P',))
        @test_throws ArgumentError r"names the field 3, but the data have the fields" HDU(Bintable, equal; variable = Dict(3 => 'P'))
        @test_throws ArgumentError r"The descriptor of a variable-length field is 'P' or 'Q', but the keyword variable has 'X'" HDU(Bintable, equal; variable = (v = 'X',))
        @test_throws ArgumentError r"An array of strings cannot be a variable-length field" HDU(Bintable, (t = ["a" "b"; "c" "d"],); variable = (t = 'P',))
        #  a P descriptor is 32-bit, so the arrays have at most the bytes of a 32-bit integer, and a Q descriptor is 64-bit
        @test_throws ArgumentError r"Use the 64-bit descriptor, Q" FITSFiles.variabledescriptor((1:2^31,), Int32)
        @test FITSFiles.variabledescriptor((1:2^31,), Int64)[[2, 3, 4, 5, 6]] == (1, 16, Int64, "2147483648", 2^34)
        #  the type of a column that has no array is that of its elements, and the cells that are missing have no storage
        @test FITSFiles.variabledescriptor(Vector{Int16}[], Int32)[1] == Int16 && FITSFiles.variabledescriptor(Int16[], Int32)[1] == Int16
        @test FITSFiles.variabledescriptor([Int16[1, 2], missing], Int32)[[1, 5, 6]] == (Int16, "2", 4)

        #  the arrays have at least the elements that the dimensions TDIMn have (Sect. 7.3.2): an array that has fewer is not reshaped, with a warning
        #  that counts the arrays, but not for an array of no elements, which TDIMn is not applicable to, and the arrays that have more are reshaped
        cards = Card{<:Any}[Card("TDIM1", "(2,3)")]
        arrays = [Int16[1, 2, 3, 4, 5, 6], Int16[1, 2, 3], Int16[], Int16[1, 2, 3, 4, 5, 6, 7]]
        short = bytesof([HDU(Primary), HDU(Bintable, (v = arrays,), cards)])
        read_ = @test_logs (:warn, r"TDIM of field v, 2 × 3, has 6 elements, but 1 of its arrays has fewer .*so it is not reshaped") fits(IOBuffer(short))[2].data.v
        @test read_[1] == Int16[1 3 5; 2 4 6] && read_[2] == Int16[1, 2, 3] && read_[3] == Int16[] && read_[4] == Int16[1 3 5; 2 4 6]
        read_ = @test_logs (:warn, r"but 2 of its arrays have fewer .*so they are not reshaped") fits(IOBuffer(bytesof([HDU(Primary),
            HDU(Bintable, (v = [Int16[1], Int16[1, 2], Int16[1, 2, 3, 4, 5, 6]],), cards)])))[2].data.v
        @test read_[3] == Int16[1 3 5; 2 4 6] && read_[1] == Int16[1]
        @test_logs fits(IOBuffer(bytesof([HDU(Primary), HDU(Bintable, (v = [Int16[], Int16[1, 2, 3, 4, 5, 6]],), cards)])))
        #  and the bit arrays, which are all of the repeat count of the field, whether they are read, or mapped
        bits = (b = [BitVector([1, 0, 1]), BitVector([0, 1, 1])],)
        path = joinpath(mktempdir(), "bits.fits")
        write(path, [HDU(Primary), HDU(Bintable, bits, Card{<:Any}[Card("TDIM1", "(2,3)")])])
        @test_logs (:warn, r"TDIM of field b, 2 × 3, has 6 elements, but 2 of its arrays have fewer") fits(path; access = :memory)
        @test_logs (:warn, r"TDIM of field b, 2 × 3, has 6 elements, but 2 of its arrays have fewer") fits(path; access = :mapped)
        @test_logs fits(path)
        write(path, [HDU(Primary), HDU(Bintable, (b = [BitVector([1, 0, 1, 1, 0, 0]), BitVector([0, 1, 1, 0, 0, 1])],), Card{<:Any}[Card("TDIM1", "(2,3)")])])
        @test_logs fits(path; access = :memory)
        @test_logs fits(path; access = :mapped)

        #  an array that is missing is an array of no elements, which is written without storage and is read as an empty array (Sect. 7.3.5)
        for data in ((v = [Int16[1, 2], missing, Int16[3]],), (v = ["ab", missing, "c"],), (v = [BitVector([1, 0]), missing, BitVector([1])],),
            [(v = Int16[1, 2],), (v = missing,), (v = Int16[3],)])
            hdu = HDU(Bintable, data; variable = (v = 'P',))
            read_ = fits(IOBuffer(bytesof([HDU(Primary), hdu])))[2].data.v
            @test length(read_) == 3 && isempty(read_[2]) && !ismissing(read_[2]) && !ismissing(read_[1]) && !ismissing(read_[3])
        end
        @test fits(IOBuffer(bytesof([HDU(Primary), HDU(Bintable, (v = [Int16[1, 2], missing, Int16[3]],))])))[2].data.v == [Int16[1, 2], Int16[], Int16[3]]

        #  a 32-bit descriptor (P) has the offset and the number of elements that are 32-bit integers, which is checked before the header or the data
        #  are written (Sect. 7.3.5), and the field is written with a 64-bit descriptor (Q) if the header says Q
        small = HDU(Bintable, (v = [1:2, 1:3],); variable = (v = 'P',))
        huge = HDU{Bintable}(getfield(small, :cards), (v = [1:2^31, 1:2],))
        @test_throws ArgumentError(
            "The array of row 1 of field v is at the offset 0 in the heap and has 2147483648 elements, which a 32-bit array descriptor (P) cannot " *
            "address (Sect. 7.3.5). Use the 64-bit descriptor, Q, with the keyword variable or in TFORM1.") write(IOBuffer(), huge)
        @test_throws ArgumentError r"The array of row 3 of field v is at the offset 2147483648 in the heap" write(IOBuffer(), HDU{Bintable}(
            getfield(HDU(Bintable, (v = [1:2, 1:3, 1:4, 1:5],); variable = (v = 'P',)), :cards), (v = [1:2^27, 1:2^27, 1:2^27, 1:2],)))
        quad = HDU(Bintable, (v = [1:2, 1:3],); variable = (v = 'Q',))
        @test_throws ArgumentError r"PCOUNT" write(IOBuffer(), HDU{Bintable}(getfield(quad, :cards), (v = [1:2^31, 1:2],)))
    end

    @testset "data and cards" begin
        bytesof(hdus; kwds...) = (io = IOBuffer(); write(io, hdus; kwds...); take!(io))
        reread(data, cards = Card{<:Any}[]; kwds...) = fits(IOBuffer(bytesof([HDU(Primary), HDU(Bintable, data, cards)])); kwds...)[2]
        #  every field has an entry in each of the NAXIS2 rows, so the columns of the data have the same number of rows (Sects. 7.3.1 and 7.3.3.1)
        @test_throws ArgumentError("The columns of the data have different numbers of rows, but every field of a binary table has an entry in " *
            "each of the NAXIS2 rows (Sects. 7.3.1 and 7.3.3.1): a has 2, b has 3.") HDU(Bintable, (a = [1, 2], b = [1, 2, 3]))
        @test_throws ArgumentError r"column1 has 2, column2 has 3, column3 has 2" HDU(Bintable, ([1, 2], [1, 2, 3], ["a", "b"]))
        @test getfield(HDU(Bintable, (a = [1, 2], b = [1.5 2.5; 3.5 4.5])), :cards)["NAXIS2"] == 2

        #  the columns of a tuple, and the records of tuples, are named by the fields, as the columns and the records of the header are, and are written
        columns = (Int32[1, 2], ["a", "b"], FITSFiles.ScaledArray(Float32[1, 2], 2f0, 1f0))
        hdu = HDU(Bintable, columns)
        @test keys(hdu.data) == (:column1, :column2, :column3) && hdu.data.column2 == ["a", "b"] && hdu.data.column3 isa FITSFiles.ScaledArray
        @test getfield(hdu, :cards)["TTYPE1"] == "column1" && getfield(hdu, :cards)["TSCAL3"] == 2.0f0 && getfield(hdu, :cards)["TZERO3"] == 1.0f0
        read_ = reread(columns).data
        @test read_.column1 == Int32[1, 2] && read_.column2 == ["a", "b"] && read_.column3 == Float32[1, 2] && read_.column3 isa FITSFiles.ScaledArray
        named = reread(columns, Card{<:Any}[Card("TTYPE2", "label")])
        @test keys(named.data) == (:column1, :label, :column3)
        records = [(1, "a"), (2, "b")]
        @test HDU(Bintable, records).data == [(column1 = 1, column2 = "a"), (column1 = 2, column2 = "b")]
        @test reread(records).data == (column1 = [1, 2], column2 = ["a", "b"])
        @test reread(records; record = true).data == [(column1 = 1, column2 = "a"), (column1 = 2, column2 = "b")]

        #  the data are the fields, so a TFORMn or TFIELDS card that is not their format or their number is set to what they have, with a warning, and the
        #  cards of the same format are kept, with the characters after the data type, and the largest number of elements of the arrays of a field
        for (card, data, form) in (("1E", Int32[1], "1J"), ("4A", Int32[1], "1J"), ("8X", UInt8[5], "1B"), ("2J", Int32[1], "1J"),
            ("1D", Int64[1], "1K"), ("1K", [1.5], "1D"), ("1PJ(100)", [Int16[1, 2], Int16[3, 4]], "1PI(2)"), ("", [1.5], "1D"))
            cards = Card{<:Any}[Card("TFORM1", card)]
            hdu = @test_logs (:warn, "TFORM1 set to $(repr(form)), the format of field 1 of the data, and not $(repr(card)).") HDU(Bintable, (a = data,), cards)
            @test getfield(hdu, :cards)["TFORM1"] == form
            read_ = fits(IOBuffer(bytesof([HDU(Primary), hdu])))[2].data.a
            @test read_ == data
        end
        for (card, data) in (("1J", Int32[1]), ("6A3", ["abcdef"]), ("1PI(100)", [Int16[1, 2], Int16[3, 4]]), ("1QI(3)", [Int16[1, 2], Int16[3, 4]]), ("3I", Int16[1 2 3;]))
            hdu = @test_logs HDU(Bintable, (a = data,), Card{<:Any}[Card("TFORM1", card)])
            @test getfield(hdu, :cards)["TFORM1"] == card
        end
        @test getfield(HDU(Bintable, (a = [Int16[1, 2], Int16[3, 4]],), Card{<:Any}[Card("TFORM1", "1PI(100)")]), :cards)["TFORM1"] == "1PI(100)"
        hdu = @test_logs (:warn, "TFIELDS set to 2, the number of fields of the data.") HDU(Bintable, (a = [1], b = [2]), Card{<:Any}[Card("TFIELDS", 1)])
        @test getfield(hdu, :cards)["TFIELDS"] == 2 && keys(fits(IOBuffer(bytesof([HDU(Primary), hdu])))[2].data) == (:a, :b)
        hdu = @test_logs (:warn, "NAXIS2 set to 2") HDU(Bintable, (a = [1, 2],), Card{<:Any}[Card("NAXIS2", 5)])
        @test getfield(hdu, :cards)["NAXIS2"] == 2 && reread((a = [1, 2],), Card{<:Any}[Card("NAXIS1", 3)]).data.a == [1, 2]
        #  the keyword variable has priority over the card, which is set without a warning
        @test_logs getfield(HDU(Bintable, (v = [Int16[1, 2], Int16[3, 4]],), Card{<:Any}[Card("TFORM1", "1PI(3)")]; variable = (v = 'Q',)), :cards)["TFORM1"] == "1QI(2)"
        #  a card of a field of data that have no rows is the format of the field
        @test getfield(HDU(Bintable, (a = Int16[],), Card{<:Any}[Card("TFORM1", "1I")]), :cards)["TFORM1"] == "1I"

        #  the rows of a table can have no bytes (NAXIS1 is 0), e.g., the strings of no characters, and the arrays of no bits, which are the data of
        #  the rows, and not missing (Sect. 7.3.1)
        for data in ((s = ["", ""],), (b = [BitVector(), BitVector()],), (s = ["", ""], b = [BitVector(), BitVector()]))
            hdu = reread(data)
            @test getfield(hdu, :cards)["NAXIS1"] == 0 && getfield(hdu, :cards)["NAXIS2"] == 2 && size(hdu) == (0, 2)
            @test hdu.data == data && length(bytesof([HDU(Primary), HDU(Bintable, data)])) == 5760
        end
        @test reread((s = ["", ""],); record = true).data == [(s = nothing,), (s = nothing,)]
        path = joinpath(mktempdir(), "empty.fits")
        write(path, [HDU(Primary), HDU(Bintable, (s = ["", "", ""],))])
        @test fits(path)[2].data.s == ["", "", ""] && fits(path; access = :mapped)[2].data.s == ["", "", ""]
        @test bytesof(fits(path)) == read(path) && bytesof(fits(path; access = :memory)) == read(path)
        #  and a table that has no fields has no data, and a table that has fields and no rows has the empty columns
        @test ismissing(fits(IOBuffer(bytesof([HDU(Primary), HDU(Bintable)])))[2].data)
        @test fits(IOBuffer(bytesof([HDU(Primary), HDU(Bintable, (a = Int16[], b = String[]))])))[2].data == (a = Int16[], b = String[])
    end

    @testset "strings, no fields, and names" begin
        bytesof(hdus; kwds...) = (io = IOBuffer(); write(io, hdus; kwds...); take!(io))
        reread(data, cards = Card{<:Any}[]; kwds...) = fits(IOBuffer(bytesof([HDU(Primary), HDU(Bintable, data, cards)])); kwds...)[2]
        #  the characters of a string are the bytes 32 to 126 (Sect. 7.3.3.1), so the strings that have others, which are before the NUL that ends a string, are
        #  read as they are, with a warning for the field that counts them, and those after it, which are not defined, are not read
        raw = bytesof([HDU(Primary), HDU(Bintable, (s = ["abc", "def", "ghi"], t = ["xyz", "uvw", "rst"]))])
        function change(raw, old, offset, byte)
            raw = copy(raw)
            raw[first(findfirst(Vector{UInt8}(old), raw)) + offset] = byte
            raw
        end
        bad = change(change(raw, "abc", 1, 0xff), "ghi", 0, 0x09)
        read_ = @test_logs (:warn, "Field s has 2 strings with characters that are not ASCII text characters, which are the bytes 32 to 126 " *
            "(Sect. 7.3.3.1). They are read as they are.") fits(IOBuffer(bad))[2].data
        @test read_.s == ["a\xffc", "def", "\thi"] && read_.t == ["xyz", "uvw", "rst"] && !isvalid(read_.s[1])
        after = copy(raw)
        i = first(findfirst(Vector{UInt8}("abc"), after))
        after[i + 1], after[i + 2] = 0x00, 0xff
        @test_logs fits(IOBuffer(after))
        @test fits(IOBuffer(after))[2].data.s == ["a", "def", "ghi"]
        #  and the strings of the arrays of a variable-length field are those of its rows
        variable = bytesof([HDU(Primary), HDU(Bintable, (s = ["abc", "de"],); variable = (s = 'P',))])
        @test_logs (:warn, r"Field s has 1 strings with characters that are not ASCII") fits(IOBuffer(change(variable, "abc", 1, 0xff)))
        #  the data that are read are not written, since the standard has only the characters 32 to 126, but a file that is not read is written as it is
        @test_throws ArgumentError r"has characters that are not ASCII, but the characters of a field of a binary table" bytesof(
            @test_logs((:warn, r"not ASCII text characters"), fits(IOBuffer(bad))))
        path = joinpath(mktempdir(), "ascii.fits")
        write(path, bad)
        @test bytesof(fits(path)) == bad
        #  unless the check is turned off, where the data that are read are written with the bytes that they were read with, the arrays of the strings
        #  of a variable-length field and of an array of strings too
        @test bytesof(@test_logs((:warn, r"not ASCII text characters"), fits(IOBuffer(bad); access = :memory)); check = false) == bad
        for (data, kwds) in (((s = ["é", "abc"],), (;)), ((s = ["é", "abc"],), (; variable = (s = 'P',))), ((t = ["é" "b"; "c" "d"],), (;)))
            written = bytesof([HDU(Primary), HDU(Bintable, data; kwds...)]; check = false)
            read_ = @test_logs((:warn, r"not ASCII text characters"), fits(IOBuffer(written))[2].data)
            @test read_ == data && bytesof(fits(IOBuffer(written)); check = false) == written
        end

        #  a string is not missing, since the strings have no undefined value, and its null string, which begins with a NUL, is the empty string
        @test_throws ArgumentError("Field s has a missing string, but the strings of a binary table have no undefined value: a null string, " *
            "which begins with a NUL, is read as the empty string (Sect. 7.3.3.1). Use the empty string.") bytesof([HDU(Primary), HDU(Bintable, (s = ["a", missing],))])
        @test_throws ArgumentError r"The array of strings has a missing string, but the strings of a binary table have no undefined value" HDU(
            Bintable, (s = ["a" missing; "b" "c"],))
        @test reread((s = ["a", "b"],)).data.s == ["a", "b"]
        nul = change(change(raw, "abc", 0, 0x00), "def", 1, 0x00)
        @test fits(IOBuffer(nul))[2].data.s == ["", "d", "ghi"]
        #  and the arrays of strings of no characters have a character of each string, since their first dimension is the characters of TDIMn (Sect. 7.3.2)
        for data in ((t = ["" ""; "" ""],), (t = reshape(["", "", "", "", "", ""], 2, 3),))
            hdu = HDU(Bintable, data)
            @test getfield(hdu, :cards)["TDIM1"] == "(1," * join(size(data.t)[2:end], ",") * ")"
            @test reread(data).data.t == data.t
        end
        hdu = HDU(Bintable, (t = ["ab" "cd"; "ef" "gh"],))
        cards = copy(getfield(hdu, :cards))
        cards["TDIM1"] = "(0,2)"
        @test_throws ArgumentError r"needs the dimensions of TDIM, whose first dimension is the number of characters of a string \(Sect. 7.3.2\), but 0 × 2 cannot be used" bytesof(
            [HDU(Primary), HDU{Bintable}(cards, hdu.data)])
        cards = copy(getfield(hdu, :cards))
        popat!(cards, "TDIM1")
        @test_throws ArgumentError r"but the field has none" bytesof([HDU(Primary), HDU{Bintable}(cards, hdu.data)])

        #  a table that has no fields has no rows and no data, whether it is made without data or from data that have no fields, and is read as the same
        for hdu in (HDU(Bintable), HDU(Bintable, NamedTuple()), HDU(Bintable, ()))
            @test getfield(hdu, :cards)["TFIELDS"] == 0 && getfield(hdu, :cards)["NAXIS1"] == 0 && getfield(hdu, :cards)["NAXIS2"] == 0
            @test ismissing(getfield(hdu, :data)) && size(hdu) == (0, 0)
            read_ = fits(IOBuffer(bytesof([HDU(Primary), hdu])))[2]
            @test ismissing(read_.data) && getfield(read_, :cards)["TFIELDS"] == 0
        end

        #  the name of a field is a string of the ASCII text characters that has at most 68 characters, which is its TTYPEn (Sect. 4.2.1.1)
        @test_throws ArgumentError("The name of field 2, \"ñ\", has characters that are not ASCII text characters, but the value of a TTYPEn keyword " *
            "is a string of them (Sect. 4.2.1.1).") HDU(Bintable, NamedTuple{(:a, :ñ)}(([1], [2])))
        @test_throws ArgumentError("The name of field 1, \"" * "a"^20 * "\"..., has 80 characters, but the value of a TTYPEn keyword has at most 68 " *
            "(Sect. 4.2.1.1).") HDU(Bintable, NamedTuple{(Symbol("a"^80),)}(([1],)))
        @test keys(reread(NamedTuple{(Symbol("a"^68), :b)}(([1], [2]))).data) == (Symbol("a"^68), :b)
    end

    @testset "strict writes" begin
        bytesof(hdus; kwds...) = (io = IOBuffer(); write(io, hdus; kwds...); take!(io))
        #  a field of bits has no scale and zero (Sect. 7.3.2), which is an error when the table is written, unless the check is turned off
        cards = Card{<:Any}[Card("TSCAL1", 2.0)]
        hdu = HDU(Bintable, (b = [BitVector([1, 0, 1])],), cards)
        @test_throws ArgumentError r"TSCAL1 and TZERO1 must not be used for a field of type X \(Sect. 7.3.2\)\. They are not used\. Use check = false to write it as it is\.$" bytesof(
            [HDU(Primary), hdu])
        written = @test_logs (:warn, r"TSCAL1 and TZERO1 must not be used") match_mode = :any bytesof([HDU(Primary), hdu]; check = false)
        @test @test_logs((:warn, r"TSCAL1 and TZERO1 must not be used"), match_mode = :any, fits(IOBuffer(written)))[2].data.b == [BitVector([1, 0, 1])]
        #  the bytes of a row that no field has are not read, so the data that are written from memory have zeros in their place, which an error says, and
        #  the data that are not read are copied with them, if the check is turned off
        raw = bytesof([HDU(Primary), HDU(Bintable, (a = Int16[1, 2],))])
        i = findfirst(b"NAXIS1  =                    2", raw)
        longer = copy(raw)
        longer[first(i) + 29] = UInt8('4')
        longer = vcat(longer[1:5760], UInt8[0x00, 0x01, 0xaa, 0xbb, 0x00, 0x02, 0xcc, 0xdd], zeros(UInt8, 2880 - 8))
        message = "NAXIS1 is 4, but the fields of TFORMn have 2 bytes in a row, which is the value that NAXIS1 must have (Eq. 8, Sect. 7.3.1)."
        eager = @test_logs (:warn, r"NAXIS1 is 4") (:warn, r"NAXIS1 is 4") match_mode = :any fits(IOBuffer(longer); access = :memory)
        @test_throws ArgumentError(message * " Use check = false to write it, where the 2 bytes after the fields of a row, which are not read, are " *
            "written as zeros.") bytesof(eager)
        out = @test_logs (:warn, r"The 2 bytes after the fields of a row are not read, and are written as zeros") match_mode = :any bytesof(eager; check = false)
        @test out[5761:5768] == UInt8[0x00, 0x01, 0x00, 0x00, 0x00, 0x02, 0x00, 0x00]
        path = joinpath(mktempdir(), "longer.fits")
        write(path, longer)
        lazy = @test_logs (:warn, r"NAXIS1 is 4") (:warn, r"NAXIS1 is 4") match_mode = :any fits(path)
        @test_throws ArgumentError(message * " Use check = false to write it as it is.") bytesof(lazy)
        @test @test_logs((:warn, r"NAXIS1 is 4"), (:warn, r"NAXIS1 is 4"), match_mode = :any, bytesof(lazy; check = false)) == longer
        small = bytesof([HDU(Primary), HDU(Bintable, (v = [Int16[1, 2, 3], Int16[4]],))])
        #  the repeat count of an array descriptor is 0 or 1 (Sect. 7.3.3.1), which is read as 1, with a warning, and is an error when it is written
        repeat2 = copy(small)
        j = findfirst(b"1PI(3)", repeat2)
        repeat2[first(j)] = UInt8('2')
        wide = @test_logs (:warn, r"TFORM1 has the repeat count 2, but the only permitted repeat counts of an array descriptor are 0 and 1") match_mode = :any fits(IOBuffer(repeat2); access = :memory)
        @test wide[2].data.v == [Int16[1, 2, 3], Int16[4]]
        @test_throws ArgumentError r"TFORM1 has the repeat count 2.*Use check = false to write it as it is\.$" bytesof(wide)
        #  an emax of a variable-length field that is less than its arrays is corrected in the header that is written, and the bytes of the file that is
        #  not read are copied as they are
        i = findfirst(b"1PI(3)", small)
        less = copy(small)
        less[first(i) + 4] = UInt8('2')
        @test @test_logs((:warn, r"TFORM1 set to \"1PI\(3\)\", since the longest array of field v has 3 elements"), bytesof(fits(IOBuffer(less); access = :memory))) == small
        write(path, less)
        @test bytesof(fits(path)) == less
    end

end

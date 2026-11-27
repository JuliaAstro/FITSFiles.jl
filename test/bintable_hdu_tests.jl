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
    write(io, HDU(data, cards))
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
    write(io, HDU(data, cards))
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
    write(io, HDU(data, cards))
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
    write(io, HDU(data, cards))
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
                   ("TSCAL1", 0.1f0, "",
                    "TSCAL1  =                  0.1                                                  "),
                   ("TZERO2", 1.0f0, "",
                    "TZERO2  =                  1.0                                                  "),
                   ("TSCAL2", 0.1f0, "",
                    "TSCAL2  =                  0.1                                                  "),
                   ("TZERO3", 1.0f0, "",
                    "TZERO3  =                  1.0                                                  "),
                   ("TSCAL3", 0.1f0, "",
                    "TSCAL3  =                  0.1                                                  "),
                   ("TZERO4", 1.0f0, "",
                    "TZERO4  =                  1.0                                                  "),
                   ("TSCAL4", 0.1f0, "",
                    "TSCAL4  =                  0.1                                                  "),
                   ("TZERO5", 1.0f0, "",
                    "TZERO5  =                  1.0                                                  "),
                   ("TSCAL5", 0.1f0, "",
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
                "NAXIS1  =                    $naxis1", "NAXIS2  =                    $naxis2",
                "PCOUNT  =                    $pcount", "GCOUNT  =                    1"], cards, ["END"])
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
                "NAXIS1  =                    $naxis1", "NAXIS2  =                    $naxis2",
                "PCOUNT  =                    $pcount", "GCOUNT  =                    1", "TFIELDS =                    1"], cards, ["END"])
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
                "NAXIS1  =                    $naxis1", "NAXIS2  =                    $naxis2",
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
end

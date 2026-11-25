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
    @test columns.UINT == [46.0, 128.0] && eltype(columns.UINT) === Float64
    @test columns.SCALED == Float32[2, 3] && eltype(columns.SCALED) === Float32
    @test columns.UINTS == [46.0 128.0; 128.0 46.0]

    seekstart(scaled_io)
    records = read(scaled_io, HDU; record=true, scale=true).data
    @test getproperty.(records, :UINT) == [46.0, 128.0]
    @test getproperty.(records, :SCALED) == Float32[2, 3]
    @test getproperty.(records, :UINTS) == [[46.0, 128.0], [128.0, 46.0]]

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
            bintablebytes([cards; "THEAP   =                    1"], 1, 2, UInt8[T, F]))

        #  a variable-length array of logical values
        cardsp = ["TFIELDS =                    1", "TFORM1  = '1PL(3)  '", "TTYPE1  = 'flags   '"]
        descriptors = UInt8[0, 0, 0, 3, 0, 0, 0, 0, 0, 0, 0, 2, 0, 0, 0, 3]
        bytes = bintablebytes(cardsp, 8, 2, [descriptors; UInt8[T, F, N, F, T]]; pcount = 5)
        flags = reread(bytes).data.flags
        @test isequal(flags[1], [true, false, missing]) && flags[2] == [false, true]
    end

end

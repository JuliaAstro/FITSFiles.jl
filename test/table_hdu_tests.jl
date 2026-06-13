@testset "Table HDU" begin

    #  test Table (specific HDU) type
    hdu = HDU(Table)

    @test isequal(
        showfields.(hdu.cards),
        [
            (
                "XTENSION", "TABLE   ", "",
                "XTENSION= 'TABLE   '                                                            ",
            ),
            (
                "BITPIX", 8, "",
                "BITPIX  =                    8                                                  ",
            ),
            (
                "NAXIS", 2, "",
                "NAXIS   =                    2                                                  ",
            ),
            (
                "NAXIS1", 0, "",
                "NAXIS1  =                    0                                                  ",
            ),
            (
                "NAXIS2", 0, "",
                "NAXIS2  =                    0                                                  ",
            ),
            (
                "PCOUNT", 0, "",
                "PCOUNT  =                    0                                                  ",
            ),
            (
                "GCOUNT", 1, "",
                "GCOUNT  =                    1                                                  ",
            ),
            (
                "TFIELDS", 0, "",
                "TFIELDS =                    0                                                  ",
            ),
        ]
    )

    @test ismissing(hdu.data)

    #  test Table type with cards
    cards = [
        Card("XTENSION", "TABLE"),
        Card("BITPIX", 8),
        Card("NAXIS", 2),
        Card("NAXIS1", 16),
        Card("NAXIS2", 3),
        Card("PCOUNT", 0),
        Card("GCOUNT", 1),
        Card("TFIELDS", 3),
        Card("TFORM1", "A4"),
        Card("TBCOL1", 1),
        Card("TFORM2", "A4"),
        Card("TBCOL2", 7),
        Card("TFORM3", "A4"),
        Card("TBCOL3", 13),
    ]
    hdu = HDU(cards)

    @test isequal(
        showfields.(hdu.cards),
        [
            (
                "XTENSION", "TABLE   ", "",
                "XTENSION= 'TABLE   '                                                            ",
            ),
            (
                "BITPIX", 8, "",
                "BITPIX  =                    8                                                  ",
            ),
            (
                "NAXIS", 2, "",
                "NAXIS   =                    2                                                  ",
            ),
            (
                "NAXIS1", 16, "",
                "NAXIS1  =                   16                                                  ",
            ),
            (
                "NAXIS2", 3, "",
                "NAXIS2  =                    3                                                  ",
            ),
            (
                "PCOUNT", 0, "",
                "PCOUNT  =                    0                                                  ",
            ),
            (
                "GCOUNT", 1, "",
                "GCOUNT  =                    1                                                  ",
            ),
            (
                "TFIELDS", 3, "",
                "TFIELDS =                    3                                                  ",
            ),
            (
                "TFORM1", "A4", "",
                "TFORM1  = 'A4'                                                                  ",
            ),
            (
                "TBCOL1", 1, "",
                "TBCOL1  =                    1                                                  ",
            ),
            (
                "TFORM2", "A4", "",
                "TFORM2  = 'A4'                                                                  ",
            ),
            (
                "TBCOL2", 7, "",
                "TBCOL2  =                    7                                                  ",
            ),
            (
                "TFORM3", "A4", "",
                "TFORM3  = 'A4'                                                                  ",
            ),
            (
                "TBCOL3", 13, "",
                "TBCOL3  =                   13                                                  ",
            ),
        ]
    )

    @test (
        length(hdu.data) == 3 && length(hdu.data[1]) == 16
            && eltype(hdu.data) <: AbstractString
    )

    #  test Table type with data being a tuple of arrays and cards
    data = [
        (par1 = 1, par2 = 1.0f0, par3 = 1.0, par4 = "1.0")
        (par1 = 2, par2 = 2.0f0, par3 = 2.0, par4 = "2.0")
        (par1 = 3, par2 = 3.0f0, par3 = 3.0, par4 = "3.0")
    ]
    cards = [
        Card("TFIELDS", 4),
        Card("TFORM1", "A4"),
        Card("TBCOL1", 1),
        Card("TFORM2", "A4"),
        Card("TBCOL2", 7),
        Card("TFORM3", "A4"),
        Card("TBCOL3", 13),
        Card("TFORM4", "A4"),
        Card("TBCOL4", 19),
    ]
    hdu = HDU(Table, data, cards)

    #  test Table type with data being a tuple of arrays and inconsistent cards


    #  test Table type with data being an array of records and cards


    #  test Table type with data being an array of records and inconsistent cards


    #  test Table type with data being an array of records and cards and record == false


    #  test Table type with data being an array of records and cards and record == true


    #  test Table type with data being an array of records and cards and scale == true


    #  test Table type with data being an array of records and cards and scale == false


end

@testset "Table HDU" begin

    #  test Table (specific HDU) type
    hdu = HDU(Table)

    @test isequal(showfields.(hdu.cards),
                  [("XTENSION", "TABLE   ", "",
                    "XTENSION= 'TABLE   '                                                            "),
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

    #  test Table type with cards
    cards = [Card("XTENSION", "TABLE"),
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
             Card("TBCOL3", 13)]
    hdu = HDU(cards)

    @test isequal(showfields.(hdu.cards),
                  [("XTENSION", "TABLE   ", "",
                    "XTENSION= 'TABLE   '                                                            "),
                   ("BITPIX", 8, "",
                    "BITPIX  =                    8                                                  "),
                   ("NAXIS", 2, "",
                    "NAXIS   =                    2                                                  "),
                   ("NAXIS1", 16, "",
                    "NAXIS1  =                   16                                                  "),
                   ("NAXIS2", 3, "",
                    "NAXIS2  =                    3                                                  "),
                   ("PCOUNT", 0, "",
                    "PCOUNT  =                    0                                                  "),
                   ("GCOUNT", 1, "",
                    "GCOUNT  =                    1                                                  "),
                   ("TFIELDS", 3, "",
                    "TFIELDS =                    3                                                  "),
                   ("TFORM1", "A4", "",
                    "TFORM1  = 'A4'                                                                  "),
                   ("TBCOL1", 1, "",
                    "TBCOL1  =                    1                                                  "),
                   ("TFORM2", "A4", "",
                    "TFORM2  = 'A4'                                                                  "),
                   ("TBCOL2", 7, "",
                    "TBCOL2  =                    7                                                  "),
                   ("TFORM3", "A4", "",
                    "TFORM3  = 'A4'                                                                  "),
                   ("TBCOL3", 13, "",
                    "TBCOL3  =                   13                                                  ")])

    @test (length(hdu.data) == 3 && length(hdu.data[1]) == 16
           && eltype(hdu.data) <: AbstractString)

    #  test Table type with data being a tuple of arrays and cards
    data = [(par1=1, par2=1.0f0, par3=1.0, par4="1.0")
            (par1=2, par2=2.0f0, par3=2.0, par4="2.0")
            (par1=3, par2=3.0f0, par3=3.0, par4="3.0")]
    cards = [Card("TFIELDS", 4),
             Card("TFORM1", "A4"),
             Card("TBCOL1", 1),
             Card("TFORM2", "A4"),
             Card("TBCOL2", 7),
             Card("TFORM3", "A4"),
             Card("TBCOL3", 13),
             Card("TFORM4", "A4"),
             Card("TBCOL4", 19)]
    hdu = HDU(Table, data, cards)

    #  test Table type with data being a tuple of arrays and inconsistent cards


    #  test Table type with data being an array of records and cards


    #  test Table type with data being an array of records and inconsistent cards


    #  test Table type with data being an array of records and cards and record == false



    #  test Table type with data being an array of records and cards and record == true


    #  test Table type with data being an array of records and cards and scale == true


    #  test Table type with data being an array of records and cards and scale == false



    ####    Test the undefined values of a column    ####

    @testset "TNULLn" begin
        #  the bytes of a Table HDU of the cards and the rows, preceded by an empty Primary HDU
        card(s) = rpad(s, 80)
        function tablebytes(cards, rows)
            primary = ["SIMPLE  =                    T", "BITPIX  =                    8",
                "NAXIS   =                    0", "END"]
            header = vcat(["XTENSION= 'TABLE   '", "BITPIX  =                    8", "NAXIS   =                    2",
                "NAXIS1  =                    $(length(rows[1]))", "NAXIS2  =                    $(length(rows))",
                "PCOUNT  =                    0", "GCOUNT  =                    1"], cards, ["END"])
            rpad(join(card.(primary)), 2880) * rpad(join(card.(header)), 2880) * rpad(join(rows), 2880)
        end
        reread(bytes; kwds...) = (io = IOBuffer(bytes); read(io, HDU); read(io, HDU; kwds...))
        cards = ["TFIELDS =                    2", "TFORM1  = 'I4      '", "TBCOL1  =                    1",
            "TNULL1  = '  -9'", "TSCAL1  =                  2.0", "TZERO1  =                 10.0",
            "TFORM2  = 'F5.1    '", "TBCOL2  =                    5"]
        rows = ["   1  1.5", "  -9  2.5", "   3  3.5"]
        bytes = tablebytes(cards, rows)

        #  scaling keeps an undefined entry in place, and the other entries are not moved
        data = reread(bytes).data
        @test isequal(data.column1, Union{Float32, Missing}[12, missing, 16])
        @test data.column2 == [1.5, 2.5, 3.5]
        @test isequal(reread(bytes; scale = false).data.column1, [1, missing, 3])

        #  a row has the same values as the column
        records = reread(bytes; record = true).data
        @test isequal([r.column1 for r in records], data.column1)
        @test [r.column2 for r in records] == data.column2

        #  a column without undefined entries has no missing values
        data = reread(tablebytes(cards, ["   1  1.5", "   2  2.5"])).data
        @test data.column1 isa Vector{Float32} && data.column1 == Float32[12, 14]

        #  without TSCALn and TZEROn the values are not scaled, so an integer above 2^24 is exact (Sect. 7.2.2)
        cards = ["TFIELDS =                    2", "TFORM1  = 'I10     '", "TBCOL1  =                    1",
            "TFORM2  = 'F5.1    '", "TBCOL2  =                   11"]
        bytes = tablebytes(cards, ["1234567891  1.5", "       -17  2.5"])
        data = reread(bytes).data
        @test data.column1 == [1234567891, -17] && data.column1 isa Vector{Int64}
        @test data.column2 == [1.5, 2.5]
        @test [r.column1 for r in reread(bytes; record = true).data] == [1234567891, -17]
        @test reread(bytes; scale = false).data == data
        #  a column with only one of TSCALn and TZEROn is scaled
        shifted = reread(tablebytes([cards[1:3]; "TZERO1  =                  1.0"; cards[4:5]],
            ["1234567891  1.5", "       -17  2.5"])).data
        @test shifted.column1 ≈ [1234567892, -16] rtol = 1e-6

        #  TNULLn is space filled to the width of the field (Sect. 7.2.2)
        cards = ["TFIELDS =                    1", "TFORM1  = 'I6      '", "TBCOL1  =                    1",
            "TNULL1  = 'NULL'"]
        bytes = tablebytes(cards, ["NULL  ", "    12"])
        @test isequal(reread(bytes; scale = false).data.column1, [missing, 12])
        @test isequal([r.column1 for r in reread(bytes; scale = false, record = true).data], [missing, 12])

        #  an undefined entry is written as TNULLn, or as blanks if there is no TNULLn
        function written(hdu)
            io = IOBuffer(); write(io, hdu); take!(io)[end-2879:end]
        end
        @test written(reread(bytes; scale = false)) == codeunits(rpad("NULL      12", 2880))
        bytes = tablebytes(cards[1:3], ["      ", "    12"])
        @test written(reread(bytes; scale = false)) == codeunits(rpad("          12", 2880))
    end
end

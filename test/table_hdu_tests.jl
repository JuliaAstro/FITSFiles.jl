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

    @test hdu.data == data

    ####    The bytes of tables for the tests    ####

    #  a header card of an integer, or of a string, in fixed format
    kw(key, value) = rpad(key, 8) * "=" * lpad(value, 21)
    sk(key, value) = rpad(key, 8) * "= '" * rpad(value, 8) * "'"
    card(s) = rpad(s, 80)
    #  the mandatory cards of a table of NAXIS1 `rowlen` and NAXIS2 `nrows`, up to GCOUNT
    mandatorycards(rowlen, nrows) = [sk("XTENSION", "TABLE"), kw("BITPIX", 8), kw("NAXIS", 2), kw("NAXIS1", rowlen),
        kw("NAXIS2", nrows), kw("PCOUNT", 0), kw("GCOUNT", 1)]
    #  the bytes of an empty Primary HDU and a Table HDU of the cards and the rows, which have no data blocks if the rows have no characters
    function tablebytes(cards, rows; rowlen = isempty(rows) ? 0 : length(rows[1]), nrows = length(rows), mandatory = nothing)
        primary = [kw("SIMPLE", "T"), kw("BITPIX", 8), kw("NAXIS", 0), "END"]
        header = vcat(isnothing(mandatory) ? mandatorycards(rowlen, nrows) : mandatory, cards, ["END"])
        data = join(rows)
        rpad(join(card.(primary)), 2880) * rpad(join(card.(header)), 2880) * (isempty(data) ? "" : rpad(data, 2880))
    end
    #  the cards of the fields: TFIELDS, the formats and the first columns, and the other cards
    function fieldcards(forms, columns; extra = String[])
        vcat([kw("TFIELDS", length(forms))], reduce(vcat, [[sk("TFORM$j", forms[j]), kw("TBCOL$j", columns[j])]
            for j in eachindex(forms)]; init = String[]), extra)
    end
    reread(bytes; kwds...) = (io = IOBuffer(bytes); read(io, HDU); read(io, HDU; kwds...))
    #  the bytes of an HDU that is read from `bytes` and written, with the empty Primary HDU that precedes it
    function written(bytes; kwds...)
        io = IOBuffer(bytes)
        primary, table = read(io, HDU), read(io, HDU; kwds...)
        out = IOBuffer()
        write(out, primary)
        write(out, table)
        take!(out)
    end
    #  the last data block of the HDU that is written, which is its rows
    rowsof(hdu; kwds...) = (io = IOBuffer(); write(io, hdu; kwds...); String(take!(io))[end-2879:end])
    #  the HDU that is written after an empty Primary HDU, and read
    function roundtrip(hdu; kwds...)
        io = IOBuffer()
        write(io, HDU(Primary))
        write(io, hdu)
        seekstart(io)
        read(io, HDU)
        read(io, HDU; kwds...)
    end

    ####    Test the values of a field (Sect. 7.2.5)    ####

    @testset "reading numbers" begin
        value(form, text; kwds...) = reread(tablebytes(fieldcards([form], [1]), [text]); kwds...).data.column1[1]
        #  an integer is a sign and digits with spaces around them
        for (text, number) in ["   12" => 12, "  +12" => 12, "  -12" => -12, "12   " => 12, " 12  " => 12, "00012" => 12]
            @test value("I5", text) === number
        end
        #  a real number has an optional sign, digits and a decimal point, and an exponent of E or D and a signed integer, or of a signed integer
        for (text, number) in ["  1.5   " => 1.5, " -1.5   " => -1.5, " 1.5E3  " => 1500.0, " 1.5E+3 " => 1500.0, " 1.5E-3 " => 0.0015,
            " 1.5D3  " => 1500.0, " 1.5e3  " => 1500.0, " 1.5+3  " => 1500.0, " 1.5-3  " => 0.0015, "   .5   " => 0.5,
            "   5.   " => 5.0, "  +.5E1 " => 5.0, " 15E-1  " => 0.15, "1.500E+0" => 1.5, "   0.   " => 0.0]
            @test value("E8.1", text) === number
        end
        @test value("D8.3", " 1.5D+00") === 1.5
        @test value("F8.3", "  -2.500") === -2.5
        @test value("F8.3", "  -0.000") === -0.0
        #  a number without a decimal point has it before the rightmost d digits (the d of the format), with leading zeros if necessary
        @test value("F6.2", "  1234") === 12.34
        @test value("F6.2", " -0123") === -1.23
        @test value("F6.2", "     5") === 0.05
        @test value("F6.2", " 12.34") === 12.34
        @test value("F6.2", "  12.3") === 12.3
        @test value("E8.1", " 123E2  ") === 1230.0
        @test value("F6.0", "   123") === 123.0
        #  a value that is not a number of the standard is an error that names the value, the field, the row, and the format, whatever Julia reads
        for (form, text) in ["I5" => "0x1F ", "I5" => "1.5  ", "I5" => "1 2  ", "I5" => "1e2  ", "I5" => "+    ", "I5" => "-    ",
            "I5" => "1_0  ", "I5" => "NaN  ", "E8.1" => "NaN     ", "E8.1" => "Inf     ", "E8.1" => "1 .5    ",
            "E8.1" => "1.5.2   ", "E8.1" => "1.5E    ", "E8.1" => "1.5E+   ", "E8.1" => "-       ", "E8.1" => ".       ",
            "E8.1" => "0x1F    ", "E8.1" => "1,5     ", "E8.1" => "1.5E3.2 ", "E8.1" => "1.5+3-2 "]
            kind = startswith(form, "I") ? "an integer" : "a real number"
            @test_throws ArgumentError("The value $(repr(text)) of field column1 in row 1 is not $kind of the format $form (Sect. 7.2.5).") value(
                form, text)
        end
        #  the row is the row of the value
        @test_throws ArgumentError r"in row 2 is not an integer" reread(tablebytes(fieldcards(["I4"], [1]), ["   1", "  x1"]))
        #  a number that an Int64 or a Float64 cannot hold is an error that says so, and not a Julia error
        @test_throws ArgumentError r"is not in the range of an Int64" value("I25", "12345678901234567890123  ")
        @test_throws ArgumentError r"is not in the range of a Float64" value("E10.1", "1.5E+400  ")
        @test value("I20", "-9223372036854775808    ") === typemin(Int64)
        #  a row has the same value in a record and in a column
        bytes = tablebytes(fieldcards(["I4", "F6.2"], [1, 5]), ["   1  1234", "  -2 -0123"])
        @test reread(bytes; record = true).data == [(column1 = 1, column2 = 12.34), (column1 = -2, column2 = -1.23)]
        @test reread(bytes).data == (column1 = [1, -2], column2 = [12.34, -1.23])
    end

    ####    Test the blank fields and the undefined values (Sects. 7.2.2 and 7.2.5)    ####

    @testset "blank fields" begin
        #  a blank field is 0, and an undefined value is the string TNULLn, which the field is space filled with
        rows = ["   1  1.5", "      2.5", "   3     "]
        bytes = tablebytes(fieldcards(["I4", "F5.1"], [1, 5]), rows)
        data = reread(bytes).data
        @test data.column1 isa Vector{Int64} && data.column1 == [1, 0, 3]
        @test data.column2 isa Vector{Float64} && data.column2 == [1.5, 2.5, 0.0]
        @test reread(bytes; record = true).data == [(column1 = 1, column2 = 1.5), (column1 = 0, column2 = 2.5), (column1 = 3, column2 = 0.0)]
        data = reread(tablebytes(fieldcards(["I4", "F5.1"], [1, 5]; extra = [sk("TNULL1", "  -9")]), ["   1  1.5", "  -9  2.5"])).data
        @test isequal(data.column1, [1, missing])
        #  a TNULLn that is blank makes a blank field undefined
        data = reread(tablebytes(fieldcards(["I4"], [1]; extra = [sk("TNULL1", "")]), ["   1", "    "])).data
        @test isequal(data.column1, [1, missing])
        #  a blank field of characters is an empty string, and a field of characters can have a TNULLn
        data = reread(tablebytes(fieldcards(["A4", "A4"], [1, 5]; extra = [sk("TNULL2", "N/A")]), ["ab  N/A ", "    cd  "])).data
        @test data.column1 == ["ab", ""] && isequal(data.column2, [missing, "cd"])

        #  the blank field is read as 0, so it is written as 0
        @test rowsof(reread(bytes))[1:27] == "   1  1.5   0  2.5   3  0.0"
        #  an undefined value is written as TNULLn, which the field has, and fits in it
        hdu = HDU(Table, (a = [1, missing],), Card{<:Any}[Card("TFORM1", "I4"), Card("TNULL1", "-9")])
        @test rowsof(hdu)[1:8] == "   1-9  "
        @test_throws ArgumentError("A missing value cannot be written to field a, which has no TNULLn keyword (Sect. 7.2.2).") rowsof(
            HDU(Table, (a = [1, missing],), Card{<:Any}[Card("TFORM1", "I4")]))
        @test_throws ArgumentError r"has more than the 4 characters of the field" rowsof(
            HDU(Table, (a = [1, missing],), Card{<:Any}[Card("TFORM1", "I4"), Card("TNULL1", "NOT DEFINED")]))
        #  an undefined value is read again as an undefined value
        @test isequal(roundtrip(hdu).data.a, [1, missing])
        bytes = tablebytes(fieldcards(["I4"], [1]; extra = [sk("TNULL1", "  -9")]), ["   1", "  -9"])
        @test written(bytes) == codeunits(bytes) && written(bytes; scale = false) == codeunits(bytes)
    end

    ####    Test the scaled values (Eq. 7)    ####

    @testset "scaled values" begin
        cards = fieldcards(["I4", "F5.1"], [1, 5]; extra = [sk("TNULL1", "  -9"), kw("TSCAL1", "2.0"), kw("TZERO1", "10.0")])
        rows = ["   1  1.5", "  -9  2.5", "   3  3.5"]
        bytes = tablebytes(cards, rows)
        #  the physical values are 64-bit floating-point numbers, and an undefined entry stays in place
        data = reread(bytes).data
        @test data.column1 isa Vector{Union{Float64, Missing}} && isequal(data.column1, [12.0, missing, 16.0])
        @test data.column2 == [1.5, 2.5, 3.5]
        @test isequal(reread(bytes; scale = false).data.column1, [1, missing, 3])
        @test reread(tablebytes(cards, rows[[1, 3]])).data.column1 isa Vector{Float64}
        #  a column that has the default scale and zero is not scaled, so an integer above 2^24 is exact (Sect. 7.2.2), and a column that has
        #  one of them is, with exact integers if the scale is 1 and the zero is an integer, and 64-bit floating-point numbers if it is not
        cards = fieldcards(["I10", "F5.1"], [1, 11])
        rows = ["1234567891  1.5", "       -17  2.5"]
        @test reread(tablebytes(cards, rows)).data.column1 == [1234567891, -17]
        shifted = reread(tablebytes([cards[1:3]; kw("TZERO1", "1.0"); cards[4:5]], rows)).data.column1
        @test shifted isa FITSFiles.ScaledArray{Int64} && shifted == [1234567892, -16]
        shifted = reread(tablebytes([cards[1:3]; kw("TZERO1", "1.5"); cards[4:5]], rows)).data.column1
        @test shifted isa Vector{Float64} && shifted == [1234567892.5, -15.5]
        #  the scale is a 64-bit number, so 0.1 is 0.1 and not the number of a 32-bit one
        scaled = reread(tablebytes(fieldcards(["F12.9"], [1]; extra = [kw("TSCAL1", "0.1")]), ["1.123456789 "])).data.column1
        @test scaled[1] ≈ 0.1123456789 rtol = 1e-15
        @test reread(tablebytes(fieldcards(["I4"], [1]; extra = [kw("TSCAL1", "0.1")]), ["   3"])).data.column1[1] ≈ 0.3 rtol = 1e-15
        #  a floating-point column that is scaled is a ScaledArray, which has the scale and the zero, and so are the records
        cards = fieldcards(["F5.1"], [1]; extra = [kw("TSCAL1", "2.0"), kw("TZERO1", "10.0")])
        bytes = tablebytes(cards, [" 1.5 ", " 2.5 "])
        column = reread(bytes).data.column1
        @test column isa FITSFiles.ScaledArray && column == [13.0, 15.0] && (column.scale, column.zero) == (2.0, 10.0)
        @test reread(bytes; scale = false).data.column1 == [1.5, 2.5]
        records = reread(bytes; record = true).data
        @test records isa FITSFiles.ScaledRows && records == [(column1 = 13.0,), (column1 = 15.0,)]
        #  the scaled values are written as the stored values, so that the HDU is written as it was read (Eq. 7), whether the values were
        #  scaled or not
        cards = fieldcards(["I4", "F5.1"], [1, 5]; extra = [sk("TNULL1", "  -9"), kw("TSCAL1", "2.0"), kw("TZERO1", "10.0"),
            kw("TSCAL2", "0.5"), kw("TZERO2", "-1.0")])
        bytes = tablebytes(cards, ["   1  1.5", "  -9  2.5", "   3  3.5"])
        for kwds in ((;), (; record = true), (; scale = false))
            @test written(bytes; kwds...) == codeunits(bytes)
        end
        #  the data that are made with a scale have the scale of the header, and the physical values are written as the stored values
        hdu = HDU(Table, (a = FITSFiles.ScaledArray([13.0, 15.0], 2.0, 10.0),), Card{<:Any}[Card("TFORM1", "F5.1")])
        @test getfield(hdu, :cards)["TSCAL1"] == 2.0 && getfield(hdu, :cards)["TZERO1"] == 10.0
        @test rowsof(hdu)[1:10] == "  1.5  2.5"
        again = roundtrip(hdu).data.a
        @test again == [13.0, 15.0] && again isa FITSFiles.ScaledArray
        #  data that have a scale and a zero that are not those of the header are an error
        data = (a = FITSFiles.ScaledArray([13.0, 15.0], 2.0, 10.0),)
        cards = copy(getfield(HDU(Table, data, Card{<:Any}[Card("TFORM1", "F5.1")]), :cards))
        cards["TSCAL1"] = 3.0
        @test_throws ArgumentError r"The scale and the zero of the data of field a, 2.0 and 10.0, are not the TSCAL and the TZERO of the header, 3.0 and 10.0" rowsof(
            HDU{Table}(cards, data))
        #  the values of an integer field that are physical values are inverted and rounded, and are checked
        hdu = HDU(Table, (a = [11.2],), Card{<:Any}[Card("TFORM1", "I4"), Card("TSCAL1", 2.5), Card("TZERO1", 10.0)])
        @test_throws ArgumentError r"The value 11.2 cannot be stored as Int64 data with TSCAL 2.5 and TZERO 10.0" rowsof(hdu)
        @test rowsof(hdu; check = false)[1:4] == "   0"
        hdu = HDU(Table, (a = [12.5],), Card{<:Any}[Card("TFORM1", "I4"), Card("TSCAL1", 2.5), Card("TZERO1", 10.0)])
        @test rowsof(hdu)[1:4] == "   1"
        #  the values of an integer field that are integers are the stored values, and an integer field does not have other numbers
        hdu = HDU(Table, (a = [12],), Card{<:Any}[Card("TFORM1", "I4"), Card("TSCAL1", 2.5), Card("TZERO1", 10.0)])
        @test rowsof(hdu)[1:4] == "  12"
        @test_throws ArgumentError r"not an integer" rowsof(HDU(Table, (a = [1.5],), Card{<:Any}[Card("TFORM1", "I4")]))
    end

    ####    Test the exact integers of the scaled integer fields (Sect. 7.2.2)    ####

    @testset "exact integers" begin
        zero2 = "9223372036854775808"
        cards(zero, form = "I20") = fieldcards([form], [1]; extra = [kw("TZERO1", zero)])
        bytes(zero, values; form = "I20") = tablebytes(cards(zero, form), [lpad(value, parse(Int, form[2:end])) for value in values])
        #  the physical values are integers if TSCALn is 1 and TZEROn is an integer, which a floating-point number of a whole number is, and
        #  they are the first type of Int64, UInt64, and Int128 that holds them
        column = reread(bytes("100", [1, 2, -3])).data.column1
        @test column isa FITSFiles.ScaledArray{Int64} && column == [101, 102, 97] && (column.scale, column.zero) == (1, 100)
        @test reread(bytes("100.0", [1, 2, -3])).data.column1 isa FITSFiles.ScaledArray{Int64}
        @test reread(bytes("100.5", [1, 2, -3])).data.column1 isa Vector{Float64}
        @test reread(tablebytes(fieldcards(["I4"], [1]; extra = [kw("TZERO1", "100"), kw("TSCAL1", "2")]), ["   1"])).data.column1 isa Vector{Float64}
        #  an offset that is 2^63 gives the 64-bit unsigned integers, which a 64-bit float does not hold
        values = [typemin(Int64), typemin(Int64) + 5, typemax(Int64)]
        column = reread(bytes(zero2, values)).data.column1
        @test column isa FITSFiles.ScaledArray{UInt64} && column == UInt64[0, 5, 18446744073709551615]
        column = reread(bytes(zero2, values[1:2])).data.column1
        @test column isa FITSFiles.ScaledArray{Int64} && column == [0, 5]
        #  an offset beyond 64 bits gives 128-bit integers, and one that is not a number of Int128 is a floating-point number
        column = reread(bytes("-9223372036854775809", [typemin(Int64), 5])).data.column1
        @test column isa FITSFiles.ScaledArray{Int128} && column == Int128[-18446744073709551617, -9223372036854775804]
        @test reread(bytes("1.0E40", [1, 2])).data.column1 isa Vector{Float64}
        #  an undefined entry stays in place, and the columns of no values have the type of the others
        cards2 = fieldcards(["I4"], [1]; extra = [kw("TZERO1", "100"), sk("TNULL1", "  -9")])
        column = reread(tablebytes(cards2, ["   1", "  -9", "   3"])).data.column1
        @test column isa FITSFiles.ScaledArray{Union{Int64, Missing}} && isequal(column, [101, missing, 103])
        @test isequal(reread(tablebytes(cards2, ["  -9"])).data.column1, [missing])
        #  the values that are not scaled are the stored values, and the records have the exact integers
        @test reread(bytes("100", [1, 2]); scale = false).data.column1 == [1, 2]
        records = reread(bytes("100", [1, 2]); record = true).data
        @test records isa FITSFiles.ScaledRows && records == [(column1 = 101,), (column1 = 102,)]
        @test records[1].column1 isa Int64
        #  the exact integers are written as the stored values, so that the HDU is written as it was read, whichever way it was read
        for (zero, values) in ["100" => [1, 2, -3], zero2 => values, "-9223372036854775809" => [typemin(Int64), 5], "100.0" => [1, 2]]
            for kwds in ((;), (; record = true), (; scale = false))
                source = bytes(zero, values)
                @test written(source; kwds...) == codeunits(source)
            end
        end
        source = tablebytes(cards2, ["   1", "  -9", "   3"])
        @test written(source) == codeunits(source) && written(source; record = true) == codeunits(source)
        #  the data that are made from them have the scale and the zero of the header, and the values that are not exact integers are errors
        hdu = HDU(Table, (a = FITSFiles.ScaledArray([101, 102], 1, 100),), Card{<:Any}[Card("TFORM1", "I4")])
        @test getfield(hdu, :cards)["TZERO1"] == 100 && !haskey(getfield(hdu, :cards), "TSCAL1")
        @test rowsof(hdu)[1:8] == "   1   2"
        again = roundtrip(hdu).data.a
        @test again isa FITSFiles.ScaledArray{Int64} && again == [101, 102]
        hdu = HDU(Table, (a = FITSFiles.ScaledArray([101.0, 102.0], 1, 100),), Card{<:Any}[Card("TFORM1", "I4")])
        @test rowsof(hdu)[1:8] == "   1   2"
        hdu = HDU(Table, (a = FITSFiles.ScaledArray([101.5], 1, 100),), Card{<:Any}[Card("TFORM1", "I4")])
        @test_throws ArgumentError r"The value 101.5 of field a is not an integer, but the field has the format I4" rowsof(hdu)
        hdu = HDU(Table, (a = FITSFiles.ScaledArray(UInt64[18446744073709551615], 1, parse(Int128, zero2)),), Card{<:Any}[Card("TFORM1", "I20")])
        @test strip(rowsof(hdu)[1:20]) == "9223372036854775807"
        hdu = HDU(Table, (a = FITSFiles.ScaledArray(Int128[Int128(2)^100], 1, parse(Int128, zero2)),), Card{<:Any}[Card("TFORM1", "I20")])
        @test_throws ArgumentError r"is the stored value .* with TZERO 9223372036854775808, which is not in the range of an Int64" rowsof(hdu)
        hdu = HDU(Table, (a = FITSFiles.ScaledArray([1], 1, 5),), Card{<:Any}[Card("TFORM1", "I4"), Card("TZERO1", 6)])
        @test getfield(hdu, :cards)["TZERO1"] == 5
        #  the integers of a field of the header are the stored values
        hdu = HDU(Table, (a = [7],), Card{<:Any}[Card("TFORM1", "I4"), Card("TZERO1", 100)])
        @test rowsof(hdu)[1:4] == "   7"
    end

    ####    Test the fields that are made from data    ####

    @testset "creating tables" begin
        columns = (a = [1, 22], b = [2.5, -3.25], c = ["xy", "z"])
        hdu = HDU(Table, columns)
        cards = Dict(card.key => card.value for card in getfield(hdu, :cards))
        @test [rstrip(cards["TFORM$j"]) for j = 1:3] == ["I2", "D25.16", "A2"] && [cards["TBCOL$j"] for j = 1:3] == [1, 4, 30]
        @test [cards[key] for key in ("NAXIS", "NAXIS1", "NAXIS2", "TFIELDS", "PCOUNT", "GCOUNT")] == [2, 31, 2, 3, 0, 1]
        @test [rstrip(cards["TTYPE$j"]) for j = 1:3] == ["a", "b", "c"]
        @test hdu.data == columns
        #  the rows have the fields one space apart, and the data are written and read as they are
        row1 = " 1" * " " * lpad("2.5000000000000000D+00", 25) * " " * "xy"
        row2 = "22" * " " * lpad("-3.2500000000000000D+00", 25) * " " * "z "
        @test rowsof(hdu)[1:62] == row1 * row2
        @test roundtrip(hdu).data == columns
        #  records give the same table as columns
        records = [(a = 1, b = 2.5, c = "xy"), (a = 22, b = -3.25, c = "z")]
        @test rowsof(HDU(Table, records)) == rowsof(hdu)
        @test HDU(Table, records).data == records
        @test roundtrip(HDU(Table, records); record = true).data == records
        #  the formats and the columns of the cards are kept, and the fields that do not have them follow the previous field
        hdu = HDU(Table, columns, Card{<:Any}[Card("TFORM2", "F8.3"), Card("TBCOL2", 10)])
        cards = Dict(card.key => card.value for card in getfield(hdu, :cards))
        @test [rstrip(cards["TFORM$j"]) for j = 1:3] == ["I2", "F8.3", "A2"] && [cards["TBCOL$j"] for j = 1:3] == [1, 10, 19]
        @test cards["NAXIS1"] == 20
        @test rowsof(hdu)[1:40] == (" 1" * " "^7 * "   2.500" * " " * "xy") * ("22" * " "^7 * "  -3.250" * " " * "z ")
        #  the format of a column of floating-point numbers that are not 64-bit, of integers, and of characters is the format of its digits, and a
        #  column of no values has a field of one character
        forms(data) = [rstrip(card.value) for card in getfield(HDU(Table, data), :cards) if startswith(card.key, "TFORM")]
        @test forms((a = Float32[1.5], b = Int8[-100], c = [""])) == ["E16.8", "I4", "A1"]
        @test forms((d = Int64[], e = Float64[], f = String[])) == ["I1", "D25.16", "A1"]
        #  the values that are not strings, integers, or floating-point numbers are errors that say what the fields have
        @test_throws ArgumentError r"The values of field 1 have the type Bool, but the values of a field of an ASCII table are strings \(A\)" HDU(
            Table, (a = [true],))
        @test_throws ArgumentError r"type Symbol" HDU(Table, (a = [:x],))
        @test_throws ArgumentError r"at most 999" HDU(Table, [collect(1:1000)])
        #  the keywords formats and columns are the formats and the first columns of the fields, for columns, records, and tuples of columns, and
        #  they override the cards
        for data in (columns, [(a = 1, b = 2.5, c = "xy"), (a = 22, b = -3.25, c = "z")], ([1, 22], [2.5, -3.25], ["xy", "z"]))
            hdu = HDU(Table, data; formats = ["I4", "F8.3", "A3"], columns = [1, 6, 15])
            cards = Dict(card.key => card.value for card in getfield(hdu, :cards))
            @test [rstrip(cards["TFORM$j"]) for j = 1:3] == ["I4", "F8.3", "A3"] && [cards["TBCOL$j"] for j = 1:3] == [1, 6, 15]
            @test cards["NAXIS1"] == 17
            @test rowsof(hdu)[1:34] == ("   1" * " " * "   2.500" * " " * "xy ") * ("  22" * " " * "  -3.250" * " " * "z  ")
        end
        hdu = HDU(Table, columns, Card{<:Any}[Card("TFORM2", "E10.2"), Card("TBCOL2", 9)]; formats = ["I4", "F8.3", "A3"])
        cards = Dict(card.key => card.value for card in getfield(hdu, :cards))
        @test [rstrip(cards["TFORM$j"]) for j = 1:3] == ["I4", "F8.3", "A3"] && [cards["TBCOL$j"] for j = 1:3] == [1, 9, 18]
        hdu = HDU(Table, columns; columns = [1, 10, 20])
        cards = Dict(card.key => card.value for card in getfield(hdu, :cards))
        @test [rstrip(cards["TFORM$j"]) for j = 1:3] == ["I2", "D25.16", "A2"] && [cards["TBCOL$j"] for j = 1:3] == [1, 10, 20]
        @test roundtrip(HDU(Table, columns; formats = ["I4", "F8.3", "A3"], columns = [1, 6, 15])).data == columns
        #  the strings of the rows have the fields of the keywords
        hdu = HDU(Table, ["   1  1.5", "   2  2.5"]; formats = ["I4", "F5.1"], columns = [1, 5])
        @test getfield(hdu, :cards)["TFIELDS"] == 2 && roundtrip(hdu).data == (column1 = [1, 2], column2 = [1.5, 2.5])
        #  the keywords have a value for each field, and the formats are the formats of Table 15
        @test_throws ArgumentError("The keyword formats has 1 values, but the data have 3 fields.") HDU(Table, columns; formats = ["I4"])
        @test_throws ArgumentError("The keyword columns has 2 values, but the data have 3 fields.") HDU(Table, columns; columns = [1, 5])
        @test_throws ArgumentError r"columns\[1\] must be an integer of at least 1, the first column of a row, but its value is 0" HDU(
            Table, columns; columns = [0, 5, 9])
        @test_throws ArgumentError r"columns\[2\] must be an integer of at least 1.*value is 2.5" HDU(Table, columns; columns = Any[1, 2.5, 9])
        @test_throws ArgumentError r"formats\[2\] must be a format of Table 15, Aw, Iw, Fw.d, Ew.d, or Dw.d" HDU(
            Table, columns; formats = ["I4", "G8.3", "A3"])
        @test_throws ArgumentError("formats[2] must be a character string, but its value is 5.") HDU(Table, columns; formats = ["I4", 5, "A3"])
        #  the records and the columns are matched to the fields by name, in any order, so that the fields have their values whichever way the
        #  names are ordered
        records = [(a = 1000, b = 2), (b = 3, a = 4)]
        hdu = HDU(Table, records)
        @test [rstrip(card.value) for card in getfield(hdu, :cards) if startswith(card.key, "TFORM")] == ["I4", "I1"]
        @test roundtrip(hdu).data == (a = [1000, 4], b = [2, 3])
        @test rowsof(hdu)[1:12] == "1000 2   4 3"
        hdu = HDU(Table, (a = [1, 2], b = ["x", "yy"]))
        @test rowsof(HDU{Table}(getfield(hdu, :cards), (b = ["x", "yy"], a = [1, 2]))) == rowsof(hdu)
        @test rowsof(HDU{Table}(getfield(hdu, :cards), [(b = "x", a = 1), (a = 2, b = "yy")])) == rowsof(hdu)
        @test_throws ArgumentError r"Record 2 of the data does not have the names of the first record, a, b" HDU(Table, [(a = 1, b = 2), (a = 3, c = 4)])
        @test_throws ArgumentError r"Record 2 of the data has no value named b, the name of field 2, but it has a, c" rowsof(HDU{Table}(
            getfield(hdu, :cards), [(a = 1, b = "x"), (a = 3, c = "y")]))
        @test_throws ArgumentError r"The data have no column named b, the name of field 2, but they have a, c" rowsof(HDU{Table}(
            getfield(hdu, :cards), (a = [1, 2], c = ["x", "yy"])))
        #  a tuple of columns, and records that are tuples, are at the place of the field
        @test rowsof(HDU(Table, ([1, 2], ["x", "yy"])))[1:8] == "1 x 2 yy"
        @test roundtrip(HDU(Table, [(1, "x"), (2, "yy")])).data == (column1 = [1, 2], column2 = ["x", "yy"])
        #  a column is a vector, which a matrix and a number are not, since the table has a value of the column for each row
        @test_throws ArgumentError("Column 1 of the data, a, is not a vector, but a column of an ASCII table has a value for each row (Sect. 7.2.3).") HDU(
            Table, (a = [1 2; 3 4],))
        @test_throws ArgumentError r"Column 2 of the data is not a vector" HDU(Table, ([1, 2], 3))
        hdu = HDU(Table, (a = [1, 2],))
        @test_throws ArgumentError r"Column 1 of the data, a, is not a vector" rowsof(HDU{Table}(getfield(hdu, :cards), (a = [1 2; 3 4],)))
        #  a column that has missing values has the TNULLn of the cards, which is in the header with the other cards of the fields
        hdu = HDU(Table, (a = [1, missing],), Card{<:Any}[Card("TNULL1", "-9"), Card("TUNIT1", "m")])
        @test_throws ArgumentError r"has more than the 1 characters of the field" rowsof(hdu)
        hdu = HDU(Table, (a = [1, missing],), Card{<:Any}[Card("TFORM1", "I3"), Card("TNULL1", "-9"), Card("TUNIT1", "m")])
        @test rowsof(hdu)[1:6] == "  1-9 " && getfield(hdu, :cards)["TUNIT1"] == "m"
        #  the data and the cards must have the same number of fields and of rows
        hdu = HDU(Table, columns)
        @test_throws ArgumentError r"The data have 2 columns, but the table has TFIELDS = 3 fields" rowsof(HDU{Table}(
            getfield(hdu, :cards), (a = [1, 22], b = [2.5, -3.25])))
        @test_throws ArgumentError r"Column 2 of the data has 1 rows, but the table has NAXIS2 = 2" rowsof(HDU{Table}(
            getfield(hdu, :cards), (a = [1, 22], b = [2.5], c = ["xy", "z"])))
        @test_throws ArgumentError r"Record 2 of the data has 1 values, but the table has TFIELDS = 3 fields" rowsof(HDU{Table}(
            getfield(hdu, :cards), [(a = 1, b = 2.5, c = "x"), (a = 2,)]))
        #  a tuple of columns is named by TTYPEn or the number of the column
        hdu = HDU(Table, ([1, 2], ["x", "y"]), Card{<:Any}[Card("TTYPE2", "name")])
        @test hdu.data == ([1, 2], ["x", "y"]) && !haskey(getfield(hdu, :cards), "TTYPE1") && getfield(hdu, :cards)["TTYPE2"] == "name"
        @test propertynames(roundtrip(hdu).data) == (:column1, :name)
        #  the HDU of the rows of strings, whose fields the cards describe, has the rows as the data
        rows = ["   1  1.5", "   2  2.5"]
        hdu = HDU(Table, rows, Card{<:Any}[Card("TFIELDS", 2), Card("TFORM1", "I4"), Card("TBCOL1", 1), Card("TFORM2", "F5.1"), Card("TBCOL2", 5)])
        @test hdu.data == rows && rowsof(hdu)[1:18] == join(rows)
        @test roundtrip(hdu).data == (column1 = [1, 2], column2 = [1.5, 2.5])
        @test_throws ArgumentError r"Row 1 of the data has 11 characters, but a row has NAXIS1 = 9" rowsof(HDU{Table}(getfield(hdu, :cards),
            ["   1  1.5  ", "   2  2.5"]))
        @test_throws ArgumentError r"TFORM1 is missing, but TFIELDS is 1" HDU(Table, rows, Card{<:Any}[Card("TFIELDS", 1)])
    end

    ####    Test the tables that have no data    ####

    @testset "no data" begin
        #  the HDU that has no cards and no data is written and read, and the data are missing
        io = IOBuffer()
        write(io, HDU(Primary))
        write(io, HDU(Table))
        seekstart(io)
        read(io, HDU)
        hdu = read(io, HDU)
        @test ismissing(hdu.data) && position(io) == 2880*2 && eof(io)
        #  a table that has no rows has no data blocks, and its data are the empty columns of its fields, or the empty records
        cards = fieldcards(["I4", "A3", "F8.2"], [1, 6, 10])
        bytes = tablebytes(cards, String[]; rowlen = 17, nrows = 0)
        data = reread(bytes).data
        @test data == (column1 = Int64[], column2 = String[], column3 = Float64[]) && data.column1 isa Vector{Int64}
        @test reread(bytes; record = true).data isa Vector && isempty(reread(bytes; record = true).data)
        @test written(bytes) == codeunits(bytes)
        @test roundtrip(HDU(Table, (a = Int[], b = String[]))).data == (a = Int[], b = String[])
        #  no records are the empty records of the fields of their type, or no fields if the type does not have them
        records = NamedTuple{(:a, :b), Tuple{Int, String}}[]
        hdu = HDU(Table, records)
        @test hdu.data == records && [rstrip(card.value) for card in getfield(hdu, :cards) if startswith(card.key, "TFORM")] == ["I1", "A1"]
        @test roundtrip(hdu; record = true).data == records && roundtrip(hdu).data == (a = Int64[], b = String[])
        @test ismissing(roundtrip(HDU(Table, Any[])).data) && getfield(HDU(Table, Any[]), :cards)["TFIELDS"] == 0
        #  a table that has no fields has blank rows, or no data if it has no rows
        bytes = tablebytes([kw("TFIELDS", 0)], ["    ", "    "])
        @test reread(bytes).data == NamedTuple() && written(bytes) == codeunits(bytes)
        bytes = tablebytes([kw("TFIELDS", 0)], String[]; rowlen = 0, nrows = 0)
        @test ismissing(reread(bytes).data) && written(bytes) == codeunits(bytes)
        #  the data of a header that has the fields and the rows are blank rows, which are written, and read as 0
        hdu = HDU(Table, missing, Card{<:Any}[Card("NAXIS", 2), Card("NAXIS1", 4), Card("NAXIS2", 2), Card("TFIELDS", 1), Card("TFORM1", "I4"),
            Card("TBCOL1", 1)])
        @test hdu.data == ["    ", "    "] && rowsof(hdu)[1:8] == " "^8
        @test roundtrip(hdu).data == (column1 = [0, 0],)
    end

    ####    Test the writing of the fields (Sect. 7.2.5)    ####

    @testset "writing fields" begin
        row(form, value) = rowsof(HDU(Table, (a = [value],), Card{<:Any}[Card("TFORM1", form)]))
        #  the characters are left-justified, and the numbers are right-justified, in their fields, as they are read
        bytes = tablebytes(fieldcards(["I4", "A6"], [1, 5]), ["   1  ab  ", "   2cd    "])
        @test reread(bytes).data.column2 == ["  ab", "cd"] && written(bytes) == codeunits(bytes)
        @test row("A6", "cd")[1:6] == "cd    "
        #  the exponent letter of a D field is a D, the digits are those of the format, and the numbers fill the field
        @test row("D10.3", 1.5)[1:10] == " 1.500D+00"
        @test row("E10.3", -1.5e-5)[1:10] == "-1.500E-05"
        @test row("F8.3", -2.5)[1:8] == "  -2.500"
        @test row("F8.3", 2)[1:8] == "   2.000"
        @test row("I4", Int8(-5))[1:4] == "  -5"
        @test row("E16.8", 0.1f0)[1:16] == "  1.00000001E-01"
        @test row("D12.3", 1.5e100)[1:12] == "  1.500D+100"
        #  a value that does not fit the field, or that the field does not hold, is an error, and does not shift the fields after it
        for (form, value, message) in [("I2", 12345, "The value 12345 of field a has 5 characters, but the format I2 has 2"),
            ("A3", "abcdefgh", "has 8 characters, but the format A3 has 3"), ("F6.3", 123456.789, "has 10 characters, but the format F6.3 has 6"),
            ("E6.3", 1.5e-5, "has 9 characters, but the format E6.3 has 6"),
            ("F8.3", NaN, "cannot be written in the format F8.3, which has no NaN or infinity"),
            ("E8.3", -Inf, "cannot be written in the format E8.3"), ("I4", 1.5, "is not an integer, but the field has the format I4"),
            ("I4", NaN, "is not an integer"), ("I4", "x", "is not a number"), ("F4.1", true, "is not a number"),
            ("A4", 1, "is not a string"), ("A3", "é", "not ASCII text characters, from 32 to 126"), ("A3", "a\tb", "not ASCII text characters")]
            @test_throws ArgumentError Regex(message) row(form, value)
        end
        #  fields that overlap are written at their columns, and the characters between the fields are spaces
        hdu = HDU(Table, (a = [1], b = [2]), Card{<:Any}[Card("TFORM1", "I4"), Card("TBCOL1", 1), Card("TFORM2", "I4"), Card("TBCOL2", 3)])
        @test rowsof(hdu)[1:6] == "     2"
        hdu = HDU(Table, (a = [1], b = [2]), Card{<:Any}[Card("TFORM1", "I4"), Card("TBCOL1", 1), Card("TFORM2", "I4"), Card("TBCOL2", 9)])
        @test rowsof(hdu)[1:12] == "   1    " * "   2"
    end

    ####    Test the formats and the columns of the fields (Sect. 7.2.1)    ####

    @testset "formats and columns" begin
        header(form; column = 1) = [kw("TFIELDS", 1), sk("TFORM1", form), kw("TBCOL1", column)]
        #  a format that is not one of Table 15 is an error, since the field cannot be read, which names TFORMn
        for form in ["i4", "Z4", "I", "A", "F6", "E8", "D8", "A4.2", "I4.1", "F4.1x", " I4", "I0", "A0", "F4.0.1", "E8.1.2", "I4.", "L1", "B8",
            "X1", "G8.3", "I-4", "F6.-2", "4I", "F.2", "AI4", "", "I99999999999999999999"]
            @test_throws ArgumentError r"TFORM1 must be a format of Table 15, Aw, Iw, Fw.d, Ew.d, or Dw.d, in upper case, with a width of at least 1 \(Sect. 7.2.1\)" reread(
                tablebytes(header(form), ["   1"]))
        end
        @test_throws ArgumentError("TFORM1 must be a character string, but its value is 5.") reread(tablebytes(
            [kw("TFIELDS", 1), kw("TFORM1", 5), kw("TBCOL1", 1)], ["   1"]))
        #  the formats of the table are read, and the spaces after the format are not significant
        for (form, text, number) in [("I4", "   1", 1), ("A4", "abcd", "abcd"), ("F4.1", " 1.5", 1.5), ("E8.2", "1.50E+00", 1.5), ("D8.2", "1.50D+00", 1.5),
            ("I4    ", "   1", 1), ("F10.0", "         1", 1.0)]
            @test reread(tablebytes(header(form), [text])).data.column1 == [number]
        end
        #  the field is within the NAXIS1 characters of a row, which the TBCOLn of the first column does not leave, and a field is not read from the
        #  next row
        @test_throws ArgumentError r"Field 2, whose TFORM2 is \"I4\" and TBCOL2 is 9, ends in column 12, but a row has NAXIS1 = 8 characters \(Sects. 7.2.1 and 7.2.4\)" reread(
            tablebytes(fieldcards(["I4", "I4"], [1, 9]), ["   1   2", "   3   4"]))
        @test_throws ArgumentError r"Field 1, whose TFORM1 is \"I4\" and TBCOL1 is 6, ends in column 9, but a row has NAXIS1 = 8 characters" reread(
            tablebytes(fieldcards(["I4"], [6]), ["   1   2", "   3   4"]; rowlen = 8))
        @test reread(tablebytes(fieldcards(["I4", "I4"], [1, 5]), ["   1   2", "   3   4"])).data == (column1 = [1, 3], column2 = [2, 4])
        @test reread(tablebytes(fieldcards(["I4"], [1]), ["   1    ", "   3    "])).data == (column1 = [1, 3],)
        #  a header without a TFORMn or with a TBCOLn less than 1 cannot be read, and TFIELDS is an integer (Sect. 7.2.1)
        fields = fieldcards(["I4", "F5.1"], [1, 5])
        rows = ["   1  1.5", "   2  2.5"]
        @test reread(tablebytes(fields, rows)).data.column1 == [1, 2]
        @test_throws ArgumentError("TFORM2 is missing, but TFIELDS is 2.") reread(tablebytes(fields[1:3], rows))
        @test_throws ArgumentError("TBCOL2 is missing, but TFIELDS is 2.") reread(tablebytes(fields[1:4], rows))
        @test_throws ArgumentError r"TBCOL1 must be at least 1" reread(tablebytes([fields[1:2]; kw("TBCOL1", 0); fields[4:5]], rows))
        @test_throws ArgumentError r"TFIELDS must be an integer" reread(tablebytes([[kw("TFIELDS", "2.0")]; fields[2:5]], rows))
        #  fields that overlap are a warning, and are read as they are
        @test_logs (:warn, r"Fields 1 and 2 overlap, but the fields of a row should not overlap \(Sect. 7.2.4\)") @test reread(tablebytes(
            fieldcards(["I4", "I4"], [1, 3]), ["   1  "])).data == (column1 = [1], column2 = [1])
    end

    ####    Test the keywords of the fields (Sect. 7.2.2)    ####

    @testset "keywords of fields" begin
        read1(extra; forms = ["I4"], rows = ["   1"]) = reread(tablebytes(fieldcards(forms, [1]; extra), rows))
        #  TTYPEn, TUNITn, TNULLn, and TDISPn are character strings, and a value that is not is not used
        for key in ("TTYPE", "TUNIT", "TNULL", "TDISP")
            @test_logs (:warn, Regex("$(key)1 must be a character string, but its value is 5")) @test propertynames(read1([kw("$(key)1", 5)]).data) == (:column1,)
        end
        @test_logs (:warn, r"TUNIT1 must be a units string \(Sect. 4.3\), but its value is \"foo bar\"") read1([sk("TUNIT1", "foo bar")])
        @test_logs read1([sk("TUNIT1", "km/s"), sk("TTYPE1", "velocity")])
        @test propertynames(read1([sk("TTYPE1", "velocity")]).data) == (:velocity,)
        #  TSCALn, TZEROn, TDMINn, TDMAXn, TLMINn, and TLMAXn are numbers, which the values are made of
        for key in ("TSCAL", "TZERO", "TDMIN", "TDMAX", "TLMIN", "TLMAX")
            @test_throws ArgumentError("$(key)1 must be a number, but its value is \"a\".") read1([sk("$(key)1", "a")])
        end
        #  TSCALn and TZEROn are not used for a field of characters, and TNULLn is not longer than its field
        @test_logs (:warn, r"TSCAL1 and TZERO1 must not be used for a field of format A \(Sect. 7.2.2\)") @test read1([kw("TSCAL1", "2.0")];
            forms = ["A4"], rows = ["abcd"]).data.column1 == ["abcd"]
        @test_logs (:warn, r"TNULL1, \"NOT DEFINED\", is longer than the 4 characters of its field") read1([sk("TNULL1", "NOT DEFINED")])
        #  the display format is a format of Table 16, which suits the type of the field
        for (form, disp) in [("I4", "I4"), ("I4", "I4.2"), ("I4", "B8.4"), ("I4", "O5"), ("I4", "Z5.2"), ("I4", "F8.3"), ("I4", "G10.3E2"),
            ("F5.1", "F8.3"), ("F5.1", "E10.3E2"), ("F5.1", "EN10.3"), ("F5.1", "ES10.3"), ("F5.1", "D10.3"), ("A4", "A5")]
            @test_logs read1([sk("TDISP1", disp)]; forms = [form], rows = [form == "A4" ? "abcd" : form == "I4" ? "   1" : "  1.5"])
        end
        for disp in ["Q5", "L1", "I", "F8", "e10.3", "A", "EN10", "B"]
            @test_logs (:warn, Regex("TDISP1 must be a display format of Table 16 \\(Sect. 7.2.2\\), but its value is $(repr(disp))")) read1(
                [sk("TDISP1", disp)])
        end
        @test_logs (:warn, r"TDISP1, \"A5\", is not a display format for a field of format I \(Sect. 7.2.2\), which has the formats I, B, O, Z, F, E, D, EN, ES, G") read1(
            [sk("TDISP1", "A5")])
        @test_logs (:warn, r"TDISP1, \"I5\", is not a display format for a field of format F \(Sect. 7.2.2\), which has the formats F, E, D, EN, ES, G") read1(
            [sk("TDISP1", "I5")]; forms = ["F5.1"], rows = ["  1.5"])
        @test_logs (:warn, r"TDISP1, \"F5.1\", is not a display format for a field of format A") read1([sk("TDISP1", "F5.1")]; forms = ["A4"],
            rows = ["abcd"])
        #  the minimum and maximum values have the data type of the physical values: integers for an integer field that is not scaled to
        #  floating-point numbers, and floating-point numbers for the others
        for key in ("TDMIN", "TDMAX", "TLMIN", "TLMAX")
            @test_logs read1([kw("$(key)1", 5)])
            @test_logs (:warn, Regex("$(key)1 must be an integer, since the values of field 1 are integers \\(Sect. 7.2.2\\), but its value is 1.5")) read1(
                [kw("$(key)1", "1.5")])
            @test_logs read1([kw("$(key)1", "1.5")]; forms = ["F5.1"], rows = ["  1.5"])
            @test_logs (:warn, Regex("$(key)1 must be a floating-point number, since the values of field 1 are floating-point numbers.*is 5")) read1(
                [kw("$(key)1", 5)]; forms = ["F5.1"], rows = ["  1.5"])
        end
        @test_logs (:warn, r"TDMIN1 must be a floating-point number") read1([kw("TDMIN1", 5), kw("TSCAL1", "2.0")])
        @test_logs read1([kw("TDMIN1", "5.5"), kw("TSCAL1", "2.0")])
    end

    ####    Test the mandatory keywords (Sects. 4.4.1.2 and 7.2.1)    ####

    @testset "mandatory keywords" begin
        fields = fieldcards(["I4"], [1])
        normal = mandatorycards(4, 1)
        #  the mandatory keywords are in order, which a header that has others between them is not
        @test_logs reread(tablebytes(fields, ["   1"]))
        swapped = [normal[1:3]; normal[5]; normal[4]; normal[6:7]]
        @test_logs (:warn, r"Keyword 4 of the header is NAXIS2, but the Standard requires NAXIS1 \(Sects. 4.4.1.2 and 7.2.1\)") reread(
            tablebytes(fields, ["   1"]; mandatory = swapped))
        @test_logs (:warn, r"Keyword 8 of the header is TTYPE1, but the Standard requires TFIELDS") reread(
            tablebytes([sk("TTYPE1", "a"); fields], ["   1"]))
        @test_logs (:warn, r"Keyword 6 of the header is TFIELDS, but the Standard requires PCOUNT") reread(
            tablebytes(fields[2:end], ["   1"]; mandatory = [normal[1:5]; fields[1]; normal[6:7]]))
        #  the values are in fixed format
        @test_logs (:warn, r"The value of NAXIS1 is not in fixed format \(Sect. 4.4.1\)") reread(
            tablebytes(fields, ["   1"]; mandatory = [normal[1:3]; "NAXIS1  = 4"; normal[5:7]]))
        #  PCOUNT and GCOUNT are read as 0 and 1 if they are missing
        @test_logs (:warn, r"PCOUNT is missing, but it is a mandatory keyword of a TABLE extension \(Sect. 7.2.1\), and has the value 0") reread(
            tablebytes(fields, ["   1"]; mandatory = normal[[1:5; 7]])).data.column1 == [1]
        @test_logs (:warn, r"GCOUNT is missing, but it is a mandatory keyword of a TABLE extension \(Sect. 7.2.1\), and has the value 1") reread(
            tablebytes(fields, ["   1"]; mandatory = normal[1:6]))
        @test_throws ArgumentError("BITPIX is missing, but it is a mandatory keyword of a TABLE extension (Sect. 7.2.1).") reread(
            tablebytes(fields, ["   1"]; mandatory = normal[[1, 3, 4, 5, 6, 7]]))
        @test_throws ArgumentError("NAXIS is missing, but it is a mandatory keyword of a TABLE extension (Sect. 7.2.1).") reread(
            tablebytes(fields, ["   1"]; mandatory = normal[[1, 2, 4, 5, 6, 7]]))
        #  TFIELDS is mandatory, and a header that does not have it has no fields
        @test_logs (:warn, r"TFIELDS is missing, but it is a mandatory keyword of a TABLE extension \(Sect. 7.2.1\), and the table has no fields. It is read as 0.") @test reread(
            tablebytes(String[], ["    "])).data == NamedTuple()
        #  the keywords that describe arrays are not used in a table (Sect. 4.4.2.5)
        for (key, value) in ["BSCALE" => "2.0", "BZERO" => "1.0", "BLANK" => "5", "DATAMIN" => "2.0", "DATAMAX" => "9.0"]
            @test_logs (:warn, Regex("$key must not be used in a TABLE extension header \\(Sect. 4.4.2.5\\), since it describes an array, and the header " *
                "describes a table. It is read as it is, and is not used.")) @test reread(tablebytes([fields; kw(key, value)], ["   1"])).data.column1 == [1]
        end
        @test_logs (:warn, r"BUNIT must not be used in a TABLE extension header") reread(tablebytes([fields; sk("BUNIT", "Jy")], ["   1"]))
        #  the keywords of the primary header and of the physical blocks are not in an extension
        @test_logs (:warn, r"SIMPLE must not appear in an extension header \(Sect. 4.4.1.1\)") reread(tablebytes([fields; kw("SIMPLE", "T")], ["   1"]))
        for key in ("EXTEND", "BLOCKED")
            @test_logs (:warn, Regex("$key must not appear in a TABLE extension header \\(Sects. 4.4.2.1 and 7.2.2\\)")) reread(
                tablebytes([fields; kw(key, "T")], ["   1"]))
        end
    end

    ####    Test the names of the fields and the characters of the rows (Sects. 7.2.2, 7.2.4, and 7.2.5)    ####

    @testset "names and characters" begin
        names(cards; forms = ["I4", "I4", "I4"], rows = ["   1   2   3"]) =
            propertynames(reread(tablebytes(fieldcards(forms, [1, 5, 9][1:length(forms)]; extra = cards), rows)).data)
        #  the names of the fields are unique without regard to the case, which a warning says, and the names of the columns of the data are
        @test_logs (:warn, r"TTYPE2 and TTYPE1 have the same name, \"a\", without regard to the case, but the names of the fields should be unique \(Sect. 7.2.2\)\.$") @test names(
            [sk("TTYPE1", "A"), sk("TTYPE2", "a")]; forms = ["I4", "I4"], rows = ["   1   2"]) == (:A, :a)
        @test_logs (:warn, r"The column of the data of TTYPE2 is named x_2") @test names([sk("TTYPE1", "x"), sk("TTYPE2", "x"),
            sk("TTYPE3", "y")]) == (:x, :x_2, :y)
        @test_logs @test names([sk("TTYPE1", "x"), sk("TTYPE2", "y")]; forms = ["I4", "I4"], rows = ["   1   2"]) == (:x, :y)
        #  the name of a field that has none is the number of its column, and the field of an empty name has the default
        @test_logs @test names([sk("TTYPE1", ""), sk("TTYPE3", "z")]) == (:column1, :column2, :z)
        #  a name has at most 68 characters, which is the most that a string of a card has, and has the characters that are recommended for a name
        @test HDU(Table, NamedTuple{(Symbol(repeat("x", 68)),)}(([1],))) isa HDU
        @test_throws ArgumentError r"The name of field 1, \"xxxxxxxxxxxxxxxxxxxx\"\.\.\., has 69 characters, but the value of a TTYPEn keyword has at most 68 \(Sect. 4.2.1.1\)" HDU(
            Table, NamedTuple{(Symbol(repeat("x", 69)),)}(([1],)))
        for name in ["a b", "a-b", "a+b", " ab", "a*b", "a.b"]
            @test_logs (:warn, Regex("TTYPE1, $(replace(repr(name), r"([.+*])" => s"\\\1")), has characters other than letters, digits, and the underscore, which a name should have")) names(
                [sk("TTYPE1", name)]; forms = ["I4"], rows = ["   1"])
        end
        @test_logs names([sk("TTYPE1", "Ab_9")]; forms = ["I4"], rows = ["   1"])
        #  the characters of a field of characters are the ASCII text characters, from 32 to 126, which a warning says if they are not, and
        #  the characters are read as they are and are not written
        bytes = tablebytes(fieldcards(["A4"], [1]), ["ab\tc", "efgh"])
        @test_logs (:warn, r"The characters of field column1 are not all ASCII text characters, from 32 to 126 \(Sect. 7.2.5\)") @test reread(bytes).data.column1 == ["ab\tc", "efgh"]
        @test_throws ArgumentError r"The string \"ab\\tc\" of field column1 has characters that are not ASCII text characters" written(bytes)
        @test_logs reread(tablebytes(fieldcards(["A4"], [1]), ["abcd", "e g "]))
        #  the characters of a row that are not in a field are not read, and are written as spaces, which a warning says if they are not spaces
        bytes = tablebytes(fieldcards(["I4"], [1]), ["   1xyz", "   2   "])
        @test_logs (:warn, r"The character 'x' of row 1, column 5, is not in a field and is not a space, but the characters of a row that are not in a field are not read, and are written as spaces \(Sect. 7.2.4\)") @test reread(
            bytes).data == (column1 = [1, 2],)
        @test_logs (:warn, r"column 5") @test rowsof(reread(bytes))[1:14] == "   1   " * "   2   "
        @test_logs reread(tablebytes(fieldcards(["I4"], [1]), ["   1   ", "   2   "]))
        @test_logs (:warn, r"The character '\\r' of row 1, column 5") reread(tablebytes(fieldcards(["I4"], [1]), ["   1\r\n", "   2\r\n"]))
    end
end

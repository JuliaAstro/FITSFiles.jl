@testset "HDU" begin
    ####    Test mandatory keyword verification    ####

    #  an HDU type that raises an error when its mandatory keywords are verified
    struct ProbeHDU <: FITSFiles.AbstractHDU end
    FITSFiles.verify!(::Type{ProbeHDU}, cards::FITSFiles.Cards, mankeys::AbstractDict) =
        error("verified $(sort(collect(keys(mankeys))))")

    #  the generic method accepts all values and returns the cards.
    cards = Card{<:Any}[Card("SIMPLE", true), Card("BITPIX", 16), Card("NAXIS", 0)]
    mankeys = Dict{AbstractString, FITSFiles.ValueType}("BITPIX" => "sixteen")
    @test FITSFiles.verify!(FITSFiles.Primary, cards, mankeys) === cards
    @test mankeys == Dict("BITPIX" => "sixteen")

    #  mandatory keywords are verified before the data format is created when an HDU is read,
    #  written, or created without data. The data format of ProbeHDU is not defined.
    header = join(rpad.(["SIMPLE  =                    T", "BITPIX  = sixteen", "NAXIS   = 0", "END"], 80))
    io = IOBuffer(rpad(header, 2880))
    @test_throws r"verified .*\"BITPIX\".*\"NAXIS\".*\"SIMPLE\"" read(io, HDU; type = ProbeHDU)
    cards = Card{<:Any}[Card("BITPIX", 16)]
    @test_throws r"verified .*\"BITPIX\"" write(IOBuffer(), HDU{ProbeHDU}(cards, missing))
    @test_throws r"verified .*\"BITPIX\"" HDU(ProbeHDU, missing, cards)

    #  the format of the data is created before the header is corrected to match the data.
    @test_throws MethodError HDU(ProbeHDU, [1, 2, 3], cards)

    ####    Test the correction of the shape and the counts    ####

    @testset "verifyshape! and verifycounts!" begin
        keys(cards) = Dict{AbstractString, FITSFiles.ValueType}(c.key => c.value for c in cards)
        header(cards...) = Card{<:Any}[cards...]
        format(type, shape, param = 0, group = 1) =
            FITSFiles.DataFormat(type, prod(shape), shape, param, group, 0)

        #  a header that matches the format is not changed, and has no warning.
        cards = header(Card("BITPIX", 16), Card("NAXIS", 2), Card("NAXIS1", 3), Card("NAXIS2", 4))
        fmt = format(Int16, (3, 4))
        @test_logs FITSFiles.verifyshape!(cards, keys(cards), fmt) === cards
        @test (cards["BITPIX"], cards["NAXIS"], cards["NAXIS1"], cards["NAXIS2"]) == (16, 2, 3, 4)

        #  BITPIX and the NAXIS keywords are set to the format.
        fmt = format(Float32, (5,))
        @test_logs (:warn, "BITPIX set to -32.") (:warn, "NAXIS1:1 set to (5,)") FITSFiles.verifyshape!(
            cards, keys(cards), fmt)
        @test (cards["BITPIX"], cards["NAXIS"], cards["NAXIS1"]) == (-32, 1, 5)

        #  random groups have NAXIS1 = 0 and the shape begins at NAXIS2.
        cards = header(Card("BITPIX", 16), Card("NAXIS", 3), Card("NAXIS1", 0), Card("NAXIS2", 4), Card("NAXIS3", 5))
        @test_logs (:warn, "NAXIS2:3 set to (2, 3)") FITSFiles.verifyshape!(
            cards, keys(cards), format(Int16, (2, 3)); first = 2)
        @test (cards["NAXIS"], cards["NAXIS1"], cards["NAXIS2"], cards["NAXIS3"]) == (3, 0, 2, 3)

        #  a header without NAXIS1 is not changed
        cards = header(Card("BITPIX", 16), Card("NAXIS", 0))
        @test_logs FITSFiles.verifyshape!(cards, keys(cards), format(Int16, ())) === cards

        #  PCOUNT and GCOUNT are set to the format, and only when they are in the header.
        cards = header(Card("PCOUNT", 0), Card("GCOUNT", 1))
        @test_logs (:warn, "PCOUNT set to 7") (:warn, "GCOUNT set to 2") FITSFiles.verifycounts!(
            cards, keys(cards), format(Int16, (3,), 7, 2))
        @test (cards["PCOUNT"], cards["GCOUNT"]) == (7, 2)
        cards = header(Card("BITPIX", 16))
        @test_logs FITSFiles.verifycounts!(cards, keys(cards), format(Int16, (3,), 7, 2)) === cards
        @test length(cards) == 1
    end

    ####    Test the arrangement of the required cards    ####

    @testset "arrangecards!" begin
        format = FITSFiles.DataFormat(Int16, 6, (2, 3), 0, 1, 0)

        #  the required cards are first and in order, a card of the deck keeps its comment and layout, and
        #  the other cards follow in order. The END card is removed.
        naxis2 = Card("NAXIS2", 3, "rows")
        cards = Card{<:Any}[Card("COMMENT", "text"), naxis2, Card("EXTRA", 1.5),
            Card("BITPIX", 16), Card("END")]
        kards = FITSFiles.arrangecards!(cards, ["SIMPLE" => true; FITSFiles.shapekeys(format)])
        @test [c.key for c in kards] == ["SIMPLE", "BITPIX", "NAXIS", "NAXIS1", "NAXIS2", "COMMENT", "EXTRA"]
        @test (kards[1].value, kards[2].value, kards[3].value, kards[4].value, kards[5].value) ==
            (true, 16, 2, 2, 3)
        @test kards[5].comment == "rows" && kards[5] === naxis2

        #  the keys of the shape begin at NAXIS2 for random groups, whose NAXIS1 is 0
        @test FITSFiles.shapekeys(format) == ["BITPIX" => 16, "NAXIS" => 2, "NAXIS1" => 2, "NAXIS2" => 3]
        @test FITSFiles.shapekeys(format; first = 2) ==
            ["BITPIX" => 16, "NAXIS" => 3, "NAXIS1" => 0, "NAXIS2" => 2, "NAXIS3" => 3]
        @test FITSFiles.shapekeys(FITSFiles.DataFormat(Float32, 1, (), 0, 1, 0)) == ["BITPIX" => -32, "NAXIS" => 0]

        #  the keys of a table are the length of a row and the number of rows, or zero
        table = FITSFiles.DataFormat(UInt8, 12, (4, 3), 0, 1, 0)
        @test FITSFiles.tablekeys("TABLE", table, 2) == ["XTENSION" => "TABLE", "BITPIX" => 8, "NAXIS" => 2,
            "NAXIS1" => 4, "NAXIS2" => 3, "PCOUNT" => 0, "GCOUNT" => 1, "TFIELDS" => 2]
        @test FITSFiles.tablekeys("BINTABLE", format, 0)[4:5] == ["NAXIS1" => 2, "NAXIS2" => 3]
        @test FITSFiles.tablekeys("BINTABLE", FITSFiles.DataFormat(UInt8, 0, (), 0, 1, 0), 0)[4:5] ==
            ["NAXIS1" => 0, "NAXIS2" => 0]

        #  the extension type is padded to 8 characters by the card, as the standard requires
        kards = FITSFiles.arrangecards!(Card{<:Any}[], FITSFiles.tablekeys("TABLE", table, 0))
        @test kards[1].value == "TABLE   " && length(kards) == 8

        #  the types of HDU: the first card is SIMPLE or XTENSION, and the random group cards are in order
        fmt = FITSFiles.DataFormat(Int16, 6, (2, 3), 0, 1, 0)
        for (type, field, first) in ((Primary, FITSFiles.ImageField(Int16, 0f0, 1f0, nothing, nothing, nothing), "SIMPLE"),
            (Image, FITSFiles.ImageField(Int16, 0f0, 1f0, nothing, nothing, nothing), "XTENSION"),
            (FITSFiles.Conform, FITSFiles.ConformField(), "SIMPLE"))
            kards = FITSFiles.createcards!(type, fmt, field, Card{<:Any}[])
            @test [c.key for c in kards] == [first, "BITPIX", "NAXIS", "NAXIS1", "NAXIS2"]
        end
    end

    ####    Test the padding of the XTENSION value    ####

    @testset "verifyxtension!" begin
        card(text) = parse(Card, rpad(text, 80))

        #  a value that is padded to 8 characters is not changed, and a card without XTENSION is not changed.
        for value in ("IMAGE   ", "TABLE   ", "BINTABLE")
            cards = Card{<:Any}[card("XTENSION= '$value'"), Card("BITPIX", 8)]
            @test_logs FITSFiles.verifyxtension!(cards) === cards
            @test cards[1].value == rstrip(value) && cards[1].format.vend - cards[1].format.vbeg == 9
        end
        cards = Card{<:Any}[Card("SIMPLE", true), Card("BITPIX", 8)]
        @test_logs FITSFiles.verifyxtension!(cards) === cards
        @test length(cards) == 2
        @test_logs FITSFiles.verifyxtension!(Card{<:Any}[Card("XTENSION", "TABLE")])

        #  a value that is shorter than 8 characters is a warning, and the cards are not changed.
        for (text, value) in (("'IMAGE'", "IMAGE"), ("'TABLE  '", "TABLE"), ("'TABLE'", "TABLE"))
            cards = Card{<:Any}[card("XTENSION= $text"), Card("BITPIX", 8, "bits")]
            before = copy(cards)
            @test_logs (:warn, "The XTENSION value '$value' is not padded to 8 characters.") FITSFiles.verifyxtension!(cards)
            @test cards == before && cards[1].value == value
            @test repr(cards[1]) == rpad("XTENSION= $text", 80)
        end

        #  an HDU that is read with the value is written as it was read.
        header = ["XTENSION= 'IMAGE'", "BITPIX  =                    8", "NAXIS   =                    0",
            "PCOUNT  =                    0", "GCOUNT  =                    1", "END"]
        buffer = IOBuffer(join(rpad.(header, 80)) * " "^(2880 - 80length(header)))
        hdu = @test_logs (:warn, r"XTENSION value 'IMAGE' is not padded") read(buffer, HDU)
        @test hdu.cards[1].value == "IMAGE"
        io = IOBuffer()
        write(io, hdu)
        @test String(take!(io))[1:80] == rpad("XTENSION= 'IMAGE'", 80)
    end

    ####    Test the image array functions    ####

    @testset "ImageField" begin
        mankeys(pairs...) = Dict{AbstractString, FITSFiles.ValueType}(
            "BITPIX" => 16, "NAXIS" => 2, "NAXIS1" => 3, "NAXIS2" => 4, pairs...)

        #  the data format is the same for the types that have an image array
        formats = [FITSFiles.DataFormat(type, missing, mankeys()) for type in (Primary, Image, FITSFiles.Conform)]
        @test all(f -> (f.type, f.leng, f.shape, f.param, f.group, f.heap) == (Int16, 12, (3, 4), 0, 1, 0), formats)
        @test FITSFiles.DataFormat(Image, missing, mankeys("PCOUNT" => 2, "THEAP" => 5)).heap == 5
        @test FITSFiles.DataFormat(Primary, ones(Float32, 2, 5), mankeys()) ==
            FITSFiles.DataFormat(Image, ones(Float32, 2, 5), mankeys())
        @test FITSFiles.DataFormat(Image, ones(Float32, 2, 5), mankeys()).shape == (2, 5)

        #  the defaults of the scale and the offset are 1.0 and 0.0 (Sect. 4.4.2.5), and a missing value
        #  is for integer data only
        format = FITSFiles.DataFormat(Image, missing, mankeys())
        field = FITSFiles.FieldFormat(Image, format, mankeys(), missing)
        @test (field.type, field.zero, field.scale, field.miss, field.dmin, field.dmax) ==
            (Int16, 0, 1, nothing, nothing, nothing)
        field = FITSFiles.FieldFormat(Primary, format, mankeys("BZERO" => 32768, "BSCALE" => 2.5, "BLANK" => -32768,
            "DATAMIN" => 1.5, "DATAMAX" => 9.5), ones(Int16, 3, 4))
        @test (field.zero, field.scale, field.miss, field.dmin, field.dmax) == (32768, 2.5, -32768, 1.5, 9.5)
        format = FITSFiles.DataFormat(Image, missing, mankeys("BITPIX" => -32))
        @test isnothing(FITSFiles.FieldFormat(Image, format, mankeys("BITPIX" => -32, "BLANK" => 0), missing).miss)

        #  the data of a header is zeros, or missing if there are no axes
        @test FITSFiles.zerosarray(formats[1]) == zeros(Int16, 3, 4)
        @test FITSFiles.createdata(Image, formats[1], field) == zeros(Int16, 3, 4)
        @test ismissing(FITSFiles.zerosarray(FITSFiles.DataFormat(Int16, 1, (), 0, 1, 0)))
    end

    ####    Test the undefined (missing) values    ####

    @testset "setmissing, unsetmissing, and scaled" begin
        #  the raw values equal to BLANK or TNULLn are missing, whether or not any value is equal
        @test isequal(FITSFiles.setmissing(Int16[1, -1, 3], -1), [1, missing, 3])
        @test eltype(FITSFiles.setmissing(Int16[1, 2], -1)) == Union{Int16, Missing}
        @test FITSFiles.setmissing(Int16[1, -1], nothing) == Int16[1, -1]
        @test ismissing(FITSFiles.setmissing(Int16(-1), -1))
        @test FITSFiles.setmissing(Int16(2), -1) == 2

        #  the missing values are written as BLANK or TNULLn, and as NaN for floating-point data
        data = Union{Int16, Missing}[1, missing, 3]
        @test FITSFiles.unsetmissing(data, -1, Int16) == Int16[1, -1, 3]
        @test FITSFiles.unsetmissing(data[[1, 3]], nothing, Int16) == Int16[1, 3]
        @test FITSFiles.unsetmissing(Int16[1, 2], nothing, Int16) == Int16[1, 2]
        @test FITSFiles.unsetmissing(missing, -1, Int16) === Int16(-1)
        @test isequal(FITSFiles.unsetmissing(Union{Float32, Missing}[1, missing], nothing, Float32), Float32[1, NaN])
        @test_throws ArgumentError FITSFiles.unsetmissing(data, nothing, Int16)

        #  scaling is of the raw values, and a missing value stays missing
        @test isequal(FITSFiles.scaled(data, 2.0f0, 10.0f0), Union{Float32, Missing}[12, missing, 16])
        @test ismissing(FITSFiles.scaled(missing, 2.0f0, 10.0f0))
        @test FITSFiles.scaled(Int16[1, 3], 2.0f0, 10.0f0) == Float32[12, 16]
        @test eltype(FITSFiles.scaled(Int16[1, 3], 2.0f0, 10.0f0)) == Float32
    end

    @testset "BLANK of an image and TNULLn of a binary table" begin
        cards(x...) = Card{<:Any}[x...]
        bytes(hdu) = (io = IOBuffer(); write(io, hdu); take!(io))
        reread(hdu; kwds...) = read(IOBuffer(bytes(hdu)), HDU; kwds...)

        #  BLANK is compared with the raw values, before BZERO and BSCALE (Sect. 4.4.2.5)
        raw = Int16[1 -32768; 3 4]
        hdu = HDU(raw, cards(Card("BLANK", -32768), Card("BZERO", 32768), Card("BSCALE", 1)))
        @test isequal(reread(hdu).data, Union{Float32, Missing}[32769 missing; 32771 32772])
        @test isequal(reread(hdu; scale = false).data, [1 missing; 3 4])

        #  the missing values are written as BLANK, and the file is the same as the file with the raw values
        data = Union{Int16, Missing}[1 missing; 3 4]
        @test bytes(HDU(data, cards(Card("BLANK", -32768)))) == bytes(HDU(raw, cards(Card("BLANK", -32768))))
        @test_throws ArgumentError bytes(HDU(data))

        #  the undefined value of floating-point data is NaN, which needs no BLANK
        hdu = HDU(Union{Float32, Missing}[1 missing; 3 4])
        @test isequal(reread(hdu).data, Float32[1 NaN; 3 4])

        #  TNULLn is compared with the raw values of an integer column, before TZEROn and TSCALn (Sect. 7.3.2)
        columns = (a = Union{Int16, Missing}[1, missing, 3], b = [1.5, 2.5, 3.5])
        records = [(a = Int16(1), b = 1.5), (a = missing, b = 2.5), (a = Int16(3), b = 3.5)]
        table = cards(Card("TNULL1", -1))
        hdu = HDU(Bintable, columns, table)
        @test isequal(reread(hdu).data, columns)
        @test isequal(reread(hdu; record = true).data, records)
        @test bytes(HDU(Bintable, records, table)) == bytes(hdu)
        @test bytes(hdu) == bytes(HDU(Bintable, (a = Int16[1, -1, 3], b = [1.5, 2.5, 3.5]), table))
        @test_throws ArgumentError bytes(HDU(Bintable, columns))
    end

    ####    Test the values of a row    ####

    @testset "getcell, getparam, getgroup, and flatten" begin
        field = (; name = "m")
        records = [(m = [1, 2],), (m = [3, 4],)]
        columns = (m = [1 2; 3 4],)
        @test FITSFiles.getcell(Bintable, records, field, 2) == [3, 4]
        @test FITSFiles.getcell(Bintable, columns, field, 2) == [3, 4]
        @test FITSFiles.getcell(Bintable, (m = ["a", "bb"],), field, 2) == "bb"
        @test FITSFiles.getcell(Bintable, [(m = 1.5,), (m = 2.5,)], field, 2) == 2.5

        @test FITSFiles.flatten([1 2; 3 4]) == [1, 3, 2, 4]
        @test FITSFiles.flatten(3) === 3 && FITSFiles.flatten("text") == "text"
        @test ndims(FITSFiles.flatten(ones(2, 2, 2))) == 1

        #  a table has one value for each row of a column, and random groups have the parameters of a name
        #  at the index of the field
        @test FITSFiles.getcell(Table, [(m = "a",), (m = "bb",)], field, 2) == "bb"
        @test FITSFiles.getcell(Table, (m = ["a", "bb"],), field, 2) == "bb"
        @test FITSFiles.getcell(Table, (m = [1 2; 3 4],), field, 2) == 3
        param = (; name = "m", index = 2)
        @test FITSFiles.getparam([(m = 1.5,), (m = 2.5,)], param, 2) == 2.5
        @test FITSFiles.getparam([(m = [1 2; 3 4],)], param, 1) == 3
        @test FITSFiles.getparam((m = [1.5, 2.5],), param, 2) == 2.5
        @test FITSFiles.getparam((m = [1 2; 3 4],), param, 2) == 4
        format = FITSFiles.DataFormat(Float32, 6, (2, 3), 0, 2, 0)
        @test FITSFiles.getgroup([(m = [1 2 3; 4 5 6],)], param, 1, format) == [1, 4, 2, 5, 3, 6]
        @test FITSFiles.getgroup((m = [1 2 3; 4 5 6],), param, 2, format) == [4, 5, 6]

        #  a table that is written from columns is the same as one that is written from records
        bytes(hdu) = (io = IOBuffer(); write(io, hdu); take!(io))
        columns = (a = Int32[1, 2, 3], b = [1.5, 2.5, 3.5], c = ["x", "yy", "zzz"])
        records = [(a = Int32(1), b = 1.5, c = "x"), (a = Int32(2), b = 2.5, c = "yy"), (a = Int32(3), b = 3.5, c = "zzz")]
        @test bytes(HDU(Bintable, columns)) == bytes(HDU(Bintable, records))
    end
end


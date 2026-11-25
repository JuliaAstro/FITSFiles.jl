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
end


@testset "HDU" begin
    ####    Test mandatory keyword verification    ####

    #  an HDU type that raises an error when its mandatory keywords are verified
    struct ProbeHDU <: FITSFiles.AbstractHDU end
    FITSFiles.verify!(::Type{ProbeHDU}, cards::FITSFiles.Cards, mankeys::AbstractDict, reskeys::AbstractDict) =
        error("verified $(sort(collect(keys(mankeys))))")

    #  the verification of the cards of a header, with its mandatory and reserved keywords
    function verified(type, cards)
        mankeys, reskeys = FITSFiles.getreservedkeys(cards)
        FITSFiles.verify!(type, cards, mankeys, reskeys)
    end

    #  the generic method returns the cards, and leaves the keywords unchanged.
    cards = Card{<:Any}[Card("SIMPLE", true), Card("BITPIX", 16), Card("NAXIS", 0)]
    mankeys = Dict{AbstractString, FITSFiles.ValueType}("BITPIX" => 16)
    reskeys = Dict{AbstractString, FITSFiles.ValueType}("BSCALE" => 2.5)
    @test FITSFiles.verify!(FITSFiles.Primary, cards, mankeys, reskeys) === cards
    @test mankeys == Dict("BITPIX" => 16) && reskeys == Dict("BSCALE" => 2.5)

    #  the values of the keywords that the standard requires to be integers must be integers (Sects. 4.4.1, 4.4.2,
    #  6.1.1, 7.2.1, 7.3.1, 7.3.2, 8.2, 9.2.2, and 10), even if the value of a floating-point number is a whole number.
    #  Each type of HDU verifies the keywords that it defines, and all of them verify the common keywords.
    common = ["BITPIX", "NAXIS", "NAXIS1", "NAXIS12", "PCOUNT", "GCOUNT", "EXTVER", "EXTLEVEL", "WCSAXES",
        "WCSAXESA", "MJDREFI", "JDREFI"]
    integerkeys = [
        FITSFiles.Primary => ["BLANK"], FITSFiles.Conform => ["BLANK"], Image => ["BLANK"], Random => ["BLANK"],
        Table => ["TFIELDS", "TBCOL3"], Bintable => ["TFIELDS", "THEAP", "TNULL1", "TNULL12"],
        FITSFiles.ZImage => ["ZBITPIX", "ZNAXIS", "ZNAXIS2", "ZTILE1", "ZDITHER0", "ZPCOUNT", "ZGCOUNT", "ZBLANK"],
        FITSFiles.ZTable => ["ZNAXIS1", "ZNAXIS2", "ZPCOUNT", "ZTILELEN", "ZTHEAP"]]
    for (type, keys) in integerkeys, key in [common; keys]
        for value in (2.5, 3.0, "two", true, missing)
            cards = Card{<:Any}[Card("SIMPLE", true), Card(key, value)]
            @test_throws ArgumentError("$key must be an integer, but its value is $(repr(value)).") verified(
                type, cards)
        end
    end

    #  the structure keywords of each type of HDU have the values that the standard defines for it (Sects. 4.4.1,
    #  6.1.1, 7.1.1, 7.2.1, and 7.3.1). The header is given as pairs, and a value of nothing removes the keyword.
    structures = Dict(
        FITSFiles.Primary => ["SIMPLE" => true, "BITPIX" => 16, "NAXIS" => 2, "NAXIS1" => 3, "NAXIS2" => 4],
        FITSFiles.Conform => ["SIMPLE" => true, "BITPIX" => 16, "NAXIS" => 2, "NAXIS1" => 3, "NAXIS2" => 4],
        Image => ["XTENSION" => "IMAGE", "BITPIX" => -32, "NAXIS" => 2, "NAXIS1" => 3, "NAXIS2" => 4, "PCOUNT" => 0,
            "GCOUNT" => 1],
        Random => ["SIMPLE" => true, "BITPIX" => 16, "NAXIS" => 3, "NAXIS1" => 0, "NAXIS2" => 2, "NAXIS3" => 4,
            "GROUPS" => true, "PCOUNT" => 3, "GCOUNT" => 10],
        Table => ["XTENSION" => "TABLE", "BITPIX" => 8, "NAXIS" => 2, "NAXIS1" => 20, "NAXIS2" => 3, "PCOUNT" => 0,
            "GCOUNT" => 1],
        Bintable => ["XTENSION" => "BINTABLE", "BITPIX" => 8, "NAXIS" => 2, "NAXIS1" => 20, "NAXIS2" => 3,
            "PCOUNT" => 100, "GCOUNT" => 1])
    function structureheader(type, changes...)
        pairs = [get(Dict(changes), key, value) for (key, value) in structures[type]]
        names = first.(structures[type])
        extra = [key => value for (key, value) in changes if !(key in names) && !isnothing(value)]
        Card{<:Any}[Card(key, value) for (key, value) in [[(k, v) for (k, v) in zip(names, pairs) if !isnothing(v)];
            extra]]
    end
    function invalidstructure(type, message, changes...)
        @test_throws ArgumentError(message) verified(type, structureheader(type, changes...))
    end
    for type in Base.keys(structures)
        cards = structureheader(type)
        @test verified(type, cards) === cards
    end
    bitpixmessage = "BITPIX must be one of 8, 16, 32, 64, -32, or -64, but its value is"
    for type in (FITSFiles.Primary, FITSFiles.Conform, Image, Random)
        invalidstructure(type, "$bitpixmessage 17.", "BITPIX" => 17)
        invalidstructure(type, "$bitpixmessage 0.", "BITPIX" => 0)
        invalidstructure(type, "NAXIS2 must be non-negative, but its value is -4.", "NAXIS2" => -4)
    end
    for type in (FITSFiles.Primary, FITSFiles.Conform, Image)
        invalidstructure(type, "NAXIS must be an integer from 0 to 999, but its value is -1.", "NAXIS" => -1)
        invalidstructure(type, "NAXIS must be an integer from 0 to 999, but its value is 1000.", "NAXIS" => 1000)
        invalidstructure(type, "NAXIS2 is missing, but NAXIS is 2.", "NAXIS2" => nothing)
        invalidstructure(type, "NAXIS1 must be non-negative, but its value is -4.", "NAXIS1" => -4)
        invalidstructure(type, "NAXIS1 is missing, but NAXIS is 2.", "NAXIS1" => nothing, "NAXIS2" => nothing)
        #  the axes of an array of no axes, and a header with no NAXIS, are not used
        cards = structureheader(type, "NAXIS" => 0)
        if type === Image
            #  and they are keywords between NAXIS and PCOUNT, which the mandatory keywords of an IMAGE header do not have
            @test_logs (:warn, r"NAXIS1 is beyond NAXIS 0") (:warn, r"NAXIS2 is beyond NAXIS 0") (:warn,
                r"Keyword 4 of the header is NAXIS1, but the Standard requires PCOUNT") verified(type, cards)
        else
            @test_logs (:warn, r"NAXIS1 is beyond NAXIS 0") (:warn, r"NAXIS2 is beyond NAXIS 0") verified(type, cards)
        end
        #  except that the cards of a conforming header are not the mandatory keywords in order, and a primary or IMAGE
        #  header must have NAXIS
        cards = structureheader(type, "NAXIS" => nothing)
        if type === Image
            @test_throws ArgumentError("NAXIS is missing, but it is a mandatory keyword of an IMAGE extension (Sect. 7.1.1).") verified(type, cards)
        elseif type === FITSFiles.Primary
            @test_throws ArgumentError("NAXIS is missing, but it is a mandatory keyword of the primary header (Sect. 4.4.1.1).") verified(type, cards)
        else
            @test_logs (:warn, r"Keyword 3 of the header is NAXIS1, but the Standard requires NAXIS") verified(type, cards)
        end
    end
    invalidstructure(Image, "PCOUNT must be the integer 0, but its value is 3.", "PCOUNT" => 3)
    invalidstructure(Image, "GCOUNT must be the integer 1, but its value is 2.", "GCOUNT" => 2)
    invalidstructure(Random, "NAXIS3 is missing, but NAXIS is 3.", "NAXIS3" => nothing)
    invalidstructure(Random, "NAXIS must be an integer from 1 to 999, but its value is 0.", "NAXIS" => 0)
    invalidstructure(Random, "NAXIS1 must be the integer 0, but its value is 4.", "NAXIS1" => 4)
    invalidstructure(Random, "PCOUNT must be non-negative, but its value is -1.", "PCOUNT" => -1)
    invalidstructure(Random, "GCOUNT must be non-negative, but its value is -1.", "GCOUNT" => -1)
    @test verified(Random, structureheader(Random, "GCOUNT" => 0)) isa Any
    for type in (Table, Bintable)
        invalidstructure(type, "BITPIX must be the integer 8, but its value is 16.", "BITPIX" => 16)
        invalidstructure(type, "NAXIS must be the integer 2, but its value is 3.", "NAXIS" => 3)
        invalidstructure(type, "NAXIS2 is missing, but NAXIS is 2.", "NAXIS2" => nothing)
        invalidstructure(type, "NAXIS1 must be non-negative, but its value is -1.", "NAXIS1" => -1)
        invalidstructure(type, "GCOUNT must be the integer 1, but its value is 2.", "GCOUNT" => 2)
    end
    invalidstructure(Table, "PCOUNT must be the integer 0, but its value is 1.", "PCOUNT" => 1)
    invalidstructure(Bintable, "PCOUNT must be non-negative, but its value is -1.", "PCOUNT" => -1)
    @test verified(Bintable, structureheader(Bintable, "PCOUNT" => 0)) isa Any

    #  the HDU types are independent: a keyword of one type is not verified by another type, and the other
    #  keywords are not checked
    others = Dict(FITSFiles.Primary => ["TFIELDS", "THEAP", "TNULL1", "ZBITPIX"], Image => ["TBCOL1", "ZNAXIS"],
        Random => ["TFIELDS"], Table => ["BLANK", "THEAP", "TNULL1", "ZTHEAP"],
        Bintable => ["BLANK", "TBCOL1", "ZTILELEN"], FITSFiles.ZImage => ["BLANK", "TFIELDS", "ZTHEAP"],
        FITSFiles.ZTable => ["BLANK", "THEAP", "ZBLANK"])
    for (type, keys) in others, key in [keys; "BSCALE"; "EQUINOX"; "NAXISX"; "OBJECT"]
        cards = Card{<:Any}[Card(key, 2.5)]
        @test verified(type, cards) === cards
    end
    cards = Card{<:Any}[Card("TNULL1", "NULL")]
    @test verified(Table, cards) === cards
    @test_throws ArgumentError("TNULL1 must be an integer, but its value is \"NULL\".") verified(Bintable, cards)

    #  verifyinteger verifies the keywords of one dictionary that match the pattern
    dict(pairs...) = Dict{AbstractString, FITSFiles.ValueType}(pairs...)
    @test FITSFiles.verifyinteger(dict("BITPIX" => 8, "NAXIS" => 0), r"^(BITPIX|NAXIS\d*)$") === nothing
    @test FITSFiles.verifyinteger(dict("NAXIS" => 1.5), r"^BITPIX$") === nothing
    @test FITSFiles.verifyinteger(dict(), r"^BITPIX$") === nothing
    @test_throws ArgumentError("NAXIS2 must be an integer, but its value is 2.5.") FITSFiles.verifyinteger(
        dict("BITPIX" => 8, "NAXIS2" => 2.5), r"^(BITPIX|NAXIS\d*)$")

    #  the keywords that are verified are in the dictionary of the mandatory or of the reserved keywords that
    #  the verify! method of the type verifies
    for (key, mandatory) in ["BITPIX" => true, "NAXIS3" => true, "PCOUNT" => true, "GCOUNT" => true, "TFIELDS" => true,
        "TBCOL2" => true, "THEAP" => true, "ZBITPIX" => true, "ZNAXIS1" => true, "ZPCOUNT" => true, "ZTILELEN" => true,
        "EXTVER" => false, "EXTLEVEL" => false, "WCSAXES" => false, "MJDREFI" => false, "JDREFI" => false,
        "BLANK" => false, "TNULL3" => false, "ZTILE2" => false, "ZDITHER0" => false, "ZGCOUNT" => false,
        "ZBLANK" => false, "ZTHEAP" => false]
        mankeys, reskeys = FITSFiles.getreservedkeys(Card{<:Any}[Card(key, 3)])
        @test haskey(mandatory ? mankeys : reskeys, key)
    end

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

    ####    Test the keywords of the fields and the heap of a table    ####

    @testset "verifyfields! and verifyheap!" begin
        cards = Card{<:Any}[Card("TFIELDS", 2)]
        keys(pairs...) = Dict{AbstractString, FITSFiles.ValueType}(pairs...)
        ok = keys("TFIELDS" => 2, "TFORM1" => "I4", "TFORM2" => "F5.1", "TBCOL1" => 1, "TBCOL2" => 5)

        #  the cards are returned unchanged, and a header without TFIELDS is not verified (Sects. 7.2.1, 7.3.1)
        @test FITSFiles.verifyfields!(Table, cards, ok) === cards
        @test FITSFiles.verifyfields!(Bintable, cards, keys("TFORM3" => "I4")) === cards
        @test FITSFiles.verifyfields!(Bintable, cards, keys("TFIELDS" => 0)) === cards

        #  TFIELDS is not negative, and TFORMn is present for each field of both types of table, and TBCOLn for an ASCII table
        for type in (Table, Bintable)
            @test_throws ArgumentError("TFIELDS must be non-negative, but its value is -1.") FITSFiles.verifyfields!(
                type, cards, keys("TFIELDS" => -1))
            @test_throws ArgumentError("TFORM2 is missing, but TFIELDS is 2.") FITSFiles.verifyfields!(
                type, cards, keys("TFIELDS" => 2, "TFORM1" => "I4", "TBCOL1" => 1, "TBCOL2" => 5))
        end
        @test_throws ArgumentError("TBCOL2 is missing, but TFIELDS is 2.") FITSFiles.verifyfields!(
            Table, cards, delete!(copy(ok), "TBCOL2"))
        @test FITSFiles.verifyfields!(Bintable, cards, delete!(copy(ok), "TBCOL2")) === cards

        #  the first column of a row of an ASCII table is 1
        @test_throws ArgumentError FITSFiles.verifyfields!(Table, cards, merge(ok, keys("TBCOL1" => 0)))
        @test FITSFiles.verifyfields!(Bintable, cards, merge(ok, keys("TBCOL1" => 0))) === cards

        #  more than 999 fields, and keywords of fields that are beyond TFIELDS, are warnings
        for type in (Table, Bintable)
            @test_logs (:warn, r"TFIELDS 1000 is more than the maximum of 999") FITSFiles.verifyfields!(
                type, cards, keys("TFIELDS" => 1000, [("TFORM$j" => "I4") for j = 1:1000]..., [("TBCOL$j" => j) for j = 1:1000]...))
            @test_logs (:warn, r"TFORM3 is beyond TFIELDS 2") FITSFiles.verifyfields!(type, cards, merge(ok, keys("TFORM3" => "I4")))
        end
        @test_logs (:warn, r"TBCOL3 is beyond TFIELDS 2") FITSFiles.verifyfields!(
            Table, cards, merge(ok, keys("TBCOL3" => 9)))
        @test_logs FITSFiles.verifyfields!(Bintable, cards, merge(ok, keys("TBCOL3" => 9)))

        #  the heap starts at the end of the main data table or later, and within PCOUNT bytes of it (Sect. 7.3.2)
        table = keys("NAXIS1" => 8, "NAXIS2" => 3, "PCOUNT" => 10)
        @test_logs FITSFiles.verifyheap!(cards, table)
        @test_logs FITSFiles.verifyheap!(cards, merge(table, keys("THEAP" => 24)))
        @test_logs FITSFiles.verifyheap!(cards, merge(table, keys("THEAP" => 34)))
        @test_logs (:warn, r"THEAP 23 is less than NAXIS1\*NAXIS2, 24") FITSFiles.verifyheap!(
            cards, merge(table, keys("THEAP" => 23)))
        @test_logs (:warn, r"THEAP 35 is more than NAXIS1\*NAXIS2 \+ PCOUNT, 34") FITSFiles.verifyheap!(
            cards, merge(table, keys("THEAP" => 35)))
        @test FITSFiles.verifyheap!(cards, merge(table, keys("THEAP" => 23))) === cards
    end

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
            Random, cards, keys(cards), format(Int16, (2, 3)))
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
        kards = FITSFiles.arrangecards!(cards, ["SIMPLE" => true; FITSFiles.shapekeys(Primary, format)])
        @test [c.key for c in kards] == ["SIMPLE", "BITPIX", "NAXIS", "NAXIS1", "NAXIS2", "COMMENT", "EXTRA"]
        @test (kards[1].value, kards[2].value, kards[3].value, kards[4].value, kards[5].value) ==
            (true, 16, 2, 2, 3)
        @test kards[5].comment == "rows" && kards[5] === naxis2

        #  the keys of the shape begin at NAXIS2 for random groups, whose NAXIS1 is 0
        for type in (Primary, Image, FITSFiles.Conform)
            @test FITSFiles.shapekeys(type, format) == ["BITPIX" => 16, "NAXIS" => 2, "NAXIS1" => 2, "NAXIS2" => 3]
            @test FITSFiles.shapekeys(type, FITSFiles.DataFormat(Float32, 1, (), 0, 1, 0)) == ["BITPIX" => -32, "NAXIS" => 0]
        end
        @test FITSFiles.shapekeys(Random, format) ==
            ["BITPIX" => 16, "NAXIS" => 3, "NAXIS1" => 0, "NAXIS2" => 2, "NAXIS3" => 3]
        @test FITSFiles.shapekeys(Random, FITSFiles.DataFormat(Float32, 1, (), 0, 1, 0)) ==
            ["BITPIX" => -32, "NAXIS" => 1, "NAXIS1" => 0]

        #  the keys of a table are the length of a row and the number of rows, or zero
        table = FITSFiles.DataFormat(UInt8, 12, (4, 3), 0, 1, 0)
        @test FITSFiles.tablekeys(Table, table, 2) == ["XTENSION" => "TABLE", "BITPIX" => 8, "NAXIS" => 2,
            "NAXIS1" => 4, "NAXIS2" => 3, "PCOUNT" => 0, "GCOUNT" => 1, "TFIELDS" => 2]
        @test FITSFiles.tablekeys(Bintable, format, 0)[4:5] == ["NAXIS1" => 2, "NAXIS2" => 3]
        @test FITSFiles.tablekeys(Bintable, FITSFiles.DataFormat(UInt8, 0, (), 0, 1, 0), 0)[4:5] ==
            ["NAXIS1" => 0, "NAXIS2" => 0]

        #  the extension type is padded to 8 characters by the card, as the standard requires
        kards = FITSFiles.arrangecards!(Card{<:Any}[], FITSFiles.tablekeys(Table, table, 0))
        @test kards[1].value == "TABLE   " && length(kards) == 8

        #  the types of HDU: the first card is SIMPLE or XTENSION, and the random group cards are in order
        fmt = FITSFiles.DataFormat(Int16, 6, (2, 3), 0, 1, 0)
        for (type, field, first) in ((Primary, FITSFiles.PrimaryField(Int16, 0f0, 1f0, nothing, nothing, nothing), "SIMPLE"),
            (Image, FITSFiles.ImageField(Int16, 0f0, 1f0, nothing, nothing, nothing), "XTENSION"),
            (FITSFiles.Conform, FITSFiles.ConformField(), "SIMPLE"))
            kards = FITSFiles.createcards!(type, fmt, field, Card{<:Any}[])
            #  an IMAGE header has PCOUNT of 0 and GCOUNT of 1 (Sect. 7.1.1)
            @test [c.key for c in kards] == [first, "BITPIX", "NAXIS", "NAXIS1", "NAXIS2", (type === Image ? ["PCOUNT", "GCOUNT"] : [])...]
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
        for type in (Primary, Image)
            field = FITSFiles.FieldFormat(type, format, mankeys("BZERO" => 32768, "BSCALE" => 2.5, "BLANK" => -32768,
                "DATAMIN" => 1.5, "DATAMAX" => 9.5), ones(Int16, 3, 4))
            @test (field.zero, field.scale, field.miss, field.dmin, field.dmax) == (32768, 2.5, -32768, 1.5, 9.5)
            @test field isa (type === Primary ? FITSFiles.PrimaryField : FITSFiles.ImageField)
        end
        format = FITSFiles.DataFormat(Image, missing, mankeys("BITPIX" => -32))
        @test isnothing(FITSFiles.FieldFormat(Image, format, mankeys("BITPIX" => -32, "BLANK" => 0), missing).miss)

        #  the data of a header is zeros, or missing if there are no axes
        @test FITSFiles.zerosarray(formats[1]) == zeros(Int16, 3, 4)
        @test FITSFiles.createdata(Image, formats[1], FITSFiles.FieldFormat(Image, formats[1], mankeys(), missing)) == zeros(Int16, 3, 4)
        @test FITSFiles.createdata(Primary, formats[1], FITSFiles.FieldFormat(Primary, formats[1], mankeys(), missing)) == zeros(Int16, 3, 4)
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
        @test FITSFiles.tablecell([(m = "a",), (m = "bb",)], 1, 2) == "bb"
        @test FITSFiles.tablecell((m = ["a", "bb"],), 1, 2) == "bb"
        @test FITSFiles.tablecell((["a", "bb"],), 1, 2) == "bb"
        param = (; name = "m", index = 2)
        @test FITSFiles.getparam([(m = 1.5,), (m = 2.5,)], param, 2, 1) == 2.5
        @test FITSFiles.getparam([(m = [1 2; 3 4],)], param, 1, 1) == 3
        @test FITSFiles.getparam((m = [1.5, 2.5],), param, 2, 1) == 2.5
        @test FITSFiles.getparam((m = [1 2; 3 4],), param, 2, 1) == 4
        format = FITSFiles.DataFormat(Float32, 6, (2, 3), 0, 2, 0)
        @test FITSFiles.getgroup([(m = [1 2 3; 4 5 6],)], param, 1, format) == [1, 4, 2, 5, 3, 6]
        @test FITSFiles.getgroup((m = [1 2 3; 4 5 6],), param, 2, format) == [4, 5, 6]

        #  a table that is written from columns is the same as one that is written from records
        bytes(hdu) = (io = IOBuffer(); write(io, hdu); take!(io))
        columns = (a = Int32[1, 2, 3], b = [1.5, 2.5, 3.5], c = ["x", "yy", "zzz"])
        records = [(a = Int32(1), b = 1.5, c = "x"), (a = Int32(2), b = 2.5, c = "yy"), (a = Int32(3), b = 3.5, c = "zzz")]
        @test bytes(HDU(Bintable, columns)) == bytes(HDU(Bintable, records))
    end

    ####    Test the fill of the last data block (Sects. 3.3.2, 6.2, 7.2.3, and 7.3.3)    ####

    @testset "verifyfill" begin
        written(hdu) = (io = IOBuffer(); write(io, hdu); take!(io))
        reading(bytes) = read(IOBuffer(bytes), HDU)
        table = HDU(Table, [(a = 1, b = 2.0), (a = 2, b = 3.0)], Card{<:Any}[Card("TFIELDS", 2), Card("TTYPE1", "a"),
            Card("TFORM1", "I4"), Card("TBCOL1", 1), Card("TTYPE2", "b"), Card("TFORM2", "F6.1"), Card("TBCOL2", 5)])
        hdus = [HDU(Primary, Int16[1 2 3; 4 5 6]) => ("zeros", "Sect. 3.3.2"),
            HDU(Image, Int16[1 2 3; 4 5 6]) => ("zeros", "Sect. 3.3.2"),
            HDU(Random, (a = Int16[1, 3], data = Int16[10 11 12; 20 21 22])) => ("zeros", "Sect. 6.2"),
            HDU(Bintable, (a = Int32[1, 2, 3], b = [1.5, 2.5, 3.5])) => ("zeros", "Sect. 7.3.3"),
            table => ("ASCII spaces", "Sect. 7.2.3")]
        for (hdu, (name, section)) in hdus
            bytes = written(hdu)
            warning = "The fill of the last data block of the HDU is not all $name ($section). The data are read as they " *
                "are, and the fill is written as $name."
            #  the fill is zeros, or spaces for an ASCII table, and the HDU is read without a warning
            original = @test_logs reading(bytes)
            #  a byte of the fill that is another is a warning, whichever it is, and the fill is written as it should be
            for j in (length(bytes), length(bytes) - 100, 2880 + 2880 - 2000)
                changed = copy(bytes)
                changed[j] = changed[j] ⊻ 0x55
                again = @test_logs (:warn, warning) reading(changed)
                @test isequal(again.data, original.data) && getfield(again, :cards) == getfield(original, :cards)
                @test written(again) == bytes
            end
        end
        #  the fill of an ASCII table is not zeros, and the fill of the other HDUs is not spaces
        tablebytes = written(table)
        @test_logs (:warn, r"not all ASCII spaces \(Sect. 7.2.3\)") reading([tablebytes[1:end-1]; 0x00])
        primarybytes = written(HDU(Primary, Int16[1 2 3; 4 5 6]))
        @test_logs (:warn, r"not all zeros \(Sect. 3.3.2\)") reading([primarybytes[1:end-1]; 0x20])
        #  the fill is written as it should be, so a file that is read and written has the fill of the standard
        changed = copy(primarybytes)
        changed[end] = 0x01
        @test @test_logs((:warn, r"not all zeros"), written(reading(changed))) == primarybytes
        #  data that fill the last block have no fill, and a file that ends after the data does not have it
        @test_logs reading(written(HDU(Primary, zeros(Int16, 1440))))
        @test_logs reading(written(HDU(Primary, zeros(Int16, 1441))))
        @test_logs reading(primarybytes[1:2880+12])
        @test_logs reading(primarybytes[1:2880+12+5])
        @test_logs (:warn, r"not all zeros") reading([primarybytes[1:2880+12+5]; 0x01])
        #  an HDU without data has no fill, and the fill of a file of HDUs is verified for each
        @test_logs reading(written(HDU(Primary)))
        mktemp() do path, io
            write(io, [HDU(Primary), hdus[2][1], hdus[4][1]]); close(io)
            @test_logs fits(path)
            bytes = read(path)
            bytes[2880 + 2880 + 2880 - 1] ⊻= 0x01
            write(path, bytes)
            file = @test_logs (:warn, r"The fill of the last data block of the HDU is not all zeros \(Sect. 3.3.2\)") fits(path)
            @test length(file) == 3
        end
    end

    ####    Test the keywords of the cards of an HDU that is made from data    ####

    @testset "verifycards!" begin
        image, groups = Int16[1 2 3; 4 5 6], (a = Int16[1, 3], data = Int16[10 11 12; 20 21 22])
        made = [HDU(Primary, image), HDU(Image, image), HDU(Random, groups)]
        datas = (image, image, groups)
        #  a value that cannot be used is the error that a read gives, and not a MethodError or an InexactError
        for (type, data) in zip((Primary, Image, Random), datas)
            @test_throws ArgumentError("BSCALE must be a number, but its value is \"two\".") HDU(type, data,
                Card{<:Any}[Card("BSCALE", "two")])
            @test_throws ArgumentError("BZERO must be a number, but its value is true.") HDU(type, data,
                Card{<:Any}[Card("OBJECT", "x"), Card("BZERO", true)])
            @test_throws ArgumentError("BLANK must be an integer, but its value is 2.5.") HDU(type, data,
                Card{<:Any}[Card("BLANK", 2.5)])
            @test_throws ArgumentError("BLANK must be an integer, but its value is 2.5.") HDU(type, data,
                Card{<:Any}[Card("BLANK", 2.5)]; record = false)
            #  and the others are warnings, as they are for a read
            @test_logs (:warn, "DATAMIN must be a floating-point number, but its value is the integer 3. It is read as it is.") HDU(
                type, data, Card{<:Any}[Card("DATAMIN", 3)])
            @test_logs (:warn, "BUNIT must be a units string (Sect. 4.3), but its value is \"furlongs/fortnight^x\". It is " *
                "read as it is.") HDU(type, data, Card{<:Any}[Card("BUNIT", "furlongs/fortnight^x")])
            @test_logs (:warn, "ORIGIN must be a character string, but its value is 3. It is read as it is.") HDU(type, data,
                Card{<:Any}[Card("ORIGIN", 3)])
            #  cards that are valid are not a warning, and their order is not, since the header is arranged
            @test_logs HDU(type, data, Card{<:Any}[Card("BSCALE", 2.0), Card("OBJECT", "NGC 1275"), Card("BUNIT", "m/s")])
        end
        #  the keywords of the first card are made from the data, so cards of the wrong place or the wrong value are not verified
        @test_logs (:warn, r"BITPIX set to") HDU(Primary, image, Card{<:Any}[Card("OBJECT", "x"), Card("BITPIX", 32),
            Card("SIMPLE", true)])
        @test_logs (:warn, r"BITPIX set to") HDU(Image, image, Card{<:Any}[Card("OBJECT", "x"), Card("BITPIX", 32),
            Card("XTENSION", "IMAGE")])
        #  the keywords of random groups that are the parameters are verified, too
        @test_throws ArgumentError("PSCAL1 must be a number, but its value is \"x\".") HDU(Random, groups,
            Card{<:Any}[Card("PSCAL1", "x")])
        @test_logs (:warn, "PSCAL9 is beyond PCOUNT 1, and is not used.") HDU(Random, groups, Card{<:Any}[Card("PSCAL9", 2.0)])
        #  the HDUs of the other types are made as they were
        table = HDU(Bintable, (a = Int32[1, 2, 3],), Card{<:Any}[Card("TTYPE1", "a")])
        @test table isa HDU{Bintable}
    end

    ####    Test the mandatory and reserved keywords of the HDUs    ####

    @testset "MANDATORYKEYS and RESERVEDKEYS" begin
        mandatory = [
        "BITPIX", "END", "GCOUNT", "GROUPS", "NAXIS", "PCOUNT", "SIMPLE", "TBCOL", "TFIELDS", "TFORM", "THEAP",
        "XTENSION", "ZBITPIX", "ZCMPTYPE", "ZCTYP", "ZFORM", "ZIMAGE", "ZNAXIS", "ZPCOUNT", "ZTABLE", "ZTILELEN"]
        reserved = [
        "AUTHOR", "BLANK", "BLOCKED", "BSCALE", "BUNIT", "BZERO", "CHECKSUM", "DATAMAX", "DATAMIN", "DATASUM",
        "DATE", "DATE-OBS", "EPOCH", "EQUINOX", "EXTEND", "EXTLEVEL", "EXTNAME", "EXTVER", "FZALG", "FZALGOR",
        "FZTILELN", "INHERIT", "INSTRUME", "JDREFI", "MJDREFI", "OBJECT", "OBSERVER", "ORIGIN", "PSCAL", "PTYPE",
        "PZERO", "REFERENC", "TBCOL", "TDIM", "TDISP", "TDMAX", "TDMIN", "TELESCOP", "TFIELDS", "TFORM", "TLMAX",
        "TLMIN", "TNULL", "TSCAL", "TTYPE", "TUNIT", "TZERO", "WCSAXES", "ZBLANK", "ZBLOCKED", "ZDATASUM",
        "ZDITHER0", "ZEXTEND", "ZGCOUNT", "ZHECKSUM", "ZMASKCMP", "ZNAME", "ZPCOUNT", "ZQUANTIZ", "ZSIMPLE",
        "ZTENSION", "ZTHEAP", "ZTILE", "ZVAL"]
        #  the types of HDUs add the roots of their keywords, in their files, to those of the HDUs, which are each once
        @test allunique(FITSFiles.MANDATORYKEYS) && allunique(FITSFiles.RESERVEDKEYS)
        @test sort(FITSFiles.MANDATORYKEYS) == sort(mandatory) && sort(FITSFiles.RESERVEDKEYS) == sort(reserved)
        #  the keywords of each type of HDU are sorted into the mandatory and the reserved
        cards = Card{<:Any}[Card("SIMPLE", true), Card("BITPIX", 16), Card("GROUPS", true), Card("PCOUNT", 2), Card("PTYPE1", "A"),
            Card("BSCALE", 2.0), Card("INHERIT", true), Card("TFORM3", "A4"), Card("TDIM2", "(2,3)"), Card("ZTILE1", 4),
            Card("FZALGOR", "RICE_1"), Card("OBJECT", "x"), Card("NOTAKEY", 1)]
        mankeys, reskeys = FITSFiles.getreservedkeys(cards)
        @test sort(collect(keys(mankeys))) == ["BITPIX", "GROUPS", "PCOUNT", "SIMPLE", "TFORM3"]
        @test sort(collect(keys(reskeys))) == ["BSCALE", "FZALGOR", "INHERIT", "OBJECT", "PTYPE1", "TDIM2", "TFORM3", "ZTILE1"]
    end

    ####    Test the verification that each type of HDU has of its own    ####

    @testset "verifyconform and verifyrows" begin
        #  a Conform HDU verifies the order and the format of its mandatory keywords, as a primary HDU does, with its own function
        simple, bitpix, naxis = Card("SIMPLE", false), Card("BITPIX", 16), Card("NAXIS", 0)
        mankeys, _ = FITSFiles.getreservedkeys(Card{<:Any}[simple, bitpix, naxis])
        cards = Card{<:Any}[simple, bitpix, naxis]
        @test FITSFiles.verifyconform(cards, mankeys) === cards
        misordered = Card{<:Any}[Card("OBJECT", "x"), simple, bitpix, naxis]
        @test_logs (:warn, r"Keyword 1 of the header is OBJECT, but the Standard requires SIMPLE") FITSFiles.verifyconform(
            misordered, mankeys)
        @test FITSFiles.verifyconform(misordered, Dict{AbstractString, FITSFiles.ValueType}("BITPIX" => 16)) === misordered
        #  and the tables verify the structure of their rows, each with its own function
        for (type, xtension) in ((Table, "TABLE"), (Bintable, "BINTABLE"))
            ok = Dict{AbstractString, FITSFiles.ValueType}("BITPIX" => 8, "NAXIS" => 2, "NAXIS1" => 20, "NAXIS2" => 3)
            @test isnothing(FITSFiles.verifyrows(type, ok))
            @test_throws ArgumentError("BITPIX must be the integer 8, but its value is 16.") FITSFiles.verifyrows(
                type, merge(ok, Dict{AbstractString, FITSFiles.ValueType}("BITPIX" => 16)))
            @test_throws ArgumentError("NAXIS must be the integer 2, but its value is 1.") FITSFiles.verifyrows(
                type, merge(ok, Dict{AbstractString, FITSFiles.ValueType}("NAXIS" => 1)))
            @test_throws ArgumentError("NAXIS2 is missing, but NAXIS is 2.") FITSFiles.verifyrows(
                type, delete!(copy(ok), "NAXIS2"))
        end
    end

    ####    Test what each type of HDU says of how it is shown and compared    ####

    @testset "firstaxis and primarytype" begin
        #  the axes of the data begin at NAXIS1, and at NAXIS2 for random groups, whose NAXIS1 is 0
        for type in (Primary, Image, Table, Bintable, FITSFiles.Conform, FITSFiles.ZImage, FITSFiles.ZTable)
            @test FITSFiles.firstaxis(type) == 1
        end
        @test FITSFiles.firstaxis(Random) == 2
        random = HDU(Random, (a = Int16[1, 3], data = Int16[10 11 12; 20 21 22]))
        @test occursin("3", sprint(show, MIME"text/plain"(), random)) && !occursin("2 × 3", sprint(show, MIME"text/plain"(), random))
        @test occursin("2 × 3", sprint(show, MIME"text/plain"(), HDU(Primary, Int16[10 11 12; 20 21 22])))
        #  a header that begins with SIMPLE is an IMAGE for the comparison of the names, and random groups are not
        @test FITSFiles.primarytype(Primary) == "IMAGE" && FITSFiles.primarytype(FITSFiles.Conform) == "IMAGE"
        @test FITSFiles.primarytype(Random) == "GROUPS"
    end

    @testset "namedata" begin
        #  tuples of the parameters followed by the data are named for random groups, and are unchanged for the other HDUs
        one = HDU(Random, (Int16[1, 3], Int16[10 11 12; 20 21 22]))
        @test keys(one.data) == (:param1, :data) && one.data.param1 == Int16[1, 3]
        many = HDU(Random, [(Int16(1), Int16[1, 2, 3]), (Int16(3), Int16[4, 5, 6])])
        @test keys(many.data[1]) == (:param1, :data) && many.data[2].data == Int16[4, 5, 6]
        columns = (Int32[1, 2], [1.5, 2.5])
        @test HDU(Bintable, columns).data == columns
        @test FITSFiles.namedata(Primary, columns, nothing, nothing) === columns
    end
end

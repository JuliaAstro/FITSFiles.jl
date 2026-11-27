@testset "typeofhdu" begin

    ###  test typeofhdu with only data.

    #  test Primary (default) type
    cards = Card[]
    data  = missing
    mankeys, reskeys = FITSFiles.getreservedkeys(cards)
    @test FITSFiles.typeofhdu(data, mankeys) == Primary

    cards = Card[]
    data  = ones(Int16, (3,3))
    mankeys, reskeys = FITSFiles.getreservedkeys(cards)
    @test FITSFiles.typeofhdu(data, mankeys) == Primary

    #  test Random type
    cards = Card[]
    data  = [(a=1, b=1., c=[1 1; 2 2]), (a=2, b=2., c=[2 2; 2 2]), (a=3, b=3., c=[3 3; 3 3])]
    mankeys, reskmeys = FITSFiles.getreservedkeys(cards)
    @test FITSFiles.typeofhdu(data, mankeys) == Random

    #  GROUPS that is not the logical T is not the signature of random groups, even if it is equal to it
    for groups in (false, 1, 1.0, "T", "TRUE")
        cards = Card[Card("SIMPLE", true), Card("BITPIX", 32), Card("NAXIS", 2),
                     Card("NAXIS1", 0), Card("NAXIS2", 10), Card("GROUPS", groups)]
        mankeys, reskeys = FITSFiles.getreservedkeys(cards)
        @test FITSFiles.typeofhdu(missing, mankeys) == Primary
    end

    #  test Image type
    #  It is not possible to distinquish between Primary and Image HDUs
    #  based just on data. Both are just N-dimensional arrays.
    # cards, data = Card[], ones(Int16, (3,3))
    # mankeys, reskeys = FITSFiles.getreservedkeys(cards)
    # @test FITSFiles.typeofhdu(data, mankeys) == Image

    #  test Table type
    cards = Card[]
    data = ["col1  col2  col3  col4",
            "col1  col2  col3  col4"]
    mankeys, reskeys = FITSFiles.getreservedkeys(cards)
    @test FITSFiles.typeofhdu(data, mankeys) == Table

    #  test Bintable type
    cards = Card[]
    data = [(a=1, b=1., c="1"), (a=2, b=2., c="2"), (a=3, b=3., c="3")]
    mankeys, reskeys = FITSFiles.getreservedkeys(cards)
    @test FITSFiles.typeofhdu(data, mankeys) == Bintable

    #  test ZImage type
    #  test ZTable type

    ###  test typeofhdu with only cards.

    #  test Primary (default) type
    cards = Card[]
    data  = missing
    mankeys, reskeys = FITSFiles.getreservedkeys(cards)
    @test FITSFiles.typeofhdu(data, mankeys) == Primary

    cards = Card[Card("SIMPLE", true), Card("BITPIX", 32), Card("NAXIS", 0)]
    data = missing
    mankeys, reskeys = FITSFiles.getreservedkeys(cards)
    @test FITSFiles.typeofhdu(data, mankeys) == Primary

    #  test Random type
    cards = Card[Card("SIMPLE", true), Card("BITPIX", 32), Card("NAXIS", 2),
                 Card("NAXIS1", 0), Card("NAXIS2", 10), Card("GROUPS", true)]
    data = missing
    mankeys, reskeys = FITSFiles.getreservedkeys(cards)
    @test FITSFiles.typeofhdu(data, mankeys) == Random

    #  test Image type
    cards = Card[Card("XTENSION", "IMAGE   "), Card("BITPIX", 16),
                 Card("NAXIS", 2), Card("NAXIS1", 10), Card("NAXIS2", 10)]
    data = missing
    mankeys, reskeys = FITSFiles.getreservedkeys(cards)
    @test FITSFiles.typeofhdu(data, mankeys) == Image

    #  test Table type
    cards = Card[Card("XTENSION", "TABLE   "), Card("BITPIX", 8),
                 Card("NAXIS", 2), Card("NAXIS1", 10), Card("NAXIS2", 10)]
    data = missing
    mankeys, reskeys = FITSFiles.getreservedkeys(cards)
    @test FITSFiles.typeofhdu(data, mankeys) == Table

    #  test Bintable type
    cards = Card[Card("XTENSION", "BINTABLE"), Card("BITPIX", 8),
                 Card("NAXIS", 2), Card("NAXIS1", 10), Card("NAXIS2", 10)]
    data = missing
    mankeys, reskeys = FITSFiles.getreservedkeys(cards)
    @test FITSFiles.typeofhdu(data, mankeys) == Bintable

    #  test ZImage type
    cards = Card[Card("XTENSION", "BINTABLE"), Card("BITPIX", 8),
                 Card("NAXIS", 2), Card("NAXIS1", 10), Card("NAXIS2", 10),
                 Card("ZIMAGE", true)]
    data = missing
    mankeys, reskeys = FITSFiles.getreservedkeys(cards)
    @test FITSFiles.typeofhdu(data, mankeys) == ZImage

    #  test ZTable type
    cards = Card[Card("XTENSION", "BINTABLE"), Card("BITPIX", 8),
                 Card("NAXIS", 2), Card("NAXIS1", 10), Card("NAXIS2", 10),
                 Card("ZTABLE", true)]
    data = missing
    mankeys, reskeys = FITSFiles.getreservedkeys(cards)
    @test FITSFiles.typeofhdu(data, mankeys) == ZTable

    #  test Conform type
    cards = Card[Card("XTENSION", "CONFORM "), Card("BITPIX", 16),
                 Card("NAXIS", 2), Card("NAXIS1", 10), Card("NAXIS2", 10)]
    data = missing
    mankeys, reskeys = FITSFiles.getreservedkeys(cards)
    @test FITSFiles.typeofhdu(data, mankeys) == Conform

    ###  test typeofhdu with the XTENSION value.

    #  the trailing spaces of the value are not significant.
    for (value, type) in (("IMAGE", Image), ("IMAGE   ", Image), ("IMAGE ", Image),
                          ("TABLE", Table), ("TABLE   ", Table),
                          ("BINTABLE", Bintable), ("BINTABLE ", Bintable), ("BINTABLE   ", Bintable))
        mankeys = Dict{AbstractString, FITSFiles.ValueType}("XTENSION" => value)
        @test FITSFiles.typeofhdu(mankeys) == type
    end

    #  leading spaces, other values, and values that are not strings are not recognized.
    for value in (" IMAGE", "image", "A3DTABLE", "IUEIMAGE", "", 5)
        mankeys = Dict{AbstractString, FITSFiles.ValueType}("XTENSION" => value)
        @test FITSFiles.typeofhdu(mankeys) == Conform
    end

    #  a compressed table is a ZTable, whatever the padding of the value.
    for value in ("BINTABLE", "BINTABLE ")
        mankeys = Dict{AbstractString, FITSFiles.ValueType}("XTENSION" => value, "ZIMAGE" => true)
        @test FITSFiles.typeofhdu(mankeys) == ZImage
        mankeys = Dict{AbstractString, FITSFiles.ValueType}("XTENSION" => value, "ZTABLE" => true)
        @test FITSFiles.typeofhdu(mankeys) == ZTable
    end

    ###  test the registry of the types of HDUs.

    #  every type that is detected is registered once, in order of priority, and Conform, the type that no other is, is last
    types = FITSFiles.HDUTYPES
    @test allunique(types) && last(types) == Conform
    @test issorted(FITSFiles.detectpriority.(types); rev = true)
    @test Set(types) == Set([Primary, Conform, Image, Random, Table, Bintable, ZImage, ZTable])
    #  the types of the standard extensions that are not implemented are not detected, so they are read as Conform
    @test !any(type -> type in types, (IUEImage, A3DTable, Foreign, Dump))

    #  the types are told apart by their own predicates
    mankeys = Dict{AbstractString, FITSFiles.ValueType}("XTENSION" => "BINTABLE  ")
    @test FITSFiles.xtensionvalue(mankeys) == "BINTABLE"
    @test ismissing(FITSFiles.xtensionvalue(Dict{AbstractString, FITSFiles.ValueType}()))
    @test FITSFiles.frommandatory(Bintable, mankeys) && !FITSFiles.frommandatory(Image, mankeys)
    @test !FITSFiles.frommandatory(ZImage, mankeys)
    @test FITSFiles.fromdata(Primary, missing) && !FITSFiles.fromdata(Table, [1, 2])
    @test FITSFiles.firstrecord([(1, 2)]) == (1, 2) && FITSFiles.firstrecord((a = 1,)) == (a = 1,)
    @test FITSFiles.firstrecord([1, 2]) === nothing && FITSFiles.firstrecord(missing) === nothing

    #  data with missing values are an image, and a header without SIMPLE or XTENSION is not an HDU
    @test FITSFiles.typeofhdu(Union{Int16, Missing}[1, missing], Dict{AbstractString, FITSFiles.ValueType}()) == Primary
    @test_throws ErrorException("Unknown HDU") FITSFiles.typeofhdu(Dict{AbstractString, FITSFiles.ValueType}("NAXIS" => 0))
end

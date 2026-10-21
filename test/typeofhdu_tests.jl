@testset "typeofhdu" begin

    ###  test typeofhdu with only data.

    #  test Primary (default) type
    cards = Card[]
    data  = missing
    mankeys, reskeys = FITSFiles.get_reserved_keys(cards)
    @test FITSFiles.typeofhdu(data, mankeys) == Primary

    cards = Card[]
    data  = ones(Int16, (3,3))
    mankeys, reskeys = FITSFiles.get_reserved_keys(cards)
    @test FITSFiles.typeofhdu(data, mankeys) == Primary

    #  test Random type
    cards = Card[]
    data  = [(a=1, b=1., c=[1 1; 2 2]), (a=2, b=2., c=[2 2; 2 2]), (a=3, b=3., c=[3 3; 3 3])]
    mankeys, reskmeys = FITSFiles.get_reserved_keys(cards)
    @test FITSFiles.typeofhdu(data, mankeys) == Random

    #  test Image type
    #  It is not possible to distinquish between Primary and Image HDUs
    #  based just on data. Both are just N-dimensional arrays.
    # cards, data = Card[], ones(Int16, (3,3))
    # mankeys, reskeys = FITSFiles.get_reserved_keys(cards)
    # @test FITSFiles.typeofhdu(data, mankeys) == Image

    #  test Table type
    cards = Card[]
    data = ["col1  col2  col3  col4",
            "col1  col2  col3  col4"]
    mankeys, reskeys = FITSFiles.get_reserved_keys(cards)
    @test FITSFiles.typeofhdu(data, mankeys) == Table

    #  test Bintable type
    cards = Card[]
    data = [(a=1, b=1., c="1"), (a=2, b=2., c="2"), (a=3, b=3., c="3")]
    mankeys, reskeys = FITSFiles.get_reserved_keys(cards)
    @test FITSFiles.typeofhdu(data, mankeys) == Bintable

    #  test ZImage type
    #  test ZTable type

    ###  test typeofhdu with only cards.

    #  test Primary (default) type
    cards = Card[]
    data  = missing
    mankeys, reskeys = FITSFiles.get_reserved_keys(cards)
    @test FITSFiles.typeofhdu(data, mankeys) == Primary

    cards = Card[Card("SIMPLE", true), Card("BITPIX", 32), Card("NAXIS", 0)]
    data = missing
    mankeys, reskeys = FITSFiles.get_reserved_keys(cards)
    @test FITSFiles.typeofhdu(data, mankeys) == Primary

    #  test Random type
    cards = Card[Card("SIMPLE", true), Card("BITPIX", 32), Card("NAXIS", 2),
                 Card("NAXIS1", 0), Card("NAXIS2", 10), Card("GROUPS", true)]
    data = missing
    mankeys, reskeys = FITSFiles.get_reserved_keys(cards)
    @test FITSFiles.typeofhdu(data, mankeys) == Random

    #  test Image type
    cards = Card[Card("XTENSION", "IMAGE   "), Card("BITPIX", 16),
                 Card("NAXIS", 2), Card("NAXIS1", 10), Card("NAXIS2", 10)]
    data = missing
    mankeys, reskeys = FITSFiles.get_reserved_keys(cards)
    @test FITSFiles.typeofhdu(data, mankeys) == Image

    #  test Table type
    cards = Card[Card("XTENSION", "TABLE   "), Card("BITPIX", 8),
                 Card("NAXIS", 2), Card("NAXIS1", 10), Card("NAXIS2", 10)]
    data = missing
    mankeys, reskeys = FITSFiles.get_reserved_keys(cards)
    @test FITSFiles.typeofhdu(data, mankeys) == Table

    #  test Bintable type
    cards = Card[Card("XTENSION", "BINTABLE"), Card("BITPIX", 8),
                 Card("NAXIS", 2), Card("NAXIS1", 10), Card("NAXIS2", 10)]
    data = missing
    mankeys, reskeys = FITSFiles.get_reserved_keys(cards)
    @test FITSFiles.typeofhdu(data, mankeys) == Bintable

    #  test ZImage type
    cards = Card[Card("XTENSION", "BINTABLE"), Card("BITPIX", 8),
                 Card("NAXIS", 2), Card("NAXIS1", 10), Card("NAXIS2", 10),
                 Card("ZIMAGE", true)]
    data = missing
    mankeys, reskeys = FITSFiles.get_reserved_keys(cards)
    @test FITSFiles.typeofhdu(data, mankeys) == ZImage

    #  test ZTable type
    cards = Card[Card("XTENSION", "BINTABLE"), Card("BITPIX", 8),
                 Card("NAXIS", 2), Card("NAXIS1", 10), Card("NAXIS2", 10),
                 Card("ZTABLE", true)]
    data = missing
    mankeys, reskeys = FITSFiles.get_reserved_keys(cards)
    @test FITSFiles.typeofhdu(data, mankeys) == ZTable

    #  test Conform type
    cards = Card[Card("XTENSION", "CONFORM "), Card("BITPIX", 16),
                 Card("NAXIS", 2), Card("NAXIS1", 10), Card("NAXIS2", 10)]
    data = missing
    mankeys, reskeys = FITSFiles.get_reserved_keys(cards)
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

end

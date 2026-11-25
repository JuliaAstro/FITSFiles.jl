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
end

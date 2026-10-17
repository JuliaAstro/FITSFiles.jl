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
end

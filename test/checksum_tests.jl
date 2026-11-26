@testset "Checksum" begin

    ####    The ones' complement sum (Sect. 4.4.2.7)

    words(values...) = collect(reinterpret(UInt8, hton.(UInt32[values...])))
    sumof = FITSFiles.onescomplementsum
    @test sumof(words(1, 2, 3)) === 0x00000006
    #  a carry is added to the least significant bit
    @test sumof(words(0xffffffff, 1)) === 0x00000001
    @test sumof(words(0xfffffffe, 0xfffffffe)) === 0xfffffffd
    #  negative zero is all bits equal to 1, and is the sum of an integer and its complement
    @test sumof(words(0xffffffff)) === 0xffffffff
    @test sumof(words(0x12345678, ~0x12345678)) === 0xffffffff
    @test sumof(UInt8[]) === 0x00000000
    @test sumof(words(5), 7) === 0x0000000c
    #  the bytes are big-endian integers
    @test sumof(UInt8[0x01, 0x00, 0x00, 0x00]) === 0x01000000
    @test_throws ArgumentError sumof(UInt8[1, 2, 3])

    #  the sum is the sum of the integers, with the carries added, for any number of bytes
    function naive(bytes)
        total = sum(UInt128(ntoh(x)) for x in reinterpret(UInt32, bytes); init = UInt128(0))
        while total > 0xffffffff
            total = (total & 0xffffffff) + (total >> 32)
        end
        UInt32(total)
    end
    for n in (4, 2880, 2880*17, 4*(2880*4096) + 2880*3)
        bytes = rand(UInt8, n)
        @test sumof(bytes) === naive(bytes)
    end
    bytes = fill(0xff, 2*2880*4096)
    @test sumof(bytes) === 0xffffffff

    ####    The ASCII encoding (Appendix J.2)

    #  the example of Appendix J.3: the sum 868229149 of the HDU with the CHECKSUM '0000000000000000'
    @test FITSFiles.encodechecksum(868229149) == "hcHjjc9ghcEghc9g"
    @test FITSFiles.decodechecksum("hcHjjc9ghcEghc9g") === 0x33c0201d
    for sum in rand(UInt32, 2000)
        text = FITSFiles.encodechecksum(sum)
        #  16 alphanumeric characters
        @test length(text) == 16 && all(c -> isascii(c) && isletter(c) || isdigit(c), text)
        @test FITSFiles.decodechecksum(text) === sum
    end
    for sum in (0x00000000, 0xffffffff, 0x00000001, 0x80808080, 0x3a3a3a3a)
        @test FITSFiles.decodechecksum(FITSFiles.encodechecksum(sum)) === sum
    end
    @test_throws ArgumentError FITSFiles.decodechecksum("short")

end

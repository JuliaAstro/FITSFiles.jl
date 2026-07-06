using Test

if !isdefined(@__MODULE__, :HDecompress)
    include("../src/HDecompress.jl")
end
using .HDecompress

@testset "HDecompress helper functions" begin
    @testset "start_inputing_bits resets the bit reader state" begin
        HDecompress.GLOBALS[:nextchar] = 5
        HDecompress.GLOBALS[:buffer2] = UInt64(0xAA)
        HDecompress.GLOBALS[:bits_to_go] = 3

        HDecompress.start_inputing_bits()

        @test HDecompress.GLOBALS[:nextchar] == 5
        @test HDecompress.GLOBALS[:buffer2] == UInt64(0)
        @test HDecompress.GLOBALS[:bits_to_go] == 0
    end

    @testset "skip_to_byte_boundary clears any partial-byte state" begin
        HDecompress.GLOBALS[:nextchar] = 2
        HDecompress.GLOBALS[:buffer2] = UInt64(0x55)
        HDecompress.GLOBALS[:bits_to_go] = 4

        HDecompress.skip_to_byte_boundary()

        @test HDecompress.GLOBALS[:bits_to_go] == 0
        @test HDecompress.GLOBALS[:buffer2] == UInt64(0)
    end

    @testset "input_bit! reads bits from the byte stream" begin
        HDecompress.GLOBALS[:nextchar] = 0
        HDecompress.start_inputing_bits()
        data = UInt8[0b10110010]

        @test HDecompress.input_bit!(data) == 1
        @test HDecompress.input_bit!(data) == 0
        @test HDecompress.input_bit!(data) == 1
        @test HDecompress.input_bit!(data) == 1
    end

    @testset "input_nbits! reads a fixed number of bits" begin
        HDecompress.GLOBALS[:nextchar] = 0
        HDecompress.start_inputing_bits()
        data = UInt8[0b10110101]

        @test HDecompress.input_nbits!(data, 3) == 0b101
        @test HDecompress.input_nbits!(data, 2) == 0b10
    end

    @testset "input_nybble! reads four bits as a nibble" begin
        HDecompress.GLOBALS[:nextchar] = 0
        HDecompress.start_inputing_bits()
        data = UInt8[0b11010011]

        @test HDecompress.input_nybble!(data) == 0b1101
        @test HDecompress.input_nybble!(data) == 0b0011
    end

    @testset "input_huffman! decodes a simple fixed-code value" begin
        HDecompress.GLOBALS[:nextchar] = 0
        HDecompress.start_inputing_bits()
        data = UInt8[0b10000000]
        @test HDecompress.input_huffman!(data) == 3

        HDecompress.GLOBALS[:nextchar] = 0
        HDecompress.start_inputing_bits()
        data = UInt8[0b00000000]
        @test HDecompress.input_huffman!(data) == 1
    end

    @testset "qread! and readint! read bytes and integers correctly" begin
        HDecompress.GLOBALS[:nextchar] = 0
        HDecompress.start_inputing_bits()
        data = UInt8[0x01, 0x02, 0x03, 0x04]

        @test HDecompress.qread!(data, 2) == UInt8[0x01, 0x02]
        @test HDecompress.readint!(data, nbytes = 2) == 0x0304
    end

    @testset "hsmooth! adjusts detail coefficients" begin
        arr = Int32[
            0 0 0 0 0;
            0 0 0 0 0;
            0 0 1 0 0;
            0 0 -8 0 0;
            0 0 4 0 0
        ]

        HDecompress.hsmooth!(arr, 8)

        @test arr[4, 3] == -4
    end

    @testset "hsmooth! is a no-op when scale is too small" begin
        arr = fill(Int32(1), 5, 5)
        original = copy(arr)

        HDecompress.hsmooth!(arr, 1)

        @test arr == original
    end
end

using Test

if !isdefined(@__MODULE__, :HCompress)
    include("../src/HCompress.jl")
end
using .HCompress

@testset "HCompress helper functions" begin
    @testset "writeint! writes integers in the expected byte order" begin
        HCompress.GLOBALS[:noutchar] = 0
        HCompress.GLOBALS[:noutmax] = 4
        out = zeros(UInt8, 4)
        HCompress.writeint!(out, 0x01020304)
        @test out == UInt8[0x01, 0x02, 0x03, 0x04]

        HCompress.GLOBALS[:noutchar] = 0
        HCompress.GLOBALS[:noutmax] = 2
        out2 = zeros(UInt8, 2)
        HCompress.writeint!(out2, 0x1234, nbytes = 2)
        @test out2 == UInt8[0x12, 0x34]
    end

    @testset "qwrite! appends bytes and stops on overflow" begin
        HCompress.GLOBALS[:noutchar] = 0
        HCompress.GLOBALS[:noutmax] = 6
        out = zeros(UInt8, 6)

        @test HCompress.qwrite!(out, UInt8[0xAA, 0xBB]) == 2
        @test out[1:2] == UInt8[0xAA, 0xBB]
        @test HCompress.GLOBALS[:noutchar] == 2

        HCompress.GLOBALS[:noutmax] = 5
        @test HCompress.qwrite!(out, UInt8[0xCC, 0xDD, 0xEE, 0xFF]) == 0
        @test out[3:6] == zeros(UInt8, 4)
    end

    @testset "digitize! rounds values to a multiple of the scale" begin
        input = Int32[-3, -2, -1, 0, 1, 2, 3]
        expected = map(x -> div(x, 2, RoundNearest), input)
        output = copy(input)

        HCompress.digitize!(output, 2)
        @test output == expected

        unchanged = Int32[4, 5, 6]
        HCompress.digitize!(unchanged, 1)
        @test unchanged == Int32[4, 5, 6]
    end

    @testset "bit output helpers reset and flush correctly" begin
        HCompress.GLOBALS[:noutchar] = 0
        HCompress.GLOBALS[:noutmax] = 8
        out = zeros(UInt8, 8)

        HCompress.start_outputting_bits()
        @test HCompress.GLOBALS[:buffer2] == UInt64(0)
        @test HCompress.GLOBALS[:bits_to_go2] == 8

        HCompress.output_nbits!(out, 0b101, 3)
        HCompress.output_nbits!(out, 0b10, 2)
        @test HCompress.GLOBALS[:bitcount] == 5

        HCompress.done_outputting_bits!(out)
        @test HCompress.GLOBALS[:noutchar] == 1
        @test out[1] == 0xB0
    end

    @testset "output_nybble! writes a nibble into the output buffer" begin
        HCompress.GLOBALS[:noutchar] = 0
        HCompress.GLOBALS[:noutmax] = 8
        out = zeros(UInt8, 8)

        HCompress.start_outputting_bits()
        HCompress.output_nybble!(out, 0xA)
        @test HCompress.GLOBALS[:bitcount] == 4

        HCompress.done_outputting_bits!(out)
        @test out[1] == 0xA0
    end
end

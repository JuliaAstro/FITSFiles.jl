#!/usr/bin/env julia
using Test
using Random

if !isdefined(@__MODULE__, :HCompress)
    include("../src/HCompress.jl")
end
if !isdefined(@__MODULE__, :HDecompress)
    include("../src/HDecompress.jl")
end

using .HCompress
using .HDecompress

function compress_image(original::AbstractArray{<:Integer}, scale::Integer=2)
    output = Vector{UInt8}(undef, length(original) * 32)
    nbytes = Ref{Integer}(length(output))
    stat, encoded = HCompress.encode(HCompress.HComp, original, scale; output = output, nbytes = nbytes)
    return stat, encoded[1:nbytes[]], nbytes[]
end

function roundtrip_similarity(original::AbstractArray{<:Integer}, scale::Integer=2; tolerance::Integer=30)
    stat_c, compressed, _ = compress_image(original, scale)
    @test stat_c == 0
    @test length(compressed) > 0

    stat_d, decoded = HDecompress.decode(HDecompress.HComp, compressed, 0)
    @test stat_d == 0
    @test size(decoded) == size(original)

    diff = abs.(Int.(decoded) .- Int.(original))
    @test maximum(diff) <= tolerance
    return diff
end

@testset "Round-trip similarity" begin
    @testset "small deterministic matrix" begin
        original = Int32[1 2 3 4; 5 6 7 8; 9 10 11 12]
        roundtrip_similarity(original, 1; tolerance = 80)
    end

    @testset "small random matrix" begin
        Random.seed!(1234)
        original = reshape(Int32.(rand(0:50, 4 * 4)), 4, 4)
        roundtrip_similarity(original, 1; tolerance = 80)
    end
end

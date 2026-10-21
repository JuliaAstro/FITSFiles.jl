@testset "Card syntax" begin
    value = FITSFiles.value_fsc(FITSFiles.NUMBER_FSC_STR_2)
    lower = FITSFiles.value_fsc(FITSFiles.NUMBER_LOWER_STR)
    hier  = FITSFiles.hierarch_fsc(FITSFiles.NUMBER_FSC_STR_2)
    hlow  = FITSFiles.hierarch_fsc(FITSFiles.NUMBER_LOWER_STR)

    #  The fields of a value regex are the string, logical, number, complex, separator, and comment.
    @testset "value_fsc" begin
        m = match(value, "  1.5E3 / a comment")
        @test m[:numr] == "1.5E3" && m[:slash] == "/" && m[:comment] == "a comment"
        m = match(value, "  'abc' / c")
        @test m[:strg] == "'abc'" && isnothing(m[:numr]) && m[:comment] == "c"
        @test match(value, "  T")[:bool] == "T"
        m = match(value, "  (1.0, 2.0) / c")
        @test m[:cplx] == "(1.0, 2.0)" && m[:real] == "1.0" && m[:imag] == "2.0"
        m = match(value, "   / c")
        @test isnothing(m[:numr]) && isnothing(m[:strg]) && m[:slash] == "/" && m[:comment] == "c"
        @test isnothing(match(value, "  1.5E3 / c")[:strg])
    end

    #  A lower case exponent letter is a number only for the lower case regex.
    @testset "lower case exponent" begin
        @test match(lower, "  1.5e3")[:numr] == "1.5e3"
        @test match(lower, "  1.5d3 / c")[:numr] == "1.5d3"
        @test match(value, "  1.5e3")[:numr] == "1.5"
        @test isnothing(match(lower, "  'abc'")[:numr])
    end

    @testset "hierarch_fsc" begin
        m = match(hier, "ESO A = 1.5 / c")
        @test m[:key] == "ESO A" && m[:numr] == "1.5" && m[:comment] == "c"
        @test match(hier, "ESO A = 'x'")[:strg] == "'x'"
        m = match(hier, "ESO A =")
        @test m[:key] == "ESO A" && isnothing(m[:numr]) && isnothing(m[:strg])
        @test match(hier, "ESO A = T")[:bool] == "T"
        @test match(hier, "ESO A = (1, 2)")[:cplx] == "(1, 2)"
        @test match(hier, "ESO A = 1.5e3")[:numr] == "1.5"
        @test match(hlow, "ESO A = 1.5e3")[:numr] == "1.5e3"
        @test isnothing(match(hier, "ESO a = 1"))
    end
end

@testset "Card write" begin
    format = FITSFiles.CardFormat()
    image(T, key, value) = FITSFiles.format_card(T, key, value, "", "", format)

    @testset "show" begin
        cards = Card{<:Any}[Card("ABC", 1, "a"), Card("COMMENT", "text")]
        @test sprint(show, cards) == repr(cards[1]) * "\n" * repr(cards[2])
        @test sprint(show, Card{<:Any}[Card("ABC", 1)]) == repr(Card("ABC", 1))
    end

    @testset "Comment and History" begin
        @test image(FITSFiles.Comment, "COMMENT", "text") == rpad("COMMENT text", 80)
        @test image(FITSFiles.Comment, "COMMENT", missing) == rpad("COMMENT", 80)
        @test image(FITSFiles.History, "HISTORY", "text") == rpad("HISTORY text", 80)
        @test image(FITSFiles.History, "HISTORY", missing) == rpad("HISTORY", 80)
        @test_throws "Value is not a string." image(FITSFiles.Comment, "COMMENT", 1)
        @test_throws "Value is not a string." image(FITSFiles.Comment, "COMMENT", 1.5)
        @test_throws "Value is not a string." image(FITSFiles.History, "HISTORY", 1)
        @test_throws "Value is not a string." image(FITSFiles.History, "HISTORY", 1.5)
    end

    @testset "Continue" begin
        @test image(FITSFiles.Continue, "CONTINUE", "ab") == rpad("CONTINUE  'ab'", 80)
        @test_throws "Continue contains non-string value." image(FITSFiles.Continue, "CONTINUE", 1)
        @test_throws "Continue contains non-string value." image(FITSFiles.Continue, "CONTINUE", missing)
    end
end

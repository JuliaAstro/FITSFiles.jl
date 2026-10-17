using FITSFiles
using Test
using Unitful

showfields(card) = Tuple(push!([getfield(card, k) for k in fieldnames(Card)[1:3]], repr(card)))

io = IOBuffer()

include("card_tests.jl")
include("cards_tests.jl")
include("typeofhdu_tests.jl")
include("primary_hdu_tests.jl")
include("random_hdu_tests.jl")
include("image_hdu_tests.jl")
include("table_hdu_tests.jl")
include("bintable_hdu_tests.jl")
include("fits_tests.jl")

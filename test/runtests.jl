using FITSFiles
using Test
using Unitful, UnitfulAngles, UnitfulAstro

showfields(card) = (card.key, card.value, card.comment, repr(card))

io = IOBuffer()

include("card_tests.jl")
include("header_tests.jl")
include("units_tests.jl")
include("format_tests.jl")
include("typeofhdu_tests.jl")
include("primary_hdu_tests.jl")
include("random_hdu_tests.jl")
include("image_hdu_tests.jl")
include("table_hdu_tests.jl")
include("bintable_hdu_tests.jl")
include("fits_tests.jl")

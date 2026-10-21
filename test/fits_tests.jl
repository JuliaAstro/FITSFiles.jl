@testset "FITS" begin

    #  test write/read round-trip of a concrete HDU vector (dispatch previously
    #  fell through to `Base.write(::IO, ::Array)` for e.g. Vector{HDU{Primary}})
    data = reshape(Float32[1:100;], 5, 20)
    cards = [Card("FLTKEY", 1.0, "floating point keyword"),
             Card("STRKEY", "string value")]
    hdus = [HDU(data, cards)]
    @test hdus isa Vector{HDU{Primary}}

    path = joinpath(mktempdir(), "roundtrip.fits")
    write(path, hdus)
    back = fits(path)
    @test length(back) == 1
    @test back[1] isa HDU{Primary}
    @test back[1].data == data

    #  test the same round-trip through an in-memory IO
    io = IOBuffer()
    write(io, hdus)
    seekstart(io)
    @test fits(io)[1].data == data

    #  test multiple HDUs, including an Image extension
    write(path, [HDU(data, cards), HDU(Image, data, cards)])
    back = fits(path)
    @test FITSFiles.typeofhdu.(back) == [Primary, Image]
    @test back[2].data == data

    #  test Base.size from the NAXIS cards, without touching the data
    @test size(HDU(data, cards)) == (5, 20)
    @test size(back[2]) == (5, 20)

    #  test size of a lazily-loaded HDU (file-backed data not yet read)
    lazy = fits(path)[1]
    @test getfield(lazy, :data) isa FITSFiles.LazyArray
    @test size(lazy) == (5, 20)

    #  test size of a header-only HDU
    @test size(HDU(Primary)) == ()
end

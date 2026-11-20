@testset "Image HDU" begin

    #  test Image (specific HDU) type
    hdu = HDU(Image)
    @test isequal(showfields.(hdu.cards),
                  [("XTENSION", "IMAGE   ", "",
                    "XTENSION= 'IMAGE   '                                                            "),
                   ("BITPIX", 32, "",
                    "BITPIX  =                   32                                                  "),
                   ("NAXIS", 0, "",
                    "NAXIS   =                    0                                                  ")])

    @test ismissing(hdu.data)

    #  test Image (specific HDU) type with data
    data = ones(Int32, (3,3))
    hdu = HDU(Image, data)
    @test isequal(showfields.(hdu.cards),
                  [("XTENSION", "IMAGE   ", "",
                    "XTENSION= 'IMAGE   '                                                            "),
                   ("BITPIX", 32, "",
                    "BITPIX  =                   32                                                  "),
                   ("NAXIS", 2, "",
                    "NAXIS   =                    2                                                  "),
                   ("NAXIS1", 3, "",
                    "NAXIS1  =                    3                                                  "),
                   ("NAXIS2", 3, "",
                    "NAXIS2  =                    3                                                  ")])

    @test (ndims(hdu.data) == 2 && size(hdu.data) == (3, 3) && length(hdu.data) == 9 &&
           eltype(hdu.data) == Int32)

    #  test Image type with cards
    cards = [Card("XTENSION", "IMAGE"),
             Card("BITPIX", 32),
             Card("NAXIS", 2),
             Card("NAXIS1", 3),
             Card("NAXIS2", 3)]
    hdu = HDU(cards)

    @test isequal(showfields.(hdu.cards),
                  [("XTENSION", "IMAGE   ", "",
                    "XTENSION= 'IMAGE   '                                                            "),
                   ("BITPIX", 32, "",
                    "BITPIX  =                   32                                                  "),
                   ("NAXIS", 2, "",
                    "NAXIS   =                    2                                                  "),
                   ("NAXIS1", 3, "",
                    "NAXIS1  =                    3                                                  "),
                   ("NAXIS2", 3, "",
                    "NAXIS2  =                    3                                                  ")])

    @test (ndims(hdu.data) == 2 && size(hdu.data) == (3, 3) && length(hdu.data) == 9 &&
           eltype(hdu.data) == Int32)

    #  test Image type with data and cards
    data = ones(Int32, (3,3))
    cards = [Card("XTENSION", "IMAGE"),
             Card("BITPIX", 32),
             Card("NAXIS", 2),
             Card("NAXIS1", 3),
             Card("NAXIS2", 3)]
    hdu = HDU(data, cards)

    @test isequal(showfields.(hdu.cards),
                  [("XTENSION", "IMAGE   ", "",
                    "XTENSION= 'IMAGE   '                                                            "),
                   ("BITPIX", 32, "",
                    "BITPIX  =                   32                                                  "),
                   ("NAXIS", 2, "",
                    "NAXIS   =                    2                                                  "),
                   ("NAXIS1", 3, "",
                    "NAXIS1  =                    3                                                  "),
                   ("NAXIS2", 3, "",
                    "NAXIS2  =                    3                                                  ")])

    @test (ndims(hdu.data) == 2 && size(hdu.data) == (3, 3) && length(hdu.data) == 9 &&
           eltype(hdu.data) == Int32)

    #  test Image type with data and inconsistent cards
    data = ones(Int32, (3,3))
    cards = [Card("XTENSION", "IMAGE"),
             Card("BITPIX", 16),
             Card("NAXIS", 2),
             Card("NAXIS1", 9),
             Card("NAXIS2", 9)]
    hdu = HDU(data, cards)

    @test isequal(showfields.(hdu.cards),
                  [("XTENSION", "IMAGE   ", "",
                    "XTENSION= 'IMAGE   '                                                            "),
                   ("BITPIX", 32, "",
                    "BITPIX  =                   32                                                  "),
                   ("NAXIS", 2, "",
                    "NAXIS   =                    2                                                  "),
                   ("NAXIS1", 3, "",
                    "NAXIS1  =                    3                                                  "),
                   ("NAXIS2", 3, "",
                    "NAXIS2  =                    3                                                  ")])

    @test (ndims(hdu.data) == 2 && size(hdu.data) == (3, 3) && length(hdu.data) == 9 &&
           eltype(hdu.data) == Int32)

    #  test Image type with scale == true
    data = ones(Int32, (3,3))
    cards = [Card("XTENSION", "IMAGE"),
             Card("BITPIX", 32),
             Card("NAXIS", 2),
             Card("NAXIS1", 3),
             Card("NAXIS2", 3),
             Card("BZERO", 1.0),
             Card("BSCALE", 0.1)]
    seek(io, 0)
    write(io, HDU(data, cards))
    seek(io, 0)
    hdu = read(io, HDU; scale=true)

    @test isequal(showfields.(hdu.cards),
                  [("XTENSION", "IMAGE", "",
                    "XTENSION= 'IMAGE   '                                                            "),
                   ("BITPIX", 32, "",
                    "BITPIX  =                   32                                                  "),
                   ("NAXIS", 2, "",
                    "NAXIS   =                    2                                                  "),
                   ("NAXIS1", 3, "",
                    "NAXIS1  =                    3                                                  "),
                   ("NAXIS2", 3, "",
                    "NAXIS2  =                    3                                                  "),
                   ("BZERO", 1.0f0, "",
                    "BZERO   =                  1.0                                                  "),
                   ("BSCALE", 0.1f0, "",
                    "BSCALE  =                  0.1                                                  ")])

    @test (ndims(hdu.data) == 2 && size(hdu.data) == (3, 3) && length(hdu.data) == 9 &&
           eltype(hdu.data) == Float32 && all(hdu.data .== 1.1f0))

    #  test Image type with scale == false
    data = ones(Int32, (3,3))
    cards = [Card("XTENSION", "IMAGE"),
             Card("BITPIX", 32),
             Card("NAXIS", 2),
             Card("NAXIS1", 3),
             Card("NAXIS2", 3),
             Card("BZERO", 1.0),
             Card("BSCALE", 0.1)]
    seek(io, 0)
    write(io, HDU(data, cards))
    seek(io, 0)
    hdu = read(io, HDU; scale=false)


    @test isequal(showfields.(hdu.cards),
                  [("XTENSION", "IMAGE", "",
                    "XTENSION= 'IMAGE   '                                                            "),
                   ("BITPIX", 32, "",
                    "BITPIX  =                   32                                                  "),
                   ("NAXIS", 2, "",
                    "NAXIS   =                    2                                                  "),
                   ("NAXIS1", 3, "",
                    "NAXIS1  =                    3                                                  "),
                   ("NAXIS2", 3, "",
                    "NAXIS2  =                    3                                                  "),
                   ("BZERO", 1.0f0, "",
                    "BZERO   =                  1.0                                                  "),
                   ("BSCALE", 0.1f0, "",
                    "BSCALE  =                  0.1                                                  ")])

    @test (ndims(hdu.data) == 2 && size(hdu.data) == (3, 3) && length(hdu.data) == 9 &&
           eltype(hdu.data) == Int32 && all(hdu.data .== 1))

    #  test Image type with lazy array
    data = ones(Int32, (3,3))
    cards = [Card("XTENSION", "IMAGE"),
             Card("BITPIX", 32),
             Card("NAXIS", 2),
             Card("NAXIS1", 3),
             Card("NAXIS2", 3),
             Card("BZERO", 1.0),
             Card("BSCALE", 0.1)]

    temppath = joinpath(tempdir(), "image_hdu.fits")
    fileio = open(temppath, "w+")
    write(fileio, HDU(data, cards))
    close(fileio)
    fileio = open(temppath)
    hdu = read(fileio, HDU; type=Image)
    close(fileio)

    @test isequal(showfields.(hdu.cards),
                  [("XTENSION", "IMAGE", "",
                    "XTENSION= 'IMAGE   '                                                            "),
                   ("BITPIX", 32, "",
                    "BITPIX  =                   32                                                  "),
                   ("NAXIS", 2, "",
                    "NAXIS   =                    2                                                  "),
                   ("NAXIS1", 3, "",
                    "NAXIS1  =                    3                                                  "),
                   ("NAXIS2", 3, "",
                    "NAXIS2  =                    3                                                  "),
                   ("BZERO", 1.0f0, "",
                    "BZERO   =                  1.0                                                  "),
                   ("BSCALE", 0.1f0, "",
                    "BSCALE  =                  0.1                                                  ")])

    @test (ndims(hdu.data) == 2 && size(hdu.data) == (3, 3) && length(hdu.data) == 9 &&
           eltype(hdu.data) == Float32 && all(hdu.data .== 1.1f0))
    @test getfield(hdu, :data) isa FITSFiles.LazyArray
    @test getfield(hdu, :data) isa AbstractArray
    @test hdu.data[1, 1] == 1.1f0
    @test hdu.data[1:2, 2] == fill(1.1f0, 2)
    @test read(hdu.data) == fill(1.1f0, 3, 3)

    rm(temppath)

    #  lazy and eager images agree on BLANK pixels and element types, and a lazy image is read
    #  after the working directory changes
    dir = mktempdir()
    blank = joinpath(dir, "blank.fits")
    write(blank, HDU[HDU(Primary, Int16[1 -1; 3 4], Card[Card("BLANK", -1)])])
    lazy, eager = fits(blank)[1].data, fits(blank; lazy=false)[1].data
    @test eltype(lazy) == eltype(eager) == Union{Missing, Int16}
    @test ismissing(lazy[1, 2]) && isequal(collect(lazy), eager)
    plain = joinpath(dir, "plain.fits")
    write(plain, HDU[HDU(Primary, Int16[1 2; 3 4])])
    @test eltype(fits(plain)[1].data) == eltype(fits(plain; lazy=false)[1].data) == Int16
    lazy = fits(plain)[1].data
    @test cd(() -> read(lazy), mktempdir()) == Int16[1 2; 3 4]

end

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

    rm(temppath)

    #  a UInt32 image is Int32 with BZERO = 2^31: scaling must not round to Float32
    uint = Int32[-2147483602, -2147483520]
    hdu = HDU(uint, [Card("XTENSION", "IMAGE"), Card("BITPIX", 32), Card("NAXIS", 1),
                     Card("NAXIS1", 2), Card("BZERO", 2147483648)])
    uint_io = IOBuffer()
    write(uint_io, hdu)
    seekstart(uint_io)
    @test read(uint_io, HDU; scale=true).data == [46.0, 128.0]

    #  scaled computes zero + scale*data in at least double precision, rounded to the promoted type
    ints = Int32.(round.(range(-2.0^31, 2.0^31 - 1, length = 20001)))
    for (scale, zero) in ((1.0f0, 2147483648.0f0), (1.0f0, 2147483648.0), (0.1f0, 0.5f0), (1.0e-3, 1.0e5),
                          (2.5, -1.0f0), (1.0f0, 0.0f0))
        T = promote_type(typeof(scale), typeof(zero), Int32)
        expected = [T(BigFloat(zero) + BigFloat(scale)*BigFloat(x)) for x in ints]
        @test FITSFiles.scaled(ints, scale, zero) == expected
        @test eltype(FITSFiles.scaled(ints, scale, zero)) == T
    end
    #  the types of the data, the scale, and the zero
    @test eltype(FITSFiles.scaled(Int16[1, 2], 0.5f0, 3.0f0)) == Float32
    @test eltype(FITSFiles.scaled(UInt8[1, 2], 0.5f0, 3.0)) == Float64
    @test eltype(FITSFiles.scaled(Int64[1, 2], 1.0, 0.0)) == Float64
    @test FITSFiles.scaled(UInt8[1, 2], 2.0f0, 1.0f0) == Float32[3, 5]
    @test FITSFiles.scaled(reshape(Int16[1, 2, 3, 4], 2, 2), 2.0f0, 0.5f0) == Float32[2.5 6.5; 4.5 8.5]
    @test FITSFiles.scaled(5, 2.0f0, 1.0f0) === 11.0f0
    @test FITSFiles.scaled(Int32[], 2.0f0, 1.0f0) == Float32[]
    #  a stored integer that does not fit in a Float32 is not rounded to 24 bits before the scale
    @test FITSFiles.scaled(Int32[2147483647], 1.0f0, 2147483648.0) == [4294967295.0]
    @test FITSFiles.scaled(Int32[-2147483602], 1.0f0, 2147483648.0f0) == Float32[46]

end

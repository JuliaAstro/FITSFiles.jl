@testset "Image HDU" begin

    #  test Image (specific HDU) type
    hdu = HDU(Image)
    @test isequal(showfields.(hdu.cards),
                  [("XTENSION", "IMAGE   ", "",
                    "XTENSION= 'IMAGE   '                                                            "),
                   ("BITPIX", 32, "",
                    "BITPIX  =                   32                                                  "),
                   ("NAXIS", 0, "",
                    "NAXIS   =                    0                                                  "),
                   ("PCOUNT", 0, "",
                    "PCOUNT  =                    0                                                  "),
                   ("GCOUNT", 1, "",
                    "GCOUNT  =                    1                                                  ")])

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
                    "NAXIS2  =                    3                                                  "),
                   ("PCOUNT", 0, "",
                    "PCOUNT  =                    0                                                  "),
                   ("GCOUNT", 1, "",
                    "GCOUNT  =                    1                                                  ")])

    @test (ndims(hdu.data) == 2 && size(hdu.data) == (3, 3) && length(hdu.data) == 9 &&
           eltype(hdu.data) == Int32)

    #  test Image type with cards
    cards = [Card("XTENSION", "IMAGE"),
             Card("BITPIX", 32),
             Card("NAXIS", 2),
             Card("NAXIS1", 3),
             Card("NAXIS2", 3)]
    #  the header has no PCOUNT or GCOUNT, which the IMAGE header made from it has
    hdu = @test_logs (:warn, r"PCOUNT is missing") (:warn, r"GCOUNT is missing") HDU(cards)

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
                    "NAXIS2  =                    3                                                  "),
                   ("PCOUNT", 0, "",
                    "PCOUNT  =                    0                                                  "),
                   ("GCOUNT", 1, "",
                    "GCOUNT  =                    1                                                  ")])

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
                    "NAXIS2  =                    3                                                  "),
                   ("PCOUNT", 0, "",
                    "PCOUNT  =                    0                                                  "),
                   ("GCOUNT", 1, "",
                    "GCOUNT  =                    1                                                  ")])

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
                    "NAXIS2  =                    3                                                  "),
                   ("PCOUNT", 0, "",
                    "PCOUNT  =                    0                                                  "),
                   ("GCOUNT", 1, "",
                    "GCOUNT  =                    1                                                  ")])

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
                   ("PCOUNT", 0, "",
                    "PCOUNT  =                    0                                                  "),
                   ("GCOUNT", 1, "",
                    "GCOUNT  =                    1                                                  "),
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
                   ("PCOUNT", 0, "",
                    "PCOUNT  =                    0                                                  "),
                   ("GCOUNT", 1, "",
                    "GCOUNT  =                    1                                                  "),
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
                   ("PCOUNT", 0, "",
                    "PCOUNT  =                    0                                                  "),
                   ("GCOUNT", 1, "",
                    "GCOUNT  =                    1                                                  "),
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

    ####    Test the header of an IMAGE extension (Sects. 4.4 and 7.1.1)    ####

    @testset "Image header" begin
        #  a card of a keyword and a fixed-format value, and the bytes of a file of a header of the cards and the
        #  data, which is padded to the 2880 bytes of a block
        kw(key, value) = rpad(key, 8) * "= " * lpad(value, 20)
        function filebytes(cards, data = UInt8[])
            nfill = 2880*cld(length(data), 2880) - length(data)
            rpad(join(rpad.(vcat(cards, ["END"]), 80)), 2880) * String(vcat(data, zeros(UInt8, nfill)))
        end
        reading(bytes; kwds...) = read(IOBuffer(bytes), HDU; scale = false, kwds...)
        written(hdu) = (buffer = IOBuffer(); write(buffer, hdu); take!(buffer))

        xtension, bitpix, naxis, naxis1 = "XTENSION= 'IMAGE   '", kw("BITPIX", 16), kw("NAXIS", 1), kw("NAXIS1", 3)
        pcount, gcount = kw("PCOUNT", 0), kw("GCOUNT", 1)
        header = [xtension, bitpix, naxis, naxis1, pcount, gcount]
        data = UInt8[0, 1, 0, 2, 0, 3]
        silent(cards, bytes = data) = @test_logs reading(filebytes(cards, bytes))
        warned(cards, message, bytes = data) = @test_logs (:warn, message) reading(filebytes(cards, bytes))

        #  a header that conforms is read and written as it is, without a warning
        bytes = filebytes(header, data)
        hdu = @test_logs reading(bytes)
        @test hdu isa HDU{Image} && hdu.data == Int16[1, 2, 3]
        @test @test_logs(written(hdu)) == codeunits(bytes)
        silent([header; kw("INHERIT", "T"); "OBJECT  = 'NGC 1275'"])

        ####    The header of an HDU that is created has PCOUNT of 0 and GCOUNT of 1 (Sect. 7.1.1)

        for data in (Int16[1 2 3; 4 5 6], Float32[1.5 2.5], UInt16[0 40000], UInt8[1 2 3])
            hdu = HDU(Image, data)
            keys = [c.key for c in hdu.cards]
            N = hdu.cards["NAXIS"]
            @test keys[1:3] == ["XTENSION", "BITPIX", "NAXIS"] && keys[(4+N):(5+N)] == ["PCOUNT", "GCOUNT"]
            @test hdu.cards["PCOUNT"] == 0 && hdu.cards["GCOUNT"] == 1
            #  the header of the HDU that is created conforms
            again = @test_logs read(IOBuffer(written(hdu)), HDU)
            @test again isa HDU{Image} && again.data == data
        end
        #  the header of an HDU that is created without data has them too, and a header of cards that have them keeps them
        hdu = HDU(Image)
        @test [c.key for c in hdu.cards] == ["XTENSION", "BITPIX", "NAXIS", "PCOUNT", "GCOUNT"]
        hdu = @test_logs (:warn, r"PCOUNT is missing") (:warn, r"GCOUNT is missing") HDU(
            Card{<:Any}[Card("XTENSION", "IMAGE"), Card("BITPIX", 16), Card("NAXIS", 0)])
        @test [c.key for c in hdu.cards] == ["XTENSION", "BITPIX", "NAXIS", "PCOUNT", "GCOUNT"]
        hdu = HDU(Image, Int16[1 2], Card{<:Any}[Card("EXTNAME", "SCI"), Card("PCOUNT", 0), Card("GCOUNT", 1)])
        @test [c.key for c in hdu.cards] == ["XTENSION", "BITPIX", "NAXIS", "NAXIS1", "NAXIS2", "PCOUNT", "GCOUNT", "EXTNAME"]

        ####    BITPIX and NAXIS are required, and PCOUNT and GCOUNT have values that are known (Sect. 7.1.1)

        for (cards, key) in (([xtension, naxis, naxis1, pcount, gcount], "BITPIX"),
            ([xtension, bitpix, naxis1, pcount, gcount], "NAXIS"), ([xtension, pcount, gcount], "BITPIX"))
            @test_throws ArgumentError("$key is missing, but it is a mandatory keyword of an IMAGE extension (Sect. 7.1.1).") reading(
                filebytes(cards, data))
        end
        warned([xtension, bitpix, naxis, naxis1, gcount], r"PCOUNT is missing, but it is a mandatory keyword of an IMAGE extension \(Sect. 7.1.1\), and has the value 0")
        warned([xtension, bitpix, naxis, naxis1, pcount], r"GCOUNT is missing, but it is a mandatory keyword of an IMAGE extension \(Sect. 7.1.1\), and has the value 1")
        #  a header that is missing the two has the values and the order of the keywords that it has
        hdu = @test_logs (:warn, r"PCOUNT is missing") (:warn, r"GCOUNT is missing") reading(filebytes([xtension, bitpix, naxis, naxis1], data))
        @test hdu.data == Int16[1, 2, 3]

        ####    The order of the mandatory keywords (Sects. 4.4.1.2 and 7.1.1)

        for (cards, j, key, required) in (
            ([bitpix, xtension, naxis, naxis1, pcount, gcount], 1, "BITPIX", "XTENSION"),
            ([xtension, naxis, bitpix, naxis1, pcount, gcount], 2, "NAXIS", "BITPIX"),
            ([xtension, bitpix, naxis1, naxis, pcount, gcount], 3, "NAXIS1", "NAXIS"),
            ([xtension, bitpix, naxis, naxis1, gcount, pcount], 5, "GCOUNT", "PCOUNT"),
            ([xtension, bitpix, naxis, "DATE    = '2020-01-01'", naxis1, pcount, gcount], 4, "DATE", "NAXIS1"),
            ([xtension, bitpix, naxis, naxis1, "DATE    = '2020-01-01'", pcount, gcount], 5, "DATE", "PCOUNT"),
            ([xtension, bitpix, naxis, naxis1, pcount, "", gcount], 6, "a blank card", "GCOUNT"))
            #  one warning, and the file is read and written as it is
            bytes = filebytes(cards, data)
            message = Regex("Keyword $j of the header is $key, but the Standard requires $required \\(Sects. 4.4.1.2 and 7.1.1\\)")
            hdu = @test_logs (:warn, message) reading(bytes)
            @test hdu isa HDU{Image} && hdu.data == Int16[1, 2, 3]
            @test @test_logs((:warn, message), written(hdu)) == codeunits(bytes)
        end
        #  the keywords after GCOUNT are in any order
        silent([header; "OBJECT  = 'NGC 1275'"; kw("BSCALE", 2.0); "BUNIT   = 'adu'"])
        #  and the keywords of an array that has no axes, or a zero axis, are the keywords that it has
        silent([xtension, bitpix, kw("NAXIS", 0), pcount, gcount], UInt8[])
        silent([xtension, bitpix, kw("NAXIS", 2), kw("NAXIS1", 3), kw("NAXIS2", 0), pcount, gcount], UInt8[])

        ####    The fixed format of the mandatory keywords (Sect. 4.4)

        for (cards, keys) in (
            (["XTENSION=  'IMAGE   '", bitpix, naxis, naxis1, pcount, gcount], "XTENSION"),
            ([xtension, "BITPIX  = 16", naxis, naxis1, pcount, gcount], "BITPIX"),
            ([xtension, bitpix, naxis, naxis1, "PCOUNT  = 0", "GCOUNT  = 1"], "PCOUNT, GCOUNT"),
            ([xtension, "BITPIX  = 16", "NAXIS   = 1", "NAXIS1  = 3", "PCOUNT  = 0 / none", "GCOUNT  = 1"],
                "BITPIX, NAXIS, NAXIS1, PCOUNT, GCOUNT"))
            bytes = filebytes(cards, data)
            message = Regex("The value of $keys is not in fixed format \\(Sect. 4.4.1\\)")
            hdu = @test_logs (:warn, message) reading(bytes)
            @test hdu isa HDU{Image} && hdu.data == Int16[1, 2, 3]
            @test @test_logs((:warn, message), written(hdu)) == codeunits(bytes)
        end
        #  the other keywords can be in free format
        silent([header; "BZERO   = 1.0"; "OBJECT  = 'NGC 1275'"])

        ####    The keywords of the primary header, SIMPLE, EXTEND, and BLOCKED, are not in an extension (Sects. 4.4.1.1,
        ####    4.4.2.1, and 7.1.2)

        warned([header; kw("SIMPLE", "T")], r"SIMPLE must not appear in an extension header \(Sect. 4.4.1.1\)")
        for key in ("EXTEND", "BLOCKED")
            warned([header; kw(key, "T")], Regex("$key must not appear in an IMAGE extension header \\(Sects. 4.4.2.1 and 7.1.2\\)"))
        end

        ####    INHERIT is a logical immediately after the mandatory keywords (Sect. 4.4.2.6 and Appendix K)

        silent([header; kw("INHERIT", "T")])
        silent([header; kw("INHERIT", "F"); "OBJECT  = 'NGC 1275'"])
        warned([header; "OBJECT  = 'NGC 1275'"; kw("INHERIT", "T")],
            r"INHERIT must be the keyword immediately after the mandatory keywords, keyword 7 of this header \(Sect. 4.4.2.6 and Appendix K\), but it is keyword 8")
        @test_logs (:warn, r"Keyword 5 of the header is INHERIT, but the Standard requires PCOUNT") (:warn,
            r"INHERIT must be the keyword immediately after the mandatory keywords") reading(
            filebytes([xtension, bitpix, naxis, naxis1, kw("INHERIT", "T"), pcount, gcount], data))
        warned([header; kw("INHERIT", 1)], r"INHERIT must be a logical, T or F, but its value is 1")
        warned([header; kw("INHERIT", "'T'")], r"INHERIT must be a logical, T or F")
        ####    The level of an extension is 1 or more (Sect. 4.4.2.6)

        silent([header; kw("EXTLEVEL", 2); kw("EXTVER", 5); "EXTNAME = 'SCI'"])
        for level in (0, -1)
            warned([header; kw("EXTLEVEL", level)], Regex("EXTLEVEL must be 1 or more, with 1 the highest level \\(Sect. 4.4.2.6\\), but its value is $level"))
        end
        #  without PCOUNT and GCOUNT, it is after the keywords that are there
        @test_logs (:warn, r"PCOUNT is missing") (:warn, r"GCOUNT is missing") reading(
            filebytes([xtension, bitpix, naxis, naxis1, kw("INHERIT", "T")], data))
    end

end

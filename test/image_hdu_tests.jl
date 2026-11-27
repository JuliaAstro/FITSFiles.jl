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
                   ("BSCALE", 0.1, "",
                    "BSCALE  =                  0.1                                                  ")])

    @test (ndims(hdu.data) == 2 && size(hdu.data) == (3, 3) && length(hdu.data) == 9 &&
           eltype(hdu.data) == Float64 && all(hdu.data .== 1.1))

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
                   ("BSCALE", 0.1, "",
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
                   ("BSCALE", 0.1, "",
                    "BSCALE  =                  0.1                                                  ")])

    @test (ndims(hdu.data) == 2 && size(hdu.data) == (3, 3) && length(hdu.data) == 9 &&
           eltype(hdu.data) == Float64 && all(hdu.data .== 1.1))

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

    ####    Test the array of an IMAGE extension (Sects. 4.4.2.5 and 7.1.3)    ####

    @testset "Image array" begin
        kw(key, value) = rpad(key, 8) * "= " * lpad(value, 20)
        function filebytes(cards, data = UInt8[]; pad = true)
            nfill = pad ? 2880*cld(length(data), 2880) - length(data) : 0
            rpad(join(rpad.(vcat(cards, ["END"]), 80)), 2880) * String(vcat(data, zeros(UInt8, nfill)))
        end
        bytesof(values) = collect(reinterpret(UInt8, hton.(values)))
        #  an HDU that is read, which has the data scaled unless scale is false, and the bytes of an HDU that is written
        reading(bytes; kwds...) = read(IOBuffer(bytes), HDU; kwds...)
        written(hdu; kwds...) = (buffer = IOBuffer(); write(buffer, hdu; kwds...); take!(buffer))
        #  the cards of the header of an IMAGE extension of an array of one axis, and the cards that follow them
        header(bitpix = 16, n = 3, extra...) = ["XTENSION= 'IMAGE   '", kw("BITPIX", bitpix), kw("NAXIS", 1), kw("NAXIS1", n),
            kw("PCOUNT", 0), kw("GCOUNT", 1), extra...]
        stored = bytesof(Int16[-5, 0, 300])

        ####    The types of Table 11: an offset in BZERO is the type of the physical values

        offsets = (
            (16, Int16, UInt16, 2^15, Int16[-2^15, 0, 2^15-1], UInt16[0, 2^15, 2^16-1]),
            (32, Int32, UInt32, 2^31, Int32[-2^31, 0, 2^31-1], UInt32[0, 2^31, 2^32-1]),
            (64, Int64, UInt64, UInt64(2)^63, Int64[typemin(Int64), 0, typemax(Int64)], UInt64[0, UInt64(2)^63, typemax(UInt64)]),
            (8, UInt8, Int8, -128, UInt8[0, 128, 255], Int8[-128, 0, 127]))
        for (bits, type, physical, offset, values, expected) in offsets
            bytes = filebytes(header(bits, 3, kw("BZERO", offset)), bytesof(values))
            hdu = @test_logs reading(bytes)
            @test hdu isa HDU{Image} && eltype(hdu.data) === physical && hdu.data == expected
            hdu = reading(bytes; scale = false)
            @test eltype(hdu.data) === type && hdu.data == values
            #  an HDU that is read is written with the same bytes, as the stored values
            @test @test_logs(written(reading(bytes))) == codeunits(bytes)
            @test @test_logs(written(reading(bytes; scale = false))) == codeunits(bytes)
            #  an array of the physical type has the offset, and is stored as the values
            hdu = HDU(Image, expected)
            @test eltype(hdu.data) === physical && hdu.cards["BITPIX"] == bits && hdu.cards["BZERO"] == offset
            @test count(c -> c.key == "BZERO", hdu.cards) == 1
            file = @test_logs written(hdu)
            @test file[2881:2880+sizeof(values)] == bytesof(values)
            again = @test_logs reading(file)
            @test eltype(again.data) === physical && again.data == expected
            #  a scale that is not 1 is not the offset convention, and the values are floating-point
            hdu = reading(filebytes(header(bits, 3, kw("BZERO", offset), kw("BSCALE", 2.0)), bytesof(values)))
            @test eltype(hdu.data) <: AbstractFloat && hdu.data == 2 .* BigFloat.(values) .+ BigFloat(offset)
        end
        #  a floating-point BZERO of the offset is the convention, and another offset or no offset is not
        @test eltype(reading(filebytes(header(16, 3, "BZERO   = 32768.0"), stored)).data) === UInt16
        @test eltype(reading(filebytes(header(16, 3, kw("BZERO", 100)), stored)).data) <: AbstractFloat
        #  the data of a BSCALE of 1 and a BZERO of 0 are the stored values
        @test eltype(reading(filebytes(header(16, 3), stored)).data) === Int16
        #  the undefined values of the stored values are undefined in the physical values
        bytes = filebytes(header(16, 3, kw("BZERO", 32768), kw("BLANK", -32768)), bytesof(Int16[-32768, 0, 32767]))
        hdu = reading(bytes)
        @test isequal(hdu.data, [missing, 32768, 65535]) && nonmissingtype(eltype(hdu.data)) === UInt16
        @test @test_logs(written(hdu)) == codeunits(bytes)
        #  an array of integers is not given an offset
        @test !haskey(HDU(Image, Int16[1, 2]).cards, "BZERO") && !haskey(HDU(Image, UInt8[1, 2]).cards, "BZERO")

        ####    BLANK, BSCALE, BZERO, DATAMIN, DATAMAX, and BUNIT (Sect. 4.4.2.5)

        warned(cards, message, bytes = stored) = @test_logs (:warn, message) reading(filebytes(cards, bytes))
        silent(cards, bytes = stored) = @test_logs reading(filebytes(cards, bytes))
        #  BLANK is for integer data
        floats = bytesof(Float32[1, 2, 3])
        warned(header(-32, 3, kw("BLANK", -1)), r"BLANK is for integer data", floats)
        silent(header(-32, 3), floats)
        for key in ("BSCALE", "BZERO", "DATAMIN", "DATAMAX"), (value, shown) in (("'two'", "\"two\""), ("T", "true"))
            @test_throws ArgumentError("$key must be a number, but its value is $shown.") reading(
                filebytes(header(16, 3, "$(rpad(key, 8))= $value"), stored))
        end
        @test_throws ArgumentError("BLANK must be an integer, but its value is 2.5f0.") reading(filebytes(header(16, 3, kw("BLANK", 2.5)), stored))
        silent(header(16, 3, "BSCALE  = 2", "BZERO   = 1.5", "DATAMIN =                  0.5", "DATAMAX = 3.0"))
        for key in ("DATAMIN", "DATAMAX")
            warned(header(16, 3, kw(key, 3)), Regex("$key must be a floating-point number, but its value is the integer 3"))
        end
        #  BUNIT is a units string
        for unit in ("adu", "km/s", "Jy/beam", "")
            silent(header(16, 3, "BUNIT   = '$unit'"))
        end
        warned(header(16, 3, "BUNIT   = 'not a unit'"), r"BUNIT must be a units string \(Sect. 4.3\)")
        warned(header(16, 3, kw("BUNIT", 7)), r"BUNIT must be a character string, but its value is 7")
        #  and the dates and the descriptive keywords are checked in an extension
        silent(header(16, 3, "DATE    = '2020-01-31'", "DATE-OBS= '2020-01-31T12:30:00'", "ORIGIN  = 'a name'", "EXTNAME = 'SCI'"))
        warned(header(16, 3, "DATE    = '2020-02-30'"), r"DATE must be a date of the form YYYY-MM-DD")
        warned(header(16, 3, kw("OBJECT", 7)), r"OBJECT must be a character string, but its value is 7")

        ####    The scaled data are written as the stored values (Eq. 3 of the standard)

        cases = (
            "default" => (filebytes(header(), stored), Int16),
            "BSCALE and BZERO" => (filebytes(header(16, 3, kw("BSCALE", 2.5), kw("BZERO", 10)), stored), Float32),
            "BSCALE" => (filebytes(header(16, 3, kw("BSCALE", 0.5)), stored), Float32),
            "BZERO" => (filebytes(header(16, 3, kw("BZERO", -7)), stored), Float32),
            "BLANK" => (filebytes(header(16, 3, kw("BSCALE", 2.5), kw("BLANK", -32768)), bytesof(Int16[-5, -32768, 300])), Float32),
            "offset of Table 11" => (filebytes(header(16, 3, kw("BZERO", 32768)), stored), UInt16),
            "32 bits" => (filebytes(header(32, 3, kw("BSCALE", 0.5), kw("BZERO", 10)), bytesof(Int32[-5, 0, 3000])), Float64),
            "bytes" => (filebytes(header(8, 3, kw("BSCALE", 2.0), kw("BZERO", -3)), UInt8[0, 7, 255]), Float32),
            "floating-point" => (filebytes(header(-32), bytesof(Float32[1.5, NaN, -3])), Float32),
            "double precision" => (filebytes(header(-64), bytesof(Float64[1.5, Inf, -3])), Float64))
        for (name, (bytes, type)) in cases
            hdu = reading(bytes)
            @test hdu isa HDU{Image} && nonmissingtype(eltype(hdu.data)) === type
            @test @test_logs(written(hdu)) == codeunits(bytes)
        end

        ####    The data of a BSCALE of 1 and a BZERO of 0 are the stored integers, which are exact (Eq. 3 of the standard)

        for (bitpix, values) in ((16, Int16[32767, -32768, 1]), (32, Int32[16777217, 2147483647, -2147483648]),
                                 (64, Int64[2^40 + 1, 2^62 + 1, typemin(Int64)]))
            bytes = filebytes(header(bitpix, 3), bytesof(values))
            hdu = reading(bytes)
            @test hdu.data == values && eltype(hdu.data) === eltype(values)
            @test written(hdu) == codeunits(bytes)
            #  the defaults of the header are the same as no keywords
            same = reading(filebytes(header(bitpix, 3, kw("BSCALE", 1.0), kw("BZERO", 0.0)), bytesof(values)))
            @test same.data == values && eltype(same.data) === eltype(values)
        end
        @test eltype(reading(filebytes(header(8, 3), UInt8[0, 7, 255])).data) === UInt8
        #  the scaled values of 32- and 64-bit integers are at least Float64, since a Float32 holds integers to 2^24 only
        for (bitpix, values) in ((32, Int32[16777217, -5, 3]), (64, Int64[2^40 + 1, -5, 3]))
            hdu = reading(filebytes(header(bitpix, 3, kw("BSCALE", 0.5f0), kw("BZERO", 1.0f0)), bytesof(values)))
            @test eltype(hdu.data) === Float64 && hdu.data == 1.0 .+ 0.5 .* Float64.(values)
        end
        #  and those of 8- and 16-bit integers are Float32 for a Float32 scale
        @test eltype(reading(filebytes(header(16, 3, kw("BSCALE", 0.5f0)), bytesof(Int16[1, 2, 3]))).data) === Float32

        ####    An array with an axis of length 0 has no data blocks, and the data are an empty array of the axes (Sect. 7.1.1)

        for (bitpix, shape, type) in ((16, (3, 0), Int16), (-32, (0, 3), Float32), (8, (0, 2, 2), UInt8), (64, (0,), Int64))
            hdr = ["XTENSION= 'IMAGE   '", kw("BITPIX", bitpix), kw("NAXIS", length(shape)),
                [kw("NAXIS$j", n) for (j, n) in enumerate(shape)]..., kw("PCOUNT", 0), kw("GCOUNT", 1)]
            bytes = filebytes(hdr, UInt8[])
            hdu = reading(bytes)
            @test hdu isa HDU{Image} && hdu.data isa Array{type, length(shape)} && size(hdu.data) == shape
            @test written(hdu) == codeunits(bytes)
            made = HDU(Image, zeros(type, shape))
            @test size(made.data) == shape && size(reading(written(made)).data) == shape
        end
        ####    Data of a type that BITPIX does not have are an error that says which types it has (Table 8)

        for data in (Float16[1 2; 3 4], [true false], ComplexF32[1 2; 3 4], ['a' 'b'], BigFloat[1 2])
            for type in (Image, Primary)
                err = try HDU(type, data) catch e e end
                @test err isa ArgumentError && occursin("element type $(eltype(data))", err.msg) &&
                    occursin("Table 8", err.msg) && occursin("Float64", err.msg) && occursin("UInt16", err.msg)
            end
        end
        #  an array has at most 999 axes, which is an error when the HDU is created
        @test HDU(Image, Array{Int8}(undef, ntuple(_ -> 1, 20))).cards["NAXIS"] == 20
        err = try HDU(Image, Array{Int8}(undef, ntuple(_ -> 1, FITSFiles.MAXAXES + 1))) catch e e end
        @test err isa ArgumentError && occursin("1000 axes", err.msg) && occursin("0 to 999 axes", err.msg)
        #  the types of BITPIX and the physical types of Table 11 are not
        for type in (UInt8, Int8, Int16, UInt16, Int32, UInt32, Int64, UInt64, Float32, Float64)
            @test HDU(Image, type[1 2; 3 4]).data == type[1 2; 3 4]
        end
        #  an array that has no axes has no data
        noaxes = ["XTENSION= 'IMAGE   '", kw("BITPIX", 16), kw("NAXIS", 0), kw("PCOUNT", 0), kw("GCOUNT", 1)]
        @test ismissing(reading(filebytes(noaxes, UInt8[])).data)
        bytes = filebytes(header(16, 3, kw("BSCALE", 2.5), kw("BZERO", 10)), stored)
        hdu = reading(bytes)
        @test hdu.data == Float32[-2.5, 10, 760]
        #  the data that are changed are the stored values, if applying BSCALE and BZERO to them gives the data again
        hdu.data .= Float32[10, 12.5, -10]
        @test reading(written(hdu); scale = false).data == Int16[0, 1, -8]
        hdu.data .= Float32[11.2, 11.3, -10.0]
        @test_throws ArgumentError("The value 11.2 cannot be stored as Int16 data with BSCALE 2.5 and BZERO 10.0: the " *
            "nearest stored value, 0, is the value 10.0. Use check = false to write the stored value.") written(hdu)
        @test reading(written(hdu; check = false); scale = false).data == Int16[0, 1, -8]
        #  NaN is undefined if the data have a BLANK, a value is in the range of the type, and BSCALE is not 0
        hdu = reading(filebytes(header(16, 3, kw("BSCALE", 2.5), kw("BLANK", -32768)), bytesof(Int16[-5, -32768, 300])))
        @test isequal(hdu.data, Union{Float32, Missing}[-12.5, missing, 750])
        hdu.data[1], hdu.data[3] = NaN32, missing
        @test written(hdu)[2881:2886] == bytesof(Int16[-32768, -32768, -32768])
        hdu = reading(filebytes(header(16, 3, kw("BSCALE", 2.5)), stored))
        hdu.data[2] = NaN32
        @test_throws ArgumentError("NaN cannot be written as integer data that does not have a BLANK keyword.") written(hdu)
        hdu = reading(filebytes(header(16, 3, kw("BSCALE", 2.5), kw("BZERO", 10)), stored))
        hdu.data[2] = 1.0f9
        @test_throws r"The value 1.0e9 is not in the range of the Int16 data" written(hdu)
        @test_throws ArgumentError("The values cannot be written as stored values, since BSCALE is 0.") written(
            reading(filebytes(header(16, 3, kw("BSCALE", 0)), stored)))
        #  an HDU that is created from data has the type of the data, and is not changed
        for data in (Int16[1 2; 3 4], Float32[1.5 2.5; -1 7], UInt16[0 40000; 5 65535], UInt8[1 2; 3 4], Float64[1 2; 3 4])
            @test @test_logs(reading(written(HDU(Image, data)))).data == data
        end

        ####    The floating-point data with a scale are the physical values, which are a ScaledArray with the scale and the zero

        for (bitpix, T) in ((-32, Float32), (-64, Float64))
            floats = filebytes(header(bitpix, 3, kw("BSCALE", 2.0), kw("BZERO", 1.0)), bytesof(T[1, 2, 3]))
            hdu = reading(floats)
            @test hdu.data isa FITSFiles.ScaledArray && hdu.data == T[3, 5, 7] && eltype(hdu.data) == T
            @test hdu.data.scale == 2 && hdu.data.zero == 1
            @test written(hdu) == codeunits(floats)
            hdu.data[3] = 21
            @test reading(written(hdu); scale = false).data == T[1, 2, 10]
            raw = reading(floats; scale = false)
            @test raw.data isa Vector{T} && raw.data == T[1, 2, 3] && written(raw) == codeunits(floats)
            #  the data tell it, so they are the physical values in another HDU, which has the scale and the zero
            fresh = reading(floats)
            @test written(HDU(Image, fresh.data, getfield(fresh, :cards))) == codeunits(floats)
            fromdata = HDU(Image, fresh.data)
            @test fromdata.cards["BSCALE"] == 2 && fromdata.cards["BZERO"] == 1
            @test reading(written(fromdata); scale = false).data == T[1, 2, 3]
            #  an array that is made from them is plain, and the data that are made are the stored values
            @test !(fresh.data .+ 0 isa FITSFiles.ScaledArray) && copy(fresh.data) isa FITSFiles.ScaledArray
            @test !(reading(filebytes(header(bitpix, 3), bytesof(T[1, 2, 3]))).data isa FITSFiles.ScaledArray)
            @test !(reading(filebytes(header(bitpix, 3, kw("BSCALE", 1.0), kw("BZERO", 0.0)), bytesof(T[1, 2, 3]))).data isa
                FITSFiles.ScaledArray)
            @test HDU(Image, T[1, 2, 3], Card{<:Any}[Card("BSCALE", 2.0)]).data isa Vector{T}
            #  the undefined values stay undefined
            nans = filebytes(header(bitpix, 3, kw("BSCALE", 2.0), kw("BZERO", 1.0)), bytesof(T[1, NaN, 3]))
            @test isnan(reading(nans).data[2]) && written(reading(nans)) == codeunits(nans)
        end
        #  a file of HDUs that are read lazily, and are the same
        mktemp() do path, io
            write(io, [HDU(Primary), HDU(Image, FITSFiles.ScaledArray(Float32[3, 5, 7], 2.0f0, 1.0f0))]); close(io)
            file = fits(path)
            @test file[2].data isa FITSFiles.ScaledArray && file[2].data == Float32[3, 5, 7] && file[2].data.scale == 2
            unscaled = fits(path; scale = false)
            @test unscaled[2].data isa Vector{Float32} && unscaled[2].data == Float32[1, 2, 3]
        end

        ####    The size of the data (Eq. 2)

        big = "4611686018427387904"
        @test_throws r"The data array is too large: 2 bytes × 4611686018427387904 values" reading(filebytes(header(16, big), stored))
        @test_throws r"The data array is too large: 8 bytes × 2 × 4611686018427387904 values" reading(filebytes(
            ["XTENSION= 'IMAGE   '", kw("BITPIX", -64), kw("NAXIS", 2), kw("NAXIS1", 2), kw("NAXIS2", big), kw("PCOUNT", 0),
            kw("GCOUNT", 1)], stored))
        #  a file that has fewer bytes than the header says is an error that says so
        @test_throws ArgumentError("The data of the HDU is 20 bytes, as its header says, but the file has only 6 of them.") reading(
            filebytes(header(16, 10), bytesof(Int16[1, 2, 3]); pad = false))
        @test_throws r"as its header says, but the file has only 6 of them" reading(
            filebytes(header(16, 2^61), bytesof(Int16[1, 2, 3]); pad = false))
        #  and the fill of the last block is not required
        hdu = @test_logs reading(filebytes(header(16, 3), bytesof(Int16[1, 2, 3]); pad = false))
        @test hdu.data == [1, 2, 3]
        #  an array of two axes is in the order of the first axis, as is an array of three, and no axes has no data and a zero axis has an empty array
        bytes = filebytes(["XTENSION= 'IMAGE   '", kw("BITPIX", 16), kw("NAXIS", 2), kw("NAXIS1", 2), kw("NAXIS2", 3),
            kw("PCOUNT", 0), kw("GCOUNT", 1)], bytesof(Int16[1, 2, 3, 4, 5, 6]))
        @test reading(bytes).data == [1 3 5; 2 4 6]
        bytes = filebytes(["XTENSION= 'IMAGE   '", kw("BITPIX", 16), kw("NAXIS", 3), kw("NAXIS1", 2), kw("NAXIS2", 1),
            kw("NAXIS3", 2), kw("PCOUNT", 0), kw("GCOUNT", 1)], bytesof(Int16[1, 2, 3, 4]))
        @test size(reading(bytes).data) == (2, 1, 2) && vec(reading(bytes).data) == [1, 2, 3, 4]
        for axes in ([kw("NAXIS", 0)], [kw("NAXIS", 2), kw("NAXIS1", 3), kw("NAXIS2", 0)])
            hdu = @test_logs reading(filebytes(["XTENSION= 'IMAGE   '", kw("BITPIX", 16), axes..., kw("PCOUNT", 0), kw("GCOUNT", 1)]))
            #  no axes have no data, and an axis of length 0 has an empty array
            @test (length(axes) == 1 ? ismissing(hdu.data) : size(hdu.data) == (3, 0)) && @test_logs(written(hdu)) == codeunits(filebytes(
                ["XTENSION= 'IMAGE   '", kw("BITPIX", 16), axes..., kw("PCOUNT", 0), kw("GCOUNT", 1)]))
        end

        ####    The data of the IMAGE extensions of a file are read when they are used

        mktemp() do path, io
            close(io)
            data = (UInt16[0 40000; 5 65535], Float32[1.5 2.5; -1 7], Int16[1 2 3; 4 5 6])
            scaled = HDU(Image, data[3], Card{<:Any}[Card("BSCALE", 2.0), Card("BZERO", 10.0), Card("EXTNAME", "SCI")])
            write(path, [HDU(Primary), HDU(Image, data[1]), HDU(Image, data[2]), scaled])
            file = @test_logs fits(path)
            @test all(h -> getfield(h, :data) isa FITSFiles.LazyArray, file[2:4])
            @test file[2].data == data[1] && eltype(file[2].data) === UInt16
            @test file[3].data == data[2] && eltype(file[3].data) === Float32
            @test file[4].data == 2.0 .* data[3] .+ 10 && eltype(file[4].data) === Float32
            #  and the keywords of the read are the keywords of the lazy read
            file = @test_logs fits(path; scale = false)
            @test eltype(file[2].data) === Int16 && file[2].data == Int16[-32768 7232; -32763 32767]
            @test file[4].data == data[3]
            #  the HDUs are the HDUs of the vector, and the displays work
            @test length(file) == 4 && all(h -> h isa HDU{Image}, file[2:4])
            @test occursin(r"4\s+Image\s+SCI\s+1", sprint(show, MIME("text/plain"), file))
        end
    end

    ####    Test the size of the HDU, which is the NAXISn of its header    ####

    @testset "size" begin
        data = reshape(Float32[1:100;], 5, 20)
        #  the size is the NAXISn of the header, and is the size of the data
        @test size(HDU(Image, data)) == (5, 20) && size(HDU(Image, data)) == size(HDU(Image, data).data)
        @test size(HDU(Image, zeros(Int16, 2, 3, 4))) == (2, 3, 4)
        #  an IMAGE extension that has no data has no dimensions
        @test size(HDU(Image)) == ()
        #  the size of an HDU whose data are not read, which a file has, is known without reading them
        path = joinpath(mktempdir(), "size.fits")
        write(path, [HDU(Primary), HDU(Image, data)])
        lazy = fits(path)[2]
        @test getfield(lazy, :data) isa FITSFiles.LazyArray
        @test size(lazy) == (5, 20) && getfield(lazy, :data) isa FITSFiles.LazyArray
        @test size(fits(path)[1]) == ()
    end

end

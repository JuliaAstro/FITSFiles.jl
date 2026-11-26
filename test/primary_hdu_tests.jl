@testset "Primary HDU" begin

#  test Primary (default HDU) type
    hdu = HDU()
    @test isequal(showfields.(hdu.cards),
                  [("SIMPLE", true, "",
                    "SIMPLE  =                    T                                                  "),
                   ("BITPIX", 32, "",
                    "BITPIX  =                   32                                                  "),
                   ("NAXIS", 0, "",
                    "NAXIS   =                    0                                                  ")])

    @test ismissing(hdu.data)

    #  test Primary (specific HDU) type
    hdu = HDU(Primary)
    @test isequal(showfields.(hdu.cards),
                  [("SIMPLE", true, "",
                    "SIMPLE  =                    T                                                  "),
                   ("BITPIX", 32, "",
                    "BITPIX  =                   32                                                  "),
                   ("NAXIS", 0, "",
                    "NAXIS   =                    0                                                  ")])

    @test ismissing(hdu.data)

    #  test Primary type with data
    data = ones(Int32, (3,3))
    hdu = HDU(data)
    @test isequal(showfields.(hdu.cards),
                  [("SIMPLE", true, "",
                    "SIMPLE  =                    T                                                  "),
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

    #  test Primary type with cards
    cards = [Card("SIMPLE", true),
             Card("BITPIX", 32),
             Card("NAXIS", 2),
             Card("NAXIS1", 3),
             Card("NAXIS2", 3)]
    hdu = HDU(cards)

    @test isequal(showfields.(hdu.cards),
                  [("SIMPLE", true, "",
                    "SIMPLE  =                    T                                                  "),
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

    #  test Primary type with data and cards
    data = ones(Int32, (3,3))
    cards = [Card("SIMPLE", true),
             Card("BITPIX", 32),
             Card("NAXIS", 2),
             Card("NAXIS1", 3),
             Card("NAXIS2", 3)]
    hdu = HDU(data, cards)

    @test isequal(showfields.(hdu.cards),
                  [("SIMPLE", true, "",
                    "SIMPLE  =                    T                                                  "),
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

    #  test Primary type with data and inconsistent cards
    data = ones(Int32, (3,3))
    cards = [Card("SIMPLE", true),
             Card("BITPIX", 16),
             Card("NAXIS", 2),
             Card("NAXIS1", 9),
             Card("NAXIS2", 9)]
    hdu = HDU(data, cards)

    @test isequal(showfields.(hdu.cards),
                  [("SIMPLE", true, "",
                    "SIMPLE  =                    T                                                  "),
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

    #  test Primary type with scale == true
    data = ones(Int32, (3,3))
    cards = [Card("SIMPLE", true),
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
                  [("SIMPLE", true, "",
                    "SIMPLE  =                    T                                                  "),
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

    #  test Primary type with scale == false
    data = ones(Int32, (3,3))
    cards = [Card("SIMPLE", true),
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
                  [("SIMPLE", true, "",
                    "SIMPLE  =                    T                                                  "),
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

    #  test Primary type with LazyArray
    data = ones(Int32, (3,3))
    cards = [Card("SIMPLE", true),
             Card("BITPIX", 32),
             Card("NAXIS", 2),
             Card("NAXIS1", 3),
             Card("NAXIS2", 3),
             Card("BZERO", 1.0),
             Card("BSCALE", 0.1)]

    temppath = joinpath(tempdir(), "primary_hdu.fits")
    fileio = open(temppath, "w+")
    write(fileio, HDU(data, cards))
    close(fileio)
    fileio = open(temppath)
    hdu = read(fileio, HDU; type=Primary)
    close(fileio)

    @test isequal(showfields.(hdu.cards),
                  [("SIMPLE", true, "",
                    "SIMPLE  =                    T                                                  "),
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

    #  a card of a keyword and a fixed-format value, and the bytes of a file of a header of the cards and the
    #  data, which is padded to the 2880 bytes of a block, unless pad is false
    kw(key, value) = rpad(key, 8) * "= " * lpad(value, 20)
    function filebytes(cards, data = UInt8[]; pad = true)
        nfill = pad ? 2880*cld(length(data), 2880) - length(data) : 0
        rpad(join(rpad.(vcat(cards, ["END"]), 80)), 2880) * String(vcat(data, zeros(UInt8, nfill)))
    end
    reading(bytes; kwds...) = read(IOBuffer(bytes), HDU; scale = false, kwds...)
    written(hdu) = (buffer = IOBuffer(); write(buffer, hdu); take!(buffer))

    ####    Test the verification of the header of a primary HDU (Sects. 3.3, 4.4.1, and 4.4.1.1)    ####

    @testset "Primary header" begin
        simple, bitpix, naxis, naxis1 = kw("SIMPLE", "T"), kw("BITPIX", 16), kw("NAXIS", 1), kw("NAXIS1", 3)
        data = UInt8[0, 1, 0, 2, 0, 3]
        header = [simple, bitpix, naxis, naxis1]

        #  a header that conforms is read and written without a warning, as it is, with or without the fill
        for pad in (true, false)
            bytes = filebytes(header, data; pad)
            hdu = @test_logs reading(bytes)
            @test hdu isa HDU{Primary} && hdu.data == [1, 2, 3]
            @test @test_logs(written(hdu)) == codeunits(filebytes(header, data))
        end

        ####    SIMPLE (Sect. 4.4.1.1)

        #  the HDU of a file that does not conform is a Conform HDU, with its data as they are, and it is
        #  written as it is read
        simplef = kw("SIMPLE", "F")
        for cards in ([simplef, bitpix, naxis, naxis1], [simplef, bitpix, naxis, naxis1, kw("BSCALE", "2.0")])
            bytes = filebytes(cards, data)
            hdu = @test_logs (:warn, r"SIMPLE is F, so the file does not conform") reading(bytes)
            @test hdu isa HDU{Conform} && hdu.data == Int16[1, 2, 3]
            @test @test_logs((:warn, r"SIMPLE is F"), written(hdu)) == codeunits(bytes)
        end
        hdu = @test_logs (:warn, r"SIMPLE is F") reading(filebytes(
            [simplef, bitpix, kw("NAXIS", 2), kw("NAXIS1", 2), kw("NAXIS2", 2)], UInt8[0, 1, 0, 2, 0, 3, 0, 4]))
        @test hdu.data == Int16[1 3; 2 4]
        hdu = @test_logs (:warn, r"SIMPLE is F") reading(filebytes([simplef, bitpix, kw("NAXIS", 0)]))
        @test hdu isa HDU{Conform} && ismissing(hdu.data)

        #  but the other mandatory keywords must conform
        @test_throws ArgumentError("BITPIX must be one of 8, 16, 32, 64, -32, or -64, but its value is 12.") reading(
            filebytes([simplef, kw("BITPIX", 12), naxis, naxis1], data))
        @test_throws ArgumentError("NAXIS1 is missing, but NAXIS is 1.") reading(filebytes([simplef, bitpix, naxis], data))

        #  SIMPLE is a logical
        for (value, shown) in (("'T'", "\"T\""), ("1", "1"), ("1.0", "1.0f0"))
            @test_throws ArgumentError("SIMPLE must be a logical, T or F, but its value is $shown.") reading(
                filebytes([kw("SIMPLE", value), bitpix, kw("NAXIS", 0)]))
        end
        mankeys(value) = Dict{AbstractString, FITSFiles.ValueType}("SIMPLE" => value)
        @test FITSFiles.typeofhdu(mankeys(true)) == Primary
        @test FITSFiles.typeofhdu(mankeys(false)) == Conform
        @test_throws ArgumentError("SIMPLE must be a logical, T or F, but its value is missing.") FITSFiles.typeofhdu(
            mankeys(missing))

        ####    The order of the mandatory keywords (Sect. 4.4.1.1)

        for (cards, j, key, required) in (
            ([bitpix, simple, naxis, naxis1], 1, "BITPIX", "SIMPLE"),
            ([simple, naxis, bitpix, naxis1], 2, "NAXIS", "BITPIX"),
            ([simple, bitpix, naxis1, naxis], 3, "NAXIS1", "NAXIS"),
            ([simple, bitpix, naxis, "DATE    = '2020-01-01'", naxis1], 4, "DATE", "NAXIS1"),
            ([simple, "", bitpix, naxis, naxis1], 2, "a blank card", "BITPIX"),
            ([simple, bitpix, kw("NAXIS", 2), kw("NAXIS2", 2), kw("NAXIS1", 3)], 4, "NAXIS2", "NAXIS1"))
            #  one warning, and the file is read and written as it is
            bytes = filebytes(cards, data)
            message = Regex("Keyword $j of the header is $key, but the Standard requires $required")
            hdu = @test_logs (:warn, message) reading(bytes)
            @test hdu isa HDU{Primary}
            @test @test_logs((:warn, message), written(hdu)) == codeunits(bytes)
        end
        #  the extra cards after the mandatory keywords are in any order
        hdu = @test_logs reading(filebytes([header; ["DATE    = '2020-01-01'", "BZERO   =                  1.0"]], data))
        @test hdu.data == Int16[1, 2, 3]
        #  a Conform HDU of a file that does not conform has the same header
        @test_logs (:warn, r"SIMPLE is F") (:warn, r"Keyword 2 of the header is NAXIS, but the Standard requires BITPIX") reading(
            filebytes([simplef, naxis, bitpix, naxis1], data))

        ####    The fixed format of the mandatory keywords (Sect. 4.4.1)

        for (cards, keys) in (
            (["SIMPLE  = T", bitpix, naxis, naxis1], "SIMPLE"),
            ([simple, "BITPIX  = 16", naxis, naxis1], "BITPIX"),
            ([simple, bitpix, "NAXIS   = 1 / one axis", "NAXIS1  = 3"], "NAXIS, NAXIS1"),
            (["SIMPLE  = T", "BITPIX  = 16", "NAXIS   = 1", "NAXIS1  = 3"], "SIMPLE, BITPIX, NAXIS, NAXIS1"))
            bytes = filebytes(cards, data)
            message = Regex("The value of $keys is not in fixed format")
            hdu = @test_logs (:warn, message) reading(bytes)
            @test hdu isa HDU{Primary} && hdu.data == [1, 2, 3]
            @test @test_logs((:warn, message), written(hdu)) == codeunits(bytes)
        end
        #  the other keywords can be in free format
        @test_logs reading(filebytes([header; ["BZERO   = 1.0", "BUNIT   = 'adu'"]], data))
        #  an HDU that is created has the fixed format and the order, and its header is not verified when it is
        #  created without the mandatory keywords
        hdu = HDU(Primary, rand(Float32, 2, 3))
        @test_logs written(hdu)
        @test_logs HDU(Primary)
        @test_logs HDU(Primary, missing, Card{<:Any}[Card("COMMENT", "a comment")])

        ####    The size of the data (Eq. 1)

        #  a size that overflows the integers is an error, and not a size that is not read
        big = "4611686018427387904"
        @test_throws r"The data array is too large: 2 bytes × 4611686018427387904 values" reading(
            filebytes([simple, bitpix, naxis, kw("NAXIS1", big)], data))
        @test_throws r"The data array is too large: 8 bytes × 2 × 4611686018427387904 values" reading(
            filebytes([simple, kw("BITPIX", -64), kw("NAXIS", 2), kw("NAXIS1", 2), kw("NAXIS2", big)], data))
        @test_throws r"too large" reading(filebytes([simplef, bitpix, naxis, kw("NAXIS1", big)], data))
        @test_throws r"too large" reading(filebytes(["XTENSION= 'IMAGE   '", bitpix, naxis, kw("NAXIS1", big),
            kw("PCOUNT", 0), kw("GCOUNT", 1)], data))
        @test @test_logs(reading(filebytes([simple, bitpix, kw("NAXIS", 2), kw("NAXIS1", 0), kw("NAXIS2", big)]))) isa HDU

        #  a file that has fewer bytes than the header says is an error that says so, and does not allocate the bytes
        @test_throws ArgumentError("The data of the HDU is 20 bytes, as its header says, but the file has only 6 of them.") reading(
            filebytes([simple, bitpix, naxis, kw("NAXIS1", 10)], data; pad = false))
        @test_throws ArgumentError("The data of the HDU is 4 bytes, as its header says, but the file has only 2 of them.") reading(
            filebytes([simplef, bitpix, naxis, kw("NAXIS1", 2)], UInt8[0, 1]; pad = false))
        @test_throws r"as its header says, but the file has only 6 of them" reading(
            filebytes([simple, bitpix, naxis, kw("NAXIS1", 2^61)], data; pad = false))
        @test_throws r"as its header says, but the file has only 2880 of them" reading(
            filebytes([simple, bitpix, naxis, kw("NAXIS1", 2^61)], data))
    end

    ####    Test the keywords of the array and of the primary header (Sects. 4.4.2 and 4.4.2.5)    ####

    @testset "Primary keywords" begin
        simple, bitpix, naxis, naxis1 = kw("SIMPLE", "T"), kw("BITPIX", 16), kw("NAXIS", 1), kw("NAXIS1", 3)
        header = [simple, bitpix, naxis, naxis1]
        data = UInt8[0, 1, 0, 2, 0, 3]
        #  an HDU that is read, with the data scaled
        scaledreading(bytes; kwds...) = read(IOBuffer(bytes), HDU; kwds...)
        #  the bytes of the values of an integer type, which are big-endian
        bytesof(values) = collect(reinterpret(UInt8, hton.(values)))
        #  the cards that are added to the header
        warned(cards, message, bytes = data) = @test_logs (:warn, message) reading(filebytes([header; cards], bytes))
        silent(cards, bytes = data) = @test_logs reading(filebytes([header; cards], bytes))

        ####    BLANK is for integer data (Sect. 4.4.2.5)

        floats = [simple, kw("BITPIX", -32), naxis, naxis1]
        bytes = bytesof(Float32[1, 2, 3])
        hdu = @test_logs (:warn, r"BLANK is for integer data") reading(filebytes([floats; kw("BLANK", -1)], bytes))
        @test hdu.data == Float32[1, 2, 3]
        @test_logs reading(filebytes(floats, bytes))

        ####    BSCALE, BZERO, DATAMIN, and DATAMAX are numbers, and DATAMIN and DATAMAX are floating-point

        for key in ("BSCALE", "BZERO", "DATAMIN", "DATAMAX"), (value, shown) in (("'two'", "\"two\""), ("T", "true"))
            @test_throws ArgumentError("$key must be a number, but its value is $shown.") reading(
                filebytes([header; "$(rpad(key, 8))= $value"], data))
        end
        silent(["BSCALE  = 2", "BZERO   = 1.5", "DATAMIN =                  0.5", "DATAMAX = 3.0"])
        for key in ("DATAMIN", "DATAMAX")
            warned([kw(key, 3)], Regex("$key must be a floating-point number, but its value is the integer 3"))
        end

        ####    The types of Table 11: an offset in BZERO is the type of the physical values

        offsets = (
            (16, Int16, UInt16, 2^15, Int16[-2^15, 0, 2^15-1], UInt16[0, 2^15, 2^16-1]),
            (32, Int32, UInt32, 2^31, Int32[-2^31, 0, 2^31-1], UInt32[0, 2^31, 2^32-1]),
            (64, Int64, UInt64, UInt64(2)^63, Int64[typemin(Int64), 0, typemax(Int64)],
                UInt64[0, UInt64(2)^63, typemax(UInt64)]),
            (8, UInt8, Int8, -128, UInt8[0, 128, 255], Int8[-128, 0, 127]))
        for (bits, stored, physical, offset, values, expected) in offsets
            cards = [simple, kw("BITPIX", bits), naxis, naxis1, kw("BZERO", offset)]
            bytes = bytesof(values)
            hdu = @test_logs scaledreading(filebytes(cards, bytes))
            @test eltype(hdu.data) === physical && hdu.data == expected
            #  the stored values, if they are not scaled
            hdu = reading(filebytes(cards, bytes); scale = false)
            @test eltype(hdu.data) === stored && hdu.data == values
            #  an HDU that is read is written with the same bytes, and the data are read again
            hdu = @test_logs scaledreading(filebytes(cards, bytes))
            @test @test_logs(written(hdu)) == codeunits(filebytes(cards, bytes))
            #  an array of the physical type has the offset, and is stored as the values
            for type in (Primary, Image)
                hdu = HDU(type, expected)
                @test eltype(hdu.data) === physical
                @test hdu.cards["BITPIX"] == bits && hdu.cards["BZERO"] == offset
                bytes_ = @test_logs(written(hdu))
                @test bytes_[end-2879:end-2879+sizeof(values)*1-1] == bytes[1:sizeof(values)]
            end
            #  a scale that is not 1 is not the offset convention, and the values are floating-point
            hdu = scaledreading(filebytes([cards; kw("BSCALE", 2.0)], bytes))
            @test eltype(hdu.data) <: AbstractFloat && hdu.data == 2 .* BigFloat.(values) .+ BigFloat(offset)
        end
        #  a floating-point BZERO of the offset is the convention, and another offset is not
        cards = [simple, bitpix, naxis, naxis1]
        @test eltype(scaledreading(filebytes([cards; "BZERO   = 32768.0"], data)).data) === UInt16
        @test eltype(scaledreading(filebytes([cards; kw("BZERO", 100)], data)).data) <: AbstractFloat
        @test eltype(scaledreading(filebytes(cards, data)).data) <: AbstractFloat
        #  the undefined values of the stored values are undefined in the physical values
        hdu = scaledreading(filebytes([cards; kw("BZERO", 32768); kw("BLANK", -32768)], bytesof(Int16[-32768, 0, 32767])))
        @test isequal(hdu.data, [missing, 32768, 65535]) && nonmissingtype(eltype(hdu.data)) === UInt16
        #  an array of integers is not given an offset
        @test !haskey(HDU(Primary, Int16[1, 2]).cards, "BZERO") && !haskey(HDU(Primary, UInt8[1, 2]).cards, "BZERO")
        #  an array of the physical type that has a BZERO is written with it
        hdu = HDU(Primary, UInt16[0, 1], Card{<:Any}[Card("BZERO", 32768, "offset")])
        @test hdu.cards["BZERO"] == 32768 && count(c -> c.key == "BZERO", hdu.cards) == 1

        ####    EXTEND and BLOCKED are logicals, and INHERIT is not in the primary header (Sects. 4.4.2.1 and 4.4.2.6)

        silent(["EXTEND  =                    T", kw("BLOCKED", "T")])
        for key in ("EXTEND", "BLOCKED")
            warned(["$(rpad(key, 8))= 'yes'"], Regex("$key must be a logical, T or F, but its value is \"yes\""))
            warned([kw(key, 1)], Regex("$key must be a logical, T or F, but its value is 1"))
        end
        warned([kw("INHERIT", "T")], r"INHERIT must not appear in the primary header")
        #  an extension may inherit
        extension = ["XTENSION= 'IMAGE   '", bitpix, naxis, naxis1, kw("PCOUNT", 0), kw("GCOUNT", 1)]
        @test_logs reading(filebytes([extension; kw("INHERIT", "T")], data))

        ####    DATE, DATE-OBS, and the other DATExxxx are dates (Sects. 4.4.2.1 and 4.4.2.2)

        for text in ("2020-01-31", "2020-02-29", "2020-01-31T12:30:00", "2020-01-31T12:30:00.123", "2020-12-31T23:59:60",
            "31/01/99", " 2020-01-31 ")
            @test FITSFiles.isdatestring(strip(text))
            silent(["DATE    = '$text'", "DATE-OBS= '$text'", "DATE-END= '$text'"])
        end
        for text in ("2021-02-29", "2020-13-01", "2020-00-10", "2020-01-32", "2020-1-1", "20200131", "2020-01-31T24:00:00",
            "2020-01-31T12:60:00", "2020-01-31 12:30:00", "31/02/99", "31/01/1999", "yesterday", "")
            @test !FITSFiles.isdatestring(text)
            for key in ("DATE", "DATE-OBS", "DATE-END")
                warned(["$(rpad(key, 8))= '$text'"], Regex("$key must be a date of the form YYYY-MM-DD"))
            end
        end
        warned([kw("DATE", 5)], r"DATE must be a date of the form YYYY-MM-DD\[Thh:mm:ss\[.sss\]\] \(Sect. 4.4.2.1\), but its value is 5")
        #  the keywords of other HDUs are verified too
        @test_logs (:warn, r"DATE must be a date") reading(filebytes([extension; "DATE    = 'today'"], data))

        ####    The descriptive keywords are character strings (Sects. 4.4.2.1 to 4.4.2.3, and 4.4.2.5)

        keys = ("ORIGIN", "TELESCOP", "INSTRUME", "OBSERVER", "OBJECT", "AUTHOR", "REFERENC", "BUNIT")
        silent(["$(rpad(key, 8))= '$(key == "BUNIT" ? "adu" : "a name")'" for key in keys])
        for key in keys
            warned([kw(key, 7)], Regex("$key must be a character string, but its value is 7"))
        end
        warned([kw("EXTNAME", 1)], r"EXTNAME must be a character string, but its value is 1")
        @test_logs (:warn, r"EXTNAME must be a character string") reading(filebytes([extension; kw("EXTNAME", 1)], data))
        @test_logs reading(filebytes([extension; "EXTNAME = 'SCI'"], data))

        ####    BUNIT is a units string (Sect. 4.3)

        for unit in ("adu", "km/s", "Jy/beam", "mJy", "erg s-1 cm-2", "m**2", "")
            silent(["BUNIT   = '$unit'"])
        end
        for unit in ("not a unit", "kilometre/second", "m//s")
            warned(["BUNIT   = '$unit'"], Regex("BUNIT must be a units string \\(Sect. 4.3\\), but its value is \"$unit\""))
        end
    end

    ####    Test that the scaled data are written as the stored values (Eq. 3 of the standard)    ####    Test the signature of random groups, which a primary array does not have (Sect. 6.1.1)    ####

    @testset "Primary and random groups" begin
        #  the data of the arrays of 6 and 4 values, which fill the last block with zeros
        data = collect(reinterpret(UInt8, hton.(Int16[1, 2, 10, 11, 12, 3])))
        data4 = data[1:8]
        simple, bitpix = kw("SIMPLE", "T"), kw("BITPIX", 16)
        counts = [kw("PCOUNT", 2), kw("GCOUNT", 2)]
        #  GROUPS of T and an NAXIS1 that is not 0 are not random groups, so the header is read as a primary array, whose
        #  data are the NAXISn, and not the groups of PCOUNT parameters and an array
        notgroups = [simple, bitpix, kw("NAXIS", 2), kw("NAXIS1", 3), kw("NAXIS2", 2), kw("GROUPS", "T"), counts...]
        warning = r"GROUPS is T, which says that the HDU has random groups, but NAXIS1 is 3, and not 0 \(Sect. 6.1.1\), " *
            r"so it is read as a primary array, and PCOUNT and GCOUNT are not used."
        hdu = @test_logs (:warn, warning) reading(filebytes(notgroups, data))
        @test hdu isa HDU{Primary} && hdu.data == Int16[1 11; 2 12; 10 3]
        hdu = @test_logs (:warn, r"but NAXIS1 is absent, and not 0 \(Sect. 6.1.1\)") reading(filebytes(
            [simple, bitpix, kw("NAXIS", 0), kw("GROUPS", "T"), counts...], data))
        @test hdu isa HDU{Primary} && ismissing(hdu.data)
        #  and NAXIS1 of 0, which is the signature of random groups, is not without GROUPS of T
        groupsf = [simple, bitpix, kw("NAXIS", 2), kw("NAXIS1", 0), kw("NAXIS2", 3), kw("GROUPS", "F"), counts...]
        hdu = @test_logs (:warn, "NAXIS1 is 0, which is the signature of random groups, but GROUPS is F (Sect. 6.1.1), " *
            "so it is read as a primary array without data, and PCOUNT and GCOUNT are not used.") reading(
            filebytes(groupsf, data))
        @test hdu isa HDU{Primary} && ismissing(hdu.data)
        #  a primary array that has an axis of 0 has no data, with or without PCOUNT and GCOUNT, and without a warning
        for cards in ([simple, bitpix, kw("NAXIS", 2), kw("NAXIS1", 0), kw("NAXIS2", 3)],
            [simple, bitpix, kw("NAXIS", 2), kw("NAXIS1", 0), kw("NAXIS2", 3), counts...],
            [simple, bitpix, kw("NAXIS", 1), kw("NAXIS1", 0), kw("GROUPS", "F")])
            @test ismissing(@test_logs(reading(filebytes(cards, data))).data)
        end
        #  GROUPS must be a logical, and a value that is not is not the signature, even if it is equal to T
        for groups in ("1", "'T'", "1.0")
            value = groups == "'T'" ? "T" : groups == "1" ? 1 : 1.0f0
            hdu = @test_logs (:warn, "GROUPS must be a logical, T or F, but its value is $(repr(value)). It is read as it is.") reading(
                filebytes([simple, bitpix, kw("NAXIS", 2), kw("NAXIS1", 0), kw("NAXIS2", 3), kw("GROUPS", groups), counts...],
                data))
            @test hdu isa HDU{Primary} && ismissing(hdu.data)
        end
        #  GROUPS of F is not the signature, whatever NAXIS1 is
        hdu = @test_logs reading(filebytes([simple, bitpix, kw("NAXIS", 2), kw("NAXIS1", 3), kw("NAXIS2", 2),
            kw("GROUPS", "F")], data))
        @test hdu.data == Int16[1 11; 2 12; 10 3]
        #  PCOUNT and GCOUNT are not keywords of a primary array, so they do not change the size of its data
        hdu = @test_logs reading(filebytes([simple, bitpix, kw("NAXIS", 2), kw("NAXIS1", 3), kw("NAXIS2", 2), counts...], data))
        @test hdu.data == Int16[1 11; 2 12; 10 3]
        hdu = @test_logs reading(filebytes([simple, bitpix, kw("NAXIS", 1), kw("NAXIS1", 4), kw("PCOUNT", 7),
            kw("GCOUNT", 3)], data4))
        @test hdu.data == Int16[1, 2, 10, 11]
        #  the data of a header that is written have the size of the axes
        written_ = @test_logs (:warn, warning) (:warn, warning) written(reading(filebytes(notgroups, data)))
        @test @test_logs((:warn, warning), reading(written_)).data == Int16[1 11; 2 12; 10 3]
    end

    ####

    @testset "Scaled data" begin
        bytesof(values) = collect(reinterpret(UInt8, hton.(values)))
        #  an HDU that is read with the data scaled
        scaledreading(bytes; kwds...) = read(IOBuffer(bytes), HDU; kwds...)
        primary = [kw("SIMPLE", "T"), kw("BITPIX", 16), kw("NAXIS", 1), kw("NAXIS1", 3)]
        simple(bitpix) = [kw("SIMPLE", "T"), kw("BITPIX", bitpix), kw("NAXIS", 1), kw("NAXIS1", 3)]
        stored = bytesof(Int16[-5, 0, 300])
        withcards(cards...) = filebytes([primary; collect(cards)], stored)

        #  the data that are read scaled are written as they were read, whether or not the data are scaled by BSCALE and BZERO
        cases = (
            "default" => (filebytes(primary, stored), Float32),
            "BSCALE and BZERO" => (withcards(kw("BSCALE", 2.5), kw("BZERO", 10)), Float32),
            "BSCALE" => (withcards(kw("BSCALE", 0.5)), Float32),
            "BZERO" => (withcards(kw("BZERO", -7)), Float32),
            "BLANK" => (filebytes([primary; kw("BSCALE", 2.5); kw("BLANK", -32768)], bytesof(Int16[-5, -32768, 300])),
                Float32),
            "offset of Table 11" => (withcards(kw("BZERO", 32768)), UInt16),
            "32 bits" => (filebytes([simple(32); kw("BSCALE", 0.5); kw("BZERO", 10)], bytesof(Int32[-5, 0, 3000])), Float32),
            "bytes" => (filebytes([simple(8); kw("BSCALE", 2.0); kw("BZERO", -3)], UInt8[0, 7, 255]), Float32),
            "floating-point" => (filebytes(simple(-32), bytesof(Float32[1.5, NaN, -3])), Float32),
            "double precision" => (filebytes(simple(-64), bytesof(Float64[1.5, Inf, -3])), Float64))
        for (name, (bytes, type)) in cases
            hdu = scaledreading(bytes)
            @test nonmissingtype(eltype(hdu.data)) === type
            @test @test_logs(written(hdu)) == codeunits(bytes)
        end
        #  the same for an IMAGE extension
        extension = ["XTENSION= 'IMAGE   '", kw("BITPIX", 16), kw("NAXIS", 1), kw("NAXIS1", 3), kw("PCOUNT", 0),
            kw("GCOUNT", 1), kw("BSCALE", 2.5), kw("BZERO", 10)]
        bytes = filebytes(extension, stored)
        hdu = scaledreading(bytes)
        @test hdu isa HDU{Image} && eltype(hdu.data) === Float32
        @test written(hdu) == codeunits(bytes)
        #  the data that are not scaled are the stored values, which are written as they are
        for bytes in (withcards(kw("BSCALE", 2.5), kw("BZERO", 10)), withcards(kw("BZERO", 32768)))
            hdu = scaledreading(bytes; scale = false)
            @test eltype(hdu.data) === Int16 && written(hdu) == codeunits(bytes)
        end
        #  the data of the type of the HDU are the stored values, since they cannot be told from the scaled values, which
        #  is for floating-point data that BSCALE and BZERO scale: they are written as they are
        bytes = filebytes([simple(-64); kw("BSCALE", 2.0)], bytesof(Float64[1.5, 4, -3]))
        hdu = scaledreading(bytes; scale = false)
        @test hdu.data == [1.5, 4, -3] && written(hdu) == codeunits(bytes)
        @test scaledreading(bytes).data == [3.0, 8, -6]

        #  the data that are changed are written as the stored values, if they are the stored values of the data, which
        #  is checked by applying BSCALE and BZERO to them, and an error if they are not
        writtenwith(hdu; kwds...) = (buffer = IOBuffer(); write(buffer, hdu; kwds...); take!(buffer))
        bytes = withcards(kw("BSCALE", 2.5), kw("BZERO", 10))
        hdu = scaledreading(bytes)
        hdu.data .= Float32[10, 12.5, -10]
        @test scaledreading(written(hdu); scale = false).data == Int16[0, 1, -8]
        hdu.data .= Float32[11.2, 11.3, -10.0]
        @test_throws ArgumentError("The value 11.2 cannot be stored as Int16 data with BSCALE 2.5 and BZERO 10.0: the " *
            "nearest stored value, 0, is the value 10.0. Use check = false to write the stored value.") written(hdu)
        @test_throws ArgumentError writtenwith(hdu; check = true)
        #  the nearest stored values are written if the check is bypassed
        @test scaledreading(writtenwith(hdu; check = false)).data == Float32[10, 12.5, -10]
        @test scaledreading(writtenwith(hdu; check = false); scale = false).data == Int16[0, 1, -8]
        #  the check does not change the data that are read, or the undefined values
        for (name, (bytes, type)) in cases
            @test writtenwith(scaledreading(bytes); check = false) == writtenwith(scaledreading(bytes))
        end
        #  floating-point data of another type are checked to the precision of the type of the HDU
        header = scaledreading(filebytes(simple(-32), bytesof(Float32[1.5, 2, 3])))
        cards = getfield(header, :cards)
        values = HDU{Primary}(cards, Float64[1.1, 2.0, 3.5])
        @test scaledreading(written(values); scale = false).data == Float32[1.1, 2.0, 3.5]
        values = HDU{Primary}(cards, Float64[1.1, 1e300, 3.5])
        @test_throws r"The value 1.0e300 cannot be stored as Float32 data with BSCALE 1.0 and BZERO 0.0" written(values)
        @test scaledreading(writtenwith(values; check = false); scale = false).data == Float32[1.1, Inf, 3.5]

        #  the undefined values are the BLANK, and are written as it
        bytes = filebytes([primary; kw("BSCALE", 2.5); kw("BLANK", -32768)], bytesof(Int16[-5, -32768, 300]))
        hdu = scaledreading(bytes)
        @test isequal(hdu.data, Union{Float32, Missing}[-12.5, missing, 750])
        hdu.data[1], hdu.data[3] = NaN32, missing
        @test isequal(scaledreading(written(hdu); scale = false).data, Union{Int16, Missing}[missing, missing, missing])
        @test written(hdu)[2881:2886] == bytesof(Int16[-32768, -32768, -32768])
        #  NaN is undefined only if the integer data have a BLANK
        hdu = scaledreading(withcards(kw("BSCALE", 2.5)))
        hdu.data[2] = NaN32
        @test_throws ArgumentError("NaN cannot be written as integer data that does not have a BLANK keyword.") written(hdu)

        #  a value that does not have a stored value is an error
        hdu = scaledreading(withcards(kw("BSCALE", 2.5), kw("BZERO", 10)))
        hdu.data[2] = 1.0f9
        @test_throws ArgumentError written(hdu)
        @test_throws r"The value 1.0e9 is not in the range of the Int16 data that BSCALE 2.5 and BZERO 10.0 describe" written(hdu)
        hdu = scaledreading(withcards(kw("BSCALE", 0)))
        @test_throws ArgumentError("The values cannot be written as stored values, since BSCALE is 0.") written(hdu)

        #  an HDU that is created from data has the type of the data, and is not changed
        for data in (Int16[1 2; 3 4], Float32[1.5 2.5; -1 7], UInt16[0 40000; 5 65535], UInt8[1 2; 3 4])
            hdu = HDU(Primary, data)
            @test @test_logs(scaledreading(written(hdu))).data == data
        end
    end

end

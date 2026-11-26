@testset "Checksum" begin

    ####    The ones' complement sum (Sect. 4.4.2.7)

    words(values...) = collect(reinterpret(UInt8, hton.(UInt32[values...])))
    sumof = FITSFiles.onescomplementsum
    @test sumof(words(1, 2, 3)) === 0x00000006
    #  a carry is added to the least significant bit
    @test sumof(words(0xffffffff, 1)) === 0x00000001
    @test sumof(words(0xfffffffe, 0xfffffffe)) === 0xfffffffd
    #  negative zero is all bits equal to 1, and is the sum of an integer and its complement
    @test sumof(words(0xffffffff)) === 0xffffffff
    @test sumof(words(0x12345678, ~0x12345678)) === 0xffffffff
    @test sumof(UInt8[]) === 0x00000000
    @test sumof(words(5), 7) === 0x0000000c
    #  the bytes are big-endian integers
    @test sumof(UInt8[0x01, 0x00, 0x00, 0x00]) === 0x01000000
    @test_throws ArgumentError sumof(UInt8[1, 2, 3])

    #  the sum is the sum of the integers, with the carries added, for any number of bytes
    function naive(bytes)
        total = sum(UInt128(ntoh(x)) for x in reinterpret(UInt32, bytes); init = UInt128(0))
        while total > 0xffffffff
            total = (total & 0xffffffff) + (total >> 32)
        end
        UInt32(total)
    end
    for n in (4, 2880, 2880*17, 4*(2880*4096) + 2880*3)
        bytes = rand(UInt8, n)
        @test sumof(bytes) === naive(bytes)
    end
    bytes = fill(0xff, 2*2880*4096)
    @test sumof(bytes) === 0xffffffff

    ####    The ASCII encoding (Appendix J.2)

    #  the example of Appendix J.3: the sum 868229149 of the HDU with the CHECKSUM '0000000000000000'
    @test FITSFiles.encodechecksum(868229149) == "hcHjjc9ghcEghc9g"
    @test FITSFiles.decodechecksum("hcHjjc9ghcEghc9g") === 0x33c0201d
    for sum in rand(UInt32, 2000)
        text = FITSFiles.encodechecksum(sum)
        #  16 alphanumeric characters
        @test length(text) == 16 && all(c -> isascii(c) && isletter(c) || isdigit(c), text)
        @test FITSFiles.decodechecksum(text) === sum
    end
    for sum in (0x00000000, 0xffffffff, 0x00000001, 0x80808080, 0x3a3a3a3a)
        @test FITSFiles.decodechecksum(FITSFiles.encodechecksum(sum)) === sum
    end
    @test_throws ArgumentError FITSFiles.decodechecksum("short")

    ####    The keywords of an HDU

    written(hdu; kwds...) = (buffer = IOBuffer(); write(buffer, hdu; kwds...); take!(buffer))
    reading(bytes; kwds...) = read(IOBuffer(bytes), HDU; scale = false, kwds...)
    #  the card images of an HDU, and the bytes of its data after the header
    cardimages(bytes) = [String(bytes[j:j+79]) for j = 1:80:2880]
    cardof(bytes, key) = only(filter(c -> startswith(c, rpad(key, 8)), cardimages(bytes)))
    datapart(bytes) = bytes[2881:end]
    #  the bytes with the card of the keyword replaced by the card image
    function replacecard(bytes, key, image)
        k = findfirst(c -> startswith(c, rpad(key, 8)), cardimages(bytes))
        replaced = copy(bytes)
        replaced[80(k-1)+1:80k] = codeunits(rpad(image, 80))
        replaced
    end

    hdus = [HDU(Primary, Int16[1 2 3; 4 5 6]), HDU(Image, Float32[1.5 2.5; -1 7]),
        HDU(Bintable, (a = Int32[1, 2, 3], b = [1.5, 2.5, 3.5])), HDU(Primary)]
    for hdu in hdus
        bytes = written(hdu; checksum = true)
        #  the sum of the HDU is negative zero, and DATASUM is the sum of the data records
        @test sumof(bytes) === 0xffffffff
        @test startswith(cardof(bytes, "DATASUM"), "DATASUM = '$(sumof(datapart(bytes)))'")
        #  CHECKSUM is in fixed format, with the single quotes in columns 11 and 28
        card = cardof(bytes, "CHECKSUM")
        @test card[9:10] == "= " && card[11] == '\'' && card[28] == '\'' && card[29] != '\''
        @test FITSFiles.decodechecksum(card[12:27]) isa UInt32
        #  an HDU that is written without the keywords does not have them, and is written as it was
        plain = written(hdu)
        @test !any(c -> startswith(c, "CHECKSUM") || startswith(c, "DATASUM"), cardimages(plain))
        @test @test_logs(reading(bytes; checksum = true)) isa HDU
        @test @test_logs(reading(plain; checksum = true)) isa HDU
    end
    #  an HDU without data has a DATASUM of 0
    @test startswith(cardof(written(HDU(Primary); checksum = true), "DATASUM"), "DATASUM = '0'")

    #  an HDU that is read with the keywords is written with the same bytes
    for hdu in hdus
        bytes = written(hdu; checksum = true)
        again = reading(bytes)
        @test written(again; checksum = true) == bytes
        @test written(again) == bytes
    end

    ####    Verify the sums when an HDU is read

    hdu = HDU(Primary, Int16[1 2 3; 4 5 6], Card{<:Any}[Card("OBJECT", "NGC 1275")])
    bytes = written(hdu; checksum = true)
    #  the sums are not verified unless asked, and the data is as it was
    tampered = copy(bytes); tampered[2881 + 3] ⊻= 0x01
    @test @test_logs(reading(tampered)).data[2, 1] != 4
    #  a change of the data is a change of the data sum and of the HDU sum
    @test_logs (:warn, r"DATASUM is \d+, but the sum of the data records is \d+") (:warn, r"checksum of the HDU is \d+, and not -0") reading(
        tampered; checksum = true)
    #  a change of the header is a change of the HDU sum only
    changed = copy(bytes)
    changed[first(findfirst("NGC 1275", String(copy(bytes))))] = UInt8('M')
    @test_logs (:warn, r"checksum of the HDU is \d+, and not -0") reading(changed; checksum = true)
    #  a sum that is not known is not verified: the DATASUM that is blank leaves the CHECKSUM, whose HDU has changed
    #  by the blank, and the CHECKSUM that is blank leaves the DATASUM
    nodatasum = replacecard(bytes, "DATASUM", "DATASUM = '          '")
    @test_logs (:warn, r"checksum of the HDU") reading(nodatasum; checksum = true)
    nochecksum = replacecard(tampered, "CHECKSUM", "CHECKSUM= '                '")
    @test_logs (:warn, r"DATASUM is") reading(nochecksum; checksum = true)
    @test_logs reading(replacecard(nochecksum, "DATASUM", "DATASUM = ''"); checksum = true)
    @test_logs reading(replacecard(nochecksum, "DATASUM", "DATASUM = 'twelve'"); checksum = true)

    #  the value of DATASUM may have leading zeros and blanks, and a value that is not a number is not known
    datasum = match(r"DATASUM = '(\d+)'", cardof(bytes, "DATASUM"))[1]
    padded = replacecard(bytes, "DATASUM", "DATASUM = '  00$datasum  '")
    @test_logs (:warn, r"checksum of the HDU") reading(padded; checksum = true)
    @test FITSFiles.datasumvalue(Card{<:Any}[Card("DATASUM", "0000012")]) === 0x0000000c
    @test FITSFiles.datasumvalue(Card{<:Any}[Card("DATASUM", " 12 ")]) === 0x0000000c
    @test isnothing(FITSFiles.datasumvalue(Card{<:Any}[Card("DATASUM", "")]))
    @test isnothing(FITSFiles.datasumvalue(Card{<:Any}[Card("DATASUM", "twelve")]))
    @test isnothing(FITSFiles.datasumvalue(Card{<:Any}[Card("DATASUM", 12)]))
    @test isnothing(FITSFiles.datasumvalue(Card{<:Any}[Card("OBJECT", "x")]))

    #  the fill of the last data block is zeros, so a file that does not have it has the same sums
    short = bytes[1:2880+sizeof(Int16)*6]
    @test @test_logs(reading(short; checksum = true)).data == Int16[1 2 3; 4 5 6]

    ####    A file of HDUs

    mktemp() do path, io
        write(io, hdus; checksum = true)
        close(io)
        bytes = read(path)
        #  the sum of a file of HDUs that have the sum -0 is -0
        @test sumof(bytes) === 0xffffffff
        file = @test_logs fits(path; checksum = true)
        @test length(file) == 4
        #  a change of the data of the second HDU is found in that HDU
        tampered = copy(bytes)
        hdr = length(written(hdus[1]; checksum = true))
        tampered[hdr + 2881 + 1] ⊻= 0x40
        write(path, tampered)
        @test_logs (:warn, r"DATASUM is") (:warn, r"checksum of the HDU") fits(path; checksum = true)
    end
end

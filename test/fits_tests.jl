@testset "FITS" begin

    #  test fits with IO type


    #  test fits with fieldnames


    #  test fits with scale keyword


    #  test fits with record keyword



    ####    Test the structure of a file (Sects. 3.1 and 3.4.3)

    @testset "file structure" begin
        primary, image = HDU(Primary, Int16[1 2 3; 4 5 6]), HDU(Image, Float32[1.5 2.5; -1 7])
        table, empty = HDU(Bintable, (a = Int32[1, 2, 3], b = [1.5, 2.5, 3.5])), HDU(Primary)
        written(hdus) = (buffer = IOBuffer(); write(buffer, hdus); take!(buffer))
        first_ = r"The first HDU of a FITS file must be the primary HDU, which has SIMPLE \(Sect. 3.1\)"
        later(j) = Regex("HDU $j of a FITS file has SIMPLE, but only the first HDU is a primary HDU")

        #  a primary HDU, with or without data, is followed by extensions, in any order
        for hdus in ([primary], [empty], [primary, image], [empty, image, table], [primary, table, image, table])
            bytes = @test_logs written(hdus)
            file = @test_logs fits(IOBuffer(bytes))
            @test length(file) == length(hdus) && typeof.(file) == typeof.(hdus)
        end
        #  the data of the HDUs are read from a buffer, where an HDU is read from the beginning of the next
        file = fits(IOBuffer(written([primary, image, table])))
        @test file[1].data == [1 2 3; 4 5 6] && file[2].data == [1.5 2.5; -1 7]
        @test file[3].data.a == [1, 2, 3] && file[3].data.b == [1.5, 2.5, 3.5]
        mktemp() do path, io
            write(io, [primary, image, table])
            close(io)
            @test_logs fits(path)
        end

        #  the first HDU is the primary HDU, and the HDUs after it are not
        for (hdus, message) in (([image], first_), ([image, table], first_), ([table, image], first_),
            ([primary, primary], later(2)), ([empty, image, primary], later(3)), ([primary, empty], later(2)))
            bytes = @test_logs (:warn, message) written(hdus)
            @test length(@test_logs((:warn, message), fits(IOBuffer(bytes)))) == length(hdus)
        end
        @test_logs (:warn, first_) (:warn, later(2)) written([image, primary])
        @test_logs (:warn, later(2)) (:warn, later(3)) written([primary, primary, empty])
        #  the HDUs are written and read as they are
        bytes = @test_logs (:warn, first_) written([image, table])
        file = @test_logs (:warn, first_) fits(IOBuffer(bytes))
        @test typeof.(file) == [typeof(image), typeof(table)]
        mktemp() do path, io
            @test_logs (:warn, later(2)) write(io, [primary, primary])
            close(io)
            @test_logs (:warn, later(2)) fits(path)
        end

        #  an HDU of a file that does not conform is a primary HDU, since its header begins with SIMPLE
        simplef = rpad("SIMPLE  =                    F", 80)
        header = join(rpad.([simplef[1:end], "BITPIX  =                    8", "NAXIS   =                    0", "END"], 80))
        bytes = Vector{UInt8}(codeunits(rpad(header, 2880)))
        file = @test_logs (:warn, r"SIMPLE is F") fits(IOBuffer(bytes))
        @test length(file) == 1 && file[1] isa HDU{FITSFiles.Conform}
        extension = @test_logs (:warn, first_) written([image])
        @test_logs (:warn, r"SIMPLE is F") fits(IOBuffer([bytes; extension]))
        #  a file does not have to have HDUs
        @test isempty(@test_logs fits(IOBuffer(UInt8[])))

        #  the HDUs are written to a file by its name, and are the HDUs that are read from it
        mktemp() do path, io
            close(io)
            @test_logs write(path, [primary, image, table])
            file = @test_logs fits(path)
            @test typeof.(file) == [typeof(primary), typeof(image), typeof(table)]
            @test file[1].data == [1 2 3; 4 5 6] && file[2].data == [1.5 2.5; -1 7] && file[3].data.a == [1, 2, 3]
            #  the keywords are the keywords of the write of the HDUs
            @test_logs write(path, [empty, image]; checksum = true)
            @test_logs fits(path; checksum = true)
            #  and the file is verified like a vector
            @test_logs (:warn, first_) write(path, [image, table])
            @test length(@test_logs((:warn, first_), fits(path))) == 2
        end
    end

    ####    Test the names of the extensions (Sect. 4.4.2.6)    ####

    @testset "extension names" begin
        data = Int16[1 2]
        extension(cards...) = HDU(Image, data, Card{<:Any}[cards...])
        sci, sci2 = extension(Card("EXTNAME", "SCI")), extension(Card("EXTNAME", "SCI"), Card("EXTVER", 2))
        written(hdus) = (buffer = IOBuffer(); write(buffer, hdus); take!(buffer))
        captured(f) = mktemp() do path, io
            redirect_stdout(f, io)
            close(io)
            read(path, String)
        end

        #  the name, the version, and the level, with the values of the standard if the keywords are absent
        plain = HDU(Image, data)
        @test (FITSFiles.extname(plain), FITSFiles.extver(plain), FITSFiles.extlevel(plain)) == ("", 1, 1)
        @test (FITSFiles.extname(sci), FITSFiles.extver(sci), FITSFiles.extlevel(sci)) == ("SCI", 1, 1)
        hdu = extension(Card("EXTNAME", "ERR   "), Card("EXTVER", 3), Card("EXTLEVEL", 2))
        @test (FITSFiles.extname(hdu), FITSFiles.extver(hdu), FITSFiles.extlevel(hdu)) == ("ERR", 3, 2)

        #  the version is the version of the HDU that is displayed, and is 1 if it is absent
        for (hdu, version) in ((plain, 1), (sci, 1), (sci2, 2), (hdu, 3))
            shown = sprint(show, MIME("text/plain"), hdu)
            @test occursin(Regex("Image\\s+[A-Z]*\\s+$version\\s+\\d+\\s+Int16"), shown)
            @test occursin(Regex("Image\\s+[A-Z]*\\s+$version\\s+\\d+\\s+Int16"), captured(() -> FITSFiles.info(hdu, 2)))
        end
        shown = sprint(show, MIME("text/plain"), HDU[HDU(Primary, data), sci, sci2])
        @test occursin(r"2\s+Image\s+SCI\s+1\s", shown) && occursin(r"3\s+Image\s+SCI\s+2\s", shown)
        @test occursin(r"3\s+Image\s+SCI\s+2\s", captured(() -> FITSFiles.info(HDU[HDU(Primary, data), sci, sci2])))
    end

end

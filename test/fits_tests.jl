@testset "FITS" begin

    #  test fits with IO type


    #  test fits with fieldnames


    #  test fits with scale keyword


    #  test fits with record keyword



    ####    Test the structure of a file (Sects. 3.1 and 3.4.3)

    @testset "file structure" begin
        primary, image = HDU(Primary, Int16[1 2 3; 4 5 6]), HDU(Image, Float32[1.5 2.5; -1 7])
        table, empty = HDU(Bintable, (a = Int32[1, 2, 3], b = [1.5, 2.5, 3.5])), HDU(Primary)
        #  the files that are read are not all standard, so the HDUs are written with the check turned off, as they are read (see `problem`)
        written(hdus; check = false) = (buffer = IOBuffer(); write(buffer, hdus; check); take!(buffer))
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
            @test_logs (:warn, later(2)) write(io, [primary, primary]; check = false)
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
            @test_logs (:warn, first_) write(path, [image, table]; check = false)
            @test length(@test_logs((:warn, first_), fits(path))) == 2
        end
    end

    ####    Test the names of the extensions (Sect. 4.4.2.6)    ####

    @testset "extension names" begin
        data = Int16[1 2]
        extension(cards...) = HDU(Image, data, Card{<:Any}[cards...])
        sci, sci2 = extension(Card("EXTNAME", "SCI")), extension(Card("EXTNAME", "SCI"), Card("EXTVER", 2))
        #  the files that are read are not all standard, so the HDUs are written with the check turned off, as they are read (see `problem`)
        written(hdus; check = false) = (buffer = IOBuffer(); write(buffer, hdus; check); take!(buffer))
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

        #  an HDU is found by its name, without regard to the case, and by its version
        hdus = HDU[HDU(Primary, data), sci, sci2, extension(Card("EXTNAME", "ERR"))]
        @test hdus["SCI"] === sci && hdus["sci"] === sci && hdus[:SCI] === sci
        @test hdus["SCI", 1] === sci && hdus["SCI", 2] === sci2 && hdus["err", 1] === hdus[4] && hdus[:sci, 2] === sci2
        @test_throws KeyError("NONE") hdus["NONE"]
        @test_throws KeyError(("SCI", 3)) hdus["SCI", 3]
        @test_throws KeyError(("ERR", 2)) hdus["ERR", 2]

        #  the combination of the type, the name, the version, and the level is unique, as is recommended
        repeated = r"HDU 3 of a FITS file has the same type IMAGE, EXTNAME \"SCI\", EXTVER 1, and EXTLEVEL 1 as HDU 2 \(Sect. 4.4.2.6\)"
        for hdus in (HDU[HDU(Primary, data), sci, sci2], HDU[HDU(Primary, data), sci, extension(Card("EXTNAME", "SCI"), Card("EXTLEVEL", 2))],
            HDU[HDU(Primary, data), sci, HDU(Bintable, (a = Int32[1],), Card{<:Any}[Card("EXTNAME", "SCI")])],
            HDU[HDU(Primary, data), sci, plain, plain], HDU[HDU(Primary, data), plain, plain])
            bytes = @test_logs written(hdus)
            @test length(@test_logs(fits(IOBuffer(bytes)))) == length(hdus)
        end
        for hdus in (HDU[HDU(Primary, data), sci, extension(Card("EXTNAME", "SCI"), Card("EXTVER", 1), Card("EXTLEVEL", 1))],
            HDU[HDU(Primary, data), sci, extension(Card("EXTNAME", "SCI   "))])
            bytes = @test_logs (:warn, repeated) written(hdus)
            @test length(@test_logs((:warn, repeated), fits(IOBuffer(bytes)))) == 3
        end
        #  the primary array is equivalent to an IMAGE extension, and a table of the same name is not
        primary = HDU(Primary, data, Card{<:Any}[Card("EXTNAME", "SCI")])
        @test_logs (:warn, r"HDU 2 of a FITS file has the same type IMAGE, EXTNAME \"SCI\", EXTVER 1, and EXTLEVEL 1 as HDU 1") written(HDU[primary, sci])
        #  random groups are not an IMAGE, so an IMAGE extension and a table of the same name are not repeats of them
        groups = HDU(Random, (a = Int16[1, 3], data = Int16[10 11 12; 20 21 22]), Card{<:Any}[Card("EXTNAME", "SCI")])
        @test_logs written(HDU[groups, sci])
        @test_logs written(HDU[groups, HDU(Bintable, (a = Int32[1],), Card{<:Any}[Card("EXTNAME", "SCI")])])
        #  and only the keywords that are there are compared
        named = extension(Card("EXTVER", 2))
        @test_logs written(HDU[HDU(Primary, data), named, extension(Card("EXTVER", 3))])
        @test_logs (:warn, r"HDU 3 of a FITS file has the same type IMAGE, EXTNAME \"\", EXTVER 2, and EXTLEVEL 1 as HDU 2") written(HDU[HDU(Primary, data), named, named])
    end

    ####    Test the special records after the last HDU (Sect. 3.5)    ####

    @testset "Special records" begin
        #  the files that are read are not all standard, so the HDUs are written with the check turned off, as they are read (see `problem`)
        written(hdus; check = false) = (io = IOBuffer(); write(io, hdus; check); take!(io))
        primary, image = HDU(Primary, Int16[1 2 3; 4 5 6]), HDU(Image, Float32[1.5 2.5; -1 7])
        bytes = written(HDU[primary, image])
        #  the HDUs of a file that ends with the last of them are read without a warning
        @test length(@test_logs fits(IOBuffer(bytes))) == 2
        #  and the blocks that follow the last HDU, whatever they are, are special records, which are not read
        for extra in (zeros(UInt8, 2880), fill(UInt8('x'), 2880), zeros(UInt8, 3 * 2880), fill(UInt8(' '), 100),
            [codeunits(rpad("JUNK = 3", 2880)); zeros(UInt8, 12)])
            file = @test_logs (:warn, "The $(length(extra)) bytes after HDU 2 of the file are special records (Sect. 3.5 of " *
                "the standard), because they do not begin with XTENSION. They are not read.") fits(IOBuffer([bytes; extra]))
            @test length(file) == 2 && file[1] isa HDU{Primary} && file[2] isa HDU{Image}
            @test file[2].data == Float32[1.5 2.5; -1 7]
        end
        #  as they are for a file that is opened
        mktemp() do path, io
            write(io, [bytes; zeros(UInt8, 2880)]); close(io)
            file = @test_logs (:warn, r"The 2880 bytes after HDU 2 of the file are special records") fits(path)
            @test length(file) == 2 && file[2].data == Float32[1.5 2.5; -1 7]
        end
        #  the first HDU is always read, and an HDU that begins with SIMPLE is an HDU in the wrong place, and not a record
        twoprimaries = @test_logs (:warn, r"HDU 2 of a FITS file has SIMPLE") written(HDU[primary, primary])
        @test length(@test_logs((:warn, r"HDU 2 of a FITS file has SIMPLE"), fits(IOBuffer(twoprimaries)))) == 2
        @test_throws ArgumentError fits(IOBuffer(zeros(UInt8, 2880)))
    end

    ####    Test the vectors of HDUs of one type of HDU, e.g., the `Vector{HDU{Primary}}` of `[HDU(data, cards)]`    ####

    @testset "concrete vectors of HDUs" begin
        data = reshape(Float32[1:100;], 5, 20)
        cards = Card{<:Any}[Card("FLTKEY", 1.0, "floating point keyword"), Card("STRKEY", "string value")]
        hdus = [HDU(data, cards)]
        @test hdus isa Vector{HDU{Primary}}
        scimage = HDU(Image, data, Card{<:Any}[Card("EXTNAME", "SCI")])

        #  a vector of one type of HDU is written to a file and to a buffer, whichever the type is, and read as it was written
        path = joinpath(mktempdir(), "roundtrip.fits")
        write(path, hdus)
        back = fits(path)
        @test length(back) == 1 && back[1] isa HDU{Primary} && back[1].data == data
        io = IOBuffer()
        write(io, hdus)
        seekstart(io)
        @test fits(io)[1].data == data
        write(path, [HDU(data, cards), HDU(Image, data, cards)])
        back = fits(path)
        @test FITSFiles.typeofhdu.(back) == [Primary, Image] && back[2].data == data
        #  a vector of the same type that is not a Vector, e.g., a view, is written too, and the keywords of the write are those of the HDU
        io = IOBuffer()
        write(io, view(HDU[HDU(data, cards), scimage], 1:2))
        @test fits(IOBuffer(take!(io)))[2].data == data
        io = IOBuffer()
        write(io, view([HDU(data, cards)], 1:1); checksum = true)
        @test haskey(fits(IOBuffer(take!(io)))[1].cards, "CHECKSUM")
        write(path, [HDU(data, cards)]; checksum = true)
        @test haskey(fits(path)[1].cards, "CHECKSUM")

        #  the functions of the vectors of HDUs are for the vectors of one type of HDU, as they are for the vector of HDU
        images = [scimage]
        @test images isa Vector{HDU{Image}}
        for vector in (images, HDU[scimage], view(HDU[scimage], 1:1))
            @test haskey(vector, Image) && !haskey(vector, Primary)
            @test vector[Image] === scimage && vector["SCI"] === scimage && vector["SCI", 1] === scimage
            @test_throws KeyError vector[Primary]
            @test_throws KeyError vector["OTHER"]
            @test get(vector, "SCI") === scimage && isnothing(get(vector, "OTHER"))
            @test get(vector, "OTHER", "sci") === scimage
            @test get(vector, ["SCI", "OTHER"], ["x", "y"]) == [scimage, nothing] && get(vector, ("OTHER",), ("sci",)) == [scimage]
            @test findfirst("EXTNAME", vector) === findfirst("EXTNAME", HDU[scimage])
            @test findfirst("EXTNAME", vcat(vector, [HDU(Image, data, Card{<:Any}[Card("EXTNAME", "extname")])])) == 2
        end
        @test sprint(show, MIME("text/plain"), images) == sprint(show, MIME("text/plain"), HDU[scimage])
        @test occursin("Image", sprint(show, MIME("text/plain"), images)) && occursin("SCI", sprint(show, MIME("text/plain"), images))
        @test sprint(show, MIME("text/plain"), hdus) == sprint(show, MIME("text/plain"), HDU[HDU(data, cards)])
        @test_nowarn redirect_stdout(devnull) do; info(images); info(hdus); end
        #  the vectors of HDUs that are the types of HDU of a file are those of the vector of HDU
        file = fits(IOBuffer(let io = IOBuffer(); write(io, [HDU(data, cards), scimage]); take!(io) end))
        @test haskey(file, Image) && file["SCI"].data == data && file[Image].data == data
    end

    ####    Test the data that are not read, which a file is scanned for, and are copied as they are when they are written    ####

    @testset "lazy data" begin
        dir = mktempdir()
        primary, image = HDU(Primary, Int16[1 2 3; 4 5 6]), HDU(Image, Float32[1.5 2.5; -1 7])
        table = HDU(Table, (a = [1, 22], b = [2.5, -3.25], c = ["xy", "z"]), Card{<:Any}[Card("EXTNAME", "CAT")])
        bintable = HDU(Bintable, (a = Int32[1, 2, 3], b = [1.5, 2.5, 3.5], c = ["x", "yy", "zzz"], v = [[1.0], [2.0, 3.0], Float64[]]))
        groups = HDU(Random, (a = Int16[1, 3], data = Int16[10 11 12; 20 21 22]))
        islazy(hdu) = getfield(hdu, :data) isa FITSFiles.LazyArray
        bytesof(hdus; kwds...) = (io = IOBuffer(); write(io, hdus; kwds...); take!(io))
        newfile(name, hdus) = (path = joinpath(dir, name); write(path, hdus); path)

        #  the data of the HDUs of a file are not read, and are written as they are in the file, whatever the type of HDU is
        for (name, hdus) in (("a.fits", [primary, image, table, bintable]), ("b.fits", [groups]), ("c.fits", [HDU(Primary), table]))
            path = newfile(name, hdus)
            lazy = fits(path)
            @test count(islazy, lazy) == count(hdu -> !ismissing(getfield(hdu, :data)), lazy) && any(islazy, lazy)
            original = read(path)
            @test bytesof(lazy) == original
            other = joinpath(dir, "copy_" * name)
            write(other, lazy)
            @test read(other) == original
            #  the data are the data that were written, and are not changed by being written
            @test fits(other)[end].data == fits(IOBuffer(original))[end].data
            #  the checksums are those of the data that are read
            eager = fits(IOBuffer(original))
            @test bytesof(lazy; checksum = true) == bytesof(eager; checksum = true)
        end

        #  the HDUs of a file are scanned without reading their data, and the size is that of the header
        path = newfile("d.fits", [primary, HDU(Image, reshape(Float32[1:6;], 3, 2))])
        lazy = fits(path)
        @test islazy(lazy[2]) && size(lazy[2]) == (3, 2)
        #  the fill after the data is that of the type of HDU, whatever the fill of the file is, with a warning that the fill is not
        for (hdus, fill) in (([primary], 0x00), ([HDU(Primary), table], 0x20))
            path = newfile("e.fits", hdus)
            bytes = read(path)
            correct = copy(bytes)
            bytes[end] = 0x55
            write(path, bytes)
            lazy = @test_logs (:warn, r"The fill of the last data block of the HDU is not all") fits(path)
            @test bytesof(lazy) == correct && bytesof(lazy)[end] == fill
        end

        #  the header may be changed, but not the size and the type of the data
        path = newfile("f.fits", [HDU(Primary), table])
        lazy = fits(path)
        cards = copy(getfield(lazy[2], :cards))
        push!(cards, Card("OBJECT", "changed"))
        changed = HDU{Table}(cards, getfield(lazy[2], :data))
        again = fits(IOBuffer(bytesof([lazy[1], changed])))
        @test again[2].cards["OBJECT"] == "changed" && again[2].data == fits(path)[2].data
        for (key, value) in ("NAXIS2" => 1, "NAXIS1" => 40)
            cards = copy(getfield(lazy[2], :cards))
            cards[key] = value
            @test_throws ArgumentError r"The header of the HDU has a data format that is not that of the data of the file that were not read" bytesof(
                [lazy[1], HDU{Table}(cards, getfield(lazy[2], :data))])
        end

        #  the file must not have been modified since it was read, which is an error, and the data of a file that does not exist are not read
        path = newfile("g.fits", [primary, image])
        lazy = fits(path)
        sleep(0.05)
        touch(path)
        @test_throws ArgumentError r"has been modified since the HDU was read, so the data are not those that the header describes" bytesof(lazy)
        @test_throws ArgumentError r"has been modified since the HDU was read" lazy[2].data
        @test_throws ArgumentError r"has been modified since the HDU was read" write(joinpath(dir, "h.fits"), lazy)
        rm(path)
        @test_throws ArgumentError r"which the data of the HDU are read from, does not exist" bytesof(lazy)
        @test_throws ArgumentError r"does not exist" lazy[2].data
        #  the HDU that has no lazy data is written, and so is a file that has no data
        @test bytesof([HDU(Primary)]) == bytesof(fits(IOBuffer(bytesof([HDU(Primary)]))))

        #  a vector of HDUs is not written to the file that the data are read from, which opening for writing would empty, and the file is as it was
        path = newfile("i.fits", [primary, image, table])
        original = read(path)
        lazy = fits(path)
        @test_throws ArgumentError r"The data of HDU 1 are not read, and are read from .*i\.fits, which opening it for writing empties\. Write to another file\." write(path, lazy)
        @test_throws ArgumentError r"The data of HDU 2 are not read" write(path, [HDU(Primary), lazy[2]])
        @test read(path) == original && bytesof(fits(path)) == original
        #  but is to another file, and the file is written with the HDUs that have no lazy data, which modifies the file that the data of the others
        #  are read from
        other = joinpath(dir, "j.fits")
        write(other, lazy)
        @test read(other) == original
        write(path, [primary, image])
        @test fits(path)[2].data == image.data
        @test_throws ArgumentError r"has been modified since the HDU was read" bytesof(lazy)

        #  the data that are not in the file are an error, which says how many bytes the file has
        path = newfile("k.fits", [HDU(Primary, zeros(Int16, 1000))])
        open(path, "r+") do io
            truncate(io, 2880 + 500)
        end
        lazy = fits(path)
        @test_throws ArgumentError r"The data of the HDU are 2000 bytes, as its header says, but the file has only 500 of them" bytesof(lazy)

        #  the file is found when the directory is changed, since the name of the file is its absolute path
        path = newfile("l.fits", [primary, image])
        original = read(path)
        lazy = cd(() -> fits("l.fits"), dir)
        @test bytesof(lazy) == original && lazy[2].data == image.data

        #  the files of the sample data are written as they are
        sample = joinpath(@__DIR__, "data", "int32_large.fits")
        @test bytesof(fits(sample)) == bytesof(fits(IOBuffer(read(sample))))
        @test bytesof(fits(sample)) == read(sample)
    end

    @testset "strict writes of a file" begin
        primary, image = HDU(Primary, Int16[1 2 3; 4 5 6]), HDU(Image, Float32[1.5 2.5; -1 7])
        #  the order of the HDUs is an error when they are written, before anything is written, unless the check is turned off
        for hdus in ([image, primary], [primary, primary])
            io = IOBuffer()
            @test_throws ArgumentError r"of a FITS file .*Use check = false to write it as it is\.$" write(io, hdus)
            @test isempty(take!(io))
            @test_logs (:warn, r"of a FITS file") (:warn, r"of a FITS file") match_mode = :any write(io, hdus; check = false)
            @test length(take!(io)) == 4 * 2880
        end
        #  and a file is not changed, or left empty, or with some of the HDUs, by a write that fails, and there is no other file left
        mktempdir() do dir
            path = joinpath(dir, "file.fits")
            write(path, [primary, image])
            before = read(path)
            @test_throws ArgumentError r"The first HDU of a FITS file must be the primary HDU" write(path, [image, primary])
            @test read(path) == before && readdir(dir) == ["file.fits"]
            @test_throws ArgumentError r"The first HDU of a FITS file must be the primary HDU" write(joinpath(dir, "new.fits"), [image])
            @test readdir(dir) == ["file.fits"]
            @test_logs (:warn, r"The first HDU of a FITS file must be the primary HDU") write(joinpath(dir, "new.fits"), [image]; check = false)
            @test readdir(dir) == ["file.fits", "new.fits"] && length(@test_logs((:warn, r"The first HDU"), fits(joinpath(dir, "new.fits")))) == 1
            write(path, [primary, image, image])
            @test length(read(path)) > length(before) && readdir(dir) == ["file.fits", "new.fits"]
        end
        #  the names of the HDUs that are the same are a recommendation, which is a warning
        named = HDU(Image, Float32[1 2], Card{<:Any}[Card("EXTNAME", "SCI")])
        @test_logs (:warn, r"HDU 3 of a FITS file has the same type IMAGE, EXTNAME \"SCI\"") write(IOBuffer(), [primary, named, named])
    end

end

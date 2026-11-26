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

        #  the data of the HDUs are read from a buffer, where an HDU is read from the beginning of the next
        file = fits(IOBuffer(written([primary, image, table])))
        @test file[1].data == [1 2 3; 4 5 6] && file[2].data == [1.5 2.5; -1 7]
        @test file[3].data.a == [1, 2, 3] && file[3].data.b == [1.5, 2.5, 3.5]
        mktemp() do path, io
            write(io, [primary, image, table])
            close(io)
            @test_logs fits(path)
        end

    end

end

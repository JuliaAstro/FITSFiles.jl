@testset "Mapped data" begin

    dir = mktempdir()
    newfile(name, hdus) = (path = joinpath(dir, name); write(path, hdus); path)
    #  the mapped data are the data that are read, of the same type and values, and the slices are those of the data
    function compare(mapped, eager; undefined = false)
        @test (mapped isa FITSFiles.ScaledArray) == (eager isa FITSFiles.ScaledArray) && mapped isa AbstractArray
        #  the type of the logicals and of the complex numbers of a binary table has `missing` whether or not a value is undefined
        @test (eltype(mapped) == eltype(eager) || undefined && eltype(mapped) == Union{Missing, eltype(eager)}) && size(mapped) == size(eager) && ndims(mapped) == ndims(eager)
        @test isequal(collect(mapped), collect(eager)) && isequal(Array(mapped), Array(eager))
        for I in (ntuple(_ -> Colon(), ndims(eager)), ntuple(d -> d == 1 ? (1:2) : Colon(), ndims(eager)),
            ntuple(d -> d == ndims(eager) ? size(eager, d) : Colon(), ndims(eager)), ntuple(d -> 1, ndims(eager)),
            ntuple(d -> d == 1 ? (1:2:size(eager, 1)) : (size(eager, d):-1:1), ndims(eager)))
            @test isequal(mapped[I...], eager[I...])
        end
        @test isequal(mapped[1], eager[1]) && isequal(mapped[end], eager[end]) && isequal(mapped[length(eager) ÷ 2 + 1], eager[length(eager) ÷ 2 + 1])
        @test all(i -> isequal(mapped[i], eager[i]) && typeof(mapped[i]) == typeof(eager[i]), 1:length(eager))
    end
    function same(path, j = 1; kwds...)
        mapped = mapdata(fits(path; kwds...)[j])
        eager = fits(IOBuffer(read(path)); kwds...)[j].data
        compare(mapped, eager)
        mapped, eager
    end

    ####    The types of BITPIX, which have no scale    ####

    @testset "types" begin
        for type in (UInt8, Int16, Int32, Int64, Float32, Float64)
            data = reshape(type.(1:24), 2, 3, 4)
            mapped, eager = same(newfile("types.fits", [HDU(Primary, data)]))
            @test mapped isa FITSFiles.MappedArray{type, 3} && mapped == data && eltype(mapped) === type
            mapped, eager = same(newfile("image.fits", [HDU(Primary), HDU(Image, data)]), 2)
            @test mapped isa FITSFiles.MappedArray{type, 3} && mapped == data
        end
        #  a vector, a matrix, and the values of a negative number and of a large one
        mapped, _ = same(newfile("vector.fits", [HDU(Primary, Int32[-5, 2^30, typemin(Int32), typemax(Int32)])]))
        @test mapped == Int32[-5, 2^30, typemin(Int32), typemax(Int32)] && size(mapped) == (4,)
        mapped, _ = same(newfile("floats.fits", [HDU(Primary, Float64[-0.0 NaN; Inf 5e-324])]))
        @test isequal(mapped, Float64[-0.0 NaN; Inf 5e-324]) && signbit(mapped[1, 1])
        #  a value that is indexed is a value of the type, and an index that is not in the array is an error
        mapped = mapdata(fits(newfile("bounds.fits", [HDU(Primary, Int16[1 2; 3 4])]))[1])
        @test mapped[2, 2] === Int16(4) && mapped[3] === Int16(2) && mapped[CartesianIndex(1, 2)] === Int16(2)
        @test_throws BoundsError mapped[3, 1]
        @test_throws BoundsError mapped[0]
        @test_throws BoundsError mapped[5]
        @test_throws BoundsError mapped[1:3, 1]
        @test_throws BoundsError mapped[:, 3]
    end

    ####    The scale and the zero (Eq. 3)    ####

    @testset "scaled values" begin
        data = reshape(Int32.(1:24), 2, 3, 4)
        #  the physical values of integers are 64-bit floating-point numbers, and are the values that are read
        mapped, eager = same(newfile("scaled.fits", [HDU(Primary, data, Card{<:Any}[Card("BSCALE", 0.1), Card("BZERO", 1.0)])]))
        @test mapped isa FITSFiles.MappedArray{Float64, 3} && mapped[2, 3, 4] == 1 + 0.1 * 24 && eltype(mapped) === Float64
        mapped, _ = same(newfile("scaled8.fits", [HDU(Primary, UInt8.(1:12), Card{<:Any}[Card("BSCALE", 0.5)])]))
        @test eltype(mapped) === Float32 && mapped[3] == 1.5f0
        #  the offsets of the types that have no unsigned or signed forms are the unsigned integers and the signed bytes
        for (type, offset, expected) in ((Int16, 32768, UInt16), (Int32, 2147483648, UInt32), (Int64, 9223372036854775808, UInt64), (UInt8, -128, Int8))
            mapped, _ = same(newfile("offset.fits", [HDU(Primary, type[1, 2, 3, 4], Card{<:Any}[Card("BZERO", offset)])]))
            @test eltype(mapped) === expected && mapped isa FITSFiles.MappedArray
        end
        #  the physical values of floating-point stored values are a ScaledArray that has the scale and the zero, whose slices are plain arrays
        fdata = reshape(Float32.(1:24), 2, 3, 4)
        mapped, eager = same(newfile("float.fits", [HDU(Primary), HDU(Image, fdata, Card{<:Any}[Card("BSCALE", 2.0), Card("BZERO", 10.0)])]), 2)
        @test mapped isa FITSFiles.ScaledArray && mapped.parent isa FITSFiles.MappedArray && (mapped.scale, mapped.zero) == (2.0, 10.0)
        @test mapped[2, 3, 4] == 58 && mapped[:, 1, 1] isa Vector{Float32} && mapped[:, 1, 1] == Float32[12, 14]
        @test mapped[1:2, 2:3, 1] isa Matrix{Float32} && mapped[1:2, 2:3, 1] == eager[1:2, 2:3, 1]
        #  the values are the stored values if the HDU was read without the scale
        for (hdu, j) in ((HDU(Primary, data, Card{<:Any}[Card("BSCALE", 0.1), Card("BZERO", 1.0)]), 1),)
            path = newfile("noscale.fits", [hdu])
            mapped, _ = same(path, 1; scale = false)
            @test mapped == data && eltype(mapped) === Int32
        end
        mapped, _ = same(newfile("noscale2.fits", [HDU(Primary), HDU(Image, fdata, Card{<:Any}[Card("BSCALE", 2.0), Card("BZERO", 10.0)])]), 2; scale = false)
        @test mapped isa FITSFiles.MappedArray && mapped == fdata
    end

    ####    The undefined values (Sect. 4.4.2.5)    ####

    @testset "BLANK" begin
        data = Int16[1 -1 3; -1 5 6]
        for hdus in ([HDU(Primary, data, Card{<:Any}[Card("BLANK", -1)])], [HDU(Primary), HDU(Image, data, Card{<:Any}[Card("BLANK", -1)])])
            j = length(hdus)
            path = newfile("blank.fits", hdus)
            mapped, eager = same(path, j)
            @test eltype(mapped) == Union{Int16, Missing} && isequal(collect(mapped), Union{Int16, Missing}[1 missing 3; missing 5 6])
            @test ismissing(mapped[1, 2]) && mapped[2, 2] === Int16(5) && ismissing(mapped[2]) && isequal(mapped[:, 2], [missing, 5])
            @test ismissing(mapped[1, 2]) && isequal(mapped[1:2, 2:3], Union{Int16, Missing}[missing 3; 5 6])
        end
        #  and the undefined values of the values that are scaled, whose scaled values are those that are defined
        path = newfile("blank_scaled.fits", [HDU(Primary, data, Card{<:Any}[Card("BLANK", -1), Card("BSCALE", 0.5), Card("BZERO", 1.0)])])
        mapped, _ = same(path)
        @test isequal(collect(mapped), [1.5 missing 2.5; missing 3.5 4.0])
        mapped, _ = same(path, 1; scale = false)
        @test isequal(collect(mapped), Union{Int16, Missing}[1 missing 3; missing 5 6])
    end

    ####    The conforming HDUs, whose data are those of the file    ####

    @testset "Conform" begin
        card(s) = rpad(s, 80)
        kw(key, value) = rpad(key, 8) * "=" * lpad(value, 21)
        header(cards) = rpad(join(card.([cards; "END"])), 2880)
        bytes(values) = (b = collect(reinterpret(UInt8, hton.(values))); [b; zeros(UInt8, 2880 - length(b) % 2880)])
        file(cards, values) = (path = joinpath(dir, "conform.fits"); write(path, [codeunits(header(cards)); bytes(values)]); path)
        values = Int16[1, 2, 3, 4, 5, 6]
        #  the data of the HDU of a file that does not conform are those of the file, whether or not the header has a scale
        for cards in ([kw("SIMPLE", "F"), kw("BITPIX", 16), kw("NAXIS", 2), kw("NAXIS1", 3), kw("NAXIS2", 2)],
            [kw("SIMPLE", "F"), kw("BITPIX", 16), kw("NAXIS", 2), kw("NAXIS1", 3), kw("NAXIS2", 2), kw("BSCALE", "2.0"), kw("BZERO", "1.0")])
            path = file(cards, values)
            mapped, eager = @test_logs (:warn, r"SIMPLE is F") (:warn, r"SIMPLE is F") same(path)
            @test @test_logs((:warn, r"SIMPLE is F"), getfield(fits(path)[1], :data)) isa FITSFiles.LazyArray
            @test mapped isa FITSFiles.MappedArray{Int16, 2} && mapped == reshape(values, 3, 2) && size(mapped) == (3, 2)
        end
        #  the data of a conforming extension that has a heap are a vector of the values of the file, which are not the size of the axes
        extension = ["XTENSION= 'FOREIGN '", kw("BITPIX", 16), kw("NAXIS", 2), kw("NAXIS1", 2), kw("NAXIS2", 2), kw("PCOUNT", 2), kw("GCOUNT", 1)]
        path = file(extension, values)
        mapped, eager = same(path)
        @test eager isa Vector{Int16} && mapped isa FITSFiles.MappedArray{Int16, 1} && mapped == values[1:6] && size(mapped) == (6,)
        #  the data of the extension whose data are the size of its axes are an array
        extension = ["XTENSION= 'FOREIGN '", kw("BITPIX", 16), kw("NAXIS", 2), kw("NAXIS1", 3), kw("NAXIS2", 2), kw("PCOUNT", 0), kw("GCOUNT", 1)]
        mapped, eager = same(file(extension, values))
        @test mapped isa FITSFiles.MappedArray{Int16, 2} && mapped == reshape(values, 3, 2)
    end

    ####    The HDUs that have no mapped data, and the file that is verified    ####

    @testset "other data and the file" begin
        data = Int16[1 2 3; 4 5 6]
        #  the HDU that has no data returns missing, and the data that are read, e.g., from a buffer, or are made, are returned as they are
        @test ismissing(mapdata(HDU(Primary))) && ismissing(mapdata(fits(newfile("none.fits", [HDU(Primary)]))[1]))
        buffered = fits(IOBuffer(read(newfile("buffer.fits", [HDU(Primary, data)]))))[1]
        @test mapdata(buffered) === getfield(buffered, :data) && mapdata(HDU(Primary, data)) == data
        #  an axis of length 0 has no data blocks, so the data are the empty array
        @test mapdata(fits(newfile("empty.fits", [HDU(Primary, zeros(Int16, 3, 0))]))[1]) == zeros(Int16, 3, 0)
        #  the tables are not an array, which is an error that names the type
        path = newfile("tables.fits", [HDU(Primary), HDU(Table, (a = [1, 2],))])
        @test_throws ArgumentError("The data of an HDU of the type Table are not an array, so they cannot be mapped.") mapdata(fits(path)[2])
        #  the file must not have been modified since the HDU was read, or have fewer bytes than the header says
        path = newfile("verify.fits", [HDU(Primary, data)])
        hdu = fits(path)[1]
        @test mapdata(hdu) == data
        sleep(0.05)
        touch(path)
        @test_throws ArgumentError r"has been modified since the HDU was read" mapdata(hdu)
        rm(path)
        @test_throws ArgumentError r"does not exist" mapdata(hdu)
        path = newfile("short.fits", [HDU(Primary, zeros(Int16, 1000))])
        open(path, "r+") do io
            truncate(io, 2880 + 500)
        end
        @test_throws ArgumentError r"The data of the HDU are 2000 bytes, as its header says, but the file has only 500 of them" mapdata(fits(path)[1])
        #  the array that is mapped is valid when the file that it is read from is closed and the other HDUs of the file are mapped
        path = newfile("many.fits", [HDU(Primary, data), HDU(Image, Float32[1 2; 3 4]), HDU(Image, Int32[5 6; 7 8])])
        hdus = fits(path)
        maps = [mapdata(hdu) for hdu in hdus]
        @test maps[1] == data && maps[2] == Float32[1 2; 3 4] && maps[3] == Int32[5 6; 7 8]
        #  and is valid after the working directory is changed, since the name of the file is its absolute path
        mapped = cd(() -> mapdata(fits("many.fits")[2]), dir)
        @test mapped == Float32[1 2; 3 4]
    end

    ####    The array of a file, whose values are decoded as the values that are indexed    ####

    @testset "MappedArray" begin
        #  the values are those of the file, whose values are in the byte order of the file, and the decoded values are the values of the array
        values = hton.(Int16[1, 2, 3, 4, 5, 6])
        array = FITSFiles.MappedArray(values, (3, 2), identity)
        @test array == Int16[1 4; 2 5; 3 6] && array[2, 2] === Int16(5) && array[:, 1] == Int16[1, 2, 3] && array[end] === Int16(6)
        array = FITSFiles.MappedArray(values, (3, 2), raw -> Int16(2) .* raw)
        @test eltype(array) === Int16 && array == Int16[2 8; 4 10; 6 12] && array[2:3, 2] == Int16[10, 12] && array[3] === Int16(6)
        array = FITSFiles.MappedArray(values, (6,), raw -> Union{Float32, Missing}[x == 3 ? missing : Float32(x) for x in raw])
        @test eltype(array) == Union{Float32, Missing} && isequal(collect(array), [1, 2, missing, 4, 5, 6]) && ismissing(array[3])
        #  a slice and a copy are arrays that do not read the file again, and a scalar index of a slice is a value
        array = FITSFiles.MappedArray(values, (3, 2), identity)
        @test copy(array) == array && copy(array) isa Matrix{Int16} && array[CartesianIndex(2, 1)] === Int16(2) && array[2:3, :] isa Matrix{Int16}
        @test array[Int8(2), Int8(2)] === Int16(5) && array[2, :] isa Vector{Int16} && array[2, 2:2] == Int16[5]
        #  the sum of the values that are read are those of the array
        @test sum(array) == sum(Int16[1 4; 2 5; 3 6]) && maximum(array) == Int16(6) && size(array, 1) == 3 && length(array) == 6 && axes(array) == (1:3, 1:2)
    end
    ####    The keyword access, which says how the data of a file are accessed    ####

    @testset "access" begin
        data = reshape(Int16[1:24;], 2, 3, 4)
        fdata = Float32[1.5 2.5; -1 7]
        table = HDU(Table, (a = [1, 2],))
        path = newfile("access.fits", [HDU(Primary, data), HDU(Image, fdata, Card{<:Any}[Card("BSCALE", 2.0), Card("BZERO", 10.0)]), table])
        original = read(path)
        bytesof(hdus; kwds...) = (io = IOBuffer(); write(io, hdus; kwds...); take!(io))
        #  the data are lazy by default, as they were, and are all lazy if they are, which are read each time that they are accessed
        lazy = fits(path)
        @test all(hdu -> getfield(hdu, :data) isa FITSFiles.LazyArray, lazy) && fits(path; access = :lazy)[1].data == data
        @test lazy[1].data isa Array && lazy[1].data !== lazy[1].data
        #  the data are read at once if the access is :memory, and are those that are read from a buffer
        memory = fits(path; access = :memory)
        @test !any(hdu -> getfield(hdu, :data) isa FITSFiles.LazyArray, memory) && memory[1].data == data && memory[1].data isa Array
        #  the data of an array are mapped if the access is :mapped, and are the same array when they are accessed, and the other HDUs are lazy
        mapped = fits(path; access = :mapped)
        @test mapped[1].data isa FITSFiles.MappedArray && mapped[2].data isa FITSFiles.ScaledArray && mapped[2].data.parent isa FITSFiles.MappedArray
        @test mapped[1].data === mapped[1].data && getfield(mapped[3], :data) isa FITSFiles.LazyArray
        @test mapped[1].data == data && mapped[2].data == memory[2].data && mapped[1].data == mapdata(lazy[1]) && mapdata(mapped[1]) === mapped[1].data
        @test size(mapped[1]) == (2, 3, 4) && collect(mapped[1].data) == data && mapped[1].data[2, 3, 4] === Int16(24)
        #  the keywords of the data are those of the read, e.g., the data of a file that is read without the scale are the stored values
        @test fits(path; access = :mapped, scale = false)[2].data == fdata && eltype(fits(path; access = :mapped, scale = false)[2].data) === Float32
        @test fits(path; access = :mapped, scale = false)[2].data isa FITSFiles.MappedArray
        #  and the access is a symbol of the three, or an error, and the data of a stream that is not a file cannot be mapped
        @test_throws ArgumentError("The access of the data is :memory, :lazy, or :mapped, but it is :other.") fits(path; access = :other)
        @test_throws ArgumentError("The access of the data is :memory, :lazy, or :mapped, but it is \"lazy\".") fits(path; access = "lazy")
        @test_throws ArgumentError r"The data of an HDU can only be mapped from a file, and not from IOBuffer" fits(IOBuffer(original); access = :mapped)
        @test fits(IOBuffer(original); access = :memory)[1].data == data && fits(IOBuffer(original); access = :lazy)[1].data == data
        @test open(io -> read(io, HDU; access = :mapped), path).data isa FITSFiles.MappedArray

        #  the HDUs are written as the file is, whether their data are lazy or mapped, with the checksums, and a change of the header
        @test bytesof(mapped) == original && bytesof(lazy) == original && bytesof(mapped; checksum = true) == bytesof(memory; checksum = true)
        write(joinpath(dir, "copy.fits"), mapped)
        @test read(joinpath(dir, "copy.fits")) == original
        cards = copy(getfield(mapped[1], :cards))
        push!(cards, Card("OBJECT", "changed"))
        again = fits(IOBuffer(bytesof([HDU{Primary}(cards, mapped[1].data)])))
        @test again[1].cards["OBJECT"] == "changed" && again[1].data == data
        #  but not the type and the size of the data, which are those of the file, and not to the file that the data are mapped from
        cards = copy(getfield(mapped[1], :cards))
        cards["NAXIS1"] = 4
        @test_throws ArgumentError r"The header of the HDU has a data format that is not that of the data of the file that were not read" bytesof(
            [HDU{Primary}(cards, mapped[1].data)])
        @test_throws ArgumentError r"The data of HDU 1 are not read, and are read from .*access\.fits, which opening it for writing empties" write(path, mapped)
        @test_throws ArgumentError r"The data of HDU 2 are not read" write(path, [HDU(Primary), mapped[2]])
        @test read(path) == original
        #  the file that was modified after the HDU was read is an error when the data are written, but the array is the data that were mapped
        sleep(0.05)
        touch(path)
        @test_throws ArgumentError r"has been modified since the HDU was read" bytesof(mapped)
        @test_throws ArgumentError r"has been modified since the HDU was read" mapdata(lazy[1])
        #  the array is read-only, which is an error that says how to change the values
        array = mapdata(fits(newfile("readonly.fits", [HDU(Primary, data)]))[1])
        @test_throws ArgumentError r"A mapped array of the data of an HDU is read-only" array[1] = 5
        @test_throws ArgumentError r"is read-only" array[1, 2, 3] = Int16(0)
        @test_throws ArgumentError r"is read-only" array[:, 1, 1] .= 0
        changed = collect(array)
        changed[1] = 99
        @test changed[1] == 99 && array[1] == 1
    end

    ####    The value that is indexed, which is the value of the array that is read    ####

    @testset "values" begin
        #  the function of one stored value gives the value that the function of an array gives, of the same type, for every type and every scale
        scales = ((1.0, 0.0), (1.0, 32768.0), (1.0, 2147483648.0), (1, 9223372036854775808), (1, -128), (1.0f0, 5.0f0), (0.1, 1.0), (2.0f0, 10.0f0),
            (0.5, 0), (1, 0), (3, 7), (1.0, 5.0), (1e-3, 1e5), (0.5f0, 0.0))
        for type in (UInt8, Int16, Int32, Int64, Float32, Float64), (scale, zero) in scales
            raw = type <: Integer ? rand(type, 50) : type[0, -0.0, 1, -1, 1.5, NaN, Inf, -Inf, rand(type, 20)...]
            array = FITSFiles.physical(raw, type, scale, zero)
            one = FITSFiles.physicalfunction(type, scale, zero)
            @test isequal(array, one.(raw)) && eltype(array) === eltype(one.(raw)) && isequal([one(x) for x in raw], array)
        end
        #  and the value of the mapped array, which is read one at a time, is the value of the array that is read, with and without a BLANK
        data = Int16[1 -1 3; -1 5 6]
        for cards in (Card{<:Any}[], Card{<:Any}[Card("BLANK", -1)], Card{<:Any}[Card("BSCALE", 0.5), Card("BZERO", 1.0)],
            Card{<:Any}[Card("BLANK", -1), Card("BSCALE", 0.5), Card("BZERO", 1.0)], Card{<:Any}[Card("BZERO", 32768)])
            path = newfile("values.fits", [HDU(Primary, data, cards)])
            mapped, eager = mapdata(fits(path)[1]), fits(IOBuffer(read(path)))[1].data
            @test isequal([mapped[i] for i in eachindex(eager)], vec(collect(eager))) && isequal(collect(mapped), collect(eager))
            @test all(i -> typeof(mapped[i]) == typeof(eager[i]), eachindex(eager))
            @test isequal([mapped[i, j] for i = 1:2, j = 1:3], collect(eager))
        end
        #  the values of the array are read without the allocation of an array of a value
        array = mapdata(fits(newfile("fast.fits", [HDU(Primary, rand(Float32, 100, 100))]))[1])
        array[1]; array[5, 5]
        @test (@allocated array[1234]) < 100 && (@allocated array[7, 9]) < 100
        @test sum(array) ≈ sum(collect(array))
    end

    ####    The random groups, whose fields are not together in the file    ####

    @testset "Random groups" begin
        #  the fields of random groups are those that are read: the same names, the types, the values, and the slices of the arrays and the parameters
        function samegroups(path; kwds...)
            mapped = mapdata(fits(path; kwds...)[1])
            eager = fits(IOBuffer(read(path)); kwds...)[1].data
            @test mapped isa NamedTuple && keys(mapped) == keys(eager)
            for name in keys(eager)
                compare(mapped[name], eager[name])
            end
            mapped, eager
        end
        data = reshape(Float32[1:36;], 3, 3, 4)
        plain = (UU = Float32[1, 2, 3], DATE = Float32[1 2; 3 4; 5 6], data = data)
        for hdu in (HDU(Random, plain), HDU(Random, (a = Int16[1, 3, 5], b = Int16[2, 4, 6])), HDU(Random, (p = UInt8[1, 2], data = UInt8[1 2 3; 4 5 6])),
            HDU(Random, (p = Int32[1, 2], q = Int32[3, 4], data = reshape(Int32[1:24;], 2, 3, 4))),
            HDU(Random, (p = rand(2), data = rand(2, 2, 2))), HDU(Random, (p = rand(Float32, 4), DATE = rand(Float32, 4, 3), data = rand(Float32, 4, 5))))
            mapped, eager = samegroups(newfile("groups.fits", [hdu]))
        end
        mapped, eager = samegroups(newfile("groups.fits", [HDU(Random, plain)]))
        @test mapped.UU isa FITSFiles.MappedField{Float32, 1} && mapped.DATE isa FITSFiles.MappedColumns && mapped.data isa FITSFiles.MappedField{Float32, 3}
        @test size(mapped.UU) == (3,) && size(mapped.DATE) == (3, 2) && size(mapped.data) == (3, 3, 4)
        @test copy(mapped.data) == eager.data && copy(mapped.data) isa Array{Float32, 3} && copy(mapped.UU) == eager.UU
        @test mapped.data[2, 3, 4] === Float32(35) && mapped.DATE[3, 2] === 6f0 && mapped.UU[3] === 3f0 && mapped.data[:, 1, 1] == Float32[1, 2, 3]
        @test mapped.data[2, :, :] isa Matrix{Float32} && mapped.UU[2:3] isa Vector{Float32} && mapped.DATE[:, 2] isa Vector{Float32}
        #  the offsets of Table 11 of the parameters and the array, the scales, and the undefined values of the array, with the integers that are scaled
        for cards in (Card{<:Any}[Card("PZERO1", 32768), Card("PZERO2", 32768), Card("BZERO", 32768)],
            Card{<:Any}[Card("PSCAL1", 0.1), Card("PZERO1", 1.0), Card("PSCAL2", 0.5), Card("BSCALE", 0.25), Card("BZERO", 2.0)],
            Card{<:Any}[Card("BLANK", -1), Card("BSCALE", 0.5)], Card{<:Any}[Card("BLANK", -1)],
            Card{<:Any}[Card("PSCAL1", 2.0), Card("PZERO1", 10.0)])
            ints = HDU(Random, (p = Int16[1, -2], q = Int16[3, 4], data = Int16[1 -1 3; -1 5 6]), cards)
            mapped, eager = samegroups(newfile("groups.fits", [ints]))
            mapped, eager = samegroups(newfile("groups.fits", [ints]); scale = false)
        end
        #  the physical values of floating-point stored values are a ScaledArray of every field, which have the scales and the zeros of the parameters
        cards = Card{<:Any}[Card("PSCAL1", 2.0), Card("PZERO1", 10.0), Card("PSCAL2", 3.0), Card("PZERO2", -1.0), Card("PSCAL3", 0.5), Card("BSCALE", 2.0)]
        mapped, eager = samegroups(newfile("groups.fits", [HDU(Random, plain, cards)]))
        @test all(name -> mapped[name] isa FITSFiles.ScaledArray, keys(mapped)) && mapped.DATE.scale == eager.DATE.scale && mapped.DATE.zero == eager.DATE.zero
        @test mapped.UU.scale == eager.UU.scale && mapped.data.parent isa FITSFiles.MappedField && mapped.DATE.parent isa FITSFiles.MappedColumns
        mapped, eager = samegroups(newfile("groups.fits", [HDU(Random, plain, cards)]); scale = false)
        @test !any(name -> mapped[name] isa FITSFiles.ScaledArray, keys(mapped))
        #  a slice of a field of the groups and its bounds
        @test_throws BoundsError mapped.data[4, 1, 1]
        @test_throws BoundsError mapped.data[1, 4, 1]
        @test_throws BoundsError mapped.data[1:4, 1, 1]
        @test_throws BoundsError mapped.UU[0]
        @test_throws BoundsError mapped.DATE[1, 3]
        @test_throws ArgumentError r"A mapped field of the data of an HDU is read-only" mapped.UU[1] = 0
        @test_throws ArgumentError r"The mapped parameters of the data of an HDU are read-only" mapped.DATE[1, 1] = 0

        #  the access :mapped maps the groups, and is written as the file is, but the records cannot be mapped, and are lazy
        path = newfile("access_groups.fits", [HDU(Random, plain, cards)])
        original = read(path)
        bytesof(hdus; kwds...) = (io = IOBuffer(); write(io, hdus; kwds...); take!(io))
        hdus = fits(path; access = :mapped)
        @test hdus[1].data isa NamedTuple && hdus[1].data.data isa FITSFiles.ScaledArray && hdus[1].data === hdus[1].data
        @test bytesof(hdus) == original && bytesof(hdus; checksum = true) == bytesof(fits(path; access = :memory); checksum = true)
        @test_throws ArgumentError r"The data of HDU 1 are not read, and are read from .*access_groups\.fits" write(path, hdus)
        @test read(path) == original
        @test getfield(fits(path; access = :mapped, record = true)[1], :data) isa FITSFiles.LazyArray
        @test_throws ArgumentError("The data of random groups that are records cannot be mapped.") mapdata(fits(path; record = true)[1])
        @test mapdata(hdus[1]) === hdus[1].data
        #  a field that is read replaces a field that is mapped, and then the groups are written as the values are, which are those of the file
        path = newfile("mixed.fits", [HDU(Random, plain)])
        mapped = fits(path; access = :mapped)[1]
        mixed = HDU{Random}(getfield(mapped, :cards), (UU = collect(mapped.data.UU), DATE = mapped.data.DATE, data = mapped.data.data))
        @test bytesof([mixed]) == read(path)
        #  and the parameter of a group that is indexed is read without the allocation of an array of a value
        allocated3(x) = (x[2, 2, 2]; @allocated x[2, 2, 2])
        allocated1(x) = (x[2]; @allocated x[2])
        @test allocated3(mapped.data.data) < 200 && allocated1(mapped.data.UU) < 200
        #  the file that was modified after the HDU was read is an error
        sleep(0.05)
        touch(path)
        @test_throws ArgumentError r"has been modified since the HDU was read" bytesof([mapped])
    end

    ####    The binary tables, whose fields of numbers of a fixed number of elements are mapped    ####

    @testset "Bintable" begin
        function sametable(path, j = 2; kwds...)
            mapped = mapdata(fits(path; kwds...)[j])
            eager = fits(IOBuffer(read(path)); kwds...)[j].data
            @test mapped isa NamedTuple && keys(mapped) == keys(eager)
            for name in keys(eager)
                if mapped[name] isa FITSFiles.MappedColumn || mapped[name] isa FITSFiles.ScaledArray
                    compare(mapped[name], eager[name]; undefined = true)
                else
                    @test isequal(mapped[name], eager[name]) && typeof(mapped[name]) == typeof(eager[name])
                end
            end
            mapped, eager
        end
        bytesof(hdus; kwds...) = (io = IOBuffer(); write(io, hdus; kwds...); take!(io))
        #  every type of number, of one value or of many in a row, and the arrays of the rows of the dimensions TDIMn
        for type in (UInt8, Int16, Int32, Int64, Float32, Float64)
            data = (one = type.(1:5), many = type.(reshape(1:15, 5, 3)), array = type.(reshape(1:30, 5, 2, 3)), cube = type.(reshape(1:120, 5, 2, 3, 4)))
            mapped, eager = sametable(newfile("numbers.fits", [HDU(Primary), HDU(Bintable, data)]))
            @test all(column -> column isa FITSFiles.MappedColumn, values(mapped))
            @test size(mapped.one) == (5,) && size(mapped.many) == (5, 3) && size(mapped.array) == (5, 2, 3) && size(mapped.cube) == (5, 2, 3, 4)
            @test mapped.array[3, 2, 3] === type(3 + 5 * (2 - 1) + 10 * (3 - 1)) && mapped.many[2, 3] === type(12) && mapped.one[5] === type(5)
            @test mapped.cube[:, 1, 2, :] isa Matrix{type}
            @test mapped.many[:, 2] == eager.many[:, 2] && mapped.many[2, :] == eager.many[2, :] && mapped.one[2:4] isa Vector{type}
        end
        #  the HDU is written as it is read, when all of its fields are mapped, and the data are not read to write them
        path = newfile("rawtable.fits", [HDU(Primary), HDU(Bintable, (a = Int16[1, 2, 3], b = Float64[1.5 2.5; 3.5 4.5; 5.5 6.5]))])
        hdus = fits(path; access = :mapped)
        @test bytesof(hdus) == read(path) && bytesof(hdus; checksum = true) == bytesof(fits(path; access = :memory); checksum = true)
        @test FITSFiles.lazysource(hdus[2].data) isa FITSFiles.LazyArray
        @test_throws ArgumentError r"The data of HDU 2 are not read, and are read from .*rawtable\.fits" write(path, hdus)
        @test read(path) == bytesof(hdus)
        #  the scale, the offsets of Table 19, and the undefined values
        cards = Card{<:Any}[Card("TZERO1", 32768), Card("TSCAL2", 0.5), Card("TZERO2", 1.0), Card("TNULL3", -1), Card("TSCAL4", 2.5), Card("TZERO4", 10.0),
            Card("TSCAL5", 3.0), Card("TNULL5", 7), Card("TZERO6", -128)]
        data = (a = Int16[-5, 0, 5], b = Int32[1, 2, 3], c = Int16[-1, 2, 3], d = Float32[1, 2, 3], e = Int64[1, 7, 9], f = UInt8[1, 2, 3])
        path = newfile("scaled.fits", [HDU(Primary), HDU(Bintable, data, cards)])
        for kwds in ((;), (; scale = false))
            mapped, eager = sametable(path; kwds...)
            @test (mapped.d isa FITSFiles.ScaledArray) == !haskey(kwds, :scale) && mapped.c isa FITSFiles.MappedColumn
        end
        @test bytesof(fits(path; access = :mapped)) == read(path) && bytesof(fits(path; access = :mapped, scale = false)) == read(path)
        #  the undefined values are missing, in the values and in the slices
        mapped = fits(path; access = :mapped)[2].data
        @test eltype(mapped.c) == Union{Missing, Int16} && ismissing(mapped.c[1]) && mapped.c[2] === Int16(2) && ismissing(mapped.c[1:2][1])
        @test ismissing(mapped.e[2]) && mapped.e[3] === 27.0 && ismissing(mapped.e[1:3][2])
        #  the logicals, the bits, the characters, and the complex numbers are mapped, and the arrays of variable length, which are in the heap, are read at once
        data = (a = Int32[1, 2, 3, 4], l = [true, false, true, true], bits = [BitVector([1, 0, 1]) for _ in 1:4], name = ["x", "yy", "z", "w"],
            v = [Int16[1], Int16[1, 2], Int16[], Int16[4, 5, 6]], z = ComplexF32[1 + 2im, 3, 4, 5im], b = Float64[1, 2, 3, 4])
        path = newfile("mixed.fits", [HDU(Primary), HDU(Bintable, data)])
        mapped, eager = sametable(path)
        @test all(name -> mapped[name] isa FITSFiles.MappedColumn, (:a, :b, :l, :bits, :name, :z)) && !(mapped.v isa FITSFiles.MappedColumn)
        @test eltype(mapped.l) == Union{Missing, Bool} && eltype(mapped.z) == Union{Missing, ComplexF32} && eltype(mapped.name) == String
        #  and then the HDU is written as the values are, and the file that has the mapped fields is not written
        hdus = fits(path; access = :mapped)
        @test isnothing(FITSFiles.lazysource(hdus[2].data)) && FITSFiles.filesource(hdus[2].data) isa FITSFiles.LazyArray
        @test bytesof(hdus) == bytesof(fits(path; access = :memory))
        @test_throws ArgumentError r"The data of HDU 2 are not read, and are read from .*mixed\.fits" write(path, hdus)
        other = joinpath(dir, "mixed2.fits")
        write(other, hdus)
        @test bytesof(fits(other; access = :memory)) == bytesof(fits(path; access = :memory))
        #  a table that has only fields of variable length has the fields that are read
        path = newfile("variable.fits", [HDU(Primary), HDU(Bintable, (v = [Int16[1], Int16[2, 3]], w = [Int32[], Int32[4]]))])
        mapped, eager = sametable(path)
        @test mapped.v == eager.v && !any(column -> column isa FITSFiles.MappedColumn, values(mapped))
        #  the logicals have an undefined value that is a 0 byte, and their type has `missing` whether or not there is one
        data = (l = [true, false, true], u = Union{Missing, Bool}[true, missing, false], m = Union{Missing, Bool}[true missing; false true; missing false])
        path = newfile("logicals.fits", [HDU(Primary), HDU(Bintable, data)])
        mapped, eager = sametable(path)
        @test eltype(mapped.l) == Union{Missing, Bool} && eltype(eager.l) == Bool && eltype(mapped.u) == eltype(eager.u) == Union{Missing, Bool}
        @test mapped.l[1] === true && mapped.l[2] === false && ismissing(mapped.u[2]) && mapped.u[3] === false && ismissing(mapped.m[3, 1])
        @test isequal(mapped.m[:, 2], eager.m[:, 2]) && isequal(mapped.u[1:2], eager.u[1:2]) && eltype(mapped.l[1:2]) == Union{Missing, Bool}
        #  the complex numbers that have a NaN are undefined, and are scaled
        z = ComplexF32[1 + 2im, NaN + 0im, 3, 4 + NaN * im]
        cards = Card{<:Any}[Card("TSCAL2", 2.0), Card("TZERO2", 1.0)]
        data = (z = z, s = ComplexF32[1 + 2im, 3im, 4, 5], d = ComplexF64[1 2; 3 4; 5 6; 7 8])
        path = newfile("complex.fits", [HDU(Primary), HDU(Bintable, data, cards)])
        for kwds in ((;), (; scale = false))
            mapped, eager = sametable(path; kwds...)
            @test eltype(mapped.z) == Union{Missing, ComplexF32} && ismissing(mapped.z[2]) && ismissing(mapped.z[4]) && mapped.z[3] === 3f0 + 0im
            @test (mapped.s isa FITSFiles.ScaledArray) == !haskey(kwds, :scale) && mapped.d[2, 2] === 4.0 + 0im && mapped.d[4, :] == [7.0, 8.0] + 0im * [1, 1]
        end
        #  and the bytes of the undefined values are those of the file, since all of the fields are mapped and are copied as they are
        @test bytesof(fits(path; access = :mapped)) == read(path)
        #  the strings, whose spaces after the characters are not part of the value, and the arrays of strings, which have the characters of the first
        #  dimension of TDIMn in the field, and are in the later dimensions
        data = (s = ["a", "bcd", "", "ef"], t = ["ab" "cd" "ef"; "gh" "ij" "kl"; "m" "n" "o"; "" "p" "q"])
        path = newfile("strings.fits", [HDU(Primary), HDU(Bintable, data)])
        mapped, eager = sametable(path)
        @test eltype(mapped.s) == String && size(mapped.s) == (4,) && size(mapped.t) == (4, 3) && mapped.s[2] == "bcd" && mapped.s[3] == "" && mapped.t[4, 1] == ""
        @test mapped.t[2:3, 2:3] == eager.t[2:3, 2:3] && mapped.t[1, :] == ["ab", "cd", "ef"] && mapped.s[:] == eager.s
        #  the bits, and the arrays of them that the dimensions TDIMn give, which have no more elements than the bits
        bits = [BitVector([1, 0, 1, 1, 0, 0]), BitVector([0, 1, 0, 0, 1, 1]), BitVector([1, 1, 1, 0, 0, 0])]
        for (card, size) in ((Card{<:Any}[], (6,)), (Card{<:Any}[Card("TDIM1", "(2,3)")], (2, 3)), (Card{<:Any}[Card("TDIM1", "(4,3)")], (6,)))
            path = newfile("bits.fits", [HDU(Primary), HDU(Bintable, (bits = bits,), card)])
            mapped, eager = @test_logs(match_mode = :any, sametable(path))
            @test mapped.bits[2] == eager.bits[2] && Base.size(mapped.bits[2]) == size && mapped.bits[2:3] == eager.bits[2:3]
        end
        #  the dimensions TDIMn that have more elements than the field, which are warned of and not used, as they are read
        path = newfile("dims.fits", [HDU(Primary), HDU(Bintable, (a = Int16.(reshape(1:12, 4, 3)),), Card{<:Any}[Card("TDIM1", "(2,3)")])])
        mapped = @test_logs (:warn, r"TDIM of field a") match_mode = :any mapdata(fits(path)[2])
        @test size(mapped.a) == (4, 3) && mapped.a == fits(IOBuffer(read(path)))[2].data.a
        #  the values of the bounds and of the changes, and the records are not mapped
        mapped = fits(path; access = :mapped)[2].data
        @test_throws BoundsError mapped.a[5, 1]
        @test_throws BoundsError mapped.a[1, 4]
        @test_throws BoundsError mapped.a[0]
        @test_throws BoundsError mapped.a[1:5, 1]
        @test_throws ArgumentError r"A mapped field of the data of an HDU is read-only" mapped.a[1] = 0
        @test copy(mapped.a) isa Matrix{Int16} && copy(mapped.a) == collect(mapped.a) && mapped.a[2] === Int16(2)
        @test getfield(fits(path; access = :mapped, record = true)[2], :data) isa FITSFiles.LazyArray
        @test_throws ArgumentError("The data of a binary table that are records cannot be mapped.") mapdata(fits(path; record = true)[2])
        #  the values of a row are those of the file, without the allocation of the array of a value
        path = newfile("alloc.fits", [HDU(Primary), HDU(Bintable, (a = Int32[1, 2, 3], b = Float32[1 2; 3 4; 5 6]))])
        hdus = fits(path; access = :mapped)
        mapped = hdus[2].data
        allocated1(x) = (x[2]; @allocated x[2])
        allocated2(x) = (x[2, 2]; @allocated x[2, 2])
        @test allocated1(mapped.a) < 200 && allocated2(mapped.b) < 200
        #  the file that was modified after the HDU was read is an error
        sleep(0.05)
        touch(path)
        @test_throws ArgumentError r"has been modified since the HDU was read" bytesof(hdus)
    end

end

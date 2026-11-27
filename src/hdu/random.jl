####    Random HDU functions

"""
	Random header-data unit (HDU)

A Random HDU consists of a vector of cards and optionally a vector of records
containing a list of parameters followed by a multidimensional array. The
Random HDU is the first HDU in a vector of HDUs.

The data are a named tuple of arrays, or, with `record = true`, a vector of named tuples, one for each group. The
parameters are named by their PTYPEn keywords (or `param1`, `param2`, ... if there are none) and the array of a group is
named `data`, so a parameter whose PTYPEn is `data` is named `param<n>` (see the warning). The groups are along the first
axis of the array. Parameters that have the same name are the columns of one array, whose sum along its columns is the
value of the parameter (Sect. 6.1.2 of the standard), so that the parameters are written as they were read, and
`sum(data.DATE; dims = 2)` (`sum(record.DATE)` in a record) is the value of the parameter `DATE`. The data
are written by position, so the names of the data do not have to be the names of the header.

The parameters and the array have the same type, which is the type of BITPIX (Sect. 6.3). The data are read with
PSCALn and PZEROn applied to the parameters and BSCALE and BZERO to the array, unless `scale = false` is given, and the
values that are not of the type of BITPIX are written as the stored values (see [`Base.write(io::IO, hdu::HDU)`](@ref)).
A parameter with the PSCALn of 1 and the PZEROn of the offsets of Table 11 (Sect. 5.2.5, which Sect. 6.3 gives to
the parameters), and the array with the BSCALE of 1 and the BZERO of the offsets, are the unsigned integers or the signed
bytes: `UInt16`, `UInt32`, `UInt64`, or `Int8`, for the values of 16-, 32-, or 64-bit integers, or bytes. Data of those
types have the PZEROn and BZERO keywords of the offsets when the HDU is made.

A header with an NAXIS of 1 has no axes in the array of a group, and so one value in each group (Eq. 6 of the standard), which is
a vector of the groups in the data, and a number in a record. Data of a vector are a table by default, so make them with `HDU(Random, data)`.

The elements of the array of integers that are the stored value of BLANK are `missing` (Sect. 4.4.2.5), with and without
`scale = false`, and are written as BLANK. The parameters do not have undefined values.
"""
struct Random <: AbstractHDU end

#  Random groups are tried before the Primary HDU and the Bintable HDU, whose data and header they also fit. The data are records
#  whose last element, the data of a group, is an array of 2 or more dimensions, and the header has GROUPS = T and NAXIS1 = 0.
detectpriority(::Type{Random}) = 1
function fromdata(::Type{Random}, data)
    record = firstrecord(data)
    record !== nothing && record[end] isa AbstractArray && ndims(record[end]) >= 2
end
function frommandatory(::Type{Random}, mankeys)
    !haskey(mankeys, "XTENSION") && get(mankeys, "SIMPLE", nothing) === true &&
        get(mankeys, "GROUPS", false) === true && haskey(mankeys, "NAXIS1") && mankeys["NAXIS1"] == 0
end
registerhdu!(Random)

#  The mandatory and reserved keywords of the HDU (see `getreservedkeys`)
union!(MANDATORYKEYS, ["SIMPLE", "GROUPS", "PCOUNT", "GCOUNT"])
union!(RESERVEDKEYS, ["PTYPE", "PSCAL", "PZERO", "EXTEND", "BLOCKED", "BSCALE", "BZERO", "BUNIT", "BLANK", "DATAMAX",
    "DATAMIN"])

"""
    RandomField(name, index, type, slice, leng, shape, zero, scale, miss)

Random array element descriptor. `miss` is the value of BLANK, the stored value of an undefined element, for the array
of a group (Sect. 4.4.2.5), and is nothing for a parameter and for an array without a BLANK.
"""
struct RandomField <: AbstractField
    "The name of the field"
    name::String
    "The index of the field for common name fields"
    index::Int
    "The type of the field"
    type::Type
    "The slice of the field bytes from start of record"
    slice::UnitRange{Int}
    "The number of elements in the field"
    leng::Int
    "The dimensions of the field"
    shape::Tuple{Vararg{Int}}
    "The offset value of the field"
    zero::Union{AbstractFloat, Missing}
    "The scale factor of the field"
    scale::Union{AbstractFloat, Missing}
    "The value representing a missing value of the field"
    miss::Union{Integer, Nothing}
end

RandomField(name, index, type, slice, leng, shape, zero, scale) =
    RandomField(name, index, type, slice, leng, shape, zero, scale, nothing)

#  The keywords of the cards that are given with the data of an HDU that is made are verified (see `verifycardkeys`)
#  The number of parameters of random groups is that of the data, and the keywords of the parameters are verified with it
verifycards!(::Type{Random}, cards::Cards, mankeys::AbstractDict, reskeys::AbstractDict, format::DataFormat) =
    verifycardkeys(Random, cards, merge(mankeys, Dict("PCOUNT" => format.param)), reskeys)

#  The fill after the data (see `verifyfill`)
fillrule(::Type{Random}) = (0x00, "zeros", "Sect. 6.2")

#  The names of the parameters, which are the PTYPEn keywords, or param1, param2, ... for those that are absent. The
#  array of a group is named data, so a parameter whose name is data is named param<n>, where n is the number of the first
#  such parameter, or param_<n>, param__<n>, ... if that is the name of another parameter. The header is not changed.
ptypenames(reskeys::AbstractDict, P::Integer) = [rstrip(get(reskeys, "PTYPE$j", "param$j")) for j = 1:P]
function paramnames(reskeys::AbstractDict, P::Integer)
    names = ptypenames(reskeys, P)
    n = findfirst(==("data"), names)
    isnothing(n) && return names
    k = 0
    while "param" * "_"^k * string(n) in names
        k += 1
    end
    replace(names, "data" => "param" * "_"^k * string(n))
end

#  The keywords of the parameters, PTYPEn, PSCALn, and PZEROn (Sect. 6.1.2): the name of a parameter is a character string, and
#  its scale and zero are numbers, since the parameters cannot be read otherwise, so it is an error if they are not. A keyword
#  of a number n that is not of a parameter, which is from 1 to PCOUNT, is not used, so it is a warning, and so is a
#  PSCALn of 0, which makes every physical value of the parameter its PZEROn.
function verifyparamkeys(reskeys::AbstractDict, P::Integer)
    for key in sort!(collect(keys(reskeys)))
        m = match(r"^(PTYPE|PSCAL|PZERO)(\d+)$", key)
        isnothing(m) && continue
        n = Base.parse(Int, m[2])
        if n > P
            @warn "$key is beyond PCOUNT $P, and is not used."
            continue
        elseif n < 1
            @warn "$key is not the keyword of a parameter, which is numbered from 1, and is not used."
            continue
        end
        value = reskeys[key]
        if m[1] == "PTYPE"
            value isa AbstractString || throw(ArgumentError(
                "$key must be a character string, but its value is $(repr(value))."))
        else
            value isa Real && !(value isa Bool) || throw(ArgumentError(
                "$key must be a number, but its value is $(repr(value))."))
            m[1] == "PSCAL" && value == 0 && @warn "$key is 0, so every physical value of the parameter is its " *
                "PZERO$n, and its stored values cannot be written from them. It is read as it is."
        end
    end
end

#  Warn of the names of the parameters that are not what the header says: a PTYPEn of data, which is renamed, and an
#  absent PTYPEn whose default name param<n> is the name of another parameter, so the parameters are one parameter
#  that is the sum of them (Sect. 6.1.2 of the standard).
function verifyparams(reskeys::AbstractDict, P::Integer)
    names = ptypenames(reskeys, P)
    data = findall(==("data"), names)
    if !isempty(data)
        keys = join(["PTYPE$j" for j in data], ", ", " and ")
        @warn "$keys of the random groups $(length(data) > 1 ? "are" : "is") 'data', which is the name of the array of " *
            "a group, so the parameter is named $(paramnames(reskeys, P)[first(data)]). The header is not changed."
    end
    for j = 1:P
        haskey(reskeys, "PTYPE$j") && continue
        k = findfirst(i -> i != j && names[i] == names[j], 1:P)
        isnothing(k) || @warn "PTYPE$j is absent, so the parameter is named $(names[j]), which is also the name of " *
            "PTYPE$k. The parameters of the same name are one parameter, which is the sum of them (Sect. 6.1.2)."
    end
end

function Base.read(io::IO, ::Type{Random}, format::DataFormat,
    fields::Vector{RandomField}; record::Bool = false, scale::Bool = true, kwds...)

    P, G, shape = format.param, format.group, format.shape
    #  The values of the groups, one group in each column: the parameters, and then the array
    nbytes = sizeof(format.type)*format.leng
    values = reshape(ntoh.(reinterpret(format.type, readbytes(io, nbytes))), P + prod(shape), G)
    #  The physical values of a field are the values of the offset convention of Table 11 of the standard (Sect. 5.2.5, which
    #  Sect. 6.3 gives to the parameters and the array) or are scaled (Eqs. 3 and 5)
    #  The undefined elements of the array are missing, with and without the scale
    apply(value, k) = (value = setmissing(value, fields[k].miss);
        scale ? physical(value, fields[k].type, fields[k].scale, fields[k].zero) : value)
    names = [field.name for field in fields]
    ndxs = [name => findall(x -> x == name, names) for name in unique(names)]
    if record
        #  Return data as a vector of records
        #  Concatenate (horizontally) fields having the same name.
        data = []
        for g = 1:G
            flds = Any[apply(values[k, g], k) for k = 1:P]
            push!(flds, apply(isempty(shape) ? values[end, g] : reshape(values[P+1:end, g], shape), P+1))
            push!(data, (; [Symbol(name) => length(ndx) > 1 ? hcat(flds[ndx]...) : flds[ndx...]
                for (name, ndx) in ndxs]... ))
        end
        #  The type of the records, which is that of the values that they have
        data = map(identity, data)
        #  The physical values of floating-point stored values have the type of the stored values, so the records say that they are,
        #  and have the PSCALn and PZEROn of the parameters, and the BSCALE and BZERO of the array
        physicalfloat(fields) && scale && (data = ScaledRecords(data, [field.scale for field in fields],
            [field.zero for field in fields]))
    else
        #  Return data as NamedTuple of arrays
        #  Concatenate (horizontally) columns having the same name.
        cols = Any[apply(values[k, :], k) for k = 1:P]
        push!(cols, apply(reshape(permutedims(values[P+1:end, :]), (G, shape...)), P+1))
        columns = [length(ndx) > 1 ? hcat(cols[ndx]...) : cols[ndx...] for (name, ndx) in ndxs]
        #  The physical values of floating-point stored values have the type of the stored values, so the columns say that they are,
        #  and have the PSCALn and PZEROn, or the BSCALE and BZERO, of the parameters of the name, or the array
        if physicalfloat(fields) && scale
            columns = [ScaledArray(column, length(ndx) > 1 ? [fields[i].scale for i in ndx] : fields[first(ndx)].scale,
                length(ndx) > 1 ? [fields[i].zero for i in ndx] : fields[first(ndx)].zero)
                for (column, (name, ndx)) in zip(columns, ndxs)]
        end
        data = (; [Symbol(name) => column for ((name, ndx), column) in zip(ndxs, columns)]...)
    end
    data
end

#  Are the physical values of the parameters and the array the same type as the stored values, which are floating-point? They are if
#  one of them is not scaled by a PSCALn or BSCALE of 1 and a PZEROn or BZERO of 0.
physicalfloat(fields::Vector{RandomField}) =
    first(fields).type <: AbstractFloat && any(field -> !(field.scale == 1 && field.zero == 0), fields)

#  Random groups without any group have no data
function Base.write(io::IO, ::Type{Random}, data::Missing, format::DataFormat, fields::Vector{RandomField}; kwds...)
end

function Base.write(io::IO, ::Type{Random}, data::Union{AbstractArray, NamedTuple},
    format::DataFormat, fields::Vector{RandomField}; check::Bool = true, kwds...)

    #  Write data array
    N = format.group
    if N > 0
        #  The stored values of the physical values (Eqs. 3 and 5), which are the values that are of the type of BITPIX
        #  The parameters of a name are one value of the data, which is found by its position, whatever its name is
        names = unique(field.name for field in fields[1:format.param])
        positions = [findfirst(==(field.name), names) for field in fields[1:format.param]]
        #  The values that are the physical values of floating-point stored values are written as the stored values: the records of a
        #  ScaledRecords, and the vectors and the array of columns that are ScaledArrays
        scaled = scaledfields(data, fields, positions)
        for (k, sz) in enumerate(scaled)
            #  Their scale and zero are those of the header, whose PSCALn, PZEROn, BSCALE, and BZERO are those of the data
            isnothing(sz) || sz == (fields[k].scale, fields[k].zero) || throw(ArgumentError("The scale and the zero of the " *
                "$(k <= format.param ? "parameter $(fields[k].name)" : "array"), $(sz[1]) and $(sz[2]), are not the " *
                "$(k <= format.param ? "PSCAL$k and the PZERO$k" : "BSCALE and the BZERO") of the header, $(fields[k].scale) and " *
                "$(fields[k].zero)."))
        end
        scaled = .!isnothing.(scaled)
        for j=1:N
            for (k, field) in enumerate(fields[1:format.param])
                write(io, hton(storedparam(getparam(data, field, j, positions[k]), field, k, j; check,
                    scaled = scaled[k])))
            end
            stored = storedgroup(getgroup(data, fields[end], j, format), fields[end], j; check,
                scaled = scaled[end])
            #  The undefined values are written as BLANK, or NaN for floating-point data
            write(io, hton.(unsetmissing(stored, fields[end].miss, fields[end].type)))
        end
        #  Pad last block with zeros
        padblock(io, format)
    end
end

#  The scale and the zero of the values of each parameter, and of the array, if they are the physical values of floating-point stored
#  values, which are a ScaledArray or ScaledRecords, and nothing if they are not
scaledfields(records::ScaledRecords, fields, positions) = [(records.scales[k], records.zeros[k]) for k in eachindex(fields)]
scaledfields(records::AbstractArray, fields, positions) = fill(nothing, length(fields))
function scaledfields(data::NamedTuple, fields, positions)
    values = Tuple(data)
    [[values[u] isa ScaledArray ? (scaleof(values[u], field.index), zeroof(values[u], field.index)) : nothing
        for (u, field) in zip(positions, fields[1:end-1])];
        values[end] isa ScaledArray ? (scaleof(values[end]), zeroof(values[end])) : nothing]
end

#  The error of a value that cannot be stored, with the name of the field and the group of the value
function storeerror(e::ArgumentError, field::RandomField, j::Integer)
    what = field.leng == 1 && field.name != "data" ? "parameter $(field.name)" : "array $(field.name)"
    ArgumentError("The $what of group $j: " * e.msg)
end

#  The stored value of the value of a parameter, which is the value as it is if it is of the type of BITPIX, and
#  otherwise is the value without PZEROn and PSCALn (see `storedvalue`), or the value of the offset convention.
function storedparam(value, field::RandomField, k::Integer, j::Integer; check::Bool = true,
    scaled::Bool = false)

    typeof(value) == field.type && !scaled && return value
    #  The value of the offset convention of Table 11 is the stored value with the offset
    typeof(value) == offsettype(field.type, field.scale, field.zero) && return offsetvalue(value, field.type)
    field.scale == 0 && throw(ArgumentError(
        "The parameter $(field.name) of group $j cannot be written as a stored value, since its PSCAL$k is 0."))
    try
        storedvalue(value, field.type, field.scale, field.zero, field.miss, check; keys = ("PSCAL$k", "PZERO$k"))
    catch e
        e isa ArgumentError ? throw(storeerror(e, field, j)) : rethrow()
    end
end

#  The stored values of the values of the array of a group (see `storedvalues`).
function storedgroup(values::AbstractArray, field::RandomField, j::Integer; check::Bool = true,
    scaled::Bool = false)

    try
        storedvalues(scaled ? ScaledArray(values, field.scale, field.zero) : values, field.type, field.scale, field.zero,
            field.miss; check)
    catch e
        e isa ArgumentError ? throw(storeerror(e, field, j)) : rethrow()
    end
end

#  The value of a parameter of group `j`, which is the `u`th value of the data of the group, where a value of two or
#  more dimensions has the parameters of the name at the index of the field.
function getparam(data::AbstractArray, field, j::Integer, u::Integer)
    value = data[j][u]
    ndims(value) > 1 ? value[field.index] : value
end
function getparam(data::NamedTuple, field, j::Integer, u::Integer)
    value = data[u]
    ndims(value) > 1 ? value[j, field.index] : value[j]
end

#  The values of the array of group `j`, as a vector. The array is the last of the values of a group, whatever its
#  name is, and is a value, and not an array, in a record of an array without axes (NAXIS of 1).
getgroup(data::AbstractArray, field, j::Integer, format::DataFormat) =
    data[j][end] isa AbstractArray ? reshape(data[j][end], :) : [data[j][end]]
getgroup(data::NamedTuple, field, j::Integer, format::DataFormat) =
    reshape(data[end], (format.group, :))[j, :]

#  The number of bytes of the random groups, |BITPIX|/8 × GCOUNT × (PCOUNT + NAXIS2 × ... × NAXISm) (Eq. 4 of the
#  standard), is at most the largest integer, so that the data can be read and indexed.
function verifygroupsize(mankeys::AbstractDict)
    N, bits = get(mankeys, "NAXIS", 0), get(mankeys, "BITPIX", 0)
    sizes = [BigInt(mankeys["NAXIS$j"]) for j = 2:N]
    nbytes = BigInt(abs(bits) ÷ 8) * get(mankeys, "GCOUNT", 0) * (get(mankeys, "PCOUNT", 0) + prod(sizes; init = big(1)))
    nbytes > typemax(Int) && throw(ArgumentError("The random groups are too large: $(abs(bits) ÷ 8) bytes × " *
        "$(get(mankeys, "GCOUNT", 0)) groups × ($(get(mankeys, "PCOUNT", 0)) parameters + $(join(sizes, " × ")) " *
        "values) is more than $(typemax(Int)) bytes."))
end

function verify!(::Type{Random}, cards::Cards, mankeys::AbstractDict, reskeys::AbstractDict)
    cards = invoke(verify!, Tuple{Type{<:AbstractHDU}, Cards, AbstractDict, AbstractDict}, Random, cards,
        mankeys, reskeys)
    #  The keywords that describe the array of a group (Sect. 4.4.2.5), and the keywords of the primary header, which is the
    #  header of random groups
    verifyarraykeys(Random, mankeys, reskeys)
    verifyrandomkeys(reskeys)
    verifylogical(mankeys, r"^GROUPS$")
    #  BITPIX, NAXIS, PCOUNT, and GCOUNT give the size of the data (Eq. 4 of the standard), which cannot be read
    #  without them, and they are mandatory (Sect. 6.1.1). A header that is being created does not have the keywords
    #  yet, and is arranged when it is created.
    created = !haskey(mankeys, "SIMPLE")
    for key in ("BITPIX", "NAXIS", "PCOUNT", "GCOUNT")
        created || haskey(mankeys, key) || throw(ArgumentError(
            "$key is missing, but it is a mandatory keyword of random groups (Sect. 6.1.1, Table 12)."))
    end
    #  NAXIS1 is 0, and NAXIS2 to NAXIS are the axes of the array of a group. PCOUNT is the number of parameters
    #  and GCOUNT is the number of groups (Sect. 6.1.1).
    verifybitpix(mankeys)
    verifyvalue(mankeys, "NAXIS", 1:MAXAXES, "an integer from 1 to $MAXAXES")
    verifyvalue(mankeys, "NAXIS1", 0:0, "the integer 0")
    verifyaxes(mankeys; first = 2)
    verifyvalue(mankeys, "PCOUNT", 0:typemax(Int), "non-negative")
    verifyvalue(mankeys, "GCOUNT", 0:typemax(Int), "non-negative")
    created || verifygroupsize(mankeys)
    #  The mandatory keywords of the primary header come first, in order, and the keywords of random groups, GROUPS, PCOUNT, and
    #  GCOUNT, are anywhere after them (Sect. 6.1.1, Table 12). The values of the mandatory keywords are in fixed format
    #  (Sect. 4.4.1).
    if !created
        required = vcat(["SIMPLE", "BITPIX", "NAXIS"], ["NAXIS$j" for j = 1:get(mankeys, "NAXIS", 0)])
        verifyorder(cards, required; section = "Sects. 4.4.1.1 and 6.1.1",
            names = "SIMPLE, BITPIX, NAXIS, NAXIS1 of 0, and the NAXISn")
        verifyfixed(cards, [required; "GROUPS"; "PCOUNT"; "GCOUNT"])
    end
    verifyparamkeys(reskeys, get(mankeys, "PCOUNT", 0))
    verifyparams(reskeys, get(mankeys, "PCOUNT", 0))
    cards
end

function verify!(::Type{Random}, cards::Cards, format::DataFormat,
    mankeys::AbstractDict)

    get(mankeys, "SIMPLE", true) === false && @warn "Random HDU is nonconformant, since SIMPLE is F."
    verifyshape!(cards, mankeys, format; first = 2)
    if get(mankeys, "GROUPS", true) !== true
        setindex!(cards, true, "GROUPS")
        @warn "GROUPS set to true"
    end
    verifycounts!(cards, mankeys, format)
end

function DataFormat(::Type{Random}, data::Missing, mankeys::Dict{S, V}) where
    {S<:AbstractString, V<:ValueType}

    #  Mandatory keys determine HDU type
    type  = BITS2TYPE[get(mankeys, "BITPIX", 32)]
    shape = datasize(mankeys, 2)
    param = get(mankeys, "PCOUNT", 0)
    group = get(mankeys, "GCOUNT", 0)
    leng  = get(mankeys, "NAXIS", 0) > 0 ? group * (param + prod(shape)) : 0
    heap  = param > 0 ? get(mankeys, "THEAP", 0) : 0
    DataFormat(type, leng, shape, param, group, heap)
end

#  The fields of the groups: the parameters, which have the names `names` and the keywords PSCALn and PZEROn, and the
#  array, which has the name `array` and the keywords BSCALE and BZERO. Parameters of the same name are numbered. The data of
#  the types of Table 11 (`offset`) have the offset of the type for PZEROn and BZERO if the header has none.
function randomfields(format::DataFormat, reskeys::AbstractDict, names, array::AbstractString; offset::Bool = false)
    type, P, bytes = format.type, format.param, sizeof(format.type)
    #  The zero of data of a physical type of Table 11 is the offset of the type, if the header has none
    zero_ = offset ? OFFSETTYPE[type][2] : 0.0f0
    indices = Dict{String, Int}()
    fields = Vector{RandomField}(undef, P+1)
    k = 0
    for j = 1:P
        name  = String(names[j])
        index = indices[name] = get!(indices, name, 0) + 1
        pzero = leastfloat(get(reskeys, "PZERO$j", zero_))
        scale = leastfloat(get(reskeys, "PSCAL$j", 1.0f0))
        fields[j] = RandomField(name, index, type, k+1:k+bytes, 1, (1,), pzero, scale)
        k += bytes
    end
    leng  = prod(format.shape)
    bzero = leastfloat(get(reskeys,  "BZERO", zero_))
    scale = leastfloat(get(reskeys, "BSCALE", 1.0f0))
    #  The undefined elements of an array of integers are the elements of the value of BLANK (Sect. 4.4.2.5)
    miss  = type in MISSTYPE ? get(reskeys, "BLANK", nothing) : nothing
    fields[end] = RandomField(array, 1, type, k+1:k+leng*bytes, leng, format.shape, bzero, scale, miss)
    fields
end

function FieldFormat(::Type{Random}, format::DataFormat, reskeys::Dict{S, V},
    data::Missing; record::Bool = false, kwds...) where
    {S<:AbstractString, V<:ValueType}

    randomfields(format, reskeys, paramnames(reskeys, format.param), "data")
end

#  The type of the values of the groups, which is the type of the array of the groups, and is the type that BITPIX
#  gives: the parameters and the elements of the array have the same representation (Sect. 6.3 of the standard), so it is
#  an error if a parameter has another type. `values` are the parameters and the array, and `names` their names. The type
#  is the integer of the same size for an unsigned integer or a signed byte (Table 11).
function randomtype(values, names)
    type = nonmissingtype(eltype(values[end]))
    haskey(TYPE2BITS, get(RAWTYPE, type, type)) || throw(ArgumentError("The array $(names[end]) has the type $type, " *
        "but random groups have the types of BITPIX (Table 8): $(join(sort!(string.(collect(keys(TYPE2BITS)))), ", "))."))
    for (j, value) in enumerate(values[1:end-1])
        nonmissingtype(eltype(value)) == type || throw(ArgumentError("The parameter $(names[j]) has the type " *
            "$(nonmissingtype(eltype(value))), but the array $(names[end]) has the type $type: the parameters and " *
            "the array of random groups have the same type, which is BITPIX (Sect. 6.3). Convert them to one type."))
    end
    #  The stored type of the unsigned integers and the signed bytes of Table 11
    get(RAWTYPE, type, type)
end

#  The data of a type of Table 11, which are the stored values with the offset
offsetdata(array) = haskey(RAWTYPE, nonmissingtype(eltype(array)))

#  The number of parameters of a value of the data. The parameters of one name are the columns of a matrix, with a row for each
#  group or, in a record, one row (Sect. 6.1.2 of the standard), and any other value is one parameter.
paramcount(value) = value isa AbstractArray && ndims(value) > 1 ? size(value, 2) : 1

#  The names of the parameters, which are the names of the values, as many as the parameters they have
valuenames(names, values) = reduce(vcat, [fill(name, paramcount(value)) for (name, value) in zip(names, values)]; init = String[])

#  The names of the values of a group, which are the keys of a named tuple, and param1, param2, ... and data otherwise
function groupnames(group::NamedTuple)
    String.(keys(group))
end
function groupnames(group::Tuple)
    [["param$j" for j = 1:length(group)-1]; "data"]
end

function DataFormat(::Type{Random}, data::AbstractArray,
    mankeys::Dict{S, V}) where {S<:AbstractString, V<:ValueType}

    #  Determine format from data: every group has the parameters and an array of the same size and the same type
    names = groupnames(data[1])
    shape = size(data[1][end])
    for (g, group) in enumerate(data)
        length(group) == length(names) || throw(ArgumentError("Group $g has $(length(group)) values, but group 1 " *
            "has $(length(names)): the parameters and the array of each group are the same."))
        size(group[end]) == shape || throw(ArgumentError("The array of group $g has the size $(size(group[end])), " *
            "but that of group 1 has the size $shape."))
        for (j, value) in enumerate(Tuple(group)[1:end-1])
            value isa AbstractArray && !(ndims(value) == 2 && size(value, 1) == 1) && throw(ArgumentError(
                "The parameter $(names[j]) of group $g must be a number, or a matrix of one row for the parameters of its " *
                "name, but it has the size $(size(value))."))
        end
        randomtype(collect(group), names)
    end
    type  = randomtype(collect(data[1]), names)
    param = sum(paramcount, Tuple(data[1])[1:end-1]; init = 0)
    group = length(data)
    heap  = 0
    leng  = group*(param + prod(shape))
    DataFormat(type, leng, shape, param, group, heap)
end

function FieldFormat(::Type{Random}, format::DataFormat, reskeys::Dict{S, V},
    data::AbstractArray; kwds...) where {S<:AbstractString, V<:ValueType}

    #  The names of the parameters are the keys of the records, or the PTYPEn keywords
    names = data[1] isa NamedTuple ? [valuenames(groupnames(data[1])[1:end-1], Tuple(data[1])[1:end-1]); groupnames(data[1])[end]] :
        [paramnames(reskeys, format.param); "data"]
    randomfields(format, reskeys, names[1:end-1], names[end]; offset = offsetdata(data[1][end]))
end

function DataFormat(::Type{Random}, data::U, mankeys::Dict{S, V}) where
    {U<:Union{Tuple, NamedTuple}, S<:AbstractString, V<:ValueType}

    #  Determine format from data: the first axis of the array, and each parameter, is the groups
    names = groupnames(data)
    array = data[end]
    array isa AbstractArray && ndims(array) >= 1 || throw(ArgumentError(
        "The last value of random groups, $(names[end]), must be an array, with the groups along its first axis."))
    group = size(array, 1)
    for j = 1:length(data)-1
        data[j] isa AbstractArray && size(data[j], 1) == group || throw(ArgumentError(
            "The parameter $(names[j]) must have a value for each of the $group groups of the array $(names[end])."))
        ndims(data[j]) <= 2 || throw(ArgumentError("The parameter $(names[j]) must be a vector, or a matrix with a row " *
            "for each group, and a column for each of the parameters of its name, but it has $(ndims(data[j])) dimensions."))
    end
    type  = randomtype(collect(data), names)
    shape = size(array)[2:end]
    param = sum(paramcount, Tuple(data)[1:end-1]; init = 0)
    heap  = 0
    leng  = group*(param + prod(shape))
    DataFormat(type, leng, shape, param, group, heap)
end

function FieldFormat(::Type{Random}, format::DataFormat, reskeys::Dict{S, V},
    data::U; record::Bool = false) where {U<:Union{Tuple, NamedTuple},
    S<:AbstractString, V<:ValueType}

    names = data isa NamedTuple ? [valuenames(groupnames(data)[1:end-1], Tuple(data)[1:end-1]); groupnames(data)[end]] :
        [paramnames(reskeys, format.param); "data"]
    randomfields(format, reskeys, names[1:end-1], names[end]; offset = offsetdata(data[end]))
end

function createcards!(::Type{Random}, format::DataFormat,
    fields::Vector{RandomField}, cards::Cards; kwds...)

    P = format.param
    #  Include PTYPE cards if any value is not an empty string
    named = any(!isempty(field.name) for field in fields[1:P])
    ptype = named ? ["PTYPE$j" => String(fields[j].name) for j = 1:P] : Pair{String, Any}[]
    offsetcards!(arrangecards!(cards, ["SIMPLE" => true; shapekeys(Random, format);
        "GROUPS" => true; "PCOUNT" => P; "GCOUNT" => format.group; ptype]), fields)
end

#  The PZEROn and BZERO cards of the offset convention of Table 11, if the header does not have them.
function offsetcards!(cards::Cards, fields::Vector{RandomField})
    for (j, field) in enumerate(fields)
        key = j < length(fields) ? "PZERO$j" : "BZERO"
        if !isnothing(offsettype(field.type, field.scale, field.zero)) && !haskey(cards, key)
            push!(cards, Card(key, OFFSETTYPE[field.type][2]))
        end
    end
    cards
end

function createdata(::Type{Random}, format::DataFormat,
    fields::Vector{RandomField}; record::Bool = false, kwds...)
    #  Create arrays of zeros of type BITPIX: a value for each parameter of a group, and the array of a group, which is
    #  the last field and has the groups along its first axis.
    if format.group > 0
        names = [Symbol(f.name) for f in fields]
        if record
            data = [(; [name => (f === fields[end] ? (isempty(f.shape) ? zero(f.type) : zeros(f.type, f.shape)) :
                zero(f.type)) for (name, f) in zip(names, fields)]...) for k=1:format.group]
        else
            data = (; [name => (f === fields[end] ? zeros(f.type, (format.group, f.shape...)) :
                zeros(f.type, format.group)) for (name, f) in zip(names, fields)]...)
        end
    else
        data = missing
    end
    data
end


#  The PSCALn, PZEROn, BSCALE, and BZERO cards of the parameters and the array that are the physical values of floating-point stored
#  values, which have the scale and the zero of the data
function scalecards!(::Type{Random}, cards::Cards, data::ScaledRecords)
    P = length(data.scales) - 1
    for k = 1:P
        setscalecard!(cards, "PSCAL$k", data.scales[k], 1)
        setscalecard!(cards, "PZERO$k", data.zeros[k], 0)
    end
    setscalecard!(cards, "BSCALE", data.scales[end], 1)
    setscalecard!(cards, "BZERO", data.zeros[end], 0)
end
function scalecards!(::Type{Random}, cards::Cards, data::NamedTuple)
    values = Tuple(data)
    k = 0
    for value in values[1:end-1]
        for j = 1:paramcount(value)
            k += 1
            value isa ScaledArray || continue
            setscalecard!(cards, "PSCAL$k", scaleof(value, j), 1)
            setscalecard!(cards, "PZERO$k", zeroof(value, j), 0)
        end
    end
    if values[end] isa ScaledArray
        setscalecard!(cards, "BSCALE", scaleof(values[end]), 1)
        setscalecard!(cards, "BZERO", zeroof(values[end]), 0)
    end
    cards
end

#  The keywords that are in the primary header only (Sects. 4.4.2.1 and 4.4.2.6, and App. K), which the header of random groups is:
#  EXTEND and BLOCKED are logicals, and INHERIT must not appear.
function verifyrandomkeys(reskeys::AbstractDict)
    verifylogical(reskeys, r"^(EXTEND|BLOCKED)$")
    haskey(reskeys, "INHERIT") && @warn "INHERIT must not appear in the primary header (Appendix K). It is read as it is."
end

#  The keywords that describe the array of a group (Sect. 4.4.2.5): BLANK, BSCALE, BZERO, DATAMIN, DATAMAX, and BUNIT.
function verifyarraykeys(::Type{Random}, mankeys::AbstractDict, reskeys::AbstractDict)
    verifyblank(Random, mankeys, reskeys)
    verifynumber(reskeys, r"^(BSCALE|BZERO|DATAMIN|DATAMAX)$")
    verifyfloat(reskeys, r"^(DATAMIN|DATAMAX)$")
    verifystring(reskeys, r"^BUNIT$")
    verifyunit(reskeys, r"^BUNIT$")
end

#  The BLANK keyword of the array of a group is an integer, and is for integer data only (Sect. 4.4.2.5).
function verifyblank(::Type{Random}, mankeys::AbstractDict, reskeys::AbstractDict)
    verifyinteger(reskeys, r"^BLANK$")
    haskey(reskeys, "BLANK") && get(mankeys, "BITPIX", 8) < 0 && @warn "BLANK is for integer data " *
        "(a positive BITPIX) only (Sect. 4.4.2.5), so it is not used."
end

#  The keywords BITPIX and NAXIS, and NAXISn of the shape of the data of random groups, whose NAXIS1 is 0, and whose axes begin at NAXIS2
function shapekeys(::Type{Random}, format::DataFormat)
    required = Pair{String, Any}["BITPIX" => TYPE2BITS[format.type], "NAXIS" => length(format.shape) + 1, "NAXIS1" => 0]
    for (j, n) in enumerate(format.shape) push!(required, "NAXIS$(j+1)" => n) end
    required
end

#  The axes of the data that are shown begin at NAXIS2, since NAXIS1 of random groups is 0
firstaxis(::Type{Random}) = 2

#  The type of random groups for the comparison of the names of the HDUs, which are not equivalent to an IMAGE extension
primarytype(::Type{Random}) = "GROUPS"

#  Name the parameters and the data of random groups that are given as a tuple, or as a vector of tuples, of the parameters followed by the data
function namedata(::Type{Random}, data::Tuple, fields, format::DataFormat)
    (; [Symbol(fields[j].name) => data[j] for j ∈ 1:format.param]..., data = data[end])
end
function namedata(::Type{Random}, data::AbstractArray{<:Tuple}, fields, format::DataFormat)
    [(; [Symbol(fields[j].name) => data[k][j] for j ∈ 1:format.param]..., data = data[k][end]) for k ∈ 1:format.group]
end

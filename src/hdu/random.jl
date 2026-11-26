####    Random HDU functions

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
    images = [ImageField(field.type, field.zero, field.scale, field.miss, nothing, nothing) for field in fields]
    #  The undefined elements of the array are missing, with and without the scale
    apply(value, k) = (value = setmissing(value, images[k].miss); scale ? physical(value, images[k]) : value)
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
    else
        #  Return data as NamedTuple of arrays
        #  Concatenate (horizontally) columns having the same name.
        cols = Any[apply(values[k, :], k) for k = 1:P]
        push!(cols, apply(reshape(permutedims(values[P+1:end, :]), (G, shape...)), P+1))
        data = (; [Symbol(name) => (length(ndx) > 1 ? hcat(cols[ndx]...) : cols[ndx...])
            for (name, ndx) in ndxs]...)
    end
    data
end

#  Random groups without any group have no data
function Base.write(io::IO, ::Type{Random}, data::Missing, format::DataFormat, fields::Vector{RandomField}; kwds...)
end

function Base.write(io::IO, ::Type{Random}, data::Union{AbstractArray, NamedTuple},
    format::DataFormat, fields::Vector{RandomField}; check::Bool = true, kwds...)

    #  Write data array
    N = format.group
    if N > 0
        #  The stored values of the physical values (Eqs. 3 and 5), which are the values that are of the type of BITPIX
        images = [ImageField(field.type, field.zero, field.scale, field.miss, nothing, nothing) for field in fields]
        #  The parameters of a name are one value of the data, which is found by its position, whatever its name is
        names = unique(field.name for field in fields[1:format.param])
        positions = [findfirst(==(field.name), names) for field in fields[1:format.param]]
        for j=1:N
            for (k, field) in enumerate(fields[1:format.param])
                write(io, hton(storedparam(getparam(data, field, j, positions[k]), field, images[k], k, j; check)))
            end
            stored = storedgroup(getgroup(data, fields[end], j, format), fields[end], images[end], j; check)
            #  The undefined values are written as BLANK, or NaN for floating-point data
            write(io, hton.(unsetmissing(stored, images[end].miss, images[end].type)))
        end
        #  Pad last block with zeros
        padblock(io, format)
    end
end

#  The error of a value that cannot be stored, with the name of the field and the group of the value
function storeerror(e::ArgumentError, field::RandomField, j::Integer)
    what = field.leng == 1 && field.name != "data" ? "parameter $(field.name)" : "array $(field.name)"
    ArgumentError("The $what of group $j: " * e.msg)
end

#  The stored value of the value of a parameter, which is the value as it is if it is of the type of BITPIX, and
#  otherwise is the value without PZEROn and PSCALn (see `storedvalue`), or the value of the offset convention.
function storedparam(value, field::RandomField, image::ImageField, k::Integer, j::Integer; check::Bool = true)
    typeof(value) == field.type && return value
    #  The value of the offset convention of Table 11 is the stored value with the offset
    typeof(value) == offsettype(field.type, field.scale, field.zero) && return offsetvalue(value, field.type)
    image.scale == 0 && throw(ArgumentError(
        "The parameter $(field.name) of group $j cannot be written as a stored value, since its PSCAL$k is 0."))
    try
        storedvalue(value, image, check; keys = ("PSCAL$k", "PZERO$k"))
    catch e
        e isa ArgumentError ? throw(storeerror(e, field, j)) : rethrow()
    end
end

#  The stored values of the values of the array of a group (see `storedvalues`).
function storedgroup(values::AbstractArray, field::RandomField, image::ImageField, j::Integer; check::Bool = true)
    try
        storedvalues(values, image; check)
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
#  name is.
getgroup(data::AbstractArray, field, j::Integer, format::DataFormat) =
    reshape(data[j][end], :)
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
    verifyarraykeys(mankeys, reskeys)
    verifyprimarykeys(reskeys)
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
    verifyparamkeys(reskeys, get(mankeys, "PCOUNT", 0))
    verifyparams(reskeys, get(mankeys, "PCOUNT", 0))
    cards
end

function verify!(::Type{Random}, cards::Cards, format::DataFormat,
    mankeys::AbstractDict)

    !get(mankeys, "SIMPLE", true) && @warn "Primary HDU is nonconformant."
    verifyshape!(cards, mankeys, format; first = 2)
    if !get(mankeys, "GROUPS", true)
        setindex!(cards, true, "GROUPS")
        @warn "GROUPS set to true"
    end
    verifycounts!(cards, mankeys, format)
end

function DataFormat(::Type{Random}, data::Missing, mankeys::Dict{S, V}) where
    {S<:AbstractString, V<:ValueType}

    #  Mandatory keys determine HDU type
    type  = BITS2TYPE[get(mankeys, "BITPIX", 32)]
    leng  = datalength(mankeys, 2)
    shape = datasize(mankeys, 2)
    param = get(mankeys, "PCOUNT", 0)
    group = get(mankeys, "GCOUNT", 0)
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
        randomtype(collect(group), names)
    end
    type  = randomtype(collect(data[1]), names)
    param = length(names)-1
    group = length(data)
    heap  = 0
    leng  = group*(param + prod(shape))
    DataFormat(type, leng, shape, param, group, heap)
end

function FieldFormat(::Type{Random}, format::DataFormat, reskeys::Dict{S, V},
    data::AbstractArray; kwds...) where {S<:AbstractString, V<:ValueType}

    #  The names of the parameters are the keys of the records, or the PTYPEn keywords
    names = data[1] isa NamedTuple ? groupnames(data[1]) : [paramnames(reskeys, format.param); "data"]
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
    end
    type  = randomtype(collect(data), names)
    shape = size(array)[2:end]
    param = length(data)-1
    heap  = 0
    leng  = group*(param + prod(shape))
    DataFormat(type, leng, shape, param, group, heap)
end

function FieldFormat(::Type{Random}, format::DataFormat, reskeys::Dict{S, V},
    data::U; record::Bool = false) where {U<:Union{Tuple, NamedTuple},
    S<:AbstractString, V<:ValueType}

    names = data isa NamedTuple ? groupnames(data) : [paramnames(reskeys, format.param); "data"]
    randomfields(format, reskeys, names[1:end-1], names[end]; offset = offsetdata(data[end]))
end

function createcards!(::Type{Random}, format::DataFormat,
    fields::Vector{RandomField}, cards::Cards; kwds...)

    P = format.param
    #  Include PTYPE cards if any value is not an empty string
    named = any(!isempty(field.name) for field in fields[1:P])
    ptype = named ? ["PTYPE$j" => String(fields[j].name) for j = 1:P] : Pair{String, Any}[]
    offsetcards!(arrangecards!(cards, ["SIMPLE" => true; shapekeys(format; first = 2);
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

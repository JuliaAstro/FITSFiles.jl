####    Random HDU functions

"""
    RandomField(name, index, type, slice, leng, shape, zero, scale)

Random array element descriptor
"""
struct RandomField <: AbstractField
    "The name of the field"
    name::AbstractString
    "The index of the field for common name fields"
    index::Integer
    "The type of the field"
    type::Type
    "The slice of the field bytes from start of record"
    slice::UnitRange{Integer}
    "The number of elements in the field"
    leng::Integer
    "The dimensions of the field"
    shape::Tuple
    "The offset value of the field"
    zero::Union{AbstractFloat, Missing}
    "The scale factor of the field"
    scale::Union{AbstractFloat, Missing}
end

function Base.read(io::IO, ::Type{Random}, format::DataFormat,
    fields::Vector{RandomField}; record::Bool = false, kwds...)

    begpos = position(io)
    M, N = sizeof(format.type), format.leng
    #  Read data array
    names = [field.name for field in fields]
    ndxs = [name => findall(x -> x == name, names)
        for name in unique(names)]
    if record
        #  Return data as a vector of records
        #  Concatenate (horizontally) fields having the same name.
        data = []
        for j=1:format.group
            flds = [read(io, field; kwds...) for field in fields]
            push!(data, (; [Symbol(name) => length(ndx) > 1 ?
                hcat(flds[ndx]...) : flds[ndx...]
                for (name, ndx) in ndxs]... ) )
        end
    else
        #  Return data as NamedTuple of arrays
        #  Concatenate (horizontally) columns having the same name.
        cols = [read(io, field, format, begpos; kwds...)
            for field in fields]
        data = (; [Symbol(name) => (length(ndx) > 1 ? hcat(cols[ndx]...) :
            cols[ndx...]) for (name, ndx) in ndxs]...)
    end
    #   Seek to end of the last data block
    # seek(io, begpos + BLOCKLEN*div(M*N, BLOCKLEN, RoundUp))

    ####    Get WCS keywords
    data
end

function Base.write(io::IO, ::Type{Random}, data::AbstractArray,
    format::DataFormat, fields::Vector{RandomField}; kwds...)

    #  Write data array
    N = format.group
    if N > 0
        for j=1:N
            for field in fields[1:format.param]
                value = data[j][Symbol(field.name)]
                write(io, hton(ndims(value) > 1 ? value[field.index] :
                    value))
            end
            field = fields[end]
            value = reshape(data[j][Symbol(field.name)], :)
            write(io, hton.(value))
        end
        #  Pad last block with zeros
        padblock(io, format)
    end
end

function Base.write(io::IO, ::Type{Random}, data::NamedTuple, format::DataFormat,
    fields::Vector{RandomField}; kwds...)

    #  Write data array
    N = format.group
    if N > 0
        for j=1:N
            for field in fields[1:format.param]
                value = data[Symbol(field.name)]
                write(io, hton(ndims(value) > 1 ? value[j, field.index] :
                    value[j]))
            end
            field = fields[end]
            value = reshape(data[Symbol(field.name)], (format.group, :))[j,:]
            write(io, hton.(value))
        end
        #  Pad last block with zeros
        padblock(io, format)
    end
end

function verify!(::Type{Random}, cards::Cards, format::DataFormat,
    mankeys::Dict{S, V}) where {S<:AbstractString, V<:ValueType}

    if !get(mankeys, "SIMPLE", true)
        println("Warning: Primary HDU is nonconformant.")
    end
    if haskey(mankeys, "BITPIX") && format.type != BITS2TYPE[mankeys["BITPIX"]]
        setindex!(cards, TYPE2BITS[format.type], "BITPIX")
        println("Warning: BITPIX set to $(TYPE2BITS[format.type])).")
    end
    if haskey(mankeys, "NAXIS1") && (format.shape != datasize(cards, 2))
        N = length(format.shape)+1
        setindex!(cards, N, "NAXIS")
        setindex!(cards, 0, "NAXIS1")
        for j=2:N setindex!(cards, format.shape[j-1], "NAXIS$j") end
        println("Warning: NAXIS$(2:N) set to $(format.shape)")
    end
    if !get(mankeys, "GROUPS", true)
        setindex!(cards, true, "GROUPS")
        println("Warning: GROUPS set to true")
    end
    if haskey(mankeys, "PCOUNT") && (format.param != mankeys["PCOUNT"])
        setindex!(cards, format.param, "PCOUNT")
        println("Warning: PCOUNT set to $(format.param)")
    end
    if haskey(mankeys, "GCOUNT") && (format.group != mankeys["GCOUNT"])
        setindex!(cards, format.group, "GCOUNT")
        println("Warning: GCOUNT set to $(format.group)")
    end
    cards
end

function DataFormat(::Type{Random}, data::Missing, mankeys::Dict{S, V}) where
    {S<:AbstractString, V<:ValueType}

    #  Mandatory keys determine HDU tyhpe
    type  = BITS2TYPE[get(mankeys, "BITPIX", 32)]
    leng  = datalength(mankeys, 2)
    shape = datasize(mankeys, 2)
    param = get(mankeys, "PCOUNT", 0)
    group = get(mankeys, "GCOUNT", 0)
    heap  = param > 0 ? get(mankeys, "THEAP", 0) : 0
    DataFormat(type, leng, shape, param, group, heap)
end

function FieldFormat(::Type{Random}, format::DataFormat, reskeys::Dict{S, V},
    data::Missing; record::Bool = false, kwds...) where
    {S<:AbstractString, V<:ValueType}

    type = format.type
    k, P, bytes = 0, format.param, sizeof(type)

    indices = Dict{AbstractString, Integer}()
    fields = Vector{RandomField}(undef, P+1)
    for j = 1:P
        name  = rstrip(get(reskeys, "PTYPE$j", "param$j"))
        index = indices[name] = get!(indices, name, 0) + 1
        leng  = 1
    scale = least_float_type(get(reskeys, "PSCAL$j", 1.0f0))
        pzero = least_float_type(get(reskeys, "PZERO$j", 0.0f0))
        fields[j] = RandomField(name, index, type, k+1:k+bytes, leng, (leng,),
            pzero, scale)
        k += bytes
    end
    name  = "data"
    index = 1
    leng  = prod(format.shape)
    bzero = least_float_type(get(reskeys,  "BZERO", 0.0f0))
    scale = least_float_type(get(reskeys, "BSCALE", 1.0f0))
    fields[end] = RandomField(name, index, type, k+1:k+leng*bytes, leng,
        format.shape, bzero, scale)
    fields
end

function DataFormat(::Type{Random}, data::AbstractArray,
    mankeys::Dict{S, V}) where {S<:AbstractString, V<:ValueType}

    #  Determine format from data
    type  = typeof(data[1][1])
    shape = size(data[1][end])
    param = length(data[1])-1
    group = length(data)
    heap  = 0
    leng  = group*(param + prod(shape))
    DataFormat(type, leng, shape, param, group, heap)
end

function FieldFormat(::Type{Random}, format::DataFormat, reskeys::Dict{S, V},
    data::AbstractArray; kwds...) where {S<:AbstractString, V<:ValueType}

    type = format.type
    k, P, bytes = 0, format.param, sizeof(type)

    indices = Dict{AbstractString, Integer}()
    fields = Vector{RandomField}(undef, P+1)
    for j = 1:P
        name  = typeof(data[1]) <: NamedTuple ? rstrip(String(keys(data[1])[j])) :
            rstrip(get(reskeys, "PTYPE$j", "param$j"))
        index = indices[name] = get!(indices, name, 0) + 1
        leng = 1
        pzero = least_float_type(get(reskeys, "PZERO$j", 0.0f0))
        scale = least_float_type(get(reskeys, "PSCAL$j", 1.0f0))
        fields[j] = RandomField(name, index, type, k+1:k+bytes, leng, (leng,),
            pzero, scale)
        k += bytes
    end
    name  = typeof(data[1]) <: NamedTuple ? String(keys(data[1])[end]) : "data"
    index = 1
    leng  = prod(format.shape)
    bzero = least_float_type(get(reskeys,  "BZERO", 0.0f0))
    scale = least_float_type(get(reskeys, "BSCALE", 1.0f0))
    fields[end] = RandomField(name, index, type, k+1:k+leng*bytes, leng,
        format.shape, bzero, scale)
    fields
end

function DataFormat(::Type{Random}, data::U, mankeys::Dict{S, V}) where
    {U<:Union{Tuple, NamedTuple}, S<:AbstractString, V<:ValueType}

    #  Determine format from data
    type  = eltype(data[end])
    shape = size(data[end])[2:end]
    param = length(data)-1
    group = length(data[1])
    heap  = 0
    leng  = group*(param + prod(shape))
    DataFormat(type, leng, shape, param, group, heap)
end

function FieldFormat(::Type{Random}, format::DataFormat, reskeys::Dict{S, V},
    data::U; record::Bool = false) where {U<:Union{Tuple, NamedTuple},
    S<:AbstractString, V<:ValueType}

    type, P, k, bytes = format.type, format.param, 0, sizeof(format.type)

    indices = Dict{AbstractString, Integer}()
    fields = Vector{RandomField}(undef, P+1)
    for j = 1:P
        name  = typeof(data) <: NamedTuple ? rstrip(String(keys(data)[j])) :
            rstrip(get(reskeys, "PTYPE$j", "param$j"))
        index = indices[name] = get!(indices, name, 0) + 1
        leng  = 1
        pzero = least_float_type(get(reskeys, "PZERO$j", 0.0f0))
        scale = least_float_type(get(reskeys, "PSCAL$j", 1.0f0))
        fields[j] = RandomField(name, index, type, k+1:k+bytes, leng, (leng,),
            pzero, scale)
        k += bytes
    end
    name  = "data"
    index = 1
    leng  = prod(format.shape)
    bzero = least_float_type(get(reskeys,  "BZERO", 0.0f0))
    scale = least_float_type(get(reskeys, "BSCALE", 1.0f0))
    fields[end] = RandomField(name, index, type, k+1:k+leng*bytes, leng,
        format.shape, bzero, scale)
    fields
end

function create_cards!(::Type{Random}, format::DataFormat,
    fields::Vector{RandomField}, cards::Cards; kwds...)

    N, B = length(format.shape)+1, TYPE2BITS[format.type]
    P, G = format.param, format.group
    #  Include PTYPE cards if any value is not an empty string
    T = any(.!isempty.([field.name for field in fields[1:P]])) ? P : 0
    #  Create mandatory (required) header cards and remove them from the deck
    #  if necessary
    required = Vector{Card{<:Any}}(undef, 6+N+T)
    required[1] = popat!(cards, "SIMPLE", Card("SIMPLE", true))
    required[2] = popat!(cards, "BITPIX", Card("BITPIX", B))
    required[3] = popat!(cards, "NAXIS",  Card("NAXIS", N))
    required[4] = popat!(cards, "NAXIS1", Card("NAXIS1", 0))
    required[5:3+N] .= [popat!(cards, "NAXIS$j",
        Card("NAXIS$j", format.shape[j-1])) for j=2:N]
    required[4+N] = popat!(cards, "GROUPS", Card("GROUPS", true))
    required[5+N] = popat!(cards, "PCOUNT", Card("PCOUNT", P))
    required[6+N] = popat!(cards, "GCOUNT", Card("GCOUNT", G))
    required[7+N:6+N+T] .= [popat!(cards, "PTYPE$j",
        Card("PTYPE$j", String(fields[j].name))) for j=1:T]
    #  Append remaining cards in deck, but first remove the END card
    popat!(cards, "END")
    M = length(cards)
    kards = Vector{Card{<:Any}}(undef, 6+N+M+T)
    kards[1:6+N+T] .= required
    kards[7+N+T:6+N+M+T] .= cards
    #  END card is implied. It will be append on write.
    kards
end

function create_data(::Type{Random}, format::DataFormat,
    fields::Vector{RandomField}; record::Bool = false, kwds...)
    #  Create N-dimensional array of zeros of type BITPIX.
    if format.group > 0
        if record
            data = [(; [Symbol(f.name) => length(f.shape) > 1 ?
                zeros(f.type, f.shape) : zero(f.type) for f in fields]...)
                for k=1:format.group]
        else
            data = (; [Symbol(f.name) => length(f.shape) > 1 ?
                zeros(f.type, (format.group, f.shape...)) :
                zeros(f.type, format.group) for f in fields]...)
        end
    else
        data = missing
    end
    data
end

function Base.read(io::IO, field::RandomField, format::DataFormat,
    begpos::Integer; scale::Bool = true)

    L = sizeof(format.type)*(format.param + prod(format.shape))
    M, N = first(field.slice)-1, format.group
    type, leng, shape = field.type, field.leng, field.shape

    if leng == 1
        column = Array{type}(undef, N)
        for j=1:N
            seek(io, begpos + L*(j-1) + M)
            column[j] = ntoh(read(io, type))
        end
    else
        column = Array{type}(undef, (N, leng))
        for j=1:N
            seek(io, begpos + L*(j-1) + M)
            column[j,:] = ntoh.([read(io, type) for k=1:leng])
        end
        column = reshape(column, (N, shape...))
    end
    #  No missing values
    scale ? field.zero .+ field.scale.*column : column
end

function Base.read(io::IO, field::RandomField; scale::Bool = true)

    name, type, leng, shape = field.name, field.type, field.leng, field.shape
    if leng == 1
        value = ntoh(read(io, type))
    else
        value = reshape(ntoh.([read(io, type) for j=1:leng]), shape)
    end
    #  No missing values
    scale ? field.zero .+ field.scale.*value : value
end

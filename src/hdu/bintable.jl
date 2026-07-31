####    Bintable HDU functions

const BINARYFMT = Regex(
    "(?<r>\\d*)(?<p>[PQ]?)(?<t>[LXBIJKAEDCM])\\(?(?<a>\\w*)\\)?")

const BINARYTYPE = Dict(
    #  character to type
    "L" => Bool, "X" => BitVector, "B" => UInt8, "I" => Int16, "J" => Int32,
    "K" => Int64, "A" => String, "E" => Float32, "D" => Float64,
    "C" => ComplexF32, "M" => ComplexF64,
    #  type to character
    Bool => "L", BitVector => "X", UInt8 => "B", Int16 => "I", Int32 => "J",
    Int64 => "K", String => "A", Float32 => "E", Float64 => "D",
    ComplexF32 => "C", ComplexF64 => "M")

const POINTERTYPE = Dict("P" => Int32, "Q" => Int64, Int32 => "P", Int64 => "Q")

"""
    BinaryField(name, pntr, type, slice, leng, supp, unit, disp, dims,
        zero, scale, null, dmin, dmax, lmin, lmax)

Binary array element descriptor
"""
struct BinaryField <: AbstractField
    "The name of the field"
    name::AbstractString
    "The type of variable array pointer "
    pntr::Union{Type, Nothing}
    "The tye of the field"
    type::Type
    "The slice of the field from start of record"
    slice::UnitRange{<:Integer}
    "The number of elements in the field"
    leng::Integer
    "The supplmental information of the field"
    supp::AbstractString
    #  optional fields
    "The unit of the field"
    unit::AbstractString
    "The display format of the field"
    disp::AbstractString
    "The dimension of the field"
    dims::Union{Tuple, Nothing}
    "The offset of the field"
    zero::Union{AbstractFloat, Nothing}
    "The scale of the field"
    scale::Union{AbstractFloat, Nothing}
    "The missing value of the field"
    null::Union{Integer, Nothing}
    "The minimum raw value of the field"
    dmin::Union{AbstractFloat, Nothing}
    "The maximum raw value of the field"
    dmax::Union{AbstractFloat, Nothing}
    "The minimum physical value of the field"
    lmin::Union{AbstractFloat, Nothing}
    "The maximum physical value of the field"
    lmax::Union{AbstractFloat, Nothing}
end

function _parse_tdim(value)
    dim_string = strip(String(value))
    isempty(dim_string) && return nothing

    dims = eval(Meta.parse(dim_string))
    dims isa Integer ? (dims,) : dims
end

function Base.read(io::IO, ::Type{Bintable}, format::DataFormat,
    fields::Vector{BinaryField}; record::Bool = false, kwds...)

    begpos = position(io)
    M, N, P = format.shape[1], format.shape[2], format.param
    #  Read data array
    if record
        #  Read data table
        data = [(; [read(io, field; kwds...) for field in fields]...)
            for j = 1:N]
    else
        data = (; [Symbol(field.name) =>
            read(io, field, format, begpos; kwds...) for field in fields]... )
    end
    #  Seek to the beginning of the heap
    seek(io, begpos + (P > 0 ? format.heap : M*N))
    #  Read the heap
    ntoh.(read(io, P))
    #  Seek to the end of block
    # seek(io, begpos + BLOCKLEN*div(M*N + P, BLOCKLEN, RoundUp))

    ####    Get WCS keywords
    data
end

function Base.write(io::IO, ::Type{Bintable}, data::AbstractArray,
    format::DataFormat, fields::Vector{BinaryField}; kwds...)

    #  Write data array
    N = format.shape[2]
    if N > 0
        for j=1:N
            for field in fields
                value = data[j][Symbol(field.name)]
                write(io, field, typeof(value) <: AbstractArray ?
                    reshape(value, :) : value; kwds...)
            end
        end
        #  Pad last block with zeros
        padblock(io, format)
    end
end

function Base.write(io::IO, ::Type{Bintable}, data::NamedTuple, format::DataFormat,
    fields::Vector{BinaryField}; kwds...)

    #  Write data array
    N = format.shape[2]
    if N > 0
        for j=1:N
            start = position(io)
            for field in fields
                start = position(io)
                value = data[Symbol(field.name)]
                write(io, field, ndims(value) >= 2 ? reshape(value[j,:], :) :
                    value[j]; kwds...)
            end
        end
        #  Pad last block with zeros
        padblock(io, format)
    end
end

function verify!(::Type{Bintable}, cards::Cards, format::DataFormat,
    mankeys::D) where D <: Dict{AbstractString, ValueType}

    if haskey(mankeys, "BITPIX") && format.type != BITS2TYPE[mankeys["BITPIX"]]
        setindex!(cards, TYPE2BITS[format.type], "BITPIX")
        println("Warning: BITPIX set to $(TYPE2BITS[format.type])).")
    end
    if haskey(mankeys, "NAXIS1") && format.shape != datasize(cards, 1)
        println("$(format.shape), $(datasize(cards, 1))")
        N = length(format.shape)
        setindex!(cards, N, "NAXIS")
        for j=1:N setindex!(cards, format.shape[j], "NAXIS$j") end
        println("Warning: NAXIS$(1:N) set to $(format.shape)")
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

function DataFormat(::Type{Bintable}, data::Missing, mankeys::Dict{S, V}) where
    {S <: AbstractString, V <: ValueType}

    #  Mandatory keys determines HDU type.
    type  = BITS2TYPE[get(mankeys, "BITPIX", 8)]
    leng  = datalength(mankeys, 1)
    shape = datasize(mankeys, 1)
    param = get(mankeys, "PCOUNT", 0)
    group = get(mankeys, "GCOUNT", 1)
    heap  = get(mankeys, "THEAP", sizeof(type)*prod(shape))
    DataFormat(type, leng, shape, param, group, heap)
end

function FieldFormat(::Type{Bintable}, mankeys::DataFormat, reskeys::Dict{S, V},
    data::Missing; record::Bool = false, kwds...) where
    {S <: AbstractString, V <: ValueType}

    #   Add support TTYPEn and TUNITn in data arrays
    N = get(reskeys, "TFIELDS", 0)
    k, fields = 0, Vector{BinaryField}(undef, N)
    for j = 1:N
        name  = rstrip(get(reskeys, "TTYPE$j", record ? "field$j" : "column$j"))
        form  = match(BINARYFMT, reskeys["TFORM$j"])
        pntr  = !isempty(form[:p]) ? POINTERTYPE[form[:p]] : nothing
        type  = BINARYTYPE[form[:t]]
        leng  = !isempty(form[:r]) ? Base.parse(Int64, form[:r]) : 1
        if !isnothing(pntr)
            if !(leng in [0, 1])
                leng = 1
                println("Warning: TFORM$j repeat value set to 1.")
            end
            byts = 2*sizeof(pntr)
        elseif type <: BitVector
            byts = sizeofbitvector(leng)
        elseif type <: AbstractString
            byts = leng
        else
            byts = leng*sizeof(type)
        end
        supp  = form[:a]
        unit_ = get(reskeys, "TUNIT$j", "")
        disp  = get(reskeys, "TDISP$j", "")
        dims  = _parse_tdim(get(reskeys, "TDIM$j", ""))
        zero_ = least_float_type(get(reskeys, "TZERO$j",
            type <: Union{Bool, BitVector, String} ? nothing : 0.0f0))
        scale = least_float_type(get(reskeys, "TSCAL$j",
            type <: Union{Bool, BitVector, String} ? nothing : 1.0f0))
        null  = get(reskeys, "TNULL$j", nothing)
        dmin  = parse_string(get(reskeys, "TDMIN$j", nothing))
        dmax  = parse_string(get(reskeys, "TDMAX$j", nothing))
        lmin  = parse_string(get(reskeys, "TLMIN$j", nothing))
        lmax  = parse_string(get(reskeys, "TLMAX$j", nothing))

        fields[j] = BinaryField(name, pntr, type, k+1:k+byts, leng, supp,
            unit_, disp, dims, zero_, scale, null, dmin, dmax, lmin, lmax)
        k += byts
    end
    fields
end

function DataFormat(::Type{Bintable}, data::AbstractArray,
    mankeys::Dict{S, V}) where {S <: AbstractString, V <: ValueType}

    #  Determine format from data
    type  = BITS2TYPE[8]
    shape = (recordlength(data), length(data))
    leng  = prod(shape)
    param = 0
    group = 1
    heap  = 0
    DataFormat(type, leng, shape, param, group, heap)
end

function FieldFormat(::Type{Bintable}, mankey::DataFormat, reskeys::Dict{S, V},
    data::AbstractArray; kwds...) where {S <: AbstractString, V <: ValueType}

    #   Add support TTYPEn and TUNITn in data arrays
    N = length(data[1])
    k, fields = 0, Vector{BinaryField}(undef, N)
    for j = 1:N
        name = typeof(data[1]) <: NamedTuple ? rstrip(String(keys(data[1])[j])) :
            rstrip(get(reskeys, "TTYPE$j", "field$j"))
        pntr  = nothing
        type, leng, byts = field_descriptor(data[1][j])
        supp  = ""
        # unit_ = unit(data[1][j]) != NoUnits ? unit(data[1][j]) :
        #     get(reskeys, "TUNIT$j", "")
        unit_ = get(reskeys, "TUNIT$j", "")
        disp  = get(reskeys, "TDISP$j", "")
        dims  = _parse_tdim(get(reskeys, "TDIM$j", ""))
        zero_ = least_float_type(get(reskeys, "TZERO$j",
            type <: Union{Bool, BitVector, String} ? nothing : 0.0f0))
        scale = least_float_type(get(reskeys, "TSCAL$j",
            type <: Union{Bool, BitVector, String} ? nothing : 1.0f0))
        null  = get(reskeys, "TNULL$j", nothing)
        dmin  = get(reskeys, "TDMIN$j", nothing)
        dmax  = get(reskeys, "TDMAX$j", nothing)
        lmin  = get(reskeys, "TLMIN$j", nothing)
        lmax  = get(reskeys, "TLMAX$j", nothing)

        fields[j] = BinaryField(name, pntr, type, k+1:k+byts, leng, supp,
            unit_, disp, dims, zero_, scale, null, dmin, dmax, lmin, lmax)
        k += byts
    end
    fields
end

function DataFormat(::Type{Bintable}, data::U, mankeys::Dict{S, V}) where
    {U <: Union{Tuple, NamedTuple}, S <: AbstractString, V <: ValueType}

    reclen = recordlength(data)
    #  Determine format from data
    type  = BITS2TYPE[8]
    shape = (reclen, length(data[1]))
    leng  = prod(shape)
    param = 0
    group = 1
    heap  = 0
    DataFormat(type, leng, shape, param, group, heap)
end

function FieldFormat(::Type{Bintable}, mankey::DataFormat, reskeys::Dict{S, V},
    data::U; kwds...) where {U <: Union{Tuple, NamedTuple},
    S <: AbstractString, V <: ValueType}

    #   Add support TTYPEn and TUNITn in data arrays
    N = length(data)
    k, fields = 0, Vector{BinaryField}(undef, N)
    for j = 1:N
        name  = typeof(data) <: NamedTuple ? rstrip(String(keys(data)[j])) :
            rstrip(get(reskeys, "TTYPE$j", "column$j"))
        pntr  = nothing
        type, leng, byts = field_descriptor(data[j][1])
        supp  = ""
        # unit_ = unit(data[j]) != NoUnits ? unit(data[j]) :
        #     get(reskeys, "TUNIT$j", "")
        unit_ = get(reskeys, "TUNIT$j", "")
        disp  = get(reskeys, "TDISP$j", "")
        dims  = _parse_tdim(get(reskeys, "TDIM$j", ""))
        zero_ = least_float_type(get(reskeys, "TZERO$j",
            type <: Union{Bool, BitVector, String} ? nothing : 0.0f0))
        scale = least_float_type(get(reskeys, "TSCAL$j",
            type <: Union{Bool, BitVector, String} ? nothing : 1.0f0))
        null  = get(reskeys, "TNULL$j", nothing)
        dmin  = get(reskeys, "TDMIN$j", nothing)
        dmax  = get(reskeys, "TDMAX$j", nothing)
        lmin  = get(reskeys, "TLMIN$j", nothing)
        lmax  = get(reskeys, "TLMAX$j", nothing)

        fields[j] = BinaryField(name, pntr, type, k+1:k+byts, leng, supp,
            unit_, disp, dims, zero_, scale, null, dmin, dmax, lmin, lmax)
        k += byts
    end
    fields
end

function recordlength(data::AbstractArray)
	sum([typeof(f) <: BitVector ? sizeofbitvector(f) : sizeof(f)
		for f in data[1]])
end

function recordlength(data::U) where U <: Union{Tuple, NamedTuple}
	sum([typeof(f[1]) <: BitVector ? sizeofbitvector(f[1]) : sizeof(f[1])
		for f in data])
end

sizeofbitvector(v::BitVector)::Integer = (length(v)-1)÷8 + 1
sizeofbitvector(len::Integer)::Integer = (len-1)÷8 + 1

function field_descriptor(field)
    if typeof(field) <: AbstractString
        type, leng = String, length(field)
        byts = leng
    elseif typeof(field) <: BitVector
        type, leng = BitVector, length(field)
        byts = sizeofbitvector(leng)
    elseif typeof(field) <: AbstractArray
        type, leng = eltype(field), length(field)
        byts = leng*sizeof(type)
    else
        type, leng = typeof(field), 1
        byts = leng*sizeof(type)
    end
    (type, leng, byts)
end

function create_cards!(::Type{Bintable}, format::DataFormat,
    fields::Vector{BinaryField}, cards::Cards; kwds...)

    M, N = length(format.shape) == 2 ? format.shape : (0, 0)
    T = length(fields)
    L = any(.!isempty.([f.name for f in fields])) ? T : 0
    #  create mandatory header cards and remove them from the deck if necessary
    required = Vector{Card{<:Any}}(undef, 8+T+L)
    required[1] = popat!(cards, "XTENSION", Card("XTENSION", "BINTABLE"))
    required[2] = popat!(cards, "BITPIX", Card("BITPIX", 8))
    required[3] = popat!(cards, "NAXIS",  Card("NAXIS", 2))
    required[4] = popat!(cards, "NAXIS1", Card("NAXIS1", M))
    required[5] = popat!(cards, "NAXIS2", Card("NAXIS2", N))
    required[6] = popat!(cards, "PCOUNT", Card("PCOUNT", 0))
    required[7] = popat!(cards, "GCOUNT", Card("GCOUNT", 1))
    required[8] = popat!(cards, "TFIELDS", Card("TFIELDS", T))
    for j=1:T
        frmt = "$(fields[j].leng)$(BINARYTYPE[fields[j].type])"
        required[8+2*j-1] = popat!(cards, "TFORM$j", Card("TFORM$j", frmt))
        if L > 0
            required[8+2*j] = popat!(cards, "TTYPE$j", Card("TTYPE$j",
                fields[j].name))
        end
    end
    #  Append remaining cards in deck, but first remove the END card
    popat!(cards, "END")
    R = length(cards)
    kards = Vector{Card{<:Any}}(undef, 8+T+L+R)
    kards[1:8+T+L] .= required
    kards[9+T+L:8+T+L+R] .= cards
    #  END card is implied. Will be append on write.
    return kards
end

function create_data(::Type{Bintable}, format::DataFormat,
    fields::Vector{BinaryField}; record::Bool = false, kwds...)
    #  Create vector of tuples.
    if format.leng > 0
        if record
            data = [(; [Symbol(f.name) => bintab_zeros(f) for f in fields]...)
                    for k=1:format.shape[2]]
        else
            data = (; [Symbol(f.name) => bintab_zeros(f, format.shape[2])
                    for f in fields]...)
        end
    else
        data = missing
    end
end

function bintab_zeros(f)
    if f.type <: AbstractString
        repeat(" ", f.leng)
    elseif f.type <: BitVector
        BitVector(zeros(f.leng))
    elseif f.leng == 1
        zero(f.type)
    else
        zeros(f.type, f.leng)
    end
end

function bintab_zeros(f, n)
    if f.type <: AbstractString
        fill(repeat(" ", f.leng), n)
    elseif f.type <: BitVector
        fill(BitVector(zeros(f.leng)), n)
    elseif f.leng == 1
        zeros(f.type, n)
    else
        zeros(f.type, (n, f.leng))
    end
end

function Base.read(io::IO, field::BinaryField, format::DataFormat,
    begpos::Integer; scale::Bool = true)

    type, leng = field.type, field.leng

    L, M, N = format.shape[1], first(field.slice)-1, format.shape[2]
    #  Read data array
    if !isnothing(field.pntr)
        column = Array{Vector{type}}(undef, N)
        for j = 1:N
            seek(io, begpos + L*(j-1) + M)
            K   = ntoh(read(io, field.pntr))
            beg = ntoh(read(io, field.pntr))
            seek(io, begpos + format.heap + beg)
            col = ntoh.([read(io, type) for k = 1:K])
            column[j] = scale ? field.zero .+ field.scale.*col : col
        end
    elseif type <: Bool
        column = Array{type}(undef, N)
        for j = 1:N
            seek(io, begpos + L*(j-1) + M)
            column[j] = read(io, type)
        end
    elseif type <: BitVector
        column = Array{type}(undef, N)
        for j = 1:N
            seek(io, begpos + L*(j-1) + M)
            column[j] = read(io, type, leng)
        end
    elseif type <: AbstractString
        column = Array{String}(undef, N)
        for j = 1:N
            seek(io, begpos + L*(j-1) + M)
            column[j] = rstrip(type(read(io, length(field.slice))))
        end
    elseif leng == 1
        column = Array{type}(undef, N)
        for j = 1:N
            seek(io, begpos + L*(j-1) + M)
            column[j] = ntoh(read(io, type))
        end
        column = scale ? field.zero .+ field.scale.*column : column
    else
        column = Array{type}(undef, (N, leng))
        for j = 1:N
            seek(io, begpos + L*(j-1) + M)
            column[j,:] .= ntoh.([read(io, type) for k=1:leng])
        end
        column = scale ? field.zero .+ field.scale.*column : column
    end
    column
end

function Base.read(io::IO, field::BinaryField; scale::Bool = true)

    name, type, leng = field.name, field.type, field.leng

    n = position(io)
    if type <: AbstractString
        value = type(read(io, length(field.slice)))
    elseif type <: BitVector
        value = read(io, type, leng)
    elseif leng == 0
        value = nothing
    elseif leng == 1
        value = ntoh(read(io, type))
        value = scale ? field.zero + field.scale*value : value
    else
        value = ntoh.([read(io, type) for j=1:leng])
        value = scale ? field.zero .+ field.scale.*value : value
    end

    #  Append units
    ### if !isnothing(field.unit) value *= uparse(field.unit) end
    #  Create a Pair for named fields.
    Symbol(rstrip(name)) => value
end

function Base.write(io::IO, field::BinaryField, value::U; kwds...) where
    U <: Union{AbstractArray, AbstractString, BitVector, Real, Complex}

    type, leng = field.type, field.leng

    if type <: AbstractString
        write(io, rpad(value, field.leng))
    elseif type <: BitVector
        write(io, type, value)
    elseif leng == 0
        0
    elseif leng == 1
        write(io, hton(value))
    else
        write(io, hton.(value))
    end
end

function Base.read(io::IO, ::Type{BitVector}, len)
    #  Read the bytes from IO and convert the UInt8s to a Bitvector
    bv  = falses(len)
    if len > 0
        siz = sizeofbitvector(len)
        vec = [read(io, UInt8) for j=1:siz]
        unsafe_copyto!(reinterpret(Ptr{UInt8}, pointer(bv.chunks)), pointer(vec), siz)
    end
    bv
end

function Base.write(io::IO, ::Type{BitVector}, value)
    #  Convert the BitVector to UInt8s and write the bytes to IO
    siz = sizeofbitvector(value)
    vec = zeros(UInt8, siz)
    unsafe_copyto!(pointer(vec), reinterpret(Ptr{UInt8}, pointer(value.chunks)), siz)
    write(io, vec)
end

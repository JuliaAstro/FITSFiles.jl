"""
    HDecompress module

These routines apply the H-compress decompression algorithm to a 2-D image.
Original C implementation by R. White at the STScI.

Original source files:
 - hinv.c
 - hsmooth.c
 - undigitize.c
 - decode.c
 - dodecode.c
 - qtree_decode.c
 - qread.c
 - bit_input.c
"""

module HDecompress

abstract type CompressionType end
abstract type HComp <: CompressionType end

export HDecompress, decode

# Custom exceptions
struct HCompressError <: Exception
    msg::String
end

# Global variables for bit input
const GLOBALS = Dict(
    :nextchar => 0,
    :buffer2 => UInt64(0),
    :bits_to_go => 0
)

const code_magic = UInt8[0xDD, 0x99]

"""
    decode(::Type{HComp}, input::AbstractVector{<:UInt8}, smooth::Integer) -> Int, AbstractArray

Decompress data using the H-compress algorithm and return a status code together with the decoded array.
"""
function decode(::Type{HComp}, input::AbstractVector{<:UInt8}, smooth::Integer)

    # Decode the input array and initialize the bitstream state.
    GLOBALS[:nextchar] = 0
    stat, decoded, nrows, ncols, scale = initial_decode(input)

    if stat != 0
        return stat
    end

    # Undo the digitization and apply the inverse H-transform.
    undigitize!(decoded, scale[])

    # Inverse H-transform
    stat = hinv!(decoded, nrows[], ncols[], smooth, scale[])

    return stat, decoded
end

"""
    initial_decode(infile::AbstractVector{<:UInt8}) -> Int, AbstractArray, Ref{Int}, Ref{Int}, Ref{Int}

Decode the H-compress header and bit-plane metadata, then initialize the decoded
array and return its status, contents, dimensions, and scale.
"""
function initial_decode(infile::AbstractVector{<:UInt8})

    GLOBALS[:nextchar] = 0

    # Read and validate the H-compress header.
    tmagic = qread!(infile, 2)
    if tmagic != code_magic
        throw(HCompressError("Bad file format — magic bytes do not match H-compress signature"))
    end

    nrows = Ref{Int}(readint!(infile))
    ncols = Ref{Int}(readint!(infile))
    scale = Ref{Int}(readint!(infile))
    decoded = zeros(Int32, nrows[], ncols[])

    sumall = readint!(infile, nbytes = 8)

    nbitplanes = qread!(infile, 3)

    stat = dodecode!(infile, decoded, nrows[], ncols[], nbitplanes)

    # Restore the original sum into the first pixel.
    decoded[1] = Int(sumall)

    return stat, decoded, nrows, ncols, scale
end

"""
    hinv!(a::AbstractArray{<:Integer}, nrows::Integer, ncols::Integer, smooth::Integer, scale::Integer;
          log2n = Int(floor(log2(max(nrows, ncols)))), shift = 1,
          bit0 = 1 << (log2n - 1), bit1 = bit0 << 1, bit2 = bit0 << 2,
          mask0 = -bit0, mask1 = mask0 << 1, mask2 = mask0 << 2,
          prnd0 = bit0 >> 1, prnd1 = bit1 >> 1, prnd2 = bit2 >> 1,
          nrnd0 = prnd0 - 1, nrnd1 = prnd1 - 1, nrnd2 = prnd2 - 1) -> Int

Perform inverse H-transform.
"""
function hinv!(a::AbstractArray{<:Integer}, nrows::Integer, ncols::Integer, smooth::Integer, scale::Integer;
               log2n = Int(floor(log2(max(nrows, ncols)))), shift = 1,
               bit0 = 1 << (log2n - 1), bit1 = bit0 << 1, bit2 = bit0 << 2,
               mask0 = -bit0, mask1 = mask0 << 1, mask2 = mask0 << 2,
               prnd0 = bit0 >> 1, prnd1 = bit1 >> 1, prnd2 = bit2 >> 1,
               nrnd0 = prnd0 - 1, nrnd1 = prnd1 - 1, nrnd2 = prnd2 - 1)

    roundrows = div(nrows + 1, 2)
    roundcols = div(ncols + 1, 2)
    halfrows = div(nrows, 2)
    halfcols = div(ncols, 2)
    h0 = a[1:roundrows,1:roundcols]

    if max(roundrows, roundcols) > 1
        hinv!(h0, roundrows, roundcols, smooth, scale,
        bit2 = bit1, bit1 = bit0, bit0 = bit0 >> 1, mask1 = mask0, mask0 = mask0 >> 1,
        prnd1 = prnd0, prnd0 = prnd0 >> 1, nrnd1 = nrnd0, nrnd0 = prnd0 - 1)
    end
    hy, hx, hc = zeros(Int, roundrows, roundcols), zeros(Int, roundrows, roundcols), zeros(Int, roundrows, roundcols)

    hx[1:halfrows,:] = a[roundrows+1:nrows,1:roundcols]
    hy[:,1:halfcols] = a[1:roundrows,roundcols+1:ncols]
    hc[1:halfrows,1:halfcols] = a[roundrows+1:nrows,roundcols+1:ncols]

    for i in eachindex(h0)
        hx[i] = (hx[i] + (hx[i] >= 0 ? prnd1 : nrnd1)) & mask1
        hy[i] = (hy[i] + (hy[i] >= 0 ? prnd1 : nrnd1)) & mask1
        hc[i] = (hc[i] + (hc[i] >= 0 ? prnd0 : nrnd0)) & mask0

        lowbit0 = hc[i] & bit0
        hx[i] = hx[i] >= 0 ? (hx[i] - lowbit0) : (hx[i] + lowbit0)
        hy[i] = hy[i] >= 0 ? (hy[i] - lowbit0) : (hy[i] + lowbit0)

        lowbit1 = (hc[i] ⊻ hx[i] ⊻ hy[i]) & bit1
        h0[i] = h0[i] >= 0 ? (h0[i] + lowbit0 - lowbit1) : (h0[i] + (lowbit0 == 0 ? lowbit1 : (lowbit0 - lowbit1)))
    end

    # Reconstruct the four quadrants and combine them into the full image.
    tl = (h0 - hx - hy + hc)
    bl = (h0 + hx - hy - hc)
    tr = (h0 - hx + hy - hc)
    br = (h0 + hx + hy + hc)

    # 1) “interior” cells – both horizontal and vertical neighbours exist
    if halfrows ≥ 1 && halfcols ≥ 1
        for arr in (tl,bl,tr,br)
            arr[1:halfrows, 1:halfcols] .>>= 2        # divide by 4
        end
    end

    # 2) edge strips where only one neighbour exists
    if roundrows > halfrows
        # right‑hand column of each quadrant
        for arr in (tl,bl,tr,br)
            arr[roundrows, 1:halfcols] .>>= 1        # divide by 2
        end
    end
    if roundcols > halfcols
        # bottom row of each quadrant
        for arr in (tl,bl,tr,br)
            arr[1:halfrows, roundcols] .>>= 1        # divide by 2
        end
    end

    a[1:2:nrows,1:2:ncols] = tl
    a[2:2:nrows,1:2:ncols] = bl[1:halfrows,:]
    a[1:2:nrows,2:2:ncols] = tr[:,1:halfcols]
    a[2:2:nrows,2:2:ncols] = br[1:halfrows,1:halfcols]

    if smooth > 0
        hsmooth!(a, scale)
    end

    return 0
end

"""
    hsmooth!(input::AbstractArray{<:Integer}, scale::Integer)

Smooth H-transform image by adjusting coefficients.
"""
function hsmooth!(input::AbstractArray{<:Integer}, scale::Integer)
    smax = scale >> 1
    if smax <= 0
        return
    end

    nrows, ncols = size(input)

    # Adjust x-direction differences (vertical neighbors affecting hx coefficients).
    if nrows >= 5
        oddcols = 1:2:ncols
        hm = input[1:2:nrows-3, oddcols]
        h0 = input[3:2:nrows-1, oddcols]
        hp = input[5:2:nrows, oddcols]
        candidate = view(input, 4:2:nrows, oddcols)

        diff = hp .- hm
        dmax = max.(min.(hp .- h0, h0 .- hm), zero(hm)) .<< 2
        dmin = min.(max.(hp .- h0, h0 .- hm), zero(hm)) .<< 2
        mask = dmin .< dmax

        if any(mask)
            s = diff .- (candidate .<< 3)
            s = ifelse.(s .>= 0, s .>> 3, (s .+ 7) .>> 3)
            s = clamp.(s, -smax, smax)
            candidate[mask] .+= s[mask]
        end
    end

    # Adjust y-direction differences (horizontal neighbors affecting hy coefficients).
    if ncols >= 5
        oddrows = 1:2:nrows
        hm = input[oddrows, 1:2:ncols-3]
        h0 = input[oddrows, 3:2:ncols-1]
        hp = input[oddrows, 5:2:ncols]
        candidate = view(input, oddrows, 4:2:ncols)

        diff = hp .- hm
        dmax = max.(min.(hp .- h0, h0 .- hm), zero(hm)) .<< 2
        dmin = min.(max.(hp .- h0, h0 .- hm), zero(hm)) .<< 2
        mask = dmin .< dmax

        if any(mask)
            s = diff .- (candidate .<< 3)
            s = ifelse.(s .>= 0, s .>> 3, (s .+ 7) .>> 3)
            s = clamp.(s, -smax, smax)
            candidate[mask] .+= s[mask]
        end
    end
end


"""
    undigitize!(a::AbstractArray{<:Integer}, scale::Integer)

Multiply by scale factor.
"""
function undigitize!(a::AbstractArray{<:Integer}, scale::Integer)
    if scale <= 1
        return
    end
    a .= a .* scale
end

"""
    dodecode!(infile::AbstractVector{UInt8}, decoded::AbstractArray{<:Integer},
              nrows::Integer, ncols::Integer, nbitplanes::AbstractVector{UInt8})

Decode packed bit-plane data into the output array and restore the sign bits.
"""
function dodecode!(infile::AbstractVector{UInt8}, decoded::AbstractArray{<:Integer},
                   nrows::Integer, ncols::Integer, nbitplanes::AbstractVector{UInt8})

    nel = nrows * ncols
    roundrows = div(nrows, 2, RoundUp)
    roundcols = div(ncols, 2, RoundUp)
    halfrows = div(nrows, 2)
    halfcols = div(ncols, 2)

    # Initialize array to zero
    decoded .= 0

    tl = decoded[1:roundrows,1:roundcols]
    bl = decoded[roundrows+1:nrows,1:roundcols]
    tr = decoded[1:roundrows,roundcols+1:ncols]
    br = decoded[roundrows+1:nrows,roundcols+1:ncols]

    # Initialize the bit input state and decode each quadrant.
    start_inputing_bits()

    # Quadrant 1: rows 1:ny2, cols 1:nx2
    stat = qtree_decode!(infile, tl, roundrows, roundcols, nbitplanes[1])
    if stat != 0
        throw(HCompressError("qtree_decode! failed in quadrant 1 (top-left), status=$stat"))
    end

    # Quadrant 2: rows ny2+1:ny, cols 1:nx2
    stat = qtree_decode!(infile, bl, halfrows, roundcols, nbitplanes[2])
    if stat != 0
        throw(HCompressError("qtree_decode! failed in quadrant 2 (bottom-left), status=$stat"))
    end

    # Quadrant 3: rows 1:ny2, cols nx2+1:nx
    stat = qtree_decode!(infile, tr, roundrows, halfcols, nbitplanes[2])
    if stat != 0
        throw(HCompressError("qtree_decode! failed in quadrant 3 (top-right), status=$stat"))
    end

    # Quadrant 4: rows ny2+1:ny, cols nx2+1:nx
    stat = qtree_decode!(infile, br, halfrows, halfcols, nbitplanes[3])
    if stat != 0
        throw(HCompressError("qtree_decode! failed in quadrant 4 (bottom-right), status=$stat"))
    end

    skip_to_byte_boundary()

    decoded[1:roundrows,1:roundcols] = tl
    decoded[roundrows+1:nrows,1:roundcols] = bl
    decoded[1:roundrows,roundcols+1:ncols] = tr
    decoded[roundrows+1:nrows,roundcols+1:ncols] = br

    # Check for the EOF marker after the bit-plane payload.
    if input_nybble!(infile) != 0
        throw(HCompressError("Bad bit plane values or unexpected EOF in bitplane data"))
    end

    # Get sign bits
    start_inputing_bits()
    for i = 1:nrows
        for j = 1:ncols
            if decoded[i, j] != 0
                if input_bit!(infile) != 0
                    decoded[i, j] = -decoded[i, j]
                end
            end
        end
    end
    return 0
end

"""
    qtree_decode!(infile::AbstractVector{UInt8}, outfile::AbstractArray{<:Integer},
                       nrows::Integer, ncols::Integer, nbitplanes::UInt8) -> Int
Decode bit planes using quadtree coding.
"""
function qtree_decode!(infile::AbstractVector{UInt8}, outfile::AbstractArray{<:Integer},
                       nrows::Integer, ncols::Integer, nbitplanes::UInt8)

    nqmax = max(ncols, nrows)
    log2n = Int(floor(log2(nqmax)))
    if nqmax > (1 << log2n)
        log2n += 1
    end

    roundrows = div(nrows, 2, RoundUp)
    roundcols = div(ncols, 2, RoundUp)
    encoded_bitmap = zeros(UInt8, roundrows, roundcols)
    decoded_bitmap = zeros(UInt8, nrows, ncols)

    for bit = Int(nbitplanes)-1:-1:0
        # Align to the next byte boundary before reading the next bit plane.
        skip_to_byte_boundary()

        b = input_nybble!(infile)

        if b == 0
            # Bitmap written directly
            read_bdirect!(infile, outfile, nrows, ncols, encoded_bitmap, bit)
        elseif b == 0xf
            # Bitmap was quadtree-coded
            encoded_bitmap[1, 1] = input_huffman!(infile)

            nx = 1
            ny = 1
            nfx = nrows
            nfy = ncols
            c = 1 << log2n

            for k = 1:log2n-1
                c = c >> 1
                nx = nx << 1
                ny = ny << 1

                if nfx <= c
                    nx -= 1
                else
                    nfx -= c
                end

                if nfy <= c
                    ny -= 1
                else
                    nfy -= c
                end

                decoded_bitmap = qtree_expand!(infile, encoded_bitmap, nx, ny)
                encoded_bitmap = decoded_bitmap
            end

            qtree_bitins!(decoded_bitmap, nrows, ncols, outfile, bit)
        else
            throw(HCompressError("Bad quadtree format code while decoding bitplane (nibble=$b)"))
        end
    end
    return 0
end

"""
    qtree_expand!(infile::AbstractVector{UInt8}, encoded_bitmap::AbstractArray{UInt8}, nrows::Integer, ncols::Integer)

Do one quadtree expansion step.
"""
function qtree_expand!(infile::AbstractVector{UInt8}, encoded_bitmap::AbstractArray{UInt8}, nrows::Integer, ncols::Integer)

    decoded_bitmap = qtree_copy!(encoded_bitmap, nrows, ncols)

    for i = nrows*ncols:-1:1
        if decoded_bitmap[i] != 0
            decoded_bitmap[i] = input_huffman!(infile)
        end
    end
    return decoded_bitmap
end

"""
    qtree_copy!(encoded_bitmap::AbstractArray{UInt8}, nrows::Integer, ncols::Integer)

Expand a quadtree-coded bitmap into a full-size bitmap by mapping each 4-bit value
from `encoded_bitmap` into its corresponding 2×2 block in the output plane.
Unused pixels and edge pixels that fall outside the logical grid remain zero.
"""
function qtree_copy!(encoded_bitmap::AbstractArray{UInt8}, nrows::Integer, ncols::Integer)

    halfrows = div(nrows, 2)
    halfcols = div(ncols, 2)
    roundrows = div(nrows + 1, 2)
    roundcols = div(ncols + 1, 2)
    decoded_bitmap = zeros(UInt8, nrows, ncols)

    decoded_bitmap[1:2:nrows, 1:2:ncols] = encoded_bitmap[1:roundrows, 1:roundcols] .>> 3 .& 1
    decoded_bitmap[2:2:nrows, 1:2:ncols] = encoded_bitmap[1:halfrows, 1:roundcols] .>> 2 .& 1
    decoded_bitmap[1:2:nrows, 2:2:ncols] = encoded_bitmap[1:roundrows, 1:halfcols] .>> 1 .& 1
    decoded_bitmap[2:2:nrows, 2:2:ncols] = encoded_bitmap[1:halfrows, 1:halfcols] .& 1

    return decoded_bitmap
end

"""
    qtree_bitins!(bitmap::AbstractArray{UInt8}, nrows::Integer, ncols::Integer,
        a::AbstractArray{<:Integer}, bit::Integer)

Copy 4-bit values and insert into bitplane.
"""
function qtree_bitins!(bitmap::AbstractArray{UInt8}, nrows::Integer, ncols::Integer,
        a::AbstractArray{<:Integer}, bit::Integer)

    # plane_val = 1 << bit
    roundrows = div(nrows, 2, RoundUp)
    roundcols = div(ncols, 2, RoundUp)
    halfrows = div(nrows, 2)
    halfcols = div(ncols, 2)

    # treat `a` as nrows×ncols matrix (column‑major)
    Amat = reshape(a, nrows, ncols)

    Amat[1:2:nrows, 1:2:ncols] .|= ((bitmap[1:roundrows, 1:roundcols] .>> 3) .& 1) .<< bit
    Amat[2:2:nrows, 1:2:ncols] .|= ((bitmap[1:halfrows, 1:roundcols] .>> 2) .& 1) .<< bit
    Amat[1:2:nrows, 2:2:ncols] .|= ((bitmap[1:roundrows, 1:halfcols] .>> 1) .& 1) .<< bit
    Amat[2:2:nrows, 2:2:ncols] .|= (bitmap[1:halfrows, 1:halfcols] .& 1) .<< bit
end

"""
    read_bdirect!(infile::AbstractVector{UInt8}, outfile::AbstractArray{<:Integer},
                       nrows::Integer, ncols::Integer, encoded_bitmap::AbstractArray{UInt8}, bit::Integer)

Read direct bitmap and insert into bitplane.
"""
function read_bdirect!(infile::AbstractVector{UInt8}, outfile::AbstractArray{<:Integer},
                       nrows::Integer, ncols::Integer, encoded_bitmap::AbstractArray{UInt8}, bit::Integer)

    input_nnybble!(infile, div(nrows + 1, 2), div(ncols + 1, 2), encoded_bitmap)
    # decoded_bitmap = qtree_copy!(encoded_bitmap, nrows, ncols)
    qtree_bitins!(encoded_bitmap, nrows, ncols, outfile, bit)
end

"""
    start_inputing_bits()

Reset the bit-input state before decoding the next bitstream segment.
"""
function start_inputing_bits()
    GLOBALS[:bits_to_go] = 0
    GLOBALS[:buffer2] = UInt64(0)
end

"""
    skip_to_byte_boundary()

Skip remaining bits in current byte to align to next byte boundary.
This is critical for synchronizing bit reading between Huffman codes and nybbles.
"""
function skip_to_byte_boundary()
    # Discard any remaining bits in the current byte by setting bits_to_go to 0
    # This forces the next read to load a fresh byte from the file
    if GLOBALS[:bits_to_go] > 0 && GLOBALS[:bits_to_go] < 8
        GLOBALS[:bits_to_go] = 0
        GLOBALS[:buffer2] = 0
    end
end

"""
    input_bit!(infile::AbstractVector{UInt8}) -> Int

Input a single bit.
"""
function input_bit!(infile::AbstractVector{UInt8})

    if GLOBALS[:bits_to_go] == 0
        GLOBALS[:buffer2] = UInt64(infile[GLOBALS[:nextchar] + 1])
        GLOBALS[:nextchar] += 1
        GLOBALS[:bits_to_go] = 8
    end

    GLOBALS[:bits_to_go] -= 1
    return (GLOBALS[:buffer2] >> GLOBALS[:bits_to_go]) & 1
end

"""
    input_nbits!(infile::AbstractVector{UInt8}, n::Integer) -> Int

Input n bits.
"""
function input_nbits!(infile::AbstractVector{UInt8}, n::Integer)

    mask = [0, 1, 3, 7, 15, 31, 63, 127, 255]

    if GLOBALS[:bits_to_go] < n
        # GLOBALS[:buffer2] = (GLOBALS[:buffer2] << 8) | UInt64(infile[GLOBALS[:nextchar] + 1])
        # Only keep the valid bits (the ones we haven't read yet)
        valid_bits = GLOBALS[:buffer2] & ((UInt64(1) << GLOBALS[:bits_to_go]) - 1)
        new_byte = UInt64(infile[GLOBALS[:nextchar] + 1])

        GLOBALS[:buffer2] = (valid_bits << 8) | new_byte
        GLOBALS[:nextchar] += 1
        GLOBALS[:bits_to_go] += 8
    end

    GLOBALS[:bits_to_go] -= n
    val = (GLOBALS[:buffer2] >> GLOBALS[:bits_to_go]) & mask[n + 1]
    return val
end

"""
    input_nybble!(infile::Vector{UInt8}) -> Int

Input 4 bits.
"""
function input_nybble!(infile::AbstractVector{UInt8})

    if GLOBALS[:bits_to_go] < 4
        # GLOBALS[:buffer2] = (GLOBALS[:buffer2] << 8) | UInt64(infile[GLOBALS[:nextchar] + 1])
        # Only keep the valid bits (the ones we haven't read yet)
        # bits_to_go tells us how many valid bits are left
        valid_bits = GLOBALS[:buffer2] & ((UInt64(1) << GLOBALS[:bits_to_go]) - 1)
        new_byte = UInt64(infile[GLOBALS[:nextchar] + 1])

        GLOBALS[:buffer2] = (valid_bits << 8) | new_byte
        GLOBALS[:nextchar] += 1
        GLOBALS[:bits_to_go] += 8
    end

    GLOBALS[:bits_to_go] -= 4
    val = (GLOBALS[:buffer2] >> GLOBALS[:bits_to_go]) & 15
    if val != 0 && val != 15
        println("[DEBUG_BAD_NIBBLE] Read nibble=$val from buffer2=$(GLOBALS[:buffer2]), bits_to_go_after=$(GLOBALS[:bits_to_go])")
    end
    return val
end

"""
    input_nnybble!(infile::AbstractVector{UInt8}, nrows::Integer, ncols::Integer, array::AbstractArray{UInt8})

Input array of 4-bit nybbles.
"""
function input_nnybble!(infile::AbstractVector{UInt8}, nrows::Integer, ncols::Integer, array::AbstractArray{UInt8})
    # Simple, robust implementation: read nybbles one at a time
    for i = 1:nrows
        for j = 1:ncols
            array[i,j] = UInt8(input_nybble!(infile))
        end
    end
end

"""
    input_huffman!(infile::AbstractVector{UInt8}) -> Int

Huffman decode fixed codes.
"""
function input_huffman!(infile::AbstractVector{UInt8})

    # Get first 3 bits
    c = input_nbits!(infile, 3)

    if c < 4
        # This is all we need
        return 1 << c
    end

    # Get next bit
    c = input_bit!(infile) | (c << 1)

    if c < 13
        switch_val = c
        if switch_val == 8
            return 3
        elseif switch_val == 9
            return 5
        elseif switch_val == 10
            return 10
        elseif switch_val == 11
            return 12
        elseif switch_val == 12
            return 15
        end
    end

    # Get another bit
    c = input_bit!(infile) | (c << 1)

    if c < 31
        switch_val = c
        if switch_val == 26
            return 6
        elseif switch_val == 27
            return 7
        elseif switch_val == 28
            return 9
        elseif switch_val == 29
            return 11
        elseif switch_val == 30
            return 13
        end
    end

    # Need 6th bit
    c = input_bit!(infile) | (c << 1)

    if c == 62
        return 0
    else
        return 14
    end
end

"""
    readint!(infile::AbstractVector{UInt8}; nbytes::Integer=4) -> Int

Read n-byte integer from file.
"""
function readint!(infile::AbstractVector{UInt8}; nbytes::Integer=4)

    b = qread!(infile, nbytes)
    a::Int = b[1]
    for i = 2:nbytes
        a = (a << 8) + b[i]
    end
    return a
end

"""
    qread!(file::AbstractVector{UInt8}, n::Integer) -> Vector{UInt8}

Read n bytes from file.
"""
function qread!(file::AbstractVector{UInt8}, n::Integer)

    buffer = file[GLOBALS[:nextchar]+1:GLOBALS[:nextchar]+n]
    GLOBALS[:nextchar] += n
    return buffer
end

end # module HDecompress

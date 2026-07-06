"""
    HCompress module

These routines apply the H-compress compression algorithm to a 2-D image.
Original C implementation by R. White at the STScI.

Original source files:
 - htrans.c 
 - digitize.c 
 - encode.c 
 - qwrite.c 
 - doencode.c 
 - bit_output.c 
 - qtree_encode.c
"""

module HCompress

export HCompress, encode

abstract type CompressionType end
abstract type HComp <: CompressionType end

# Global variables for bit output
const GLOBALS = Dict(
    :noutchar => 0,
    :noutmax => 0,
    :buffer2 => UInt64(0),
    :bits_to_go2 => 8,
    :bitcount => 0
)

# Huffman code values and number of bits in each code
const code = [
    0x3e, 0x00, 0x01, 0x08, 0x02, 0x09, 0x1a, 0x1b,
    0x03, 0x1c, 0x0a, 0x1d, 0x0b, 0x1e, 0x3f, 0x0c
]

const ncode = [
    6, 3, 3, 4, 3, 4, 5, 5,
    3, 5, 4, 5, 4, 5, 6, 4
]

const code_magic = UInt8[0xDD, 0x99]

"""
    encode(::Type{HComp}, input::AbstractArray{<:Integer}, scale::Integer;
           output::AbstractVector{<:UInt8} = Vector{UInt8}(undef, length(input) * 4 * 5),
           nbytes::Ref{Integer} = Ref{Integer}(length(output))) -> Int, Vector{UInt8}

Encode an image using the H-compress algorithm and return a status code together with the encoded byte buffer.
"""
function encode(::Type{HComp},input::AbstractArray{<:Integer}, scale::Integer; 
                    output::AbstractVector{<:UInt8} = Vector{UInt8}(undef, length(input) * 4 * 5), nbytes::Ref{Integer} = Ref{Integer}(length(output)))
    
    if nbytes[] <= 0
        return 1  # Error status
    end
    
    nrows, ncols = size(input)

    # Apply the H-transform before digitizing the coefficients.
    input_copy = copy(input)
    stat = htrans!(input_copy, nrows, ncols)
    if stat != 0
        return stat
    end

    # Quantize the transformed values using the requested scale.
    digitize!(input_copy, scale)
    
    # encode and write to output array
    GLOBALS[:noutmax] = nbytes[]
    nbytes[] = 0
    
    # Encode the transformed values into the output buffer.
    stat = encode_data!(output, nbytes, input_copy, nrows, ncols, scale)
    
    return stat, output
end

"""
    htrans!(shuffled::AbstractArray{<:Integer}, nrows::Integer, ncols::Integer;
                mask::Integer = Int(-2), mask2::Integer = mask << 1,
                prnd::Integer = Int(1), prnd2::Integer = prnd << 1, nrnd2::Integer = prnd2 - 1) -> int

Perform recursive H-transform on integer image with given size.
"""
function htrans!(shuffled::AbstractArray{<:Integer}, nrows::Integer, ncols::Integer;
                mask::Integer = Int(-2), mask2::Integer = mask << 1,
                prnd::Integer = Int(1), prnd2::Integer = prnd << 1, nrnd2::Integer = prnd2 - 1)
    halfrows = div(nrows, 2)
    halfcols = div(ncols, 2)
    roundrows = div(nrows, 2, RoundUp)
    roundcols = div(ncols, 2, RoundUp)

    #Create temp arrays with equal dimensions for easy manipulation
    tr, bl, br = zeros(Int, roundrows, roundcols), zeros(Int, roundrows, roundcols), zeros(Int, roundrows, roundcols)

    #Slice input array, saving the top left pixel of each 2x2 bin to a temp array
    #repeat for top right, bottom left, and bottom right
    tl = shuffled[1:2:nrows, 1:2:ncols]
    bl[1:halfrows, :] = shuffled[2:2:nrows, 1:2:ncols]
    tr[:, 1:halfcols] = shuffled[1:2:nrows, 2:2:ncols]
    br[1:halfrows, 1:halfcols] = shuffled[2:2:nrows, 2:2:ncols]

    h0 = tl + tr + bl + br
    hy = tr - tl + br - bl
    hx = bl + br - tl - tr
    hc = br - tr - bl + tl

    for i in eachindex(h0)
        h0[i] = ((h0[i] >= 0) ? (h0[i] + prnd2) : (h0[i] + nrnd2)) & mask2
        hy[i] = ((hy[i] >= 0) ? (hy[i] + prnd) : hy[i]) & mask
        hx[i] = ((hx[i] >= 0) ? (hx[i] + prnd) : hx[i]) & mask
    end
    shuffled[1:roundrows,1:roundcols] = h0
    shuffled[roundrows+1:nrows,1:roundcols] = hx[1:halfrows,1:roundcols]
    shuffled[1:roundrows,roundcols+1:ncols] = hy[1:roundrows,1:halfcols]
    shuffled[roundrows+1:nrows,roundcols+1:ncols] = hc[1:halfrows,1:halfcols]
    if max(roundrows, roundcols) > 1
        # Recursive call on the top-left quadrant
        htrans!(view(shuffled, 1:roundrows, 1:roundcols), roundrows, roundcols, mask = mask2, prnd = prnd2, mask2 = mask2 << 1, nrnd2 = (prnd2 << 1) - 1, prnd2 = prnd2 << 1)
    end
    
    return 0
end

"""
    digitize!(shuffled::AbstractArray{<:Integer}, scale::Integer)

Digitize H-transform by rounding to multiple of scale.
"""
function digitize!(shuffled::AbstractArray{<:Integer}, scale::Integer)
    if scale <= 1
        return
    end
    for i in eachindex(shuffled)
        if shuffled[i] > 0
            shuffled[i] = div(shuffled[i], scale, RoundNearest)
        else
            shuffled[i] = div(shuffled[i], scale, RoundNearest)
        end
    end
end

"""
    encode_data!(outfile::AbstractVector{<:UInt8}, nlength::Ref{Integer}, shuffled::AbstractArray{<:Integer}, 
                 nrows::Integer, ncols::Integer, scale::Integer) -> int

Encode H-transform and write to output array.
"""
function encode_data!(outfile::AbstractVector{<:UInt8}, nlength::Ref{Integer}, shuffled::AbstractArray{<:Integer}, 
                 nrows::Integer, ncols::Integer, scale::Integer)    
    GLOBALS[:noutchar] = 0
    nel = nrows * ncols
    
    # Write the file header and metadata.
    qwrite!(outfile, code_magic)
    writeint!(outfile, nrows)
    writeint!(outfile, ncols)
    writeint!(outfile, scale)
    writeint!(outfile, Int(shuffled[1,1]), nbytes = 8)
    
    shuffled[1,1] = 0
    
    # Allocate storage for the sign-bit stream.
    signbits = zeros(UInt8, div(nel, 8, RoundUp))
    nsign = 1
    bits_to_go = 8
    
    for i in 1:nrows
        for j in 1:ncols
            if shuffled[i,j] > 0
                signbits[nsign] = signbits[nsign] << 1
                bits_to_go -= 1
            elseif shuffled[i,j] < 0
                signbits[nsign] = (signbits[nsign] << 1) | 1
                bits_to_go -= 1
                shuffled[i,j] = -shuffled[i,j]
            end
            
            if bits_to_go == 0
                bits_to_go = 8
                nsign += 1
            end
        end
    end
    
    if bits_to_go != 8
        signbits[nsign] = signbits[nsign] << bits_to_go
        nsign += 1
    end
    # Determine how many bit planes are needed for the quadrants.
    roundrows = div(nrows, 2, RoundUp)
    roundcols = div(ncols, 2, RoundUp)
    quadrantmax = [maximum(shuffled[1:roundrows, 1:roundcols]),
            max(maximum(shuffled[1:roundrows, roundcols+1:ncols]),maximum(shuffled[roundrows+1:nrows, 1:roundcols])),
            maximum(shuffled[roundrows+1:nrows, roundcols+1:ncols])]
    # Record the bit-plane count for each quadrant.
    nbitplanes = zeros(UInt8, 3)
    for q = 1:3
        while quadrantmax[q] > 0
            quadrantmax[q] = quadrantmax[q] >> 1
            nbitplanes[q] += 1
        end
    end
    
    # Write nbitplanes
    if qwrite!(outfile, nbitplanes) == 0
        nlength[] = GLOBALS[:noutchar]
        return 1
    end
    
    # Encode the bit planes into the output stream.
    stat = doencode!(outfile, shuffled, nrows, ncols, nbitplanes)
    
    # Append the sign-bit stream after the encoded values.
    if nsign > 1
        if qwrite!(outfile, view(signbits, 1:nsign-1)) == 0
            println("Ran out of space in output")
            nlength[] = GLOBALS[:noutchar]
            return 1
        end
    end
    
    nlength[] = GLOBALS[:noutchar]
    
    if GLOBALS[:noutchar] >= GLOBALS[:noutmax]
        return 1
    end
    
    return stat
end

"""
    writeint!(outfile::AbstractVector{<:UInt8}, int::Integer; nbytes::Integer = 4)

Write integer to outfile one byte at a time.
"""
function writeint!(outfile::AbstractVector{<:UInt8}, int::Integer; nbytes::Integer = 4)
    b = zeros(UInt8, nbytes)
    val = int
    for i = nbytes:-1:1
        b[i] = val & 0xff
        val = val >> 8
    end
    for i = 1:nbytes
        qwrite!(outfile, [b[i]])
    end
end

"""
    qwrite!(file::AbstractVector{UInt8}, buffer::AbstractVector{UInt8}) -> int

Write bytes to output array. Returns number of bytes written or 0 on failure.
"""
function qwrite!(file::AbstractVector{UInt8}, buffer::AbstractVector{UInt8})
    
    n = length(buffer)
    if GLOBALS[:noutchar] + n > GLOBALS[:noutmax]
        println("  qwrite! failed: noutchar=$(GLOBALS[:noutchar]), n=$n, noutmax=$(GLOBALS[:noutmax])")
        return 0
    end
    
    file[GLOBALS[:noutchar]+1:GLOBALS[:noutchar]+n] .= buffer
    GLOBALS[:noutchar] += n
    
    return n
end

"""
    doencode!(outfile::AbstractVector{<:UInt8}, shuffled::AbstractArray{<:Integer}, nrows::Integer, ncols::Integer,
              nbitplanes::AbstractVector{<:UInt8}) -> Int

Encode a 2-D array and write the packed bit-plane data to outfile.
"""
function doencode!(outfile::AbstractVector{<:UInt8}, shuffled::AbstractArray{<:Integer}, nrows::Integer, ncols::Integer,
                   nbitplanes::AbstractVector{<:UInt8})
    halfrows = div(nrows, 2)
    halfcols = div(ncols, 2)
    roundrows = div(nrows, 2, RoundUp)
    roundcols = div(ncols, 2, RoundUp)

    tl = shuffled[1:roundrows, 1:roundcols]
    bl = shuffled[roundrows+1:nrows, 1:roundcols]
    tr = shuffled[1:roundrows, roundcols+1:ncols]
    br = shuffled[roundrows+1:nrows, roundcols+1:ncols]
    
    start_outputting_bits()
    
    # Encode the four quadrants in order.
    # Quadrant 1
    stat = qtree_encode!(outfile, tl, roundrows, roundcols, nbitplanes[1])

    if stat == 0
        # Quadrant 2
        stat = qtree_encode!(outfile, bl, halfrows, roundcols, nbitplanes[2])
    end

    if stat == 0
        # Quadrant 3
        stat = qtree_encode!(outfile, tr, roundrows, halfcols, nbitplanes[2])
    end
    
    if stat == 0
        # Quadrant 4
        stat = qtree_encode!(outfile, br, halfrows, halfcols, nbitplanes[3])
    end
    
    # Add EOF symbol (4-bit nybble)
    output_nbits!(outfile, 0, 4)
    done_outputting_bits!(outfile)
    
    return stat
end

"""
    start_outputting_bits()

Initialize the bit-output buffer before writing encoded data.
"""
function start_outputting_bits()
    GLOBALS[:buffer2] = UInt64(0)
    GLOBALS[:bits_to_go2] = 8
    GLOBALS[:bitcount] = 0
end

"""
    output_nbits!(outfile::AbstractVector{<:UInt8}, bits::Integer, n::Integer)

Output n bits to buffer.
"""
function output_nbits!(outfile::AbstractVector{<:UInt8}, bits::Integer, n::Integer)
    
    mask = [0, 1, 3, 7, 15, 31, 63, 127, 255]
    GLOBALS[:buffer2] = GLOBALS[:buffer2] << n
    GLOBALS[:buffer2] |= (bits & mask[n+1])
    GLOBALS[:bits_to_go2] -= n
    
    if GLOBALS[:bits_to_go2] <= 0
        outfile[GLOBALS[:noutchar]+1] = ((GLOBALS[:buffer2] >> (-GLOBALS[:bits_to_go2])) & 0xff) % UInt8
        if GLOBALS[:noutchar] < GLOBALS[:noutmax]
            GLOBALS[:noutchar] += 1
        end
        # Keep only the bits that haven't been written yet (the low bits)
        GLOBALS[:buffer2] = GLOBALS[:buffer2] & ((UInt64(1) << (-GLOBALS[:bits_to_go2])) - 1)
        GLOBALS[:bits_to_go2] += 8
    end
    
    GLOBALS[:bitcount] += n
end

"""
    output_nybble!(outfile::AbstractVector{<:UInt8}, bits::Integer)

Output 4-bit nybble.
"""
function output_nybble!(outfile::AbstractVector{<:UInt8}, bits::Integer)
    
    GLOBALS[:buffer2] = (GLOBALS[:buffer2] << 4) | (bits & 15)
    GLOBALS[:bits_to_go2] -= 4
    
    if GLOBALS[:bits_to_go2] <= 0
        outfile[GLOBALS[:noutchar]+1] = ((GLOBALS[:buffer2] >> (-GLOBALS[:bits_to_go2])) & 0xff) % UInt8
        if GLOBALS[:noutchar] < GLOBALS[:noutmax]
            GLOBALS[:noutchar] += 1
        end
        GLOBALS[:bits_to_go2] += 8
    end
    
    GLOBALS[:bitcount] += 4
end

"""
    done_outputting_bits!(outfile::AbstractVector{<:UInt8})

Flush any remaining bits to the output buffer.
"""
function done_outputting_bits!(outfile::AbstractVector{<:UInt8})
    
    if GLOBALS[:bits_to_go2] < 8
        outfile[GLOBALS[:noutchar]+1] = ((GLOBALS[:buffer2] << GLOBALS[:bits_to_go2]) & 0xff) % UInt8
        if GLOBALS[:noutchar] < GLOBALS[:noutmax]
            GLOBALS[:noutchar] += 1
        end
        GLOBALS[:bitcount] += GLOBALS[:bits_to_go2]
        GLOBALS[:buffer2] = 0
        GLOBALS[:bits_to_go2] = 8
    end
end

# Buffer state used while packing Huffman-coded values.
bitbuffer_ref = [UInt64(0)]
bits_to_go3_ref = [0]

"""
    qtree_encode!(outfile::AbstractVector{<:UInt8}, quadrant::AbstractArray{<:Integer},
                       nrows::Integer, ncols::Integer, nbitplanes::Integer) -> Int

Encode values in quadrant using binary quadtree coding.
"""
function qtree_encode!(outfile::AbstractVector{<:UInt8}, quadrant::AbstractArray{<:Integer},
                       nrows::Integer, ncols::Integer, nbitplanes::Integer)
    nmax = max(nrows, ncols)
    log2n = Int(floor(log2(nmax)))
    if nmax > (1 << log2n)
        log2n += 1
    end
    
    roundrows = div(nrows, 2, RoundUp)
    roundcols = div(ncols, 2, RoundUp)

    bmax = div(roundrows * roundcols + 1, 2)
    
    buffer = zeros(UInt8, bmax)
    
    for bit = Int(nbitplanes)-1:-1:0
        # Align to the next byte boundary before writing the next bit plane.
        if GLOBALS[:bits_to_go2] < 8
            outfile[GLOBALS[:noutchar]+1] = ((GLOBALS[:buffer2] << GLOBALS[:bits_to_go2]) & 0xff) % UInt8
            if GLOBALS[:noutchar] < GLOBALS[:noutmax]
                GLOBALS[:noutchar] += 1
            end
            GLOBALS[:bits_to_go2] = 8
            GLOBALS[:buffer2] = 0
        end
        
        b = 0
        bitbuffer_ref[1] = 0
        bits_to_go3_ref[1] = 0
        
        # Extract the current bit plane from the quadrant values.
        bitmask = qtree_onebit!(quadrant, nrows, ncols, bit)
        og_bitmask = copy(bitmask)
        roundrows = div(nrows, 2, RoundUp)
        roundcols = div(ncols, 2, RoundUp)
        
        # Copy non-zero values to buffer
        b_ret = bufcopy!(bitmask, buffer, b, bmax, bitbuffer_ref, bits_to_go3_ref)
        if b_ret < 0
            # buffer overflow -> write direct bitmap
            write_bdirect!(bitmask, outfile, nrows, ncols, bit)
        else
            # Do reductions
            done = false
            for k = 1:log2n-1
                bitmask = qtree_reduce!(bitmask, roundrows, roundcols)
                roundrows = div(roundrows + 1, 2)
                roundcols = div(roundcols + 1, 2)

                b_ret2 = bufcopy!(bitmask, buffer, b_ret, bmax, bitbuffer_ref, bits_to_go3_ref)
                if b_ret2 < 0
                    write_bdirect!(og_bitmask, outfile, nrows, ncols, bit)
                    done = true
                    break
                else
                    b_ret = b_ret2
                end
            end

            if !done
                # Write the quadtree-coded bit-plane payload.
                output_nbits!(outfile, 0xF, 4)

                if b_ret == 0
                    if bits_to_go3_ref[1] > 0
                        output_nbits!(outfile, bitbuffer_ref[1] & ((1 << bits_to_go3_ref[1]) - 1), bits_to_go3_ref[1])
                    else
                        output_nbits!(outfile, code[1], ncode[1])
                    end
                else
                    if bits_to_go3_ref[1] > 0
                        output_nbits!(outfile, bitbuffer_ref[1] & ((1 << bits_to_go3_ref[1]) - 1), bits_to_go3_ref[1])
                    end

                    # Write packed Huffman bytes into the bit stream in reverse
                    # order to match the bit-packing used when they were produced.
                    for i = b_ret:-1:1
                        output_nbits!(outfile, buffer[i], 8)
                    end
                end
            end
        end
        done_outputting_bits!(outfile)
    end
    
    return 0
end

"""
    qtree_onebit!(input::AbstractArray{<:Integer}, nrows::Integer, ncols::Integer, bit::Integer)

Extract single bit plane from array.
"""
function qtree_onebit!(input::AbstractArray{<:Integer}, nrows::Integer, ncols::Integer, bit::Integer)
    
    output = zeros(UInt8, nrows, ncols)
    b0 = 1 << bit
    b1 = b0 << 1
    b2 = b0 << 2
    b3 = b0 << 3
    
    halfrows = div(nrows, 2)
    halfcols = div(ncols, 2)
    roundrows = div(nrows, 2, RoundUp)
    roundcols = div(ncols, 2, RoundUp)

    #Create temp arrays with equal dimensions for easy manipulation
    tl, bl, tr, br = zeros(Int, roundrows, roundcols), zeros(Int, roundrows, roundcols), zeros(Int, roundrows, roundcols), zeros(Int, roundrows, roundcols)

    #Slice input array, saving the top left pixel of each 2x2 bin to a temp array
    #repeat for top right, bottom left, and bottom right
    tl = input[1:2:nrows, 1:2:ncols]
    if nrows >= 2
        bl[1:halfrows, :] = input[2:2:nrows, 1:2:ncols]
    end
    if ncols >= 2
        tr[:, 1:halfcols] = input[1:2:nrows, 2:2:ncols]
        if nrows >= 2
            br[1:halfrows, 1:halfcols] = input[2:2:nrows, 2:2:ncols]
        end
    end

    output = UInt8.(
        ((br .& b0) .| ((tr .<< 1) .& b1) .| ((bl .<< 2) .& b2) .| ((tl .<< 3) .& b3)) .>> bit
    )
    return output
end

"""
    qtree_reduce!(input::AbstractArray, nrows::Integer, ncols::Integer)

Perform one quadtree reduction step on a nrows×ncols plane.
"""
function qtree_reduce!(input::AbstractArray, nrows::Integer, ncols::Integer)
    
    roundrows = div(nrows, 2, RoundUp)
    roundcols = div(ncols, 2, RoundUp)
    halfrows = div(nrows, 2)
    halfcols = div(ncols, 2)
    tl, bl, tr, br = zeros(Int, roundrows, roundcols), zeros(Int, roundrows, roundcols), zeros(Int, roundrows, roundcols), zeros(Int, roundrows, roundcols)

    tl = input[1:2:nrows, 1:2:ncols]
    if nrows >= 2
        bl[1:halfrows, :] = input[2:2:nrows, 1:2:ncols]
    end
    if ncols >= 2
        tr[:, 1:halfcols] = input[1:2:nrows, 2:2:ncols]
        if nrows >= 2
            br[1:halfrows, 1:halfcols] = input[2:2:nrows, 2:2:ncols]
        end
    end

    output = (
        (UInt8.(br .!= 0) .| (UInt8.(tr .!= 0) .<< 1) .| (UInt8.(bl .!= 0) .<< 2) .| (UInt8.(tl .!= 0) .<< 3))
    )

    return output
end

"""
    bufcopy!(input::AbstractArray, buffer::AbstractVector{<:UInt8}, 
                  b::Integer, bmax::Integer, bitbuffer_ref::AbstractVector{<:UInt64}, bits_to_go3_ref::AbstractVector) -> Int

Copy non-zero codes from array to buffer. Returns 1 if buffer overflows.
"""
function bufcopy!(input::AbstractArray, buffer::AbstractVector{<:UInt8}, 
                  b::Integer, bmax::Integer, bitbuffer_ref::AbstractVector{<:UInt64}, bits_to_go3_ref::AbstractVector)
    
    b_local = b
    
    for i in eachindex(input)
        if input[i] != 0
            bitbuffer_ref[1] |= (UInt64(code[input[i]+1]) << bits_to_go3_ref[1])
            bits_to_go3_ref[1] += ncode[input[i]+1]

            if bits_to_go3_ref[1] >= 8
                buffer[b_local+1] = bitbuffer_ref[1] & 0xFF
                b_local += 1

                if b_local >= bmax
                    return -1
                end

                bitbuffer_ref[1] = bitbuffer_ref[1] >> 8
                bits_to_go3_ref[1] -= 8
            end
        end
    end
    return b_local
end

"""
    write_bdirect!(input::AbstractArray, outfile::AbstractVector{<:UInt8},
                        nqx::Integer, nqy::Integer, bit::Integer)

Write direct bitmap of bit plane.
"""
function write_bdirect!(input::AbstractArray, outfile::AbstractVector{<:UInt8},
                        nqx::Integer, nqy::Integer, bit::Integer)
    # Write the direct-bitmap format marker and the pixel values.
    output_nbits!(outfile, 0x0, 4)
    output_nnybble!(outfile, div(nqx + 1, 2) * div(nqy + 1, 2), reshape(input, :))
end

"""
    output_nnybble!(outfile::AbstractVector{<:UInt8}, n::Integer, array::AbstractVector{<:UInt8})

Output array of 4-bit nybbles.
"""
function output_nnybble!(outfile::AbstractVector{<:UInt8}, n::Integer, array::AbstractVector{<:UInt8})
    # Emit each nybble through the single-nybble path for consistent packing.
    for i = 1:n
        output_nybble!(outfile, array[i])
    end
end

end # module HCompress


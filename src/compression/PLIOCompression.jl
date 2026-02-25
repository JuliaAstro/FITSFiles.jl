module PLIOCompression

using Statistics

export encode, decode, PLIO

abstract type CompressionType end
abstract type PLIO <: CompressionType end

const MAX_VAL = 4096

"""
    count(input::AbstractVector)

Counts the amount and value of consecutive integers as well as the number of preceding zeros and stores them in an n by 3 array.
"""
function count(input::AbstractVector)
    output = zeros(Int,length(input), 3)
    val = input[1]
    ct = 0
    op = 1
    for i in 1:(length(input)-1)
        ct += 1
        next = input[i+1]
        if val != next
            if val == 0
                output[op,3] = ct
                ct = 0
                val = next
            else
                output[op,1] = val
                output[op,2] = ct
                ct = 0
                val = next
                op += 1
            end
        end
    end
    ct += 1
    if val == 0
        output[op,3] = ct
    else
        output[op,1] = val
        output[op,2] = ct
    end
    output[1:op,:]
end

"""
    write(list::AbstractArray, pixelval::Int, n::Int, nz::Int, op::Int, hi::Int)

Takes a value, consecutive value count, and preceding zero count and encodes to the given list using the PLIO algorithm.
"""
function write(list::AbstractArray, pixelval::Int, n::Int, nz::Int, op::Int, hi::Int)
    diff = pixelval - hi
    if diff != 0
        hi = pixelval
        if abs(diff) > 4095 #High entropy, write diff as remainder and quotient
            list[op] = (pixelval & MAX_VAL-1) + MAX_VAL
            op += 1
            list[op] = div(pixelval, MAX_VAL)
            op += 1
        else
            list[op] = diff < 0 ? -diff + MAX_VAL*3 : diff + MAX_VAL*2
            op += 1
            if n == 1 && nz == 0 #Mark as lone pixel
                list[op-1] = list[op-1] | MAX_VAL*4
                return list, op, hi
            end
        end
    end
    if nz > 0
        while nz > 0 #Write out the number of zeros
            list[op] = min(MAX_VAL-1, nz)
            op += 1
            nz -= MAX_VAL-1
        end
        if n == 1 && pixelval > 0 #Mark as lone pixel
            list[op-1] += MAX_VAL*5 + 1
            return list, op, hi
        end
    end
    while n > 0
        list[op] = min(MAX_VAL-1, n) + MAX_VAL*4
        op += 1
        n -= MAX_VAL-1
    end
    list, op, hi
end

"""
Convert an integer vector to a PLIO line list.
"""

"""
    encode(::Type{PLIO}, input::AbstractVector{<:Int16};
                            xstart::Int = 1,
                            npix::Int = length(input))

Encodes the input vector using the PLIO algorithm.
xstart: index of input vector to begin encoding at. Defaults to the first index.
npix: Number of pixels to encode. Defaults to the full vector.
"""
function encode(::Type{PLIO}, input::AbstractVector{<:Int16};
                            xstart::Int = 1,
                            npix::Int = length(input))
    xend = min(xstart + npix - 1, length(input))
    if npix <= 0 || xstart > xend
        return
    end
    list = zeros(Int16,npix*3 + 8)
    list[1:3] .= (0, 7, -100)
    list[6:7] .= (0, 0)
    op = 8
    counted = count(input[xstart:xend])
    hi = 1

    for i in eachindex(counted[:,1])
        list, op, hi = write(list, counted[i,1], counted[i,2], counted[i,3], op, hi)
    end
    list[4] = (op - 1) % (MAX_VAL*8)
    list[5] = div(op - 1, MAX_VAL*8)
    list[1:op-1]
end



"""
    decode(::Type{PLIO}, list::AbstractVector, npix::Int;
                            xstart = 1,
                            output = zeros(Int16,xstart + npix -1))

Decodes the PLIO encoded vector.
npix: Number of pixels to decode. Typically the length of the original vector. If shorter, will only decode that many pixels. If longer, will decode all encoded pixels and fill remaining spots with zeros.
xstart: index of output vector to begin writing decoded values. Defaults to first index.
output: Optional output array to write values to. Will otherwise create an array of zeros to write to.
"""
function decode(::Type{PLIO}, list::AbstractVector, npix::Int;
                            xstart = 1,
                            output = zeros(Int16,xstart + npix -1))
    if list[3] > 0
        len, firstpix = list[3], 4
    else 
        len, firstpix = (list[5] << 15) + list[4], list[2] + 1
    end

    if npix <= 0 || len <= 0 
        return output
    end

    op, x1, hi = xstart, xstart, 1
    xend = min(xstart + npix - 1, length(output))
    skip = false
    
    for i in firstpix:len
        if skip
            skip = false
            continue
        end

        opcode = div(list[i],MAX_VAL)
        data = list[i] & (MAX_VAL-1)
        putpix = false
        if (opcode == 0 || opcode == 4 || opcode == 5)
            #Determine inbounds region of segment.
            x2 = x1 + data - 1
            i1 = max(x1, xstart)
            i2 = min(x2, xend)

            #Process segment if any region is inbounds.
            np = i2 - i1 + 1
            if np > 0
                otop = op + np - 1
                if opcode == 4
                    for j in op:otop
                        output[j] = hi
                    end
                else
                    for j in op:otop
                        output[j] = 0
                    end
                    if opcode == 5 && i2 == x2
                        output[otop] = hi
                    end
                end
                op = otop + 1
            end
            x1 = x2 + 1
        elseif opcode == 1
            hi = (list[i + 1] << 12) + data
            skip = true
        elseif opcode == 2
            hi += data
        elseif opcode == 3
            hi -= data
        elseif opcode == 6
            hi += data
            putpix = true
        elseif opcode == 7
            hi -= data
            putpix = true
        end
        if putpix
            if x1 >= xstart && x1 <= xend
                output[op] = hi
                op += 1
            end
            x1 += 1
        end
        if x1 > xend
            break
        end
    end
    for i in op:xend
        output[i] = 0
    end
    output
end

end
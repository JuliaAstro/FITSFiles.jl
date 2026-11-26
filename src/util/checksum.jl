####    The checksum keywords CHECKSUM and DATASUM (Sect. 4.4.2.7 and Appendix J of the standard)

#  The bytes that are summed are the 2880-byte records of the HDU, which are 720 32-bit unsigned integers in
#  big-endian byte order. The sum is the 32-bit ones' complement sum, in which a carry from the most significant
#  bit is added to the least significant bit, and negative zero is all 32 bits equal to 1.
const NEGATIVEZERO = 0xffffffff
#  The number of bytes that are summed before the carries are added, so that the sum cannot overflow
const SUMCHUNK = 2880 * 4096

#  Add the carries of a sum of 32-bit integers, which is held in 64 bits, to the 32 bits of the sum.
function foldcarries(sum::UInt64)
    while sum > NEGATIVEZERO
        sum = (sum & NEGATIVEZERO) + (sum >> 32)
    end
    UInt32(sum)
end

"""
    onescomplementsum(bytes, sum = 0)

Return the 32-bit ones' complement sum of the 32-bit big-endian unsigned integers of `bytes`, added to `sum`.
The length of `bytes` is a multiple of 4.
"""
function onescomplementsum(bytes::AbstractVector{UInt8}, sum::Integer = 0)
    length(bytes) % 4 == 0 || throw(ArgumentError("The number of bytes to sum is $(length(bytes)), " *
        "which is not a multiple of 4."))
    total = UInt64(sum)
    for first = firstindex(bytes):SUMCHUNK:lastindex(bytes)
        chunk = UInt64(0)
        @inbounds for j = first:4:min(first + SUMCHUNK - 1, lastindex(bytes))
            chunk += (UInt64(bytes[j]) << 24) | (UInt64(bytes[j+1]) << 16) | (UInt64(bytes[j+2]) << 8) | UInt64(bytes[j+3])
        end
        total = UInt64(foldcarries(total + chunk))
    end
    foldcarries(total)
end

#  The ones' complement sum of two sums
addsums(a::Integer, b::Integer) = foldcarries(UInt64(a) + UInt64(b))

#  The ones' complement sum of the next `n` bytes of `io`, which is read in chunks. The bytes that the file does
#  not have are zeros, which do not change the sum.
function sumbytes(io::IO, n::Integer)
    total = UInt32(0)
    while n > 0
        bytes = read(io, min(n, SUMCHUNK))
        isempty(bytes) && break
        n -= length(bytes)
        length(bytes) % 4 == 0 || append!(bytes, zeros(UInt8, 4 - length(bytes) % 4))
        total = onescomplementsum(bytes, total)
    end
    total
end

#  The characters that the encoded checksum does not have, which are the punctuation between 0 and A, and Z and a.
const CHECKSUMEXCLUDE = UInt8[0x3a:0x40; 0x5b:0x60]

"""
    encodechecksum(sum)

Return the 16-character string of the ASCII encoding of Appendix J.2 of the standard, which is the value of the
CHECKSUM keyword that makes the sum of the HDU negative zero, where `sum` is the ones' complement sum of the
HDU when the value of CHECKSUM is `'0000000000000000'`.
"""
function encodechecksum(sum::Integer)
    complement = ~UInt32(sum)
    chars = zeros(UInt8, 16)
    for column = 1:4
        byte = UInt8((complement >> (32 - 8column)) & 0xff)
        quotient, remainder = divrem(byte, 0x04)
        part = fill(quotient + 0x30, 4)
        part[1] += remainder
        #  The pairs of parts are moved apart until they are not punctuation, which keeps their sum
        changed = true
        while changed
            changed = false
            for pair in (1, 3)
                if part[pair] in CHECKSUMEXCLUDE || part[pair+1] in CHECKSUMEXCLUDE
                    part[pair] += 0x01
                    part[pair+1] -= 0x01
                    changed = true
                end
            end
        end
        for k = 1:4
            chars[4*(k-1)+column] = part[k]
        end
    end
    #  The string is rotated one place to the right, since it starts in the 12th byte of the card
    String(circshift(chars, 1))
end

"""
    decodechecksum(text)

Return the ones' complement sum that the 16-character string of a CHECKSUM value `text` of Appendix J.2 has
added, i.e., the inverse of [`encodechecksum`](@ref).
"""
function decodechecksum(text::AbstractString)
    length(text) == 16 && all(c -> isascii(c), text) ||
        throw(ArgumentError("The CHECKSUM value must be 16 ASCII characters, but it is $(repr(text))."))
    chars = circshift(UInt8.(collect(text)), -1) .- 0x30
    complement = foldcarries(sum(UInt64(chars[4*(j-1)+k]) << (32 - 8k) for j = 1:4, k = 1:4))
    ~complement
end

#  The value of the DATASUM card, which is the unsigned integer of the sum of the data records, or nothing if
#  the value is not known, i.e., blank, or is not a number
function datasumvalue(cards::Cards)
    j = Base.findfirst("DATASUM", cards)
    ismissing(j) && return nothing
    value = cards[j].value
    value isa AbstractString || return nothing
    tryparse(UInt32, strip(value))
end

#  Set the card of the keyword to the string value in fixed format, with the comment of the card if it has one, in
#  the place of the card, or after the last card.
function setchecksumcard!(cards::Cards, key::AbstractString, value::AbstractString, comment::AbstractString)
    j = Base.findfirst(key, cards)
    if ismissing(j)
        push!(cards, Card(key, value, comment))
    else
        cards[j] = Card(key, value, isempty(cards[j].comment) ? comment : cards[j].comment)
    end
    cards
end

"""
    setchecksum!(cards, data)

Set the DATASUM and CHECKSUM cards of the HDU of `cards` and the bytes of its `data`, which are the data records
including the fill, and return the cards. The DATASUM is the sum of the data records, and the CHECKSUM is the
encoded string that makes the sum of the HDU negative zero (Sect. 4.4.2.7 and Appendix J of the standard). The
cards that the header has are replaced, and the others are added after the last card. The CHECKSUM is in fixed
format, with the single quotes in columns 11 and 28, as the algorithm requires. The comments of the cards are not
dated, so that the same HDU is written with the same bytes.
"""
function setchecksum!(cards::Cards, data::AbstractVector{UInt8})
    datasum = onescomplementsum(data)
    setchecksumcard!(cards, "DATASUM", string(datasum), "data unit checksum")
    setchecksumcard!(cards, "CHECKSUM", "0000000000000000", "HDU checksum")
    header = IOBuffer()
    write(header, cards)
    sum = addsums(onescomplementsum(take!(header)), datasum)
    setchecksumcard!(cards, "CHECKSUM", encodechecksum(sum), "HDU checksum")
end

"""
    verifychecksum(io, cards, first, last, datafirst)

Warn if the DATASUM or the CHECKSUM of the HDU that was read from `io` is not the sum of the HDU, and return the
cards. The bytes of the HDU are from the position `first` to `last` of `io`, and the data begins at `datafirst`. A
keyword that is not there, or is blank (the value is not known), is not verified. The values are read as they are.
"""
function verifychecksum(io::IO, cards::Cards, first::Integer, datafirst::Integer, last::Integer)
    datasum = datasumvalue(cards)
    j = Base.findfirst("CHECKSUM", cards)
    known = !ismissing(j) && cards[j].value isa AbstractString && !isempty(strip(cards[j].value))
    (isnothing(datasum) && !known) && return cards
    seek(io, first)
    headersum = sumbytes(io, datafirst - first)
    dataactual = sumbytes(io, last - datafirst)
    seek(io, last)
    if !isnothing(datasum) && datasum != dataactual
        @warn "DATASUM is $datasum, but the sum of the data records is $dataactual (Sect. 4.4.2.7): the data " *
            "may have changed since the sum was set. It is read as it is."
    end
    total = addsums(headersum, dataactual)
    if known && total != NEGATIVEZERO
        @warn "The checksum of the HDU is $total, and not -0 (Sect. 4.4.2.7): the HDU may have changed since " *
            "CHECKSUM was set. It is read as it is."
    end
    cards
end

"""
Convert an integer vector to PLIO line list.
"""
function encode(::Type{PLIO}, input::AbstractVector)
    if npix <= 0
        return
        # GOTO L100
    end
    # L110
    
    lldst[1:3] .= (0, 7, -100)
    lldst[6:7] .= (0, 0)
    xe + xs + npix + 1
    op = 8
    zro = 0
    # Compute MAX
    i1, i2 .= zro, pxsrc[xs]
    pv = max(i1, i2)
    x1, iz, hi = xs, xs, 1
    i1 = xe

    for ip=xs:i1
        if ip < xe # else GOTO L130
            i2, i3 = zro, pxsrc[ip+1]
            if nv == pv # else GOTO L140
                break # GOTO L120
            end
            # L140
            if pv == 0 # else GOTO L150
                pv, x1 = nv, ip + 1
                break # GOTO L120
            end
            # L150
            # GOTO L131
        else # L130
            if pv == 0 # else GOTO L160
                x1 = xe + 1
            end
            # L160
        end
        # L131
        np, nz = ip - x1 + 1, x1 - iz
        if pv > 0 # else GOTO L170
            dv = pv - hi
            if dv != 0 # else GOTO L180
                hi = pv
                if abs(dv) > 4095 # else GOTO L190
                    lldst[op] = (pv & 4095) + 4096
                    op += 1
                    lldst[op] = div(pv, 4096)
                    op += 1
                    # GOTO L191
                else # L190
                    lldst[op] = dv < 0 ? -dv + 12288 : dv + 8192 # GOTO L201
                    # L201
                    op += 1
                    if np == 1 && nz == 0 # else GOTO L210
                        v = lldst[op-1]
                        lldst[op-1] = v | 16384
                        # GOTO L191
                    end
                    # L210
                end
                # L191
            end
            # L180
        end
        # L170
        if nz > 0 # else GOTO L220
            while nz > 0 # L230; else GOTO L232
                lldst[op] = min(4095, nz)
                op, nz += 1, -4095
                # GOTO L230
            end
            # L232
            if np == 1 && pv > 0 # else GOTO 240
                lldst[op-1] += 20481
                # GOTO L91
                # L91
                x1 = ip + 1
                iz, pv = x1, nv
                # GOTO L120
            end
            # L240
        else # L220
            while np > 0 # L250; else GOTO 252
                lldst[op] = min(4095, np) + 16384
                op, np += 1, -4095
                # GOTO L250
            end
            # L252
            # L91
            x1 = ip + 1
            iz, pv = x1, nv
            # GOTO L120
        end
        # L120
    end
    lldst[4] = (op - 1) % 32768
    lldst[5] = div(op - 1, 32768) 
    #  L100
    return lldst
end

"""
Convert a PLIO line list to an integer vector.
"""
function decode(::Type{PLIO}, list::AbstractVector)
    if list[3] > 0 # else GOTO L110
        lllen, llfirt = list[3], 4
        # GOTO L111
    else # L110
        lllen, llfirt = (list[5] << 15) + list[4], list[2] + 1
    end
    # L111
    if npix <= 0 || lllen <= 0 # else GOTO L120
        return
        # GOTO L100
    end
    # L120
    xe = xs + npix - 1
    skipwd = 0
    op, x1, pv = 1, 1, 1
    i1 = lllen
    for ip = llfirt:i1
        if skipwd # else GOTO L140
            skipwd = 0
            continue
            # GOTO L130
        end
        # L140
        opcode, data = list[ip] / 4096, list[ip] & 4095
        sw0001 = opcode
        # GOTO L150

        # L150
        sw0001 += 1
        # The following switch or if-elseif-end block is best encoded as a
        # dictionary, i.e., DECODE(1 => func1, 2 => func2, ...) and then
        # res = DECODE[1]
        if 1 <= sw0001 <= 8 # else GOTO L151
            if     sw0001 == 1 # GOTO L160
                # L160
                x2 = x1 + data - 1
                i1, i2 = min(x1, xs), min(x2, xe)
                np = i2 - i2 + 1
                if np > 0 # else GOTO L170
                    otop = op + np - 1
                    if opcode == 4 # else GOTO L180
                        i2 = otop
                        for j = op:i2
                            px_dst[j] = pv
                        end
                        # GOTO L181
                    else # L180
                        i2 = otop
                        for j = op:i2
                            px_dist[j] = 0
                        end
                        if opcode == 5 && i2 == x2 # else GOTO L210
                            px_dst[otop] = pv
                        end
                        # L210
                    end
                    # L181
                    op = otop + 1
                end
                # L170
                x1 + x2 + 1
                # GOTO L151
            elseif sw0001 == 2 # GOTO L220
                # L220
                pv = (list[ip+1] << 12) + data
                skipwd = 1
                #GOTO L151
            elseif sw0001 == 3 # GOTO L230
                # L230
                pv += data
                # GOTO L151
            elseif sw0001 == 4 # GOTO L240
                # L240
                pv -= data
                # GOTO L151
            elseif sw0001 == 5 # GOTO L160
                # L160
                # see sw0001 == 1
            elseif sw0001 == 6 # GOTO L160
                # L160
                # see sw0001 == 1. L160 should be a function.
                # GOTO L151
            elseif sw0001 == 7 # GOTO L250
                # L250
                pv += data
                # GOTO L91
                # L91
                if x1 >= xs && x1 <= xe # else GOTO L270
                    list[op] = pv
                    op += 1
                else # L270
                    x1 += 1
                end
                # GOTO L151
            elseif sw0001 == 8 # GOTO L260
                # L260
                pv -= Data
                # GOTO L91
                if x1 >= xs && x1 <= xe # else GOTO L270
                    list[op] = pv
                    op += 1
                else
                    x1 += 1
                end
                # GOTO L151
            end
        end
        # L151
        if x1 > xe # else GOTO L280
            break
            # GOTO L131
        end
        # L280
        # L130
    end
    # L131
    i1 = npix
    for j = op:i1
        list[j] = 0
    end

    # L100
    return
end
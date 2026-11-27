####    Table HDU functions

"""
	Table header-data unit (HDU)

A Table HDU consists of a vector of cards and optionally a 2-dimensional array
of ASCII data, which is a named tuple of the columns of the fields, or a vector of records, a named tuple for each row
(`record = true`), or a vector of the strings of the rows.

The fields of the table that is made from data have the formats TFORMn and the first columns TBCOLn of the cards that are given, and otherwise the
format of the values of the field and the column that follows the one space after the previous field. The keywords `formats` and `columns` of
`HDU(Table, data, cards; formats, columns)` are vectors that have a format string (Table 15 of the standard, e.g., `"F8.3"`) and a first column
(the first column of a row is 1) for each field, and override the cards.

The values of a field of type `A` are strings, of type `I` are `Int64`, and of types `F`, `E`, and `D` are `Float64`, with `missing` for an
undefined value, which is the TNULLn string of the field (Sect. 7.2.2 of the standard). A blank field is the value 0, as the standard
says (Sect. 7.2.5). The values of a field that has a TSCALn and a TZEROn that are not 1 and 0 are the physical values, which are `Float64`
(Eq. 7), unless `scale = false`. The values of an integer field whose TSCALn is 1 and TZEROn is an integer are exact integers (`Int64`, or
`BigInt` if they do not fit), which are a [`ScaledArray`](@ref). The integers of an
integer field that do not fit an `Int64` are a column of `BigInt`, since the standard has no limit (Sect. 7.2.5). The real numbers of the data are
written with the digits that they need if the field has room for them, which is more than the `d` of the format if they need it (the formats of
Table 15 are input formats, Sect. 7.2.1), so that what is read is written again.

The data are matched to the fields by name: a named tuple of columns and the records that are named tuples have a value for each field of its
TTYPEn, in any order. The fields without a TTYPEn are named `column1`, `column2`, and so on.
"""
struct Table <: AbstractHDU end

#  The data of a Table HDU are strings
fromdata(::Type{Table}, data) = eltype(data) <: AbstractString
frommandatory(::Type{Table}, mankeys) = isequal(xtensionvalue(mankeys), "TABLE")
registerhdu!(Table)

#  The maximum number of fields of the table (Sect. 7.2.1)
const MAXTABLEFIELDS = 999

#  The mandatory and reserved keywords of the HDU (see `getreservedkeys`)
union!(MANDATORYKEYS, ["XTENSION", "PCOUNT", "GCOUNT", "TFIELDS", "TFORM", "TBCOL"])
union!(RESERVEDKEYS, ["INHERIT", "TFIELDS", "TFORM", "TBCOL", "TSCAL", "TZERO", "TNULL", "TTYPE", "TUNIT", "TDISP",
    "TDMAX", "TDMIN", "TLMAX", "TLMIN"])

#  The fill after the data is ASCII spaces (see `verifyfill`)
fillrule(::Type{Table}) = (0x20, "ASCII spaces", "Sect. 7.2.3")

#  The types of the values of the fields of the formats of Table 15
const TABLETYPE = Dict("A" => String, "I" => Int64, "F" => Float64, "E" => Float64, "D" => Float64)

#  The formats of Table 15: Aw, Iw, Fw.d, Ew.d, and Dw.d, in upper case
const TABLEFORM = r"^(?:([AI])([0-9]+)|([FED])([0-9]+)\.([0-9]+))$"

#  The display formats of Table 16: Aw, Iw.m, Bw.m, Ow.m, Zw.m, Fw.d, Ew.dEe, ENw.d, ESw.d, Gw.dEe, and Dw.dEe, in upper case
const TABLEDISPFORM = r"^(A\d+|[IBOZ]\d+(\.\d+)?|F\d+\.\d+|(E|EN|ES|G|D)\d+\.\d+(E\d+)?)$"

#  The display formats that a field of the format code of Table 15 has (Sects. 7.2.2 and 7.3.4): the integer formats are for integers, and the
#  real formats are for the values that are not integers, which a scale makes of integers
const TABLEDISPCODES = let real = ["F", "E", "D", "EN", "ES", "G"]
	Dict("A" => ["A"], "I" => ["I", "B", "O", "Z", real...], "F" => real, "E" => real, "D" => real)
end

"""
    TableField(name, type, slice, unit, form, disp, zero, scale, null,
        dmin, dmax, lmin, lmax)

Table array element descriptor
"""
struct TableField <: AbstractField
    "The name of the field"
    name::String
    "The type of the field"
    type::Type
    "The slice of the field from start of record"
    slice::UnitRange{Int}
    "The unit of the field"
    unit::String
    "The format of the field"
    form::String
    "The display of the field"
    disp::String
    "The offset of the field, which is an integer for the exact integers of an integer field (see `exactzero`)"
    zero::Union{Real, Nothing}
    "The scale of the field"
    scale::Union{Float64, Nothing}
    "The null value of the field"
    null::Union{String, Nothing}
    "The minimum physical value of the field"
    dmin::Union{Real, Nothing}
    "The maximum physical value of the field"
    dmax::Union{Real, Nothing}
    "The minimum valid physical value of the field"
    lmin::Union{Real, Nothing}
    "The maximum valid physical value of the field"
    lmax::Union{Real, Nothing}
end

"""
    ScaledRows(records, scales)

The records of an ASCII table (`record = true`) that has fields of floating-point values, or of exact integers, that are scaled by a TSCALn and a
TZEROn. The values of those fields are the physical values (see [`ScaledArray`](@ref)), which the dictionary `scales` has the scale and the zero of,
by the name of the field, and are written as the stored values. The records are the values of `parent`.
"""
struct ScaledRows{R, V<:AbstractVector{R}} <: AbstractVector{R}
    parent::V
    scales::Dict{Symbol, Tuple{Real, Real}}
end

Base.parent(rows::ScaledRows) = rows.parent
Base.size(rows::ScaledRows) = size(rows.parent)
Base.IndexStyle(::Type{<:ScaledRows}) = IndexLinear()
Base.getindex(rows::ScaledRows, i::Int) = rows.parent[i]
Base.setindex!(rows::ScaledRows, value, i::Int) = (rows.parent[i] = value; rows)
Base.copy(rows::ScaledRows) = ScaledRows(copy(rows.parent), rows.scales)

#  The code, the width, and the number of decimals of the format of a field (Table 15): the decimals are 0 for the formats that do not have
#  them. A format that is not one of Table 15 is an error.
function tableformat(form::AbstractString, name::AbstractString = "TFORM")
	m = match(TABLEFORM, rstrip(form))
	code, width, decimals = isnothing(m) ? (nothing, nothing, nothing) :
		isnothing(m[1]) ? (m[3], tryparse(Int, m[4]), tryparse(Int, m[5])) : (m[1], tryparse(Int, m[2]), 0)
	(isnothing(width) || isnothing(decimals) || width < 1) && throw(ArgumentError("$name must be a format of Table 15, " *
		"Aw, Iw, Fw.d, Ew.d, or Dw.d, in upper case, with a width of at least 1 (Sect. 7.2.1), but its value is $(repr(form))."))
	(code, width, decimals)
end

#  The value of a string keyword of a field, or the default if the header does not have it or it is not a string
tablestring(keys::AbstractDict, key::AbstractString, default::AbstractString) =
    get(keys, key, default) isa AbstractString ? rstrip(get(keys, key, default)) : default

#  The value of a keyword that is a number, or nothing
tablenumber(keys::AbstractDict, key::AbstractString) = get(keys, key, nothing) isa Real && !(get(keys, key, nothing) isa Bool) ?
    get(keys, key, nothing) : nothing

#  The Float64 of a number of a header, which a card has as a Float32 if the Float32 has the digits of the number, e.g., 0.1f0 for 0.1, whose
#  Float64 is not 0.1 but the number that has the digits of the Float32
tablefloat(value::Real) = value isa Float32 ? Base.parse(Float64, string(value)) : Float64(value)

#  The TZEROn of a field: an integer if the values of the field are exact integers, which an integer field has if TSCALn is 1 and TZEROn is an
#  integer (a value of a header that is a whole floating-point number up to 2^53 is one), and a Float64 otherwise
function tablezero(value, code::AbstractString, scale::Real)
    isnothing(value) && return 0.0
    whole = value isa Integer || (value isa AbstractFloat && isinteger(value) && abs(value) <= 2.0^53)
    code == "I" && scale == 1 && whole ? (value isa Integer ? value : Int(value)) : tablefloat(value)
end

#  Are the physical values of an integer field exact integers, which are the stored values and TZEROn (see `tablezero`)?
exactzero(field::TableField) = field.type <: Integer && field.zero isa Integer && field.zero != 0

#  The name of the field j of the data, which has a character and no space at its end, since a string of a card does not keep the spaces at its end,
#  so that the data are matched to the field of the name
function checkname(j::Integer, name::AbstractString)
    (isempty(name) || name != rstrip(name)) && throw(ArgumentError("The name of field $j of the data, $(repr(name)), is empty or has a " *
        "space at its end, but the name of a field is the string of a TTYPEn keyword, which is not empty and does not keep the spaces at its end " *
        "(Sect. 7.2.2)."))
    name
end

#  The name of a field, which is the default if the name is empty, and which no other field has, since the columns of the data are named by the
#  fields, and the columns of two fields that have the same name would be one.
function tablename(name::AbstractString, default::AbstractString, names::Set{String})
    name = isempty(name) ? default : String(name)
    unique = name
    while unique in names
        unique = unique == name ? "$(name)_$(length(names) + 1)" : unique * "_"
    end
    push!(names, unique)
    unique
end

#  The descriptor of the field j of the header, which begins in the column `start`, has the format `form`, and has the name `name`
function tablefield(keys::AbstractDict, j::Integer, name::AbstractString, form::AbstractString, start::Integer)
    code, width, _ = tableformat(form, "TFORM$j")
    type = TABLETYPE[code]
    #  A field of characters has no scale and zero (Sect. 7.2.2)
    scale = code == "A" ? nothing : tablefloat(something(tablenumber(keys, "TSCAL$j"), 1.0))
    zero_ = code == "A" ? nothing : tablezero(tablenumber(keys, "TZERO$j"), code, scale)
    null = get(keys, "TNULL$j", nothing)
    null = null isa AbstractString ? String(rstrip(null)) : nothing
    TableField(name, type, start:start+width-1, tablestring(keys, "TUNIT$j", ""), String(rstrip(form)), tablestring(keys, "TDISP$j", ""),
        zero_, scale, null, tablenumber(keys, "TDMIN$j"), tablenumber(keys, "TDMAX$j"), tablenumber(keys, "TLMIN$j"),
        tablenumber(keys, "TLMAX$j"))
end

####    Verify the header and the data

#  The `formats` and the `columns` of the fields of a table that is made from data, which are the cards TFORMn and TBCOLn of the fields (the
#  cards that are given are replaced), and TFIELDS for the strings of the rows, whose fields only the cards describe
function keywordcards!(::Type{Table}, cards::Cards, data::Union{AbstractArray, Tuple, NamedTuple}; formats = nothing, columns = nothing,
    kwds...)

    isnothing(formats) && isnothing(columns) && return cards
    given = tablecolumns(data)
    n = isnothing(given) ? length(something(formats, columns)) : length(given)
    for (name, values) in (("formats", formats), ("columns", columns))
        isnothing(values) && continue
        length(values) == n || throw(ArgumentError("The keyword $name has $(length(values)) values, but the data have $n fields."))
    end
    setcard!(key, value) = haskey(cards, key) ? (cards[key] = value) : push!(cards, Card(key, value))
    isnothing(given) && setcard!("TFIELDS", n)
    for j = 1:n
        if !isnothing(formats)
            formats[j] isa AbstractString || throw(ArgumentError("formats[$j] must be a character string, but its value is $(repr(formats[j]))."))
            tableformat(formats[j], "formats[$j]")
            setcard!("TFORM$j", String(rstrip(formats[j])))
        end
        if !isnothing(columns)
            columns[j] isa Integer && columns[j] >= 1 || throw(ArgumentError("columns[$j] must be an integer of at least 1, the first column " *
                "of a row, but its value is $(repr(columns[j]))."))
            setcard!("TBCOL$j", Int(columns[j]))
        end
    end
    cards
end

#  The keywords of the cards that are given with the data of an HDU that is made are verified (see `verifycardkeys`)
verifycards!(::Type{Table}, cards::Cards, mankeys::AbstractDict, reskeys::AbstractDict, format::DataFormat) =
    verifycardkeys(Table, cards, mankeys, reskeys)

function verify!(::Type{Table}, cards::Cards, mankeys::AbstractDict, reskeys::AbstractDict)
    #  A header that is being created does not have the keywords yet, and is arranged when it is created.
    created = !haskey(mankeys, "XTENSION")
    #  The data cannot be read without BITPIX and NAXIS (Sect. 7.2.1)
    for key in ("BITPIX", "NAXIS")
        created || haskey(mankeys, key) || throw(ArgumentError(
            "$key is missing, but it is a mandatory keyword of a TABLE extension (Sect. 7.2.1)."))
    end
    cards = invoke(verify!, Tuple{Type{<:AbstractHDU}, Cards, AbstractDict, AbstractDict}, Table, cards,
        mankeys, reskeys)
    verifyrows(Table, mankeys)
    #  An ASCII table has a single table and no heap (Sect. 7.2.1)
    verifyvalue(mankeys, "PCOUNT", 0:0, "the integer 0")
    verifyvalue(mankeys, "GCOUNT", 1:1, "the integer 1")
    #  The number of fields and the first columns of the fields are integers (Sect. 7.2.1), and the scale, the zero, and the minimum and
    #  maximum values are numbers (Sect. 7.2.2), which the values of the fields are made of
    verifyinteger(mankeys, r"^(TFIELDS|TBCOL\d+)$")
    verifynumber(reskeys, r"^(TSCAL|TZERO|TDMIN|TDMAX|TLMIN|TLMAX)\d+$")
    verifyfields!(Table, cards, mankeys; created)
    created && return cards
    verifykeys(Table, cards, mankeys, reskeys)
end

#  The keywords that are in order and in fixed format, and the keywords of the fields (Sects. 4.4.1.2, 7.2.1, and 7.2.2)
function verifykeys(::Type{Table}, cards::Cards, mankeys::AbstractDict, reskeys::AbstractDict)
    #  PCOUNT and GCOUNT have the values 0 and 1 if they are missing, so the data can be read without them
    for (key, value) in ("PCOUNT" => 0, "GCOUNT" => 1)
        haskey(mankeys, key) || @warn "$key is missing, but it is a mandatory keyword of a TABLE extension " *
            "(Sect. 7.2.1), and has the value $value. It is read as $value."
    end
    #  A header without TFIELDS has no fields
    haskey(mankeys, "TFIELDS") || @warn "TFIELDS is missing, but it is a mandatory keyword of a TABLE extension (Sect. 7.2.1), and " *
        "the table has no fields. It is read as 0."
    #  The mandatory keywords are the first keywords, in order and in fixed format
    required = filter(key -> haskey(mankeys, key), ["XTENSION", "BITPIX", "NAXIS", "NAXIS1", "NAXIS2", "PCOUNT", "GCOUNT", "TFIELDS"])
    verifyorder(cards, required; section = "Sects. 4.4.1.2 and 7.2.1",
        names = "XTENSION, BITPIX, NAXIS, NAXIS1, NAXIS2, PCOUNT, GCOUNT, and TFIELDS")
    verifyfixed(cards, required)
    #  The keywords of the primary header, and of the physical blocks, are not in an extension (Sects. 4.4.1.1, 4.4.2.1, and 7.2.2)
    haskey(mankeys, "SIMPLE") && @warn "SIMPLE must not appear in an extension header (Sect. 4.4.1.1). It is read as it is."
    for key in ("EXTEND", "BLOCKED")
        haskey(reskeys, key) && @warn "$key must not appear in a TABLE extension header (Sects. 4.4.2.1 and 7.2.2). " *
            "It is read as it is."
    end
    #  The keywords that describe arrays are not used for a table (Sect. 4.4.2.5)
    for key in ("BSCALE", "BZERO", "BUNIT", "BLANK", "DATAMIN", "DATAMAX")
        haskey(reskeys, key) && @warn "$key must not be used in a TABLE extension header (Sect. 4.4.2.5), since it describes " *
            "an array, and the header describes a table. It is read as it is, and is not used."
    end
    verifyfieldkeys(Table, mankeys, reskeys)
    cards
end

function verify!(::Type{Table}, cards::Cards, format::DataFormat,
    mankeys::AbstractDict)

    verifyshape!(cards, mankeys, format)
end

#  The structure of an ASCII table extension, which is an array of bytes with NAXIS = 2 axes, the length of a row and the number
#  of rows (Sect. 7.2.1)
function verifyrows(::Type{Table}, mankeys::AbstractDict)
	verifyvalue(mankeys, "BITPIX", 8:8, "the integer 8")
	verifyvalue(mankeys, "NAXIS", 2:2, "the integer 2")
	verifyaxes(mankeys)
end

"""
	verifyfields!(Table, cards, mankeys; created = false)

Verify the keywords that describe the fields of an ASCII table extension, and return the cards unchanged
(Sect. 7.2.1 of the standard). It is an error, since the fields cannot be read, if TFIELDS
is negative, if TFORMn is missing or is not one of the formats of Table 15 (Aw, Iw, Fw.d, Ew.d, or Dw.d, in upper case) for an n from 1 to
TFIELDS, if TBCOLn is missing or less than 1, since the first column of a row is numbered 1, or if a field is not within the NAXIS1
characters of a row. A header that is being created (`created`) does not need TFORMn and TBCOLn, which are made from the data. It is a warning,
since the extra keywords are not used, if TFIELDS is more than 999, the maximum, or if TFORMn or TBCOLn
is present for an n greater than TFIELDS. A header with no TFIELDS is not verified.
"""
function verifyfields!(::Type{Table}, cards::Cards, mankeys::AbstractDict; created::Bool = false)
	N = get(mankeys, "TFIELDS", nothing)
	isnothing(N) && return cards
	N < 0 && throw(ArgumentError("TFIELDS must be non-negative, but its value is $N."))
	N > MAXTABLEFIELDS && @warn "TFIELDS $N is more than the maximum of $MAXTABLEFIELDS."
	row = get(mankeys, "NAXIS1", nothing)
	for j = 1:N
		form = get(mankeys, "TFORM$j", nothing)
		if isnothing(form)
			created || throw(ArgumentError("TFORM$j is missing, but TFIELDS is $N."))
		else
			form isa AbstractString || throw(ArgumentError("TFORM$j must be a character string, but its value is $(repr(form))."))
			tableformat(form, "TFORM$j")
		end
		start = get(mankeys, "TBCOL$j", nothing)
		if isnothing(start)
			created || throw(ArgumentError("TBCOL$j is missing, but TFIELDS is $N."))
		else
			start >= 1 || throw(ArgumentError(
				"TBCOL$j must be at least 1, the first column of a row, but its value is $start."))
			if !created && !isnothing(form) && row isa Integer
				last = start + tableformat(form, "TFORM$j")[2] - 1
				last <= row || throw(ArgumentError("Field $j, whose TFORM$j is $(repr(rstrip(form))) and TBCOL$j is $start, ends in " *
					"column $last, but a row has NAXIS1 = $row characters (Sects. 7.2.1 and 7.2.4)."))
			end
		end
	end
	for key in sort!(collect(keys(mankeys)))
		m = match(r"^(TFORM|TBCOL)(\d+)$", key)
		!isnothing(m) && Base.parse(Int, m[2]) > N &&
			@warn "$key is beyond TFIELDS $N, and is not used."
	end
	cards
end

#  The keywords that describe the fields (Sect. 7.2.2): TTYPEn, TUNITn, TNULLn, and TDISPn are character strings, TUNITn is a units
#  string, the names of the fields are unique without regard to the case, the fields do not overlap, TSCALn and TZEROn are not used for the
#  fields of type A, TNULLn is not longer than its field, TDISPn is a display format of Table 16 that suits the type of the field, and the
#  minimum and maximum values have the data type of the physical values.
function verifyfieldkeys(::Type{Table}, mankeys::AbstractDict, reskeys::AbstractDict)
    N = get(mankeys, "TFIELDS", 0)
    N isa Integer || return
    verifystring(reskeys, r"^(TTYPE|TUNIT|TNULL|TDISP)\d+$")
    verifyunit(reskeys, r"^TUNIT\d+$")
    names, spans = Dict{String, Int}(), Tuple{Int, Int, Int}[]
    for j = 1:N
        form = get(reskeys, "TFORM$j", nothing)
        form isa AbstractString || continue
        code, width, _ = tableformat(form, "TFORM$j")
        start = get(reskeys, "TBCOL$j", nothing)
        start isa Integer && push!(spans, (start, start + width - 1, j))
        (haskey(reskeys, "TSCAL$j") || haskey(reskeys, "TZERO$j")) && code == "A" &&
            @warn "TSCAL$j and TZERO$j must not be used for a field of format A (Sect. 7.2.2). They are not used."
        null = get(reskeys, "TNULL$j", nothing)
        null isa AbstractString && length(rstrip(null)) > width && @warn "TNULL$j, $(repr(rstrip(null))), is longer than the $width " *
            "characters of its field (Sect. 7.2.2), so no value is undefined. The undefined values cannot be written."
        verifyextremes(Table, reskeys, j, code)
        for (low, high) in (("TDMIN", "TDMAX"), ("TLMIN", "TLMAX"))
            a, b = get(reskeys, "$low$j", nothing), get(reskeys, "$high$j", nothing)
            a isa Real && b isa Real && !(a isa Bool) && !(b isa Bool) && a > b && @warn "$low$j, $a, is more than $high$j, $b, but " *
                "$low$j is the minimum and $high$j is the maximum (Sect. 7.2.2). They are read as they are."
        end
        disp = get(reskeys, "TDISP$j", nothing)
        if disp isa AbstractString && !occursin(TABLEDISPFORM, strip(disp))
            @warn "TDISP$j must be a display format of Table 16 (Sect. 7.2.2), but its value is $(repr(disp)). It is read as it is."
        elseif disp isa AbstractString
            shown = match(r"^[A-Z]+", strip(disp)).match
            shown in TABLEDISPCODES[code] || @warn "TDISP$j, $(repr(strip(disp))), is not a display format for a field of format " *
                "$code (Sect. 7.2.2), which has the formats $(join(TABLEDISPCODES[code], ", ")). It is read as it is."
        end
        name = get(reskeys, "TTYPE$j", nothing)
        name isa AbstractString && !isempty(strip(name)) && !occursin(r"^[A-Za-z0-9_]+$", rstrip(name)) && @warn "TTYPE$j, " *
            "$(repr(rstrip(name))), has characters other than letters, digits, and the underscore, which a name should have, since " *
            "another character may not be allowed in the name of a variable of a program (Sect. 7.2.2). It is read as it is."
        if name isa AbstractString && !isempty(strip(name))
            other = get(names, lowercase(rstrip(name)), 0)
            if other > 0
                renamed = rstrip(name) == rstrip(reskeys["TTYPE$other"]) ? " The column of the data of TTYPE$j is named $(rstrip(name))_$j." : ""
                @warn "TTYPE$j and TTYPE$other have the same name, $(repr(rstrip(name))), without regard to the case, but the " *
                    "names of the fields should be unique (Sect. 7.2.2).$renamed"
            else
                names[lowercase(rstrip(name))] = j
            end
        end
    end
    #  Fields may overlap, but this is not recommended (Sect. 7.2.4)
    sort!(spans)
    reach, last = 0, 0
    for (start, stop, j) in spans
        if start <= reach
            @warn "Fields $last and $j overlap, but the fields of a row should not overlap (Sect. 7.2.4). They are read as they are."
            break
        end
        reach, last = stop, j
    end
    nothing
end

#  The minimum and maximum values of a column, TDMINn and TDMAXn, and the minimum and maximum valid values, TLMINn and TLMAXn, have the data
#  type of the physical values of the column, an integer or a floating-point number (Sect. 7.2.2). The physical values of a field of format I
#  are integers if TSCALn is 1 and TZEROn is an integer, and those of a field of format F, E, or D are floating-point numbers.
function verifyextremes(::Type{Table}, reskeys::AbstractDict, j::Integer, code::AbstractString)
    code == "A" && return
    scale, zero = get(reskeys, "TSCAL$j", 1), get(reskeys, "TZERO$j", 0)
    integers = code == "I" && scale isa Real && zero isa Real && scale == 1 && isinteger(zero)
    for key in ("TDMIN$j", "TDMAX$j", "TLMIN$j", "TLMAX$j")
        value = get(reskeys, key, nothing)
        (value isa Real && !(value isa Bool)) || continue
        if integers && !(value isa Integer)
            @warn "$key must be an integer, since the values of field $j are integers (Sect. 7.2.2), but its value is $(repr(value)). It is read as it is."
        elseif !integers && value isa Integer
            @warn "$key must be a floating-point number, since the values of field $j are floating-point numbers (Sect. 7.2.2), but its value is $(repr(value)). It is read as it is."
        end
    end
end

#  Verify the data against the header before the header is written (see `verifydata`): the values of each field are in a column of as many rows
#  as the table has, or in each record, and the strings of the rows are not longer than a row
function verifydata(::Type{Table}, data::Union{AbstractArray, Tuple, NamedTuple}, format::DataFormat, fields::Vector{TableField})
    length(format.shape) == 2 || return nothing
    M, N = format.shape
    if data isa AbstractArray{<:AbstractString}
        length(data) == N || throw(ArgumentError("The data have $(length(data)) rows, but the table has NAXIS2 = $N (Sect. 7.2.1)."))
        for (j, row) in enumerate(data)
            length(row) <= M || throw(ArgumentError("Row $j of the data has $(length(row)) characters, but a row has NAXIS1 = $M " *
                "(Sect. 7.2.1)."))
        end
    elseif data isa AbstractArray
        length(data) == N || throw(ArgumentError("The data have $(length(data)) records, but the table has NAXIS2 = $N (Sect. 7.2.1)."))
        for (j, record) in enumerate(data)
            length(record) == length(fields) || throw(ArgumentError("Record $j of the data has $(length(record)) values, but " *
                "the table has TFIELDS = $(length(fields)) fields (Sect. 7.2.1)."))
            record isa NamedTuple && for (k, field) in enumerate(fields)
                haskey(record, Symbol(field.name)) || throw(ArgumentError("Record $j of the data has no value named $(field.name), " *
                    "the name of field $k, but it has $(join(keys(record), ", ")) (Sect. 7.2.2)."))
            end
        end
    else
        length(data) == length(fields) || throw(ArgumentError("The data have $(length(data)) columns, but the table has " *
            "TFIELDS = $(length(fields)) fields (Sect. 7.2.1)."))
        tablecolumns(data)
        data isa NamedTuple && for (k, field) in enumerate(fields)
            haskey(data, Symbol(field.name)) || throw(ArgumentError("The data have no column named $(field.name), the name of " *
                "field $k, but they have $(join(keys(data), ", ")) (Sect. 7.2.2)."))
        end
        for (k, column) in enumerate(data)
            length(column) == N || throw(ArgumentError("Column $k of the data has $(length(column)) rows, but the table has " *
                "NAXIS2 = $N (Sect. 7.2.1)."))
        end
    end
    nothing
end

####    The format of the data

#  The columns of the data: the values of each field, which are nothing for the strings of the rows, whose fields the header describes
function tablecolumns(data::Union{Tuple, NamedTuple})
    for k = 1:length(data)
        data[k] isa AbstractVector || throw(ArgumentError("Column $k of the data$(data isa NamedTuple ? ", $(keys(data)[k])," : "") is " *
            "not a vector, but a column of an ASCII table has a value for each row (Sect. 7.2.3)."))
    end
    Any[data[k] for k = 1:length(data)]
end
tablecolumns(data::AbstractArray{<:AbstractString}) = nothing
function tablecolumns(data::AbstractArray)
    if isempty(data)
        eltype(data) <: Union{Tuple, NamedTuple} && isconcretetype(eltype(data)) ?
            Any[Vector{T}() for T in fieldtypes(eltype(data))] : Any[]
    elseif first(data) isa NamedTuple
        #  The records that are named tuples have the values of a field by its name, in any order
        names = keys(first(data))
        for (j, record) in enumerate(data)
            record isa NamedTuple && length(record) == length(names) && all(name -> haskey(record, name), names) ||
                throw(ArgumentError("Record $j of the data does not have the names of the first record, $(join(names, ", "))."))
        end
        Any[[record[name] for record in data] for name in names]
    else
        Any[[record[k] for record in data] for k = 1:length(first(data))]
    end
end

#  The names of the fields of the data, which a named tuple or a record that is a named tuple has, or nothing
tablenames(data::NamedTuple) = String[String(name) for name in keys(data)]
tablenames(data::AbstractArray) = isempty(data) ? (eltype(data) <: NamedTuple && isconcretetype(eltype(data)) ?
    String[String(name) for name in fieldnames(eltype(data))] : nothing) :
    first(data) isa NamedTuple ? String[String(name) for name in keys(first(data))] : nothing
tablenames(data) = nothing

#  The format of a field from its values: the characters of the longest string (A), the digits of the largest integer (I), or the digits of a
#  floating-point number in exponential notation, which a Float64 has 17 of (D) and the other types of numbers have 9 of (E)
function defaultform(j::Integer, values)
    present = collect(skipmissing(values))
    isempty(present) && (present = nonmissingtype(eltype(values)) <: AbstractString ? [""] :
        nonmissingtype(eltype(values)) <: Integer ? [0] : nonmissingtype(eltype(values)) <: AbstractFloat ?
        [one(nonmissingtype(eltype(values)))] : [nothing])
    if all(value -> value isa AbstractString, present)
        "A$(max(1, maximum(ncodeunits, present)))"
    elseif all(value -> value isa Integer && !(value isa Bool), present)
        "I$(max(1, maximum(value -> ncodeunits(string(value)), present)))"
    elseif all(value -> value isa Real && !(value isa Bool), present)
        any(value -> value isa Float64 || value isa Integer || value isa BigFloat, present) ? "D25.16" : "E16.8"
    else
        throw(ArgumentError("The values of field $j have the type $(join(unique(typeof.(present)), ", ")), but the values of a field of " *
            "an ASCII table are strings (A), integers (I), or floating-point numbers (F, E, or D) (Table 15 of the standard)."))
    end
end

#  The formats of the fields and the first columns of the fields, from TFORMn and TBCOLn of the header, and for the data that have columns,
#  from the values of the field and the column that follows the one space after the previous field, if the header does not have them
function tablelayout(columns, keys::AbstractDict)
    n = isnothing(columns) ? get(keys, "TFIELDS", 0) : length(columns)
    n > MAXTABLEFIELDS && throw(ArgumentError("The data have $n fields, but an ASCII table has at most $MAXTABLEFIELDS (Sect. 7.2.1)."))
    forms, starts, next = String[], Int[], 1
    for j = 1:n
        form = get(keys, "TFORM$j", nothing)
        if !(form isa AbstractString)
            isnothing(columns) && throw(ArgumentError("TFORM$j is missing, but TFIELDS is $n."))
            form = defaultform(j, columns[j])
        end
        start = get(keys, "TBCOL$j", nothing)
        start isa Integer || (start = next)
        push!(forms, String(rstrip(form)))
        push!(starts, start)
        next = start + tableformat(form, "TFORM$j")[2] + 1
    end
    (forms, starts)
end

function DataFormat(::Type{Table}, data::Missing, mankeys::Dict{S, V}) where
    {S<:AbstractString, V<:ValueType}

    #  Determine format from data
    type  = BITS2TYPE[get(mankeys, "BITPIX", 8)]
    shape = datasize(mankeys, 1)
    param = get(mankeys, "PCOUNT", 0)
    group = get(mankeys, "GCOUNT", 1)
    leng  = get(mankeys, "NAXIS", 0) > 0 ? group * (param + prod(shape)) : 0
    heap  = 0
    DataFormat(type, leng, shape, param, group, heap)
end

function DataFormat(::Type{Table}, data::Union{AbstractArray, Tuple, NamedTuple}, mankeys::Dict{S, V}) where
    {S<:AbstractString, V<:ValueType}

    #  The row has the fields, which follow each other, and the characters that the header has after them
    columns = tablecolumns(data)
    forms, starts = tablelayout(columns, mankeys)
    ends = [start + tableformat(form)[2] - 1 for (form, start) in zip(forms, starts)]
    rows = data isa AbstractArray ? length(data) : isempty(columns) ? 0 : length(first(columns))
    rowlen = data isa AbstractArray{<:AbstractString} ? maximum(length, data; init = 0) : 0
    M = max(maximum(ends; init = 0), rowlen, get(mankeys, "NAXIS1", 0))
    DataFormat(BITS2TYPE[8], M*rows, (M, rows), 0, 1, 0)
end

function FieldFormat(::Type{Table}, format::DataFormat, reskeys::Dict{S, V},
    data::Missing; record::Bool = false, kwds...) where {S<:AbstractString, V<:ValueType}

    N = get(reskeys, "TFIELDS", 0)
    names = Set{String}()
    fields = Vector{TableField}(undef, N)
    for j = 1:N
        for key in ("TFORM$j", "TBCOL$j")
            haskey(reskeys, key) || throw(ArgumentError("$key is missing, but TFIELDS is $N."))
        end
        name = tablename(tablestring(reskeys, "TTYPE$j", ""), "column$j", names)
        fields[j] = tablefield(reskeys, j, name, reskeys["TFORM$j"], reskeys["TBCOL$j"])
    end
    fields
end

function FieldFormat(::Type{Table}, format::DataFormat, reskeys::Dict{S, V},
    data::Union{AbstractArray, Tuple, NamedTuple}; kwds...) where {S<:AbstractString, V<:ValueType}

    columns = tablecolumns(data)
    forms, starts = tablelayout(columns, reskeys)
    given = tablenames(data)
    names = Set{String}()
    fields = Vector{TableField}(undef, length(forms))
    for j in eachindex(forms)
        isnothing(given) || checkname(j, given[j])
        name = tablename(isnothing(given) ? tablestring(reskeys, "TTYPE$j", "") : given[j], "column$j", names)
        fields[j] = tablefield(reskeys, j, name, forms[j], starts[j])
    end
    fields
end

#  The keywords of a ASCII table extension from XTENSION to TFIELDS, where the shape is the length of a row and the number of rows
function tablekeys(::Type{Table}, format::DataFormat, nfields::Integer)
	M, N = length(format.shape) == 2 ? format.shape : (0, 0)
	Pair{String, Any}["XTENSION" => "TABLE", "BITPIX" => 8, "NAXIS" => 2, "NAXIS1" => M,
		"NAXIS2" => N, "PCOUNT" => 0, "GCOUNT" => 1, "TFIELDS" => nfields]
end

function createcards!(::Type{Table}, format::DataFormat,
    fields::Vector{TableField}, cards::Cards; kwds...)

    required = tablekeys(Table, format, length(fields))
    for (j, field) in enumerate(fields)
        push!(required, "TFORM$j" => field.form, "TBCOL$j" => first(field.slice))
        #  The name of a field is its TTYPEn unless it is the default, and a name is a string of a card
        ncodeunits(field.name) > 68 && throw(ArgumentError("The name of field $j, $(repr(first(field.name, 20)))..., has " *
            "$(ncodeunits(field.name)) characters, but the value of a TTYPEn keyword has at most 68 (Sect. 4.2.1.1)."))
        field.name == "column$j" || push!(required, "TTYPE$j" => field.name)
    end
    arrangecards!(cards, required)
end

#  The data of a header that has no data are the blank rows of the table, or missing if the table has no rows
function createdata(::Type{Table}, format::DataFormat,
    fields::Vector{TableField}; kwds...)
    length(format.shape) == 2 ? [repeat(" ", format.shape[1]) for j = 1:format.shape[2]] : missing
end

#  A table that has fields and no rows has no data blocks, and its data are the empty columns of the fields, or the empty vector of records. A
#  table that has no fields has no data.
function emptydata(::Type{Table}, format::DataFormat, fields::Vector{TableField}; kwds...)
    length(format.shape) == 2 && format.shape[2] == 0 && !isempty(fields) ?
        read(IOBuffer(UInt8[]), Table, format, fields; kwds...) : missing
end

####    Scaling

#  Are the physical values of a field a `ScaledArray`, which has the scale and the zero, and is written as the stored values? They are if the
#  values of the field are floating-point numbers like its stored values, or exact integers, and the field is scaled by a TSCAL that is not 1 or a
#  TZERO that is not 0 (Eq. 7), since the values do not say that they are scaled.
physicalscaled(field::TableField) = (field.type <: AbstractFloat || exactzero(field)) && !(field.scale == 1 && field.zero == 0)

#  The TSCALn and TZEROn cards of the fields that are the physical values of floating-point stored values, which have the scale and the zero of
#  the data
function scalecards!(::Type{Table}, cards::Cards, data::Union{Tuple, NamedTuple})
    for (j, column) in enumerate(data)
        column isa ScaledArray || continue
        setscalecard!(cards, "TSCAL$j", column.scale, 1)
        setscalecard!(cards, "TZERO$j", column.zero, 0)
    end
    cards
end
function scalecards!(::Type{Table}, cards::Cards, data::ScaledRows)
    names = isempty(data) ? something(tablenames(data), String[]) : String[String(name) for name in keys(first(data))]
    for (j, name) in enumerate(names)
        haskey(data.scales, Symbol(name)) || continue
        setscalecard!(cards, "TSCAL$j", data.scales[Symbol(name)][1], 1)
        setscalecard!(cards, "TZERO$j", data.scales[Symbol(name)][2], 0)
    end
    cards
end

#  The scale and the zero of the field k of the data, if its values are the physical values of floating-point stored values, and nothing if
#  they are the stored values
tablescale(data::Union{Tuple, NamedTuple}, k::Integer, field::TableField) =
    data[k] isa ScaledArray ? (data[k].scale, data[k].zero) : nothing
tablescale(data::ScaledRows, k::Integer, field::TableField) = get(data.scales, Symbol(field.name), nothing)
tablescale(data, k::Integer, field::TableField) = nothing

####    Read the data

#  An entry is undefined if it is the TNULLn string, which is implicitly space filled to the width of the field (Sect. 7.2.2 of the
#  standard). A blank entry has the value 0, or is an empty string (Sect. 7.2.5).
isundefined(field::TableField, item::AbstractString) = !isnothing(field.null) && rpad(field.null, length(item)) == item

function tablevalueerror(field::TableField, item::AbstractString, row::Integer, what::AbstractString)
    ArgumentError("The value $(repr(item)) of field $(field.name) in row $row is not $what of the format $(field.form) (Sect. 7.2.5).")
end

#  The value of an integer field: a single optional sign and one or more digits, with spaces before or after them, or 0 if the field is blank, an
#  Int64, or a BigInt if the Int64 does not hold it
function parseinteger(field::TableField, item::AbstractString, row::Integer)
    text = strip(item, ' ')
    isempty(text) && return 0
    occursin(r"^[+-]?[0-9]+$", text) || throw(tablevalueerror(field, item, row, "an integer"))
    #  An integer that does not fit an Int64 is a BigInt, since the standard has no limit (Sect. 7.2.5)
    value = tryparse(Int64, text)
    isnothing(value) ? Base.parse(BigInt, text) : value
end

const REALFORM = r"^([+-]?)([0-9]*)(?:\.([0-9]*))?(?:[EeDd]([+-]?[0-9]+)|([+-][0-9]+))?$"

#  The value of a real field (Sect. 7.2.5): the numeric string, a single optional sign and digits with an optional decimal point, then
#  an exponent, which is E or D and a signed integer, or a signed integer. The decimal point that a numeric string does not have is before the
#  rightmost `decimals` digits (the d of the format). The blank field is 0.
function parsereal(field::TableField, item::AbstractString, row::Integer, decimals::Integer)
    text = strip(item, ' ')
    isempty(text) && return 0.0
    m = match(REALFORM, text)
    (isnothing(m) || (isempty(m[2]) && isempty(something(m[3], "")))) && throw(tablevalueerror(field, item, row, "a real number"))
    digits, point = m[2], m[3]
    if isnothing(point) && decimals > 0
        digits = lpad(digits, decimals + 1, '0')
        whole, fraction = digits[1:end-decimals], digits[end-decimals+1:end]
    else
        whole, fraction = isempty(digits) ? "0" : digits, isempty(something(point, "")) ? "0" : point
    end
    value = tryparse(Float64, "$(m[1])$whole.$(fraction)e$(something(m[4], m[5], "0"))")
    (isnothing(value) || !isfinite(value)) && throw(ArgumentError("The number $(repr(strip(item))) of field $(field.name) in row $row is not in the range of a " *
        "Float64."))
    value
end

#  The characters of the rows that are not in a field are not read, and are written as spaces (Sect. 7.2.4)
function verifyoutside(bytes::AbstractMatrix{UInt8}, fields::Vector{TableField})
    M, N = size(bytes)
    covered = falses(M)
    for field in fields
        covered[intersect(field.slice, 1:M)] .= true
    end
    outside = findall(!, covered)
    (isempty(outside) || N == 0) && return nothing
    for i in outside, j = 1:N
        if bytes[i, j] != 0x20
            @warn "The character $(repr(Char(bytes[i, j]))) of row $j, column $i, is not in a field and is not a space, but the " *
                "characters of a row that are not in a field are not read, and are written as spaces (Sect. 7.2.4)."
            return nothing
        end
    end
    nothing
end

#  The values of a field in the bytes of the rows, which are a column of the matrix `bytes`, each, as a vector, with `missing` for an undefined
#  entry. The values are scaled by the TSCALn and TZEROn of the field (Eq. 7), unless `scale` is false: the values of an integer field are
#  floating-point numbers, and those of a floating-point field are a `ScaledArray`.
function readcolumn(field::TableField, bytes::AbstractMatrix{UInt8}; scale::Bool = true)
    code, _, decimals = tableformat(field.form)
    type, N = field.type, size(bytes, 2)
    if code == "A" && !all(byte -> 0x20 <= byte <= 0x7e, view(bytes, field.slice, :))
        @warn "The characters of field $(field.name) are not all ASCII text characters, from 32 to 126 (Sect. 7.2.5). They are read as they are."
    end
    #  The values of an integer field are Int64, or BigInt if one of them is not an Int64
    values = Vector{Union{code == "I" ? Union{Int64, BigInt} : type, Missing}}(undef, N)
    for j = 1:N
        item = String(bytes[field.slice, j])
        values[j] = isundefined(field, item) ? missing : code == "A" ? rstrip(item) :
            code == "I" ? parseinteger(field, item, j) : parsereal(field, item, j, decimals)
    end
    code == "I" && any(value -> value isa BigInt, values) && (type = BigInt)
    #  The column has missing values only if there are undefined entries
    column = any(ismissing, values) ? Union{type, Missing}[ismissing(value) ? missing : type(value) for value in values] :
        type[value for value in values]
    verifyrange(field, column)
    (scale && code != "A" && !(field.scale == 1 && field.zero == 0)) || return column
    exactzero(field) && return ScaledArray(exactvalues(column, field.zero), field.scale, field.zero)
    #  A BigInt is scaled as a 64-bit floating-point number, as the other integers are
    type == BigInt && (column = [ismissing(value) ? missing : Float64(value) for value in column])
    column = scaled(column, field.scale, field.zero)
    code == "I" ? column : ScaledArray(column, field.scale, field.zero)
end

#  The exact integers of the stored values of an integer field and TZEROn: Int64, or BigInt if an Int64 does not hold all of them, as for the
#  integers of the other fields. The sums are 128-bit integers, unless the stored values are BigInt or TZEROn is not an Int64 or an Int128 of at
#  most 2^100, which are BigInt.
function exactvalues(column::AbstractVector, zero::Integer)
    big = nonmissingtype(eltype(column)) === BigInt || !(zero isa Union{Int64, Int128} && abs(zero) < Int128(2)^100)
    wide = [ismissing(value) ? missing : big ? BigInt(value) + BigInt(zero) : Int128(value) + Int128(zero) for value in column]
    present = collect(skipmissing(wide))
    lo, hi = isempty(present) ? (0, 0) : extrema(present)
    type = typemin(Int64) <= lo && hi <= typemax(Int64) ? Int64 : BigInt
    any(ismissing, wide) ? Union{type, Missing}[ismissing(value) ? missing : type(value) for value in wide] : type[value for value in present]
end

#  The smallest and the largest value of a column of a field, which are the minimum and the maximum physical values of the column that TDMINn and
#  TDMAXn are (Sect. 7.2.2), are not less than TDMINn and not more than TDMAXn, which a warning says if they are. The values of the column are the
#  stored values, whose physical values are those of TSCALn and TZEROn (Eq. 7), and the undefined values are not in the minimum and the maximum.
#  The numbers of a header have the digits that they were written with, so a real number of the column is compared to within 10^-6 of its size.
function verifyrange(field::TableField, column::AbstractVector)
    (isnothing(field.dmin) && isnothing(field.dmax)) && return nothing
    field.type <: AbstractString && return nothing
    present = collect(skipmissing(column))
    (isempty(present) || field.scale == 0) && return nothing
    lo, hi = extrema(present)
    #  The physical values of integers are integers if the field is not scaled or its values are exact integers
    exact = field.type <: Integer && field.scale == 1 && (field.zero isa Integer || field.zero == 0)
    compact(x::BigInt) = typemin(Int64) <= x <= typemax(Int64) ? Int64(x) : x
    physical(x) = exact ? compact(BigInt(x) + (field.zero == 0 ? 0 : field.zero)) : field.zero + field.scale * Float64(x)
    lo, hi = minmax(physical(lo), physical(hi))
    number(x) = x isa Integer ? x : tablefloat(x)
    for (name, bound, value, less) in (("TDMIN", field.dmin, lo, true), ("TDMAX", field.dmax, hi, false))
        isnothing(bound) && continue
        bound = number(bound)
        outside = less ? value < bound : value > bound
        outside && !(bound isa AbstractFloat || value isa AbstractFloat ? isapprox(value, bound; rtol = 1e-6) : false) &&
            @warn "$name of field $(field.name), $bound, is $(less ? "more" : "less") than the $(less ? "smallest" : "largest") value of " *
                "the field, $value, but $name is the $(less ? "minimum" : "maximum") " *
                "physical value of the column (Sect. 7.2.2). It is read as it is."
    end
    nothing
end

function Base.read(io::IO, ::Type{Table}, format::DataFormat, fields::Vector{TableField};
    record::Bool = false, scale::Bool = true, kwds...)

    M, N = format.shape[1], format.shape[2]
    bytes = reshape(readbytes(io, M*N), M, N)
    verifyoutside(bytes, fields)
    columns = [readcolumn(field, bytes; scale) for field in fields]
    names = Tuple(Symbol(field.name) for field in fields)
    if record
        rows = [NamedTuple{names}(Tuple(column[j] for column in columns)) for j = 1:N]
        scales = Dict{Symbol, Tuple{Real, Real}}(Symbol(field.name) => (field.scale, field.zero)
            for field in fields if scale && physicalscaled(field))
        isempty(scales) ? rows : ScaledRows(rows, scales)
    else
        NamedTuple{names}(Tuple(columns))
    end
end

####    Write the data

#  The value of the field k, which is `field`, in row j of the data, which is a vector of records or a named tuple (or a tuple) of columns. The
#  value is of the name of the field, if the data have names, and otherwise at the place of the field.
tablecell(data::AbstractArray, k::Integer, field, j::Integer) = data[j] isa NamedTuple ? data[j][Symbol(field.name)] : data[j][k]
tablecell(data::NamedTuple, k::Integer, field, j::Integer) = data[Symbol(field.name)][j]
tablecell(data::Tuple, k::Integer, field, j::Integer) = data[k][j]

#  The characters of a field are the restricted set of ASCII text characters, from 32 to 126 (Sect. 7.2.5)
function checktext(text::AbstractString, name::AbstractString)
    all(c -> ' ' <= c <= '~', text) || throw(ArgumentError("The string $(repr(text)) of $name has characters that are not " *
        "ASCII text characters, from 32 to 126 (Sect. 7.2.5)."))
    text
end

#  The stored value of a value of the field: the values of the data that are the physical values of floating-point stored values are inverted,
#  if the data have the scale and the zero of the header, the physical values of an integer field with a scale or a zero are inverted and
#  rounded (Eq. 7), and the other values are the stored values
function storedreal(field::TableField, value::Real, code::AbstractString; check::Bool = true, physical = nothing)
    scale, zero = field.scale, field.zero
    if !isnothing(physical)
        physical == (scale, zero) || throw(ArgumentError("The scale and the zero of the data of field $(field.name), " *
            "$(physical[1]) and $(physical[2]), are not the TSCAL and the TZERO of the header, $scale and $zero."))
        if code == "I"
            #  The exact integers are the stored values and TZEROn, and the stored value is an Int64, or a BigInt if the Int64 does not hold it
            (value isa Integer || (value isa AbstractFloat && isfinite(value) && isinteger(value))) && zero isa Integer ||
                throw(ArgumentError("The value $value of field $(field.name) is not an integer, but the field has the format " *
                "$(field.form) of integers (Sect. 7.2.5)."))
            stored = BigInt(value) - BigInt(zero)
            return typemin(Int64) <= stored <= typemax(Int64) ? Int64(stored) : stored
        end
        scale == 0 && throw(ArgumentError("The values cannot be written as stored values, since TSCAL is 0."))
        return (Float64(value) - zero) / scale
    end
    value isa Integer && return value
    code == "I" || return value
    (scale == 1 && zero == 0) && throw(ArgumentError("The value $value of field $(field.name) is not an integer, but the " *
        "field has the format $(field.form) of integers (Sect. 7.2.5)."))
    isfinite(value) || throw(ArgumentError("The value $value of field $(field.name) cannot be written in the format " *
        "$(field.form) of integers, which has no NaN or infinity (Sect. 7.2.5)."))
    storedvalue(value, Int64, scale, zero, nothing, check; keys = ("TSCAL", "TZERO"))
end

#  The text of a value in a field, as wide as the field: a string is filled with spaces after it, a number is right-justified, and an undefined
#  value is the TNULLn string, filled with spaces (Sects. 7.2.2 and 7.2.5). A value that has more characters than the field has would shift the
#  fields after it, so it is an error.
function fieldtext(field::TableField, value, format; check::Bool = true, physical = nothing)
    code, width, decimals = tableformat(field.form)
    if ismissing(value)
        isnothing(field.null) && throw(ArgumentError("A missing value cannot be written to field $(field.name), which has no " *
            "TNULLn keyword (Sect. 7.2.2)."))
        length(field.null) > width && throw(ArgumentError("TNULL of field $(field.name), $(repr(field.null)), has more than the " *
            "$width characters of the field, so the undefined values cannot be written (Sect. 7.2.2)."))
        return rpad(field.null, width)
    end
    if code == "A"
        value isa AbstractString || throw(ArgumentError("The value $(repr(value)) of field $(field.name) is not a string, but the " *
            "field has the format $(field.form) of characters (Sect. 7.2.5)."))
        text = checktext(String(value), "field $(field.name)")
    else
        value isa Real && !(value isa Bool) || throw(ArgumentError("The value $(repr(value)) of field $(field.name) is not a number, " *
            "but the field has the format $(field.form) (Sect. 7.2.5)."))
        stored = storedreal(field, value, code; check, physical)
        if code == "I"
            text = string(stored)
        else
            isfinite(stored) || throw(ArgumentError("The value $value of field $(field.name) cannot be written in the format " *
                "$(field.form), which has no NaN or infinity (Sect. 7.2.5)."))
            text = realtext(Float64(stored), code, width, decimals, format)
        end
    end
    length(text) > width && throw(ArgumentError("The value $(repr(value)) of field $(field.name) has $(length(text)) characters, but " *
        "the format $(field.form) has $width, and a longer value would shift the fields after it (Sect. 7.2.5)."))
    code == "A" ? rpad(text, width) : lpad(text, width)
end

#  The text of a real number in a field of the format code F, E, or D, of `width` characters, and d `decimals`: the digits of the format, and the
#  fewest more digits that give the number again, if the text of them fits the field. The formats of Table 15 are input formats (Sect. 7.2.1),
#  so the digits of the number that the format does not have are not lost, which they are if the number is rounded to the digits, and the number
#  that needs more digits than the field has is rounded to the digits of the format. The exponent letter of a D format is D.
function realtext(value::Float64, code::AbstractString, width::Integer, decimals::Integer, format)
    letter = code == "F" ? "f" : "E"
    again(text) = Base.parse(Float64, replace(strip(text), "D" => "E")) == value
    text = Printf.format(format, value)
    if !again(text)
        for k = decimals+1:width
            more = Printf.format(Printf.Format("%$(width).$(k)$letter"), value)
            length(more) <= width && again(more) && (text = more; break)
        end
    end
    code == "D" ? replace(text, "E" => "D") : text
end

#  The format of the output of the real field, or nothing
function outputformat(field::TableField)
    code, width, decimals = tableformat(field.form)
    code in ("F", "E", "D") ? Printf.Format("%$(width).$(decimals)$(code == "F" ? "f" : "E")") : nothing
end

function Base.write(io::IO, ::Type{Table}, data::Union{AbstractArray, Tuple, NamedTuple},
    format::DataFormat, fields::Vector{TableField}; check::Bool = true, kwds...)

    #  Each row has the characters of the fields, and spaces in the others, so that the fields that overlap or leave a gap are written as the
    #  header says
    format.leng > 0 || return nothing
    M, N = format.shape[1], format.shape[2]
    formats = [outputformat(field) for field in fields]
    row = Vector{UInt8}(undef, M)
    for j = 1:N
        fill!(row, 0x20)
        if data isa AbstractArray{<:AbstractString}
            copyto!(row, 1, codeunits(checktext(data[j], "row $j")), 1, length(data[j]))
        else
            for (k, field) in enumerate(fields)
                text = fieldtext(field, tablecell(data, k, field, j), formats[k]; check, physical = tablescale(data, k, field))
                copyto!(row, first(field.slice), codeunits(text), 1, length(text))
            end
        end
        write(io, row)
    end
    #  Pad last block with spaces
    padblock(io, format, 0x20)
end

#  A table that has no data has no data blocks
Base.write(io::IO, ::Type{Table}, data::Missing, format::DataFormat, fields::Vector{TableField}; kwds...) = nothing

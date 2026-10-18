#  ASCII names of the units that are not ASCII or are named differently in the FITS standard
#  (Tables 3 and 4), and of the prefixes, that are the keys of the Unitful abbreviations.
const FITS_UNIT_NAMES = Dict(
	"Å" => "Angstrom", "°" => "deg", "Ω" => "Ohm", "″" => "arcsec", "′" => "arcmin",
	"M⊙" => "solMass", "L⊙" => "solLum", "R⊙" => "solRad", "ly" => "lyr", "hr" => "h",
	"minute" => "min", "Gauss" => "G", "μ" => "u", "µ" => "u")

"""
	formunit(unit[, ufmt])

Return the ASCII string of a unit in the FITS standard (Sect. 4.3). The style of the string is
`ufmt`, which has three characters: the separator of the units, a space, `.`, or `*`; `/` if
a unit with a negative power follows a slash, or `-` if it has the negative power; and the style
of a power, `d` for digits following the unit, `^`, or `*` for `**`. The default is ` -d`.
"""
function formunit(unit::Unitful.Units, ufmt::AbstractString = "")
	sep, div, pow = isempty(ufmt) ? (' ', '-', 'd') : (ufmt[1], ufmt[2], ufmt[3])
	factors = typeof(unit).parameters[1]
	numer = filter(f -> f.power > 0, collect(factors))
	denom = filter(f -> f.power < 0, collect(factors))
	if div == '/' && !isempty(numer) && !isempty(denom)
		#  The units with negative powers follow a slash.
		join(formfactor.(numer, pow), sep) * join(["/" * formfactor(typeof(f)(f.tens, -f.power), pow)
			for f in denom])
	else
		join(formfactor.(factors, pow), sep)
	end
end

#  The style of a unit string, which is the format that is used to write the string again.
function unitstyle(text::AbstractString)
	stars = replace(text, "**" => "")
	(occursin('.', text) ? '.' : occursin('*', stars) ? '*' : ' ') * (occursin('/', text) ? '/' : '-') *
		(occursin("**", text) ? '*' : occursin('^', text) ? '^' : 'd')
end

#  The standard has no affine units, e.g., degrees Celsius.
formunit(unit::Unitful.AffineUnits, ufmt::AbstractString = "") =
	throw(ArgumentError("The affine unit $unit has no FITS name."))

formunit(::Nothing, ufmt::AbstractString = "") = ""

#  The units of the writers of a card format, where no units are missing.
unitstring(::Nothing, ufmt::AbstractString = "") = missing
unitstring(unit, ufmt::AbstractString = "") = formunit(unit, ufmt)

function formfactor(unit::Unitful.Unit, pow::Char = 'd')
	name = get(FITS_UNIT_NAMES, Unitful.abbr(unit), Unitful.abbr(unit))
	prefix = get(FITS_UNIT_NAMES, Unitful.prefix(unit), Unitful.prefix(unit))
	power = unit.power.den == 1 ? (unit.power.num == 1 ? "" :
		(pow == '^' ? "^" : pow == '*' ? "**" : "") * string(unit.power.num)) :
		"**($(unit.power.num)/$(unit.power.den))"
	text = prefix * name * power
	isascii(text) || throw(ArgumentError("The unit $(Unitful.abbr(unit)) has no FITS name."))
	text
end

####  Parse FITS units  ####

#  Units of the FITS standard that are not in Unitful, namely units of counting. Each unit has
#  its own dimension, so the units cannot be combined with each other.
module FITSUnits
using Unitful

@dimension DimPixel   "Pixel"   PixelDimension
@dimension DimCount   "Count"   CountDimension
@dimension DimPhoton  "Photon"  PhotonDimension
@dimension DimADU     "ADU"     ADUDimension
@dimension DimBeam    "Beam"    BeamDimension
@dimension DimChannel "Channel" ChannelDimension
@dimension DimBin     "Bin"     BinDimension
@dimension DimVoxel   "Voxel"   VoxelDimension
@dimension DimBit     "Bit"     BitDimension

@refunit pix   "pix"   Pixel   DimPixel   false
@refunit ct    "ct"    Count   DimCount   false
@refunit ph    "ph"    Photon  DimPhoton  false
@refunit adu   "adu"   ADU     DimADU     false
@refunit beam  "beam"  Beam    DimBeam    false
@refunit chan  "chan"  Channel DimChannel false
@refunit bin   "bin"   Bin     DimBin     false
@refunit voxel "voxel" Voxel   DimVoxel   false
@refunit bit   "bit"   Bit     DimBit     true
@unit    byte  "byte"  Byte    8bit       true

function __init__()
	Unitful.register(FITSUnits)
end
end

#  Names of the FITS units (Tables 3 and 4) that are different in Unitful.
const UNITFUL_UNIT_NAMES = Dict(
	"Ohm" => "Ω", "deg" => "°", "arcmin" => "arcminute", "arcsec" => "arcsecond",
	"min" => "minute", "h" => "hr", "solMass" => "Msun", "solLum" => "Lsun",
	"solRad" => "Rsun", "Angstrom" => "Å", "lyr" => "ly", "G" => "Gauss", "R" => "Ra",
	"barn" => "b", "count" => "ct", "photon" => "ph", "pixel" => "pix")

const UNITFUL_MODULES = [Unitful, UnitfulAstro, UnitfulAngles, UnitfulAtomic, FITSUnits]

#  Base units (Tables 3 and 4) and prefixes (Table 5) of the FITS standard. The units D, Sun,
#  and mag have no Unitful unit.
const FITS_UNIT_BASES = Set(split("m g s rad sr K A mol cd Hz J W V N Pa C Ohm S F Wb T H lm lx " *
	"deg arcmin arcsec mas min h d a yr eV erg Ry solMass u solLum Angstrom solRad AU lyr pc " *
	"count ct photon ph Jy R G barn bit byte adu beam pixel pix chan bin voxel"))
const FITS_PREFIXES = ("da", "Y", "Z", "E", "P", "T", "G", "M", "k", "h", "d", "c", "m", "u",
	"n", "p", "f", "a", "z", "y")

const UNIT_CACHE = Dict{String, Any}()

#  Return the Unitful unit of a FITS unit name, which is a base unit with an optional prefix,
#  or nothing. A base unit has priority over a prefix, e.g., min is minutes and not milli-in.
function unitname(name::AbstractString)
	get!(UNIT_CACHE, name) do
		candidates = [("", name)]
		append!(candidates, [(p, name[(length(p)+1):end]) for p in FITS_PREFIXES if startswith(name, p)])
		for (prefix, base) in candidates
			base in FITS_UNIT_BASES || continue
			text = (prefix == "u" ? "μ" : prefix) * get(UNITFUL_UNIT_NAMES, base, base)
			unit = try
				uparse(text; unit_context = UNITFUL_MODULES)
			catch
				nothing
			end
			unit isa Unitful.FreeUnits && return unit
		end
		nothing
	end
end

"""
	parseunit(string)

Parse a unit string of the FITS standard (Sect. 4.3) and return the unit, or `nothing` if the
string is not a valid unit string or has a unit that is not known. Units are multiplied by a
space, `.`, or `*`, and divided by `/`, which may begin the string. A unit is raised to a power by
an integer following the unit, by a decimal number or a ratio in parentheses following the unit,
or by `**` or `^` followed by an integer, a decimal number, or a ratio in parentheses.
A scale factor, `10**k`, `10^k`, or `10+k`, is followed by a unit and returns a quantity.
"""
function parseunit(str::AbstractString)
	str = strip(str)
	unit, i = parse_units(str, firstindex(str))
	isnothing(unit) || i <= lastindex(str) && return nothing
	unit
end

#  Parse a unit string from the index `i`, and return the unit and the index after the unit.
#  Products and quotients are evaluated from the left to the right.
function parse_units(str::AbstractString, i::Integer)
	#  A unit string may begin with a division, e.g., /m3.
	j = skipspaces(str, i)
	if j <= lastindex(str) && str[j] == '/'
		unit, i = parse_factor(str, skipspaces(str, j + 1))
		isnothing(unit) || (unit = inv(unit))
	else
		unit, i = parse_factor(str, i)
	end
	while !isnothing(unit)
		j = skipspaces(str, i)
		op = j <= lastindex(str) ? str[j] : ' '
		if op in ('*', '.', '/')
			factor, k = parse_factor(str, skipspaces(str, j + 1))
			isnothing(factor) && return nothing, i
			unit, i = op == '/' ? unit / factor : unit * factor, k
		elseif j > i && j <= lastindex(str) && str[j] != ')'
			factor, k = parse_factor(str, j)
			isnothing(factor) && return nothing, i
			unit, i = unit * factor, k
		else
			break
		end
	end
	unit, i
end

#  Parse a unit with a power, a unit string in parentheses, or a scale factor.
function parse_factor(str::AbstractString, i::Integer)
	i = skipspaces(str, i)
	i > lastindex(str) && return nothing, i
	if str[i] == '('
		unit, j = parse_units(str, i + 1)
		(isnothing(unit) || skipspaces(str, j) > lastindex(str) || str[skipspaces(str, j)] != ')') && return nothing, i
		return parse_power(str, skipspaces(str, j) + 1, unit)
	elseif (m = match(r"^10(?:[+-]\d+|(?=\*\*|\^))", str[i:end])) !== nothing
		#  A scale factor is a power of ten, 10+k, 10-k, 10**k, or 10^k, followed by a unit.
		op = match(r"^(?:\*\*|\^)", str[(i+2):end])
		power, j = m.match == "10" ? parse_exponent(str, i + 2 + ncodeunits(op.match)) :
			(parse(Int, m.match[3:end]) // 1, i + ncodeunits(m.match))
		isnothing(power) && return nothing, i
		unit, k = parse_factor(str, skipspaces(str, j))
		isnothing(unit) && return nothing, i
		return 10.0^power * unit, k
	elseif (m = match(r"^([A-Za-z]+)([+-]?\d+)?", str[i:end])) !== nothing
		name, j = m[1], i + ncodeunits(m.match)
		if name == "sqrt" && j <= lastindex(str) && str[j] == '('
			unit, k = parse_units(str, j + 1)
			(isnothing(unit) || k > lastindex(str) || str[k] != ')') && return nothing, i
			return unit^(1//2), k + 1
		end
		unit = unitname(name)
		isnothing(unit) && return nothing, i
		isnothing(m[2]) ? parse_power(str, j, unit) : (unit^parse(Int, m[2]), j)
	else
		nothing, i
	end
end

#  Parse an optional power of a unit, which follows ** or ^, or is a number in parentheses.
function parse_power(str::AbstractString, i::Integer, unit)
	m = match(r"^(?:\*\*|\^)", str[i:end])
	if isnothing(m)
		isnothing(match(r"^\([+-]?\d+(?:\.\d+)?(?:/\d+)?\)", str[i:end])) && return unit, i
		power, j = parse_exponent(str, i)
		return unit^power, j
	end
	power, j = parse_exponent(str, i + ncodeunits(m.match))
	isnothing(power) ? (nothing, i) : (unit^power, j)
end

#  Parse an exponent, which is an integer, a decimal number, or a ratio in parentheses.
function parse_exponent(str::AbstractString, i::Integer)
	m = match(r"^(?:\(([+-]?\d+(?:\.\d+)?)(?:/(\d+))?\)|([+-]?\d+))", str[i:end])
	isnothing(m) && return nothing, i
	value = rationalize(parse(Float64, something(m[1], m[3])))
	isnothing(m[2]) || (value //= parse(Int, m[2]))
	value, i + ncodeunits(m.match)
end

#  The index of the first character that is not a space, from the index `i`.
function skipspaces(str::AbstractString, i::Integer)
	while i <= lastindex(str) && str[i] == ' '
		i = nextind(str, i)
	end
	i
end

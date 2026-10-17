const unit_conversions = (
    "Ohm"    => "Ω",          "Ω" => "Ohm",
    "deg"    => "°",          "°" => "deg",
    "arcmin" => "arcminute",  "arcminute" => "arcmin",
    "arscec" => "arcsecond",  "arcsecond" => "arcsec",
    "min"    => "minute",     "minute" => "min",
    "h" => "hr",              "hr" => "h",
    "a" => "yr",              "yr" => "a",
    "solMass" => "Msun",      "Msun" => "solMass",
    "Angstrom" => "angstrom", "angstrom" => "Angstrom",
    "solRad" => "Rsun",       "Rsun" => "solRad",
    "lyr" => "ly",            "ly" => "lyr",
    # "count" => "",          "" => "count",
    # "ct" => "",             "" => "ct",
    # "photon" => "",         "" => "photon",
    # "ph" => "",             "" => "ph",
    # "R" => "Rayleigh",      "Rayleigh" => "R",
    "G" => "Gauss",           "Gauss" => "G",
    # "pixel" => "pix",       "pix" => "pixel",
    # "pix" => "pix",         "pix" => "pix",
    # "barn" => "barn",       "barn" => "barn",
    # "D" => "debye",         "debye" => "D",
    # "chan" => "",           "" => "chan",
    # "bin => "",             "" => "bin",
    # "voxel" => "",          "" => "voxel",
    # "bit" => "",            "" => "bit",
    # "byte" => "",           "" => "byte",
    # "adu" => "",            "" => "adu",
    # "beam" => "",           "" => "beam"
)

#  ASCII names of the units that are not ASCII or are named differently in the FITS standard
#  (Tables 3 and 4), and of the prefixes, that are the keys of the Unitful abbreviations.
const FITS_UNIT_NAMES = Dict(
	"Å" => "Angstrom", "°" => "deg", "Ω" => "Ohm", "″" => "arcsec", "′" => "arcmin",
	"M⊙" => "solMass", "L⊙" => "solLum", "R⊙" => "solRad", "ly" => "lyr", "hr" => "h",
	"minute" => "min", "Gauss" => "G", "μ" => "u", "µ" => "u")

"""
	formunit(unit)

Return the ASCII string of a unit in the FITS standard (Sect. 4.3), where the units are
separated by spaces and the integer powers follow the unit, e.g., `km s-1`.
"""
formunit(unit::Unitful.Units) = join(formfactor.(typeof(unit).parameters[1]), " ")

#  The standard has no affine units, e.g., degrees Celsius.
formunit(unit::Unitful.AffineUnits) =
	throw(ArgumentError("The affine unit $unit has no FITS name."))

function formfactor(unit::Unitful.Unit)
	name = get(FITS_UNIT_NAMES, Unitful.abbr(unit), Unitful.abbr(unit))
	prefix = get(FITS_UNIT_NAMES, Unitful.prefix(unit), Unitful.prefix(unit))
	power = unit.power.den == 1 ? (unit.power.num == 1 ? "" : string(unit.power.num)) :
		"**($(unit.power.num)/$(unit.power.den))"
	text = prefix * name * power
	isascii(text) || throw(ArgumentError("The unit $(Unitful.abbr(unit)) has no FITS name."))
	text
end

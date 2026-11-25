module DynamicQuantitiesExt

#  The units of the FITS standard for the quantities of DynamicQuantities, which has symbolic
#  dimensions. A unit is a quantity with the value one and the symbolic dimensions of the unit,
#  e.g., `km/s` has the symbols `km` and `s`. Units that DynamicQuantities does not have are
#  registered, and a prefix is registered when the unit with the prefix is first used.

using FITSFiles
using DynamicQuantities
import FITSFiles: FITS_PREFIXES, FITS_UNIT_BASES, formunit, isunit, joinunits, lookupunit, splitunits

const DQ = DynamicQuantities

#  The names of the FITS units (Tables 3 and 4) that are different in DynamicQuantities.
const DQ_UNIT_NAMES = Dict(
	"Ohm" => "Ω", "Angstrom" => "Å", "G" => "Gauss", "lyr" => "ly", "AU" => "au", "a" => "yr")

#  The inverse, which are the names of the units of a quantity that are not FITS names.
const FITS_UNIT_NAMES = Dict("Ω" => "Ohm", "Å" => "Angstrom", "Gauss" => "G", "ly" => "lyr", "au" => "AU")

#  The factors of the prefixes (Table 5).
const PREFIX_POWERS = Dict("da" => 1, "Y" => 24, "Z" => 21, "E" => 18, "P" => 15, "T" => 12,
	"G" => 9, "M" => 6, "k" => 3, "h" => 2, "d" => -1, "c" => -2, "m" => -3, "u" => -6, "n" => -9,
	"p" => -12, "f" => -15, "a" => -18, "z" => -21, "y" => -24)

#  The units that DynamicQuantities does not have, in terms of the units that it has. The
#  counting units are dimensionless, which the symbolic dimensions keep apart.
const OWN_UNITS = [
	:Ry => () -> 2.1798723611035e-18 * us"J",
	:lm => () -> 1.0 * us"cd" * us"sr",
	:lx => () -> 1.0 * us"cd" * us"sr" / us"m"^2,
	:solMass => () -> 1.988409870698051e30 * us"kg",
	:solLum => () -> 3.828e26 * us"W",
	:solRad => () -> 6.957e8 * us"m",
	:barn => () -> 1.0e-28 * us"m"^2,
	:D => () -> (1.0e-29 / 3) * us"C" * us"m",
	:pix => () -> 1.0 * us"m" / us"m",
	:pixel => () -> 1.0 * us"m" / us"m",
	:ct => () -> 1.0 * us"m" / us"m",
	:count => () -> 1.0 * us"m" / us"m",
	:ph => () -> 1.0 * us"m" / us"m",
	:photon => () -> 1.0 * us"m" / us"m",
	:adu => () -> 1.0 * us"m" / us"m",
	:beam => () -> 1.0 * us"m" / us"m",
	:chan => () -> 1.0 * us"m" / us"m",
	:bin => () -> 1.0 * us"m" / us"m",
	:voxel => () -> 1.0 * us"m" / us"m",
	:bit => () -> 1.0 * us"m" / us"m",
	:mag => () -> 1.0 * us"m" / us"m",
	:Sun => () -> 1.0 * us"m" / us"m"]

const REGISTER_LOCK = ReentrantLock()

#  The unit with the symbol `name` as a quantity with symbolic dimensions.
symbolic(name::Symbol) = DQ.Quantity(1.0, DQ.SymbolicDimensions{DQ.FRInt32}(; name => 1))

known(name::Symbol) = !iszero(get(DQ.ALL_MAPPING, name, 0))

#  Register the unit `name` as `value`, unless it is registered.
function register(name::Symbol, value)
	@lock REGISTER_LOCK begin
		known(name) || DQ.update_all_values(name, DQ.uexpand(value))
	end
	nothing
end

function __init__()
	for (name, value) in OWN_UNITS
		known(name) || register(name, value())
	end
	#  The byte is eight bits and the rayleigh is 10^10/(4π) photons per square metre, second, and steradian.
	known(:byte) || register(:byte, 8.0 * symbolic(:bit))
	known(:R) || register(:R, (1.0e10 / (4π)) * symbolic(:ph) / (us"m"^2 * us"s" * us"sr"))
end

#  The quantity of a FITS unit name, which is a base unit with an optional prefix, or nothing.
function FITSFiles.lookupunit(::Val{:DynamicQuantities}, name::AbstractString)
	candidates = [("", name)]
	append!(candidates, [(p, name[(length(p)+1):end]) for p in FITS_PREFIXES if startswith(name, p)])
	for (prefix, base) in candidates
		base in FITS_UNIT_BASES || continue
		text = get(DQ_UNIT_NAMES, base, base)
		symbol = Symbol(prefix * text)
		isempty(prefix) && !known(symbol) && continue
		if !known(symbol)
			basic = Symbol(text)
			known(basic) || continue
			register(symbol, 10.0^PREFIX_POWERS[prefix] * DQ.uexpand(symbolic(basic)))
		end
		return symbolic(symbol)
	end
	nothing
end

#  A unit is a quantity with symbolic dimensions and the value one.
isunit(unit::DQ.AbstractQuantity) = DQ.dimension(unit) isa DQ.SymbolicDimensions && isone(DQ.ustrip(unit))

splitunits(value::DQ.AbstractQuantity) = (DQ.ustrip(value), DQ.Quantity(one(DQ.ustrip(value)), DQ.dimension(value)))

#  The FITS name of the symbol of a unit.
function fitsname(symbol::Symbol)
	name = string(symbol)
	name = get(FITS_UNIT_NAMES, name, name)
	name = replace(name, r"^[μµ]" => "u")
	isascii(name) || throw(ArgumentError("The unit $symbol has no FITS name."))
	name
end

function formunit(unit::DQ.AbstractQuantity, ufmt::AbstractString = "")
	isone(DQ.ustrip(unit)) || throw(ArgumentError("The quantity $unit is not a unit."))
	dims = DQ.dimension(unit)
	dims isa DQ.SymbolicDimensions ||
		throw(ArgumentError("The unit $unit has no symbols, so it has no FITS name."))
	factors = [(fitsname(DQ.ALL_SYMBOLS[i]), Rational(p)) for (i, p) in zip(DQ.nzdims(dims), DQ.nzvals(dims))]
	joinunits(sort!(factors; by = f -> f[2] < 0), ufmt)
end

end

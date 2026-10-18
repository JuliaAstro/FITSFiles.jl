const PRINTF_FORMATS = Dict{String, Printf.Format}()

"""
	printfmt(vfmt, value)

Return the text of a number with the printf format `vfmt`. The conversion `e` is for a number
with a D exponent, which is written as a D. The format may end with `|-`, which writes the
exponent with a sign only if it is negative and without leading zeros, e.g., `E6`.
"""
function printfmt(vfmt::AbstractString, value::Number)
	spec, tag = occursin('|', vfmt) ? split(vfmt, '|'; limit = 2) : (vfmt, "")
	format = get!(() -> Printf.Format(spec), PRINTF_FORMATS, String(spec))
	text = value isa Complex ? Printf.format(format, real(value), imag(value)) :
		Printf.format(format, value)
	tag == "-" && (text = replace(text, r"([Ee])\+?(-?)0*(\d+)" => s"\1\2\3"))
	occursin('e', text) ? replace(text, 'e' => 'D') : text
end

#  The printf format of the text of a real number.
function realfmt(text::AbstractString)
	m = match(r"^([+-]?)(\d*)(\.?)(\d*)(?:([DEde])([+-]?)(\d+))?$", text)
	isnothing(m) && return ""
	flags = (m[1] == "+" ? "+" : "") * (m[3] == "." && isempty(m[4]) ? "#" : "")
	#  Zeros before the number are in the width.
	width = length(m[2]) > 1 && m[2][1] == '0' ? "0" * string(length(text)) : ""
	conv = !isnothing(m[5]) ? (uppercase(m[5]) == "D" ? "e" : "E") :
		isempty(m[3]) ? "d" : "f"
	prec = conv == "d" ? "" : "." * string(length(m[4]))
	#  An exponent that has neither a plus sign nor leading zeros is the minimal exponent.
	minimal = !isnothing(m[5]) && m[6] != "+" && !(length(m[7]) > 1 && m[7][1] == '0')
	"%" * flags * width * prec * conv * (minimal ? "|-" : "")
end

#  The printf format of the text of a complex number.
function complexfmt(text::AbstractString)
	m = match(r"^\((\s*)(\S+?)(\s*,\s*)(\S+?)(\s*)\)$", text)
	isnothing(m) && return ""
	re, im = realfmt(m[2]), realfmt(m[4])
	#  The tag of the format is for both numbers.
	tag = occursin('|', re) || occursin('|', im) ? "|-" : ""
	"(" * m[1] * replace(re, r"\|.*$" => "") * m[3] * replace(im, r"\|.*$" => "") * m[5] * ")" * tag
end

#  The printf format is kept for a new value of the same kind, and not for another kind.
function keepfmt(vfmt::AbstractString, value)
	isempty(vfmt) && return ""
	spec = first(split(vfmt, '|'))
	if last(spec) == ')'
		value isa Complex && (!occursin('d', spec) || real(value) isa Integer) ? vfmt : ""
	else
		value isa Real && !(value isa Bool) && (last(spec) != 'd' || value isa Integer) ? vfmt : ""
	end
end

#  The text of a number, which is aligned by the positions of the format. A number in fixed-format
#  ends at the index 30, and otherwise begins at the beginning index.
alignnumber(text::AbstractString, format::CardFormat) =
	format.fixd ? lpad(text, FIXEDINDEX) : " "^(first(format.vbeg)-1) * text

"""
	parse_number(real::AbstractString)

Determine the type of a number as a Float32, Float64, Int64, Int128, or BigInt. A floating-point
number is a Float32 only if it is represented exactly by its shortest Float32 string.
"""
function parse_number(real::AbstractString)
	real = uppercase(real)
	if occursin('D', real)
		value = parse(Float64, replace(real, "D" => "e"))
	elseif occursin(r"[.E]", real)
		value = parse(Float64, replace(real, "E" => "e"))
		value = parse(Float64, string(Float32(value))) == value ? Float32(value) : value
	else
		value = try
			parse(Int64, real)
		catch _
			try
				parse(Int128, real)
			catch _
				parse(BigInt, real)
			end
		end
	end
	value
end

"""
	parse_complex(real::AbstractString, imag::AbstractString)

Determine the type of a complex number as the smallest type that holds both parts.
"""
function parse_complex(real::AbstractString, imag::AbstractString)
	complex(parse_number(real), parse_number(imag))
end

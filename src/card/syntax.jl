####    Card type    ####

const CARDLENGTH::Int = 80
const KEYLENGTH::Int = 8
const TOKENLEN::Int = 10
const FIXEDINDEX::Int = 20  # from end of value token
const HIERINDEX::Int = 0

const EQUAL_TOKEN::String = "= "

const KEYWD_CHARS = "[A-Z0-9_-]"
const ASCII_CHARS = "[ -~]"
const VALUE_TOKEN = "[ A-Z0-9_-]{8}= "
const VALUE_KEY = KEYWD_CHARS*"*?"
const COMMENTARY_KEY = "COMMENT |HISTORY | {8}"
const COMMENT_KEY = COMMENTARY_KEY*"|HIERARCH"
const CONTINUE_KEY = "CONTINUE"

const VALUE_CARD = "(?!"*COMMENTARY_KEY*")(?="*VALUE_TOKEN*")(?<key>"*VALUE_KEY*") *= "
const CONTINUE_CARD = "(?<key>"*CONTINUE_KEY*")"*ASCII_CHARS*"{2}"
const COMMENT_CARD = "(?<key>"*COMMENT_KEY*")"*ASCII_CHARS*"{2}"

const END_IMAGE = "END"*repeat(' ', 77)

#  regex for a FITS standard compliant (FSC) keyword.
const KEY_FSC = Regex("^[A-Z0-9_-]{0," * string(KEYLENGTH) * "}\$")
const NON_KEY_TEXT = Regex("[^A-Z0-9_-]")
#  regex for the tokens of a HIERARCH keyword, which are separated by spaces and
#  contain only characters that are legal in a FITS keyword.
const HIERARCH_TOKENS = r"^[A-Z0-9_-]+(?: +[A-Z0-9_-]+)*$"

#  regex for FSC real number substring.
const DIGITS_FSC_STR_2 = "(?:\\.\\d+|\\d+(?:\\.\\d*)?)(?:[DE][+-]?\\d+)?"
#  regex for non-FSC (NFSC) real number substring.
#  (NFSC allows lower case of DE for exponent, space between sign,
#  digits, exponent sign, and exponents.)
const DIGITS_NFSC_STR = "(\\.\\d+|\\d+(\\.\\d*)?) *([deDE] *[+-]? *\\d+)?"
const NUMBER_NFSC_STR = "[+-]?" * DIGITS_NFSC_STR

const NUMBER_FSC_STR_2 = "[+-]?" * DIGITS_FSC_STR_2
const NUMBER_NFSC      = Regex("(?P<sign>[+-])? *0*?(?P<digt>" * DIGITS_NFSC_STR * ")")

#  use in cards having the CONTINUE convention which expects a string
#  followed by an optional comment.
const STRING_FIELD_STR = "\\'(?P<strg>([ -~]+?|\\'\\'|) *?)\\'(?=\$|/| )"
const COMMENT_FIELD_STR = "(?P<comm_field>(?P<sepr>/ *)(?P<comm>(.|\\n)*))"

#  FSC commentary card string which must contain printable ASCII
#  characters.
const ASCII_TEXT = Regex("[ -~]*\\Z")
const NON_ASCII_TEXT = Regex("[^ -~]")

#  check for a valid value & comment string. The value group returns a
#  match for a FITS string, boolean, number, and complex value,
#  otherwise it returns 'missing'. The comment field returns a match
#  when the comment separator is found, though the comment may be an
#  empty string.
#
#  The <strg> regex is not correct for all cases, but it comes pretty
#  darn close.  It appears to find the end of a string rather well,
#  but will accept strings with an odd number of single quotes,
#  instead of issuing an error.  The FITS standard appears vague on
#  this issue and only states that a string should not end with two
#  single quotes, whereas it should not end with an even number of
#  quotes to be precise.
#
#  Note that a non-greedy match is done for a string, since a greedy
#  match will find a single-quote after the comment separator
#  resulting in an incorrect match.
#  regex for a FSC real number substring that has a lower case exponent letter, which is
#  not allowed by the standard but is valid FORTRAN.
const NUMBER_LOWER_STR = "[+-]?(?:\\.\\d+|\\d+(?:\\.\\d*)?)(?:[DEde][+-]?\\d+)?"

#  regexes for a value field with the real numbers of a number regex.
value_fsc(number) = Regex(
	"^ *" *
	"(?:" *
	"(?<strg>'(?:[ -&(-~]|''|)*?(?<ampr>&)? *')(?=\$|/| )|" *
	"(?<bool>[FT])|" *
	"(?<numr>" * number * ")|" *
	"(?<cplx>\\( *(?<real>" * number * ") *, *(?<imag>" * number * ") *\\))|" *
	"(?<miss> *)" *
	") *" *
	"(?<slash>/)? *" *
	"(?<comment>[!-~][ -~]*?)?(?= *\$) *\$")

hierarch_fsc(number) = Regex(
	"^ *" *
	"(?<key>[A-Z0-9 _-]*?)" *
	" *(?<equal>=) *" *
	"(?:" *
	"(?<strg>'(?:[ -&(-~]|''|)*?')(?=\$|/| )|" *
	"(?<bool>[FT])|" *
	"(?<numr>" * number * ")|" *
	"(?<cplx>\\( *(?<real>" * number * ") *, *(?<imag>" * number * ") *\\))|" *
	"(?<miss> *)" *
	") *" *
	"(?<slash>/)? *" * "(?<comment>[!-~][ -~]*?)?(?= *\$) *\$")

const VALUE_FSC_2    = value_fsc(NUMBER_FSC_STR_2)
const VALUE_LOWER    = value_fsc(NUMBER_LOWER_STR)
const HIERARCH_FSC   = hierarch_fsc(NUMBER_FSC_STR_2)
const HIERARCH_LOWER = hierarch_fsc(NUMBER_LOWER_STR)

const VALUE_NFSC = Regex(
	"(?P<valu_field> *" *
	"(?P<valu>" * STRING_FIELD_STR * "|(?P<bool>[FT])|" *
	"(?P<numr>" * NUMBER_NFSC_STR * ")|(?P<cplx>\\( *" *
	"(?P<real>" * NUMBER_NFSC_STR * ") *, *(?P<imag>" * NUMBER_NFSC_STR * ") *\\)))? *)" *
	COMMENT_FIELD_STR * "?\$")

#  values must be right padded to 8 characters
const XTENSION_VALUES = ("BINTABLE", "IMAGE", "TABLE")

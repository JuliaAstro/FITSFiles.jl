# Cards

A FITS header is a list of 80-character *cards*, or keyword records. A [`Card`](@ref) holds the
parts of one card, the keyword, the value, the units, and the comment, and the layout that is
needed to write the card as it was read. This page describes the creation, the parsing, and the
modification of cards. The rules are those of the FITS Standard 4.0, Sect. 4, and of the ESO
HIERARCH convention.

The examples use the following definitions, where `show_` prints the 80-character image of a card
without the trailing spaces.

```@meta
DocTestSetup = quote
    using FITSFiles, Unitful
    import FITSFiles: setvalue!, join_cards
    show_(card) = println(rstrip(repr(card)))
end
```

## Creating a card

A card is created from a keyword, a value, and a comment, which are all optional.

```jldoctest cards
julia> card = Card("EXPTIME", 1200.0, "exposure time");

julia> show_(card)
EXPTIME =               1200.0 / exposure time

julia> card.key, card.value, card.units, card.comment
("EXPTIME", 1200.0, nothing, "exposure time")

julia> typeof(card)
Card{Value{Float64}}
```

The type of the card is the kind of the card, `Value`, `Hierarch`,
`Comment`, `History`, `Continue`, `End`, or `Invalid`, and
for a value the type of the value.

| Value                                             | Card                     |
|:--------------------------------------------------|:-------------------------|
| `missing`, or none                                | an undefined value       |
| `true`, `false`                                   | a logical                |
| `Integer`                                         | an integer               |
| `AbstractFloat`                                   | a real number            |
| `Complex` of integers or of floats                | a complex number         |
| `AbstractString`                                  | a string                 |

```jldoctest cards
julia> show_(Card("NAXIS", 2))
NAXIS   =                    2

julia> show_(Card("OBJECT", "NGC 1275", "target"))
OBJECT  = 'NGC 1275'           / target

julia> show_(Card("FLAG", true))
FLAG    =                    T

julia> show_(Card("Z", 1.5 + 2.5im))
Z       = (1.5, 2.5)

julia> show_(Card("EMPTY"))
EMPTY   =
```

Other values, e.g., a `Rational` or `Complex{Bool}`, are an `ArgumentError`, and a number that is
not finite is a `DomainError`, since the FITS Standard has no such values. The text of a string
and of a comment is the printable ASCII characters, 32 to 126.

A keyword is converted to upper case. A keyword with the characters `A`-`Z`, `0`-`9`, `-`, and `_`
and at most 8 characters is a regular keyword. A longer keyword is a [HIERARCH](#HIERARCH-keywords)
keyword.

## Keyword arguments

The keyword arguments of `Card` format the card. The word keyword also means the name of a card,
so a keyword argument is called a keyword here only if it is clear. The arguments are the layout
of the card, and the layout of a card that is parsed is read from the image.

| Keyword    | Default | Function                                                                                   |
|:-----------|:--------|:-------------------------------------------------------------------------------------------|
| `fixed`    | `true`  | Use the fixed format, where a number ends at byte 30 and a string begins at byte 11. The free format has the value anywhere after byte 10. The mandatory keywords are always in fixed format. See [Fixed and free format](#Fixed-and-free-format). |
| `slash`    | `32`    | The index, in bytes, of the comment separator `/`. A value that passes the index moves the separator and the comment to the right, and a separator at the end of the card has no comment, unless `truncate = false`, where the comment is continued at index 32. A number in fixed format ends at byte 30, so its separator is at byte 32 or later. |
| `lpad`     | `1`     | The least number of spaces between the value and the comment separator.                    |
| `rpad`     | `1`     | The number of spaces between the comment separator and the units or the comment.           |
| `upad`     | `1`     | The number of spaces between the units and the comment.                                    |
| `truncate` | `true`  | Truncate a comment that is longer than the space at the end of the card. If `false`, the comment of a string is continued on `CONTINUE` cards, and a comment of another value, and units, that do not fit are an `ArgumentError`. See [Long strings](#Long-strings). |
| `splitat`  | `' '`   | Split a long string and its comment after the last character `splitat` that fits, or at any character if `nothing`. See [Long strings](#Long-strings). |
| `append`   | `false` | Append an ampersand to the string, which marks that a `CONTINUE` card continues the string. A string that is too long for a card has the ampersand without the keyword. |
| `warn`     | `true`  | Warn when a keyword with more than 8 characters creates a [HIERARCH](#HIERARCH-keywords) card. |

```jldoctest cards
julia> show_(Card("KEY", 1, "comment"))
KEY     =                    1 / comment

julia> show_(Card("KEY", 1, "comment"; slash = 20, lpad = 0, rpad = 3))
KEY     =                    1/   comment

julia> show_(Card("KEY", 1, "comment"; fixed = false))
KEY     = 1                    / comment

julia> show_(Card("KEY", "abc", "comment"; append = true))
KEY     = 'abc&'               / comment
```

`setvalue!` has the same keyword arguments, except `warn`, and the default of a layout keyword
argument is the layout of the card, see [Changing the value](#Changing-the-value). The function
`parse` has the keywords `strict`, which allows a lower case exponent letter if `false`, and
`units`, which reads the units from the comment if `true`, see
[Parsing an image](#Parsing-an-image).

## Units

A `Quantity` is not a type of value. The units of a quantity are not part of the value, so a
`Quantity` that is given in place of a number is split into its number and its units, and the
type of the card is the type of the number, e.g., the type of a card with `1200.0u"s"` is
`Card{Value{Float64}}`. The units are read from the comment when a card is parsed, where the
units are in square brackets at the beginning of the comment (Sect. 4.3.2), and they are read in
the same way from the comment of a number that is given to `Card`: the unit string is removed
from the comment and is the units of the card, as if the number were a `Quantity`.

```jldoctest cards
julia> card = Card("EXPTIME", 1200.0u"s", "exposure time");

julia> show_(card)
EXPTIME =               1200.0 / [s] exposure time

julia> card.value, card.units
(1200.0, s)

julia> units(card)
s

julia> show_(Card("RATE", 3.5f0u"km/s", "velocity"))
RATE    =                  3.5 / [km s-1] velocity

julia> card = Card("RATE", 3.5f0, "[km/s] velocity"); card.units, card.comment
(km s⁻¹, "velocity")

julia> show_(card)
RATE    =                  3.5 / [km/s] velocity

julia> card = Card("RATE", 3.5f0, "[foo] velocity"); card.units, card.comment
(nothing, "[foo] velocity")
```

The style of the unit string of the comment is written again, e.g., `[km/s]`, and a `Quantity`
is written in the default style. The comment of a string or a logical, of a mandatory keyword,
and of a number with a `Quantity`, is not units, and text that is not a unit string or a scale
factor remains in the comment.

The units are written as the strings of the FITS Standard (Sect. 4.3), by `formunit`, and are
read by `parseunit`. All the units of Tables 3 and 4 of the Standard are read, with the prefixes of
Table 5 for the units that take them, e.g., `a`, the Julian year, `Ma`, `R`, the rayleigh, `mag`,
`D`, the debye, and `Sun`. A unit with a scale factor, e.g., `10**3 m`, or without a name in the
Standard, e.g., a function such as `log(Hz)`, remains in the comment. The units of a card are
not read if the keyword `units = false` is given to `parse`.

## Fixed and free format

The values of a card are in fixed format by default, where a number ends at byte 30 and a string
begins at byte 11. A number has at most 20 characters in fixed format, so a `Float64` that has
more characters is written with fewer digits of the mantissa. The free format has no such limit.

```jldoctest cards
julia> show_(Card("EXPTIME", 1200.0, "exposure time"; fixed = false))
EXPTIME = 1200.0               / exposure time

julia> show_(Card("DELTA", 1.2345678901234567e-100))
DELTA   = 1.2345678901234D-100

julia> show_(Card("DELTA", 1.2345678901234567e-100; fixed = false))
DELTA   = 1.2345678901234567D-100
```

The mandatory keywords `SIMPLE`, `XTENSION`, `BITPIX`, `NAXIS`, `NAXIS`*n*, `PCOUNT`, `GCOUNT`,
and `END` are always in fixed format and have no units.

The position of the comment is the keyword `slash`, the byte of the comment separator, which is
32 by default, and `lpad`, `rpad`, and `upad` are the numbers of spaces before and after the
separator and after the units. A comment that is longer than the space at the end of the card is
truncated, and the comment of the card is the truncated comment, unless `truncate = false`, which
is an `ArgumentError`.

```jldoctest cards
julia> show_(Card("EXPTIME", 1200.0, "exposure time"; slash = 40))
EXPTIME =               1200.0         / exposure time

julia> Card("A", 1, repeat("x", 100)).comment |> length
47

julia> Card("A", 1, repeat("x", 100); truncate = false)
ERROR: ArgumentError: Comment does not fit on the card.
[...]
```

## Commentary cards

A `COMMENT`, a `HISTORY`, and a blank keyword have no value indicator and only text.

```jldoctest cards
julia> show_(Card("COMMENT", "A comment"))
COMMENT A comment

julia> show_(Card("HISTORY", "processed"))
HISTORY processed

julia> card = Card("COMMENT", "A comment"); card.value
"A comment"
```

## HIERARCH keywords

A keyword that is longer than 8 characters is a HIERARCH keyword, where the tokens of the
keyword follow `HIERARCH`. A warning is given, unless `warn = false`. The key of the card is the
tokens.

```jldoctest cards
julia> card = Card("HIERARCH", "ESO TEL FOCU SCALE", 1.489, "(deg/m) Focus");

julia> show_(card)
HIERARCH ESO TEL FOCU SCALE = 1.489 / (deg/m) Focus

julia> card.key, typeof(card)
("ESO TEL FOCU SCALE", Card{Hierarch{Float64}})

julia> show_(Card("LONGKEYWORD", 1.5; warn = false))
HIERARCH LONGKEYWORD = 1.5
```

The tokens have the characters of a keyword, and a HIERARCH card is in free format. A card
without a value, e.g., `HIERARCH some text`, is commentary text.

## Long strings

A string of at most 68 characters, with the doubled single quotes, is on one card, and is not
split. A string that passes the comment separator moves the separator and the comment to the right,
and the comment is truncated if it does not fit on the card, unless `truncate = false`, where the
comment is continued on `CONTINUE` cards.

```jldoctest cards
julia> show_(Card("DATE-OBS", "2020-01-01T00:00:00.000", "observation date"))
DATE-OBS= '2020-01-01T00:00:00.000' / observation date

julia> card = Card("KEY", repeat("x", 60), "a comment that is truncated"); card.comment
"a com"

julia> cards = Card("KEY", repeat("x", 60), "a comment that is continued"; truncate = false);

julia> foreach(show_, cards)
KEY     = 'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx&' / a
CONTINUE  ''                   / comment that is continued
```

The spaces at the ends of a comment are not significant, so they are not part of the comment of a
card. The comments of the cards of a long string are joined by `join_cards` with a space, unless a
comment ends with a space.

A string that does not fit on one card is split into the cards of a long string, a card and
the `CONTINUE` cards (Sect. 4.2.1.2), which are returned as a vector. Every card but the last
ends with an ampersand. The string is split at the comment separator, or at the end of the card if
there is no comment. A string is split after the last space that fits, unless the keyword
`splitat = nothing` is given, where it is split at any character, or the keyword `splitat` is
another character.

```jldoctest cards
julia> cards = Card("LONGSTR", repeat("This is a long string value. ", 5), "comment");

julia> foreach(show_, cards)
LONGSTR = 'This is a long &'   / comment
CONTINUE  'string value. &'
CONTINUE  'This is a long &'
CONTINUE  'string value. &'
CONTINUE  'This is a long &'
CONTINUE  'string value. &'
CONTINUE  'This is a long &'
CONTINUE  'string value. &'
CONTINUE  'This is a long &'
CONTINUE  'string value. '
```

The comment is split in the same way. A list of cards is joined into the value of the card by
`join_cards`.

```jldoctest cards
julia> join_cards(cards).value
"This is a long string value. This is a long string value. This is a long string value. This is a long string value. This is a long string value. "
```

## Parsing an image

`parse(Card, image)` creates a card from an 80-character image. The type of the card follows the
image: a value, a HIERARCH keyword, commentary text, a CONTINUE card, an END card, or an invalid
record.

```jldoctest cards
julia> image = rpad("EXPTIME = 1200. / [s] exposure time in seconds", 80);

julia> card = parse(Card, image);

julia> card.key, card.value, card.units, card.comment
("EXPTIME", 1200.0f0, s, "exposure time in seconds")

julia> repr(card) == image
true

julia> typeof(parse(Card, rpad("COMMENT some text", 80)))
Card{Comment}

julia> typeof(parse(Card, rpad("END", 80)))
Card{End}
```

The type of a number is the smallest type that holds the number, and a floating-point number is
a `Float32` if it is exactly the shortest `Float32` of its text. An integer is an `Int64`, an
`Int128`, or a `BigInt`.

A record with a malformed value is an `Invalid` card, which keeps the text of the record
and is written as it was read. Only a record that is not a value, e.g., a keyword without the
value indicator `= ` in bytes 9 and 10, is commentary text.

```jldoctest cards
julia> card = parse(Card, rpad("KEY     = 1 2 3", 80));

julia> typeof(card), card.key
(Card{Invalid}, "KEY")

julia> typeof(parse(Card, rpad("HIERARCH ESO A = 1 2 3", 80)))
Card{Invalid}

julia> typeof(parse(Card, rpad("KEY=  1", 80)))
Card{Invalid}

julia> typeof(parse(Card, rpad("HIERARCH some text", 80)))
Card{Comment}
```

The Standard allows an upper case `E` or `D` for the exponent. A number with a lower case
letter is an invalid card, unless the keyword `strict = false` is given.

```jldoctest cards
julia> typeof(parse(Card, rpad("KEY     = 1.5e3", 80)))
Card{Invalid}

julia> card = parse(Card, rpad("KEY     = 1.5e3", 80); strict = false);

julia> card.value
1500.0f0

julia> show_(card)
KEY     = 1.5E3
```

A CONTINUE card continues a string only if the card before it is a string that ends with an
ampersand, so the card before it is given to `parse`. A CONTINUE card that does not continue a
string, and a CONTINUE record without spaces in bytes 9 and 10 or without a string, is commentary.

```jldoctest cards
julia> images = [rpad("LONGSTR = 'This is a long &' / comment", 80), rpad("CONTINUE  'string value.'", 80)];

julia> cards = Card{<:Any}[]; previous = nothing;

julia> for image in images
           card = parse(Card, image, previous)
           push!(cards, card)
           previous = card
       end

julia> typeof.(cards)
2-element Vector{DataType}:
 Card{Value{String}}
 Card{Continue}

julia> join_cards(cards).value
"This is a long string value."

julia> typeof(parse(Card, rpad("CONTINUE  'orphan'", 80), nothing))
Card{Comment}
```

## Reading and writing a card

A card is written as it was read, and the image of a parsed card is the image that was read,
including the format of the numbers, the position of the values, the units, and the comment. The
exceptions are those of the reading, where the value is not changed:

- a number without an integer digit has a zero, e.g., `.5` is `0.5`;
- an exponent has at least two digits, and a mantissa has one integer digit, e.g., `E+007` is
  `E+07` and `56.53E+13` is `5.653E+14`;
- the sign of an integer zero is lost;
- a number that is longer than before takes the spaces before the comment, but may move the
  comment, and the end of the comment of a full card is lost.

Trailing spaces of a string are not significant, and are restored in the written card.

## Changing the value

`setvalue!` returns the card with a new value, and the units, format, and comment of the card.
The new value may have another type. A number keeps the format of the old number, e.g., the
digits and the exponent letter, only if the number is written with that format without a loss
of digits. A number without units has the units of the card.

```jldoctest cards
julia> card = Card("EXPTIME", 1200.0, "exposure time");

julia> show_(setvalue!(card, 1500.0))
EXPTIME =               1500.0 / exposure time

julia> show_(setvalue!(card, 1500.0u"s"))
EXPTIME =               1500.0 / [s] exposure time

julia> show_(setvalue!(Card("N", 1, "c"), "text"))
N       = 'text'               / c

julia> card = parse(Card, rpad("KEY     = 1.50 / c", 80));

julia> show_(setvalue!(card, 2.5))
KEY     = 2.50 / c

julia> show_(setvalue!(card, 2.567))
KEY     = 2.567 / c
```

A string that does not fit is split into the cards of a long string, as by `Card`. The value of
a commentary card is a string or `missing`, and an END card has no value, otherwise an
`ArgumentError` is raised.

The keywords of `setvalue!` are the keywords of `Card` that format the card, and the default of
a layout keyword is the layout of the card, so the new card is formatted as the card was.

| Keyword                 | Default                                                                  |
|:------------------------|:-------------------------------------------------------------------------|
| `fixed`                 | the format of the card, fixed or free                                    |
| `slash`                 | the index of the comment separator of the card, and for the cards of a long string the index 32 or more |
| `lpad`                  | 0 if the separator follows the value of the card directly, otherwise 1   |
| `rpad`                  | the number of spaces after the separator of the card, or 1               |
| `upad`                  | the number of spaces after the units of the card, or 1                   |
| `append`                | `false`                                                                  |
| `truncate`              | `true`, as in `Card`                                                     |
| `splitat`               | `' '`, as in `Card`                                                      |

A keyword formats the card again, even if the value is the same, and a keyword creates the same
card as the constructor of a card with the keyword.

```jldoctest cards
julia> card = parse(Card, rpad("KEY     = 1.5/ c", 80));

julia> show_(setvalue!(card, 2.5))
KEY     = 2.5/ c

julia> show_(setvalue!(card, 2.5; lpad = 3))
KEY     = 2.5   / c

julia> show_(setvalue!(card, 2.5; slash = 20))
KEY     = 2.5      / c

julia> show_(setvalue!(card, 2.5; fixed = true))
KEY     =                  2.5/ c
```

A list of cards in a header is changed by `setvalue!(cards, key,
value)` and by `cards[key] = value`, which also replace the CONTINUE cards of the old value.

## A list of cards

A header is a vector of cards, and the cards with a keyword are found by the keyword, without regard
to the case.

```jldoctest cards
julia> cards = Card{<:Any}[Card("BITPIX", 16), Card("BZERO", 1.5), Card("OBJECT", "NGC 1275"),
                           Card("HISTORY", "first step"), Card("HISTORY", "second step")];

julia> cards["bitpix"], get(cards, "NOPE", 0), haskey(cards, "OBJECT")
(16, 0, true)

julia> get(cards, ["BITPIX", "BZERO", "NOPE"], [0, 0, "default"])
(16, 1.5, "default")

julia> FITSFiles.getall(cards, "HISTORY")
2-element Vector{String}:
 "first step"
 "second step"

julia> findall("HISTORY", cards)
2-element Vector{Int64}:
 4
 5
```

The value of a card is the first card with the keyword, for `getindex`, `get`, and `haskey`, and
`findfirst` is the index of the first card. With a list of keys, `get` is the tuple of the values of
the first cards, where the types of the values are the types of the cards and not of the defaults.
`findall` and `getall` are the indexes and the values of all the cards with a keyword, e.g., the
`COMMENT` and `HISTORY` cards. The value of a continued string is the joined string, and
`setvalue!(cards, key, value)` replaces the card and the `CONTINUE` cards of the old string.

## Comparing and copying

Two cards are equal if their images are equal, so a card is equal to the card that is parsed
from its image, and equal cards have the same hash. A copy has its own format, so the copy can
be changed without changing the card.

```jldoctest cards
julia> a, b = Card("A", 1, "c"), Card("A", 1, "c");

julia> a == b, hash(a) == hash(b), copy(a) == a, copy(a) === a
(true, true, true, false)

julia> parse(Card, repr(a)) == a
true
```

A card is a scalar in a broadcast, e.g., `cards .== a`.

## Errors

| Error                                         | Cause                                                              |
|:----------------------------------------------|:-------------------------------------------------------------------|
| `ArgumentError`                               | a keyword, a string, or a comment with characters that are not allowed |
| `ArgumentError`                               | a value of a type that cannot be written                           |
| `ArgumentError`                               | a string value for a number, or a value that is not a string for a commentary or CONTINUE card |
| `ArgumentError`                               | a comment, units, or a HIERARCH keyword and value that do not fit on the card |
| `DomainError`                                 | a number that is not finite                                        |

Reading an image never raises an error. A record that is not valid is an `Invalid` card.

```@meta
DocTestSetup = nothing
```

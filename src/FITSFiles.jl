"""
FITSFiles.jl is a Julia implementation of the Flexible Image Transport System (FITS) file
format.

FITS files are composed of a vector of header-data units (HDUs), where an HDU is a header, which
is a vector of cards, followed by data.

- [`fits`](@ref) is the most common function for reading a file, and `write` writes it.
- [`HDU`](@ref) creates a header-data unit.
- [`Card`](@ref) creates, and `parse` reads, a card of a header.
"""
module FITSFiles

export Comment, Continue, End, Hierarch, History
export Invalid, Value
export Primary, Conform, Random, Image, Table, Bintable, ZImage, ZTable
export IUEImage, A3DTable, Foreign, Dump
export Card, HDU, fits
export info, units

using Printf, Unitful, UnitfulAngles, UnitfulAstro, UnitfulAtomic

#  V0.1   Implement Card type. Card only handles syntax, i.e., parsing and
#         writing, including HIERARCH cards.
#  V0.2   Implement HDU type. HDU handles value access and IO, including
#         joining and splitting long cards, mandatory and reserved keywords.
#         Standard extensions: Conform, Image, Table, Bintable, and Random
#         Groups.
#  V0.3   Implement lazy array
#  V0.4   Implement compression
#  V0.5   Implement units, including date and time
#  V0.6   Implement verification
#  V0.7   Implement World-coordinate system
#  V0.8   Implement checksums
#  V0.9   Implement Conforming extensions
#  V0.10  Implement optimizations
#  V1.0   Verify implementation meets current standard

include("card.jl")
include("field.jl")
include("format.jl")
include("lazyarray.jl")
include("units.jl")
include("hdu.jl")
include("hdu/primary.jl")
include("hdu/conform.jl")
include("hdu/random.jl")
include("hdu/image.jl")
include("hdu/table.jl")
include("hdu/bintable.jl")
include("hdu/zimage.jl")
include("hdu/ztable.jl")
include("fitscore.jl")

end

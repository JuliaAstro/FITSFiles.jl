"""
FITSFiles.jl is a Julia implementation of the Flexible Image Transport System (FITS) file
format.

FITS files are composed of an array of header-data units (HDUs).

* fits: is the most common function for reading a file.
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
#  V0.5   Implement units, inluding date and time
#  V0.6   Implement verification
#  V0.7   Implement World-coordinate system
#  V0.8   Implement checksums
#  V0.9   Implement Conforming extensions
#  V0.10  Implement optimizations
#  V1.11  Verify implementation meets current standard

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

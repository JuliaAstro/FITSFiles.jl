# FITSFiles.jl

`FITSFiles.jl` is a Julia implementation of the Flexible Image Transport System (FITS) file IO standard.

A FITS file is a vector of header-data units (HDUs), where the header of an HDU is a vector of
[cards](cards.md), and `fits` reads the file.

```@autodocs
Modules = [FITSFiles]
Pages = ["FITSFiles.jl", "fitscore.jl", "hdu.jl", "format.jl", "lazyarray.jl", "field.jl",
         "hdu/primary.jl", "hdu/conform.jl", "hdu/random.jl", "hdu/image.jl", "hdu/table.jl",
         "hdu/bintable.jl", "hdu/zimage.jl", "hdu/ztable.jl", "card/types.jl", "card/numbers.jl",
         "card/constructor.jl", "card/values.jl", "card/parse.jl", "units.jl"]
```

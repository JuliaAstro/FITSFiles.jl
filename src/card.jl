#  The type without its parameters, e.g., Vector{Int} is Array
basetype(T) = Base.typename(T).wrapper

include("card/syntax.jl")
include("card/types.jl")
include("card/numbers.jl")
include("card/constructor.jl")
include("card/values.jl")
include("card/layout.jl")
include("card/write.jl")
include("card/parse.jl")

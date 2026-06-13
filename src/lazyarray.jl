####    LazyArray    ####

"""
    LazyArray(filnam, mtime, begpos, format, fields, keywds)

    Lazy array file descriptor
"""
struct LazyArray
    "File name"
    filnam::String
    "Modification time"
    mtime::Float64
    "Beginning file position"
    begpos::Int64
    "Array format"
    format::DataFormat
    "Field formats"
    fields::Union{AbstractField, AbstractVector{<:AbstractField}}
    "HDU keywords"
    keywds::NamedTuple
end

####    DataFormat    ###

"""
    DataFormat(type, leng, shape, param, group, heap)

The generic data format descriptor for HDUs.
"""
struct DataFormat
    "The type of the array element."
    type::Type
    "The number of elements."
    leng::Integer
    "The shape of the array."
    shape::Tuple
    "The number of parameters."
    param::Integer
    "The number of groups."
    group::Integer
    "The offset of the heap in bytes."
    heap::Integer
end

# Springer books for the quarantine

Two functions are exported by this package (see [example.jl](./example.jl)):

1. The list of currently free books can be downloaded for subsetting:
This function returns a DataFrame of the list.

```julia
path = pwd()
bl = getbooklist(path, name = "booklist.xlsx")
```

2. The books are downloaded based on the booklist:

```julia
loadbooks(path, bl[1:3, :])
```

### Example

This example will download the first three Mathematics books:

```julia
using SpringerQuarantineBooks
using DataFrames

path = "/home/daniel/Documents/books"
booklist = getbooklist(path, name = "booklist.xlsx")

mathbooks = filter(row -> occursin(r".*Mathematics.*", row[Symbol("English Package Name")]),booklist)

loadbooks(path, mathbooks[1:3, :])
```
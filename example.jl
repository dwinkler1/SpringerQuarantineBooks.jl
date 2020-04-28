import Pkg; Pkg.activate(".")
include("src/SpringerQuaratineBooks.jl")
using .SpringerQuarantineBooks
using DataFrames

path = "/home/daniel/Documents/books"
booklist = getbooklist(path, name = "booklist.xlsx")

mathbooks = filter(row -> occursin(r".*Mathematics.*", row[Symbol("English Package Name")]),booklist)

loadbooks(path, mathbooks[1:3, :])

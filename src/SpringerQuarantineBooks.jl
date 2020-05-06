module SpringerQuarantineBooks

    import HTTP
    import XLSX
    import DataFrames
    import ProgressMeter

    export getbooklist,
            loadbooks

    function makepath(a, b)
        if(a[end] == '/' || b[1] == '/')
            out = a * b
        else
            out = a * '/' * b
        end
    end

    function getbooklist(path = pwd(); name = "booklist.xlsx")
        fname = makepath(path, name)
        if(!isfile(fname))
            bookurl = "https://resource-cms.springernature.com/springer-cms/rest/v1/content/17858272/data/"
            req = HTTP.get(bookurl)
            open(fname, "w") do io
                write(io, req.body)
            end
        end
        file = XLSX.readxlsx(fname)
        sheetname = XLSX.sheetnames(file)[1]
        table = file[sheetname][:]

        df = DataFrames.DataFrame(table[2:end,:])
        DataFrames.rename!(df, names(df) .=> Symbol.(table[1,:]))
        return df
    end

    function loadbooks(path = pwd(), booklist = getbooklist(path); format = "pdf", fixnames = true, verbose = true, printerrors = (lowercase(format) == "pdf"))
        format = lowercase(format)
        @assert format ∈ ["pdf", "epub"] """ Valid formats are "pdf" and "epub" """
        fixednames = replace.(string.(names(booklist)), r"\s" => "_")
        bl = DataFrames.rename(booklist, names(booklist) .=> Symbol.(fixednames))
        subjects = unique(bl.English_Package_Name)

        fixnames && (fixer = r"[,\s/:]+")

        if format == "pdf"
            baseurl = "https://link.springer.com/content/pdf"
        elseif format == "epub"
            baseurl = "https://link.springer.com/download/epub"
        end

        verbose && (progress = ProgressMeter.Progress(size(bl, 1); desc = "Downloading"))

        for i in eachrow(bl)
            url = i.OpenURL
            if(fixnames)
                folder = replace(strip(i.English_Package_Name), fixer => "_")
                book = replace(strip(i.Book_Title), fixer => "_")
                isbn = replace(strip(i.Electronic_ISBN), fixer => "_")
            else
                folder = replace(i.English_Package_Name, r"[/:]+" => "_")
                book = replace(i.Book_Title, r"[/:]+" => "_")
                isbn = replace(i.Electronic_ISBN, r"[/:]+" => "_")
            end
            isdir(makepath(path, folder)) || mkdir(makepath(path, folder))
            fname = folder * '/' * book * '_' * isbn * '.' * format
            isfile(fname) && continue

            try
                res = HTTP.get(url)
                dlurl = replace(res.request.target, r"\%2F|/book/" => '/') * '.' * format
                book = HTTP.get(baseurl * dlurl)
                open(makepath(path, fname), "w") do io
                    write(io, book.body)
                end
                verbose && ProgressMeter.next!(progress; showvalues = [(Symbol("Book name"), i.Book_Title), (:Folder, i.English_Package_Name)])
            catch e
                printerrors && println("Error: ", e, " when loading: ", url)
            end
        end
    end
end # module

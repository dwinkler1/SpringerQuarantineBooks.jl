module SpringerQuarantineBooks

    import HTTP 
    import XLSX
    import DataFrames

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
            bookurl = "https://resource-cms.springernature.com/springer-cms/rest/v1/content/17858272/data/v4/"
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

    function loadbooks(path = pwd(), booklist = getbooklist(path); fixnames = true, verbose = true)
        fixednames = replace.(string.(names(booklist)), r"\s" => "_")
        bl = DataFrames.rename(booklist, names(booklist) .=> Symbol.(fixednames))
        subjects = unique(bl.English_Package_Name)
        if(fixnames)
            fixer = r"[,\s/:]+"
            subjects = replace.(subjects, fixer => "_")
        end
        
        for subject in subjects
            isdir(makepath(path, subject)) || mkdir(makepath(path, subject))
        end

        baseurl = "https://link.springer.com/content/pdf"
        for i in eachrow(bl)
            url = i.OpenURL
            if(fixnames)
                folder = replace(i.English_Package_Name, fixer => "_")
                book = replace(i.Book_Title, fixer => "_")
            else
                folder = replace(i.English_Package_Name, r"[/:]+" => "_") 
                book = replace(i.Book_Title, r"[/:]+" => "_")
            end

            fname = folder * '/' * book * ".pdf"
            isfile(fname) && continue
            
            try
                res = HTTP.get(url)
                dlurl = replace(res.request.target, r"\%2F|/book/" => '/') * ".pdf"
                open(makepath(path, fname), "w") do io
                    book = HTTP.request("GET", baseurl * dlurl)
                    write(io, book.body)
                end
                verbose && println("Loaded: ", fname)
            catch e
                println("Error: ", e, "when loading", url)
            end
        end
    end
end # module

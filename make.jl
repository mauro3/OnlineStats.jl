module MakeOnlineStatsDocs
reload("OnlineStats")
using OnlineStats

rootdir = Pkg.dir("OnlineStats")

#-------------------------------------------------------------------# Generate fit.md
fit = rootdir * "/doc/fit.md"
rm(fit)
touch(fit)
file = open(fit, "r+")
write(file, "<!--- Generated at " * string(now()) * ".  Don't edit --->\n")
write(file, "# Update Methods\n\n")
meth = methods(OnlineStats.fit!)
ms = map(string, collect(meth))  # get Vector of strings of methods
for m in ms
    write(file, "- ")
    write(file, replace(m, "OnlineStats.", ""))
    write(file, "\n")
end
close(file)

#-------------------------------------------------------------------# Generate api.md
api = rootdir * "/doc/api.md"
rm(api)
touch(api)
file = open(api, "r+")
write(file, "<!--- Generated at " * string(now()) * ".  Don't edit --->\n")
write(file, "# API\n\n")
info("The following items are included in the output file:\n")
nms = setdiff(names(OnlineStats), [:OnlineStats])  # Vector{Symbol} of names
for nm in nms
    @eval obj = OnlineStats.$nm
    d = Docs.doc(obj)
    if d != nothing
        println(nm)
        write(file, "## " * string(nm) * "\n" * Markdown.plain(d) * "\n")
    end
end
close(file)

#-------------------------------------------------------------# push site to gh-pages
cd(rootdir)
run(`mkdocs gh-deploy --clean`)
end  # MakeOnlineStatsDocs


function pretty_pq(v, maxchar)
    if isempty(v)
        res = "{}"
    else
        res = replace(string(v), "[", "{")
        res = replace(res, "]", "}")
    end
    res = replace(res, r"\"|String", "")
    n = length(res)
    out = ""
    str = 1
    stp = maxchar
    keep_splitting = true
    while keep_splitting
        if stp < n
            # this regex finds the last comma
            offset = match(r",[^,]*$", res[str:stp]).offset
            stp = str + offset - 1
        else
            stp = n
            keep_splitting = false
        end
        out = string(out, res[str:stp], "\n")
        str = stp + 1
        stp = str + maxchar - 1
        stp = stp > n ? n : stp
    end
    return out
end

v = ["this", "is", "my", "vector", "which", "contains", "a", "number", "of", "variable-length", "terms", "such", "as", "these."]
println(pretty_pq(v, 25))

function prettyprint_rulestats(r::Rule, plen, qlen)
    p = pretty_pq(r.p)
    q = pretty_pq(r.q)
    println(rpad(p, plen, " "), " => ", rpad(q, qlen, " "), " $(r.supp) $(r.conf) $(r.lift)", )
end


function show_rulestats(rs::Vector{Rule})
    n = length(rs)

    maxlen_p = maximum(map(x -> length(pretty_pq(x.p)), rs))
    maxlen_q = maximum(map(x -> length(pretty_pq(x.q)), rs))
    for i = 1:n
        prettyprint_rulestats(rs[i], maxlen_p, maxlen_q, T)
    end
end

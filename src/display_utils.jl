# using Formatting

function wrap_line(v, maxchar)
    if isempty(v)
        res = "{}"
    else
        res = replace(string(v), "[", "{")
        res = replace(res, "]", "}")
    end
    res = replace(res, r"\"|String|Any", "")
    n = length(res)
    out = ""
    str = 1
    stp = maxchar
    if n > maxchar
        keep_splitting = true
        iter = 1

        while keep_splitting
            if stp < n
                # this regex finds the last comma
                offset = match(r",[^,]*$", res[str:stp]).offset
                stp = str + offset - 1
            else
                stp = n
                keep_splitting = false
            end
            if iter == 1
                out = string(out, res[str:stp])
            else
                out = string("\n", out, res[str:stp])
            end
            str = stp + 1
            stp = str + maxchar - 1
            stp = stp > n ? n : stp
            iter += 1
        end
    elseif n ≤ maxchar
        out = res
    end

    return out
end

# v = ["this", "is", "my", "vector", "which", "contains", "a", "number", "of", "variable-length", "terms", "such", "as", "these."]
# w = collect(1:100)
# println(wrap_line(v, 25))
# println(wrap_line(w, 25))
#


function prettyprint_rulestats(r::Rule, plen, qlen)
    p = wrap_line(r.p, 25)
    q = wrap_line(r.q, 25)
    fmt = "%0.4f"

    println(rpad(p, plen, " "), " => ", rpad(q, qlen, " "), " $(sprintf1(fmt, r.supp)) $(sprintf1(fmt, r.conf)) $(sprintf1(fmt, r.lift))", )
end

# prettyprint_rulestats(rules[1], 10, 10)

function show_rulestats(rs::Vector{Rule})
    n = length(rs)

    maxlen_p = maximum(map(x -> length(wrap_line(x.p, 25)), rs))
    maxlen_q = maximum(map(x -> length(wrap_line(x.q, 25)), rs))
    println(rpad("lhs", maxlen_p, " "), "    ", rpad("rhs", maxlen_q, " "), " supp.  conf.  lift")
    for i = 1:n
        prettyprint_rulestats(rs[i], maxlen_p, maxlen_q)
    end
end

# show_rulestats(rules)

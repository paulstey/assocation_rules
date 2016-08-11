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

        while keep_splitting
            if stp < n
                # this regex finds the last comma
                chk = match(r",[^,]*$", res[str:stp])

                # In cases where we have single elements longer than
                # maxchar, `offset` will be of type Void.
                if isa(chk, RegexMatch)
                    offset = chk.offset
                elseif isa(chk, Void)
                    offset = maxchar
                end

                stp = str + offset - 1
            else
                stp = n
                keep_splitting = false
            end
            if keep_splitting
                out = string(out, res[str:stp], "\n")
            else
                n_char = maxchar - (stp - str) - 1
                padding = rpad(" ", n_char, " ")
                out = string(out, res[str:stp], padding)
            end
            str = stp + 1
            stp = str + maxchar - 1
            stp = stp > n ? n : stp
        end
    elseif n ≤ maxchar
        out = res
    end

    return out
end

# v = ["this", "is", "my", "vector", "which", "contains", "a", "number", "of", "variable-length", "terms", "such", "as", "these."]
# println(wrap_line(v, 25))
#


function prettyprint_rulestats(r::Rule, plen, qlen, colwidth)
    p = wrap_line(r.p, colwidth)
    q = wrap_line(r.q, colwidth)
    fmt = "%0.4f"

    # if plen < colwidth
        arrow = " => "
    # else
    #     arrow = lpad(" => ", colwidth, " ")
    # end

    println(rpad(p, plen, " "), arrow, rpad(q, qlen, " "), " $(sprintf1(fmt, r.supp)) $(sprintf1(fmt, r.conf)) $(sprintf1(fmt, r.lift))", )
end

# prettyprint_rulestats(rules[1], 10, 10)

function show_rulestats(rs::Vector{Rule}, colwidth = 25)
    n = length(rs)

    maxlen_p = maximum(map(x -> length(wrap_line(x.p, colwidth)), rs))
    maxlen_q = maximum(map(x -> length(wrap_line(x.q, colwidth)), rs))

    # When column width greater than the max string length,
    # we use colwidth as the width of our columns.
    maxlen_p = maxlen_p < colwidth ? maxlen_p : colwidth
    maxlen_q = maxlen_q < colwidth ? maxlen_q : colwidth

    println(rpad("lhs", maxlen_p, " "), "    ", rpad("rhs", maxlen_q, " "), " supp.  conf.  lift")
    for i = 1:n
        prettyprint_rulestats(rs[i], maxlen_p, maxlen_q, colwidth)
    end
end

# show_rulestats(rules)

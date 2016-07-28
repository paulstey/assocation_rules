
function pretty_pq(v)
    if isempty(v)
        res = "{}"
    else
        v1 = replace(string(v), "[", "{")
        res = replace(string(v1), "]", "}")
    end
    return res
end


function prettyprint_rulestats(r::Rule, plen, qlen, T)
    p = pretty_pq(r.p)
    q = pretty_pq(r.q)
    println(rpad(p, plen, " "), " => ", rpad(q, qlen, " "), " $(supp(r.p, r.q, T)) $(conf(r.p, r.q, T))", )
end


function show_rulestats(rs::Vector{Rule}, T)
    n = length(rs)
    maxlen_p = maximum(map(x -> length(pretty_pq(x.p)), rs))
    maxlen_q = maximum(map(x -> length(pretty_pq(x.q)), rs))
    for i = 1:n
        prettyprint_rulestats(rs[i], maxlen_p, maxlen_q, T)
    end
end

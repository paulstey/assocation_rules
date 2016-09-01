
import Base.display
import Base.isempty
import Base.==
import Base.unique

isempty(x::IDList) = isempty(x.sids)

function allempty(x::Array{IDList, 1})
    res = true
    for i = 1:length(x)
        if !isempty(x[i])
            res = false
            break
        end
    end
    return res
end

# This is needed for the in() function
# to work in our unique() function
function ==(x::IDList, y::IDList)
    res = x.pattern == y.pattern &&
          x.sids == y.sids &&
          x.eids == y.eids &&
          x.elems == y.elems &&
          x.typ == y.typ &&
          x.supp == y.supp
    return res
end


function unique(v::Array{IDList, 1})
    out = Array{IDList, 1}(0)
    for i = 1:length(v)
        if !in(v[i], out)
            push!(out, v[i])
        end
    end
    return out
end


# function display(x::IDList)
#     if isempty(x)
#         println("$(x.pattern) has support 0")
#     else
#         last = x.sids[end]
#         nchar = 2 + length(string(last))
#
#         println("$(x.pattern)")
#         for i = 1:length(x.sids)
#             println(rpad(x.sids[i], nchar, " "), x.eids[i])
#         end
#     end
# end

# function display(x::Array{IDList,1})
#     for i = 1:length(x)
#         display(x[i])
#         println("\n")
#     end
# end

# Behaves a bit like Python's str.rfind() method, gets
# the indices of where the `needle` appears in the `haystack`.
# Returns 0:-1 if `needle` is not found.
function rfind(haystack, needle::String)
    n = length(haystack)
    nchar = length(needle)
    window = nchar - 1
    start_idx = 0
    stop_idx = -1
    for i = (n - window):-1:1
        if haystack[i:i+window] == needle
            start_idx = i
            stop_idx = i+window
            break
        end
    end
    return UnitRange{Int}(start_idx, stop_idx)
end


function rfind(haystack, needle::Char)
    found_indcs = find(x -> x == needle, collect(haystack))
    if isempty(found_indcs)
        last_idx = -1
    else
        last_idx = maximum(found_indcs)
    end
    return last_idx
end



function unique_items(s::Sequence)
    d = Dict{String, Int64}()
    for i = 1:length(s.items)
        for k in s.items[i]
            d[k] = get(d, k, 0) + 1
        end
    end
    return collect(keys(d))
end

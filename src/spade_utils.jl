
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



"""
This function behaves a bit like Python's str.rfind()
method; it gets the indices where the `needle` appears
in the `haystack`. Returns 0:-1 if `needle` is not found.
"""
function rfind{T::String}(haystack::T, needle::T)
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

function rfind(haystack::String, needle::Char)
    last_idx = findlast(haystack, needle)
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



"""
Given a data set, `dat`, in long format, this function extracts all
the sequences and returns an array of `Sequence` objects.
"""
function make_sequences(dat::Array{Any, 2}, sid_col, eid_col, item_col)
    seq_ids = unique(dat[:, sid_col])
    num_seqs = length(seq_ids)
    seq_arr = Array{Sequence, 1}(num_seqs)

    for (i, sid) in enumerate(seq_ids)
        row_indcs = find(dat[:, sid_col] .== sid)

        dat_subset = dat[row_indcs, :]
        event_ids = unique(dat[row_indcs, eid_col])
        items = Array{Array{String, 1}, 1}(0)


        for eid in event_ids

            indcs = find(eid .== dat_subset[:, eid_col])
            items_arr = convert(Array{String, 1}, dat_subset[indcs, item_col])
            println(sid, " ", eid, " ", items_arr)

            push!(items, items_arr)

        end
        seq_arr[i] = Sequence(sid, event_ids, items)
    end
    return seq_arr
end

d = readcsv("./data/zaki_data.csv", skipstart = 1)

seq_array = make_sequences(d, 2, 3, 1)

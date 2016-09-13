
# This is needed for the in() function
# to work in our unique() function

# original version: spade.jl

# function ==(x::IDList, y::IDList)
#     res = x.pattern == y.pattern &&
#           x.sids == y.sids &&
#           x.eids == y.eids &&
#         #   x.elems == y.elems &&
#           x.typ == y.typ &&
#           x.supp == y.supp
#     return res
# end


# used for alternative version: spade_alt.jl

function ==(x::IDList, y::IDList)
    res = x.sids == y.sids &&
          x.eids == y.eids &&
          x.patrn == y.patrn &&
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
function rfind(haystack::String, needle::String)
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



function sanitize_items(items, excluded_strings)
    res = items
    n = length(res)
    for i = 1:n
        for s in excluded_strings
            res[i] = replace(res[i], s, " ")
        end
    end
    return res
end

# these two find() functions are just for dev purposes
# to track down cases where we disagree with R
function find(x::Array{IDList, 1}, patrn::String)
    indcs = Array{Int, 1}(0)
    n = length(x)

    for i = 1:n
        if x[i].pattern == patrn
            push!(indcs, i)
        end
    end
    return indcs
end


function find(x::Array{IDList, 1}, patrn::Array{Array{String, 1}, 1})
    indcs = Array{Int, 1}(0)
    n = length(x)

    for i = 1:n
        if x[i].patrn == patrn
            push!(indcs, i)
        end
    end
    return indcs
end



"""
Given a data set, `dat`, in long format, this function extracts all
the sequences and returns an array of `Sequence` objects.
"""
function make_sequences(dat::Array{Any, 2}, sid_col, eid_col, item_col, excluded_strings = ["=>", ","])
    seq_ids = unique(dat[:, sid_col])
    num_seqs = length(seq_ids)
    seq_arr = Array{Sequence, 1}(num_seqs)

    dat[:, item_col] = sanitize_items(dat[:, item_col], excluded_strings)

    for (i, sid) in enumerate(seq_ids)
        row_indcs = find(dat[:, sid_col] .== sid)

        dat_subset = dat[row_indcs, :]
        event_ids = unique(dat[row_indcs, eid_col])
        items = Array{Array{String, 1}, 1}(0)


        for eid in event_ids

            indcs = find(eid .== dat_subset[:, eid_col])
            items_arr = convert(Array{String, 1}, dat_subset[indcs, item_col])
            push!(items, sort(items_arr))

        end
        seq_arr[i] = Sequence(sid, event_ids, items)
    end
    return seq_arr
end

# d = readcsv("./data/zaki_data.csv", skipstart = 1)
#
# seq_array = make_sequences(d, 2, 3, 1)



# Given a vector of strings, this function returns
# a single string with all elements of the vector
# having been concatenated.
function join_strings(x::Array{String, 1})
    n = length(x)
    s = ""
    for i = 1:n
        if i < n
            s *= string(x[i], ",")
        elseif i == n
            s *= x[i]
        end
    end
    return s
end



# Given the pattern from an IDList, this function returns
# a string illustrating the temporal relation of the
# seqeunce. For example: "{A} -> {B,C} -> {D}".
function pattern_string(x::Array{Array{String, 1}, 1})
    n = length(x)
    s = ""
    for i = 1:n
        if i < n
            s *= string("{", join_strings(x[i]), "} -> ")
        elseif i == n
            s *= string("{", join_strings(x[i]), "}")
        end
    end
    return s
end


function count_patterns(F::Array{Array{IDList, 1}, 1})
    m = length(F)
    cnt = Dict{String, Int}()
    for k = 1:m
        n = length(F[k]) 
        for i = 1:n
            cnt[pattern_string(F[k][i].patrn)] = F[k][i].supp_cnt
        end
    end
    cnt
end

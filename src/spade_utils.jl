
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



function sanitize_items(items, excluded_strings = ["{", "}", "->"])
    res = items
    n = length(res)
    for i = 1:n
        for s in excluded_strings
            res[i] = replace(res[i], s, " ")
        end
    end
    return res
end

# itms1 = ["this -> is a {string}", "and {so} is -> {} this"]
# sanitize_items(itms1)


# These two find() functions are just for dev purposes
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

# join_strings(["ab", "cd"])



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

function pattern_string(args...)
    n = length(args)
    s = ""
    for i = 1:n
        if i < n
            s *= string("{", join_strings(args[i]), "} -> ")
        elseif i == n
            s *= string("{", join_strings(args[i]), "}")
        end
    end
    return s
end

# pattern_string(["ab", "cd"], ["de", "fg"])


# This is our workhorse used in the nloops_gen(), which
# is a function that generates n nested loops.
function addpattern!(v, args...)
    s = pattern_string(args...)
    push!(v, s)
end



# This function gets the counts for each pattern
# we have in our frequent-pattern set.

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



function gen_combos(x::Array{Array{String,1},1})
    allcombos = Array{Array{Array{String,1},1},1}(0)

    n = length(x)
    for i = 1:n
        combos = collect(combinations(x[i]))
        push!(allcombos, combos)
    end
    allcombos
end




function subset_pattern(x::Array{Array{Array{String, 1}, 1}, 1})
    out = String[]
    for c1 in x[1]
        for c2 in x[2]
            push!(out, string(join_strings(c1), " -> ", join_strings(c2)))
        end
    end
    out
end

# combins = gen_combos(res[6][13].patrn)
# subset_pattern(combins)




function one_set_left(s)
    idx = search(s, '{')
    if search(s[(idx+1):end], '{') == 0
        res = true
    else
        res = false
    end
    res
end



# Given a string containing a pattern of the
# form "{A} -> {B,C} -> {} -> {D,E,F} -> {}",
# this function removes all empty sets `{}`, and
# would return "{A} -> {B,C} -> {D,E,F}"
function remove_empties(s::String)
    n = length(s)
    persist = true

    while persist
        rng = rfind(s, "{}")
        if rng == 0:-1
            persist = false
        elseif rng ≠ 0:-1

            # `{}` found at end of string
            if rng[end] == n
                s = s[1:(rng[1] - 5)]
            # `{}` found in middle of string
            elseif rng[end] ≠ n
                s = s[1:(rng[1] - 1)] * s[(rng[end]+5):end]
            # `{}` found at beginning of string
            elseif rng[1] == 1
                s = s[(rng[end]+5):end]
            end
        end
        n = length(s)
        if n == 0
            return ""
        end
    end

    if one_set_left(s)
        idx1 = search(s, '{')
        idx2 = search(s, '}')

        s = s[idx1:idx2]
    end
    s
end
#
s1 = "{A} -> {B,C} -> {} -> {D,E,F} -> {}"
remove_empties(s1)


# Given a frequent pattern (from and IDList), this function returns
# all the sub-patterns that can be generated that preserve the order.
# For example, we can generate the sub-pattern {A} -> {B} (and
# many others) from the original pattern {A,C} -> {B,D} -> {F,E}.

function gen_combin_subpatterns(patrn)
    global combinations_arrays = gen_combos(patrn)

    # Here we add vectors with empty strings b/c for each
    # timepoint set, x1, where x1 = {...}, we want to consider
    # combinations in which no element is drawn from x1.
    for i = 1:length(combinations_arrays)
        push!(combinations_arrays[i], String[""])
    end
    out = String[]

    function fill_pattern_array!()
        vars = Symbol[]
        inner = :(addpattern!($out))
        outer = inner
        n = length(combinations_arrays)

        for dim = 1:n
            var = Symbol("c$dim")
            push!(vars, var)
            push!(inner.args, var)
            outer = :(
                for $var in combinations_arrays[$dim]
                    $outer
                end
            )
            # println(outer)
        end
        # push!(inner.args, :out)
        return outer
    end
    eval(fill_pattern_array!())
    out_cln = map(remove_empties, out)
    return out_cln
end



# combins = gen_combos(res[6][13].patrn)

# push!(combins[1], String[""])
# push!(combins[2], String[""])
# push!(combins[3], String[""])
#
# out = String[]
# eval(fill_pattern_array!(combins))
# gen_combin_subpatterns(res[6][13].patrn)



# This function performs a sequence extension for patterns in
# a prefix tree. In essence, we take a single string `s` and
# append it as an array in the sequence pattern `seq`.
sequence_extension(seq::Array{Array{String,1},1}, s::String) = [seq; [[s]]]

s1 = [["A"], ["B", "C"]]
str = "D"
sequence_extension(s1, str)


# Given a sequence pattern in the form of a nested array, `seq`, and
# a single string, `s`, this function takes `s` and appends it to
# the last array in the nested array `seq`. Note that this function
# is a bit messy looking b/c I couldn't get type-inference to work
# without breaking the steps up a bit. So it goes.
function item_extension(seq::Array{Array{String,1},1}, s::String)
    old_last_arr = seq[end]
    new_last_arr::Array{String,1} = [old_last_arr; s]

    child_seq = [seq; [sort!(new_last_arr)]]
    return child_seq
end

s1 = [["A"], ["B", "C"], ["D"]]
str = "E"
item_extension(s1, str)





# Given two pattern strings such as "{A,B} -> {C}" and
# "{A,B} -> {C} -> {D,E}", where one is a subset of the
# other, this function will extract the postfix from
# the second string, `p2`. 
function extract_postfix(p1::String, p2::String)
    last_idx = length(p1)
    out = p2[last_idx+5:end]
    out
end






















































###
# NOTE: These are spare parts from a false start where we
# considered using strings to represent the patterns in
# the PrefixNode objects. Now, we use nested arrays, as we
# did in the IDList object to ensure sortability when inserting.
###

# function sequence_extension(seq::String, uniq_items::Array{String,1})
#     child_seqs = String[]
#     n = length(uniq_items)
#
#     for i = 1:n
#         push!(child_seqs, string(seq, ",{", uniq_items[i], "}"))
#     end
#     child_seqs
# end
#
#
# function item_extension(seq::String, uniq_items::Array{String,1})
#     child_seqs = String[]
#     n = length(uniq_items)
#
#     for i = 1:n
#         push!(child_seqs, string(seq[1:end-1], ",", uniq_items[i], "}"))
#     end
#     child_seqs
# end
#
# sequence_extension("{A}", ["A", "B", "C"])
# item_extension("{A}", ["A", "B", "C"])
#
# sequence_extension(seq::String, item::String) = string(seq[1:end], ",{", item, "}")
# item_extension(seq::String, item::String) = string(seq[1:end-1], ",", item, "}")
#
# sequence_extension("{A}", "B")
# item_extension("{A}", "B")
#
#
# function seq_and_item_extension(seq::String, uniq_items::Array{String,1})
#     child_seqs = String[]
#     n = length(uniq_items)
#
#     for i = 1:n
#         push!(child_seqs, string(seq, ",{", uniq_items[i], "}"))
#         push!(child_seqs, string(seq[1:end-1], ",", uniq_items[i], "}"))
#     end
#     child_seqs
# end
#
# seq_and_item_extension("{A}", ["A", "B", "C"])
#
#
#

#
#
#
# p1 = "{A} -> {BC}"
# p2 = "{A} -> {BC} -> {D}"
#
# extract_postfix(p1, p2)

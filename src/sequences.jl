
import Base.display
import Base.isempty

type Sequence
    sid::Int64                          # sequence ID
    eids::Array{Int, 1}                 # event IDs
    items::Array{Array{String, 1}, 1}   # items at each event (e.g., symptoms)
end


type IDList
    pattern::String
    sids::Array{Int, 1}
    eids::Array{Int, 1}
    typ::Symbol                         # pattern type is `:initial`, `:sequence` or `:event`
    supp::Int
end

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


function first_idlist(seqs::Array{Sequence, 1}, pattern)
    sids = Array{Int, 1}(0)
    eids = Array{Int, 1}(0)

    for s in seqs
        for j = 1:length(s.eids)
            if pattern ∈ s.items[j]
                push!(sids, s.sid)
                push!(eids, s.eids[j])
            end
        end
    end
    support = length(unique(sids))
    return IDList(pattern, sids, eids, :initial, support)
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



# l1 and l2 are IDList objects
function equality_join(l1, l2)
    sids = Array{Int, 1}(0)
    eids = Array{Int, 1}(0)
    n = length(l1.sids)
    m = length(l2.sids)
    for i = 1:n
        for j = 1:m
            if l1.sids[i] == l2.sids[j] && l1.eids[i] == l2.eids[j]
                push!(sids, l1.sids[i])
                push!(eids, l1.eids[i])
            end
        end
    end
    support = length(unique(sids))
    return IDList(string(l1.pattern, ",", l2.pattern[end]), sids, eids, :event, support)
end


function already_seen(sid1, eid2, tm_sids, tm_eids)
    res = false
    n = length(tm_sids)
    for i = 1:n
        if tm_sids[i] == sid1 && tm_eids[i] == eid2
            res = true
            break
        end
    end
    return res
end



# This function performs a temporal join for cases in which
# both `l1` and `l2` are sequence patterns.

function temporal_join_bothseq(l1, l2)
    # initialize 3 pairs of empty `sids` and `eids` arrays
    for i = 1:3, x in ["sids", "eids"]
        arr = Symbol(string(x, i))
        @eval $arr = Array{Int,1}(0)
    end

    n = length(l1.sids)
    m = length(l2.sids)
    for i = 1:n
        for j = 1:m
            if l1.sids[i] == l2.sids[j]
                if l1.eids[i] < l2.eids[j] && !already_seen(l1.sids[i], l2.eids[j], sids1, eids1)
                    push!(sids1, l1.sids[i])
                    push!(eids1, l2.eids[j])
                elseif l1.eids[i] > l2.eids[j] && !already_seen(l1.sids[i], l1.eids[i], sids2, eids2)
                    push!(sids2, l1.sids[i])
                    push!(eids2, l1.eids[i])
                elseif l1.eids[i] == l2.eids[j] && !already_seen(l1.sids[i], l1.eids[i], sids3, eids3)
                    push!(sids3, l1.sids[i])
                    push!(eids3, l1.eids[i])
                end
            end
        end
    end
    supp1 = length(unique(sids1))
    supp2 = length(unique(sids2))
    supp3 = length(unique(sids3))

    return IDList[IDList(string(l1.pattern, " => ", l2.pattern[end]), sids1, eids1, :sequence, supp1),
                  IDList(string(l1.pattern, " => ", l1.pattern[end]), sids2, eids2, :sequence, supp2),
                  IDList(string(l1.pattern, ",", l2.pattern[end]), sids3, eids3, :event, supp3)]
end

# example from Zaki (2001)
pa_idlist = IDList("P => A", [1, 1, 1, 4, 7, 8, 8, 8, 8, 13, 13, 15, 17, 20], [20, 30, 40, 60, 40, 10, 30, 50, 80, 50, 70, 60, 20, 10], :sequence, 4)
pf_idlist = IDList("P => F", [1, 1, 3, 5, 8, 8, 8, 8, 11, 13, 16, 20], [70, 80, 10, 70, 30, 40, 50, 80, 30, 10, 80, 20], :sequence, 2)

temporal_join_bothseq(pa_idlist, pf_idlist)



function temporal_join_eventseq(l1, l2)
    sids = Array{Int,1}(0)
    eids = Array{Int,1}(0)
    n = length(l1.sids)
    m = length(l2.sids)

    for i = 1:n
        for j = 1:m
            if l1.sids[i] == l2.sids[j] && l1.eids[i] < l2.eids[j] && !already_seen(l1.sids[i], l2.eids[j], sids, eids)
                push!(sids, l1.sids[i])
                push!(eids, l2.eids[j])
            end
        end
    end
    supp = length(unique(sids))
    return IDList(string(l1.pattern, " => ", l2.pattern[end]), sids, eids, :sequence, supp)
end





# The first merging operation executes both equality and
# temporal joins on id-lists with atoms of length 1.
function first_merge!(l1::IDList, l2::IDList, eq_sids, eq_eids, tm_sids, tm_eids)
    for i = 1:length(l1.sids)
        for j = 1:length(l2.sids)
            if l1.sids[i] == l2.sids[j]
                # equality join
                if l1.eids[i] == l2.eids[j]
                    push!(eq_sids, l1.sids[i])
                    push!(eq_eids, l1.eids[i])
                # temporal join
                elseif l1.eids[i] < l2.eids[j] && !already_seen(l1.sids[i], l2.eids[j], tm_sids, tm_eids)
                    push!(tm_sids, l1.sids[i])
                    push!(tm_eids, l2.eids[j])
                end
            end
        end
    end
end


function first_merge(l1::IDList, l2::IDList)
    eq_sids = Array{Int, 1}(0)
    tm_sids = Array{Int, 1}(0)

    eq_eids = Array{Int, 1}(0)
    tm_eids = Array{Int, 1}(0)

    first_merge!(l1, l2, eq_sids, eq_eids, tm_sids, tm_eids)

    # calculate support
    supp1 = length(unique(eq_sids))
    supp2 = length(unique(tm_sids))

    event_idlist = IDList(string(l1.pattern, ",", l2.pattern), eq_sids, eq_eids, :event, supp1)
    seq_idlist = IDList(string(l1.pattern, " => ", l2.pattern), tm_sids, tm_eids, :sequence, supp2)

    merged_idlists = Array{IDList, 1}(0)
    if !isempty(event_idlist)
        push!(merged_idlists, event_idlist)
    end
    if !isempty(seq_idlist)
        push!(merged_idlists, seq_idlist)
    end
    if isempty(merged_idlists)
        return nothing
    end

    return merged_idlists
end

# Behaves a bit like Python's str.rfind() method, gets
# the indices of where the `needle` appears in the `haystack`.
# Returns 0:-1 if `needle` is not found.
function rfind(haystack, needle::String)
    n = length(haystack)
    nchar = length(needle)
    window = nchar - 1
    start_idx = 0
    stop_idx = -1
    for i = 1:(n - window)
        println(i)
        if haystack[i:i+window] == needle
            start_idx = i
            stop_idx = i+window
            break
        end
    end
    return UnitRange{Int}(start_idx, stop_idx)
end


function rfind(s, char::Char)
    found_indcs = find(x -> x == char, collect(s))
    if isempty(found_indcs)
        last_idx = -1
    else
        last_idx = maximum(found_indcs)
    end
    return last_idx
end


suffix(idlist) = idlist.pattern[end]





function merge_idlists(l1, l2)
    if l1.typ == l2.typ == :event                     # both event patterns
        idlist_arr = IDList[equality_join(l1, l2)]
    elseif l1.typ == l2.typ == :sequence              # both sequence patterns
        idlist_arr = temporal_join_bothseq(l1, l2)
    elseif l1.typ == :event && l2.typ == :sequence
        idlist_arr = IDList[temporal_join_eventseq(l1, l2)]
    elseif l1.typ == :sequence && l2.typ == :event
        idlist_arr = IDList[temporal_join_eventseq(l2, l1)]
    end
    return idlist_arr          # array of merged ID-lists (often of length 1)
end




s1 = Sequence(
    1,
    [1, 2, 3, 4, 5, 6],
    [["a", "b", "d"], ["a", "e"], ["a", "b", "e"], ["b", "c", "d"], ["b", "c"], ["b", "d"]])

s2 = Sequence(
    2,
    [1, 2, 3, 4, 5],
    [["a", "c", "d"], ["a"], ["a", "b", "d"], ["a", "b"], ["b", "d"]])


seq_arr = [s1, s2]
alist = first_idlist(seq_arr, "a")
clist = first_idlist(seq_arr, "c")
dlist = first_idlist(seq_arr, "d")

equality_join(clist, dlist)
equality_join(alist, dlist)


@code_warntype merge_idlists(alist, clist)



first_merge(clist, dlist)
first_merge(alist, dlist)


function unique_items(s::Sequence)
    d = Dict{String, Int64}()
    for i = 1:length(s.items)
        for k in s.items[i]
            d[k] = get(d, k, 0) + 1
        end
    end
    return collect(keys(d))
end


function spade!(f, F, min_n)
    n = length(f)
    f_tmp = Array{Array{IDList, 1}, 1}(0)
    for i = 1:n
        for j = (i+1):n
            idlist_arr = merge_idlists(f[i], f[j])

            if idlist_arr ≠ nothing
                push!(f_tmp, idlist_arr)
            end
        end
    end
    if !isempty(f_tmp)
        fk = reduce(vcat, f_tmp)
        push!(F, fk)
    end
end


# only does F[1] and F[2] now.
function spade(seqs::Array{Sequence, 1}, minsupp = 0.1, max_length = 4)
    F = Array{Array{IDList, 1}, 1}(0)
    f1 = Array{IDList, 1}(0)
    items = Array{String, 1}(0)
    n_seq = length(seqs)
    min_n = round(Int, minsupp * n_seq)

    for i = 1:n_seq
        append!(items, unique_items(seqs[i]))
    end
    uniq_items = unique(items)

    for itm in uniq_items
        push!(f1, first_idlist(seqs, itm))
    end
    push!(F, f1)
    push!(F, Array{IDList,1}(0))

    n = length(F[1])

    # first merge is handled differently
    for j = 1:n
        for k = (j+1):n
            idlist_arr = first_merge(F[1][j], F[1][k])
            if idlist_arr ≠ nothing
                append!(F[2], idlist_arr)
            end
        end
    end
    i = 3
    while i ≤ max_length && !allempty(F[i-1])
        spade!(F[i-1], F, min_n)
        i += 1
    end

    return F
end

res = spade(seq_arr)




#

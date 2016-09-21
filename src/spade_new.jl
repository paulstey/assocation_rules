# NOTE: This is an alternative to the spade.jl implementation. In this
# version we don't rely on building up the id-list pattern with string
# concatenation. Instead, we used a vector of vectors (of string), where
# each nested vector corresponds to a time point. For example, the pattern
# [["a"], ["b", "c"]] has one item in the first time point and two in the
# second. So it corresponds to "a => b,c" in our original implementation.

import Base.isempty


type Sequence
    sid::Int64                          # sequence ID
    eids::Array{Int, 1}                 # event IDs
    items::Array{Array{String, 1}, 1}   # items at each event (e.g., symptoms)
end


type IDList
    patrn::Array{Array{String, 1}, 1}   # vector of vectors with the elements in `pattern`
    sids::Array{Int, 1}
    eids::Array{Int, 1}
    typ::Symbol                         # pattern type is `:initial`, `:sequence` or `:event`
    supp::Float64
    supp_cnt::Int

    function IDList(patrn, sids, eids, typ, num_sequences)
        res = new(patrn, sids, eids, typ, length(unique(sids))/num_sequences, length(unique(sids)))
        return res
    end
end


type PrefixNode
    patrn::Array{Array{String,1},1}
    supp::Int64
    seq_extension_children::Array{PrefixNode, 1}
    item_extension_children::Array{PrefixNode, 1}
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


# This function extracts the suffix
# from the ID list's pattern
suffix(idlist::IDList) = idlist.patrn[end]


# This function extracts the prefix
# from the ID list's pattern
prefix(idlist::IDList) = prefix(idlist.patrn)


function prefix(x::Array{Array{String, 1}, 1})
    res = x[1:end-1]
    if length(x[end]) > 1
        res = [res; [x[end][1:end-1]]]
    end
    res                 # returns array of arrays
end


function suffix(x::Array{Array{String, 1}, 1})
     res = x[end][end]
     res                # returns a string
end


# Given an array of `Sequence` objects, this function
# returns the first (k = 1) id-lists.
function first_idlist(seqs::Array{Sequence, 1}, pattern, num_sequences)
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
    return IDList([[pattern]], sids, eids, :initial, num_sequences)
end



# l1 and l2 are IDList objects
function equality_join(l1, l2, num_sequences)
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
    pattern::Array{Array{String, 1}, 1} = [l1.patrn[1:end-1]; [sort([l1.patrn[end]; suffix(l2.patrn)])]]

    return IDList(pattern, sids, eids, :event, num_sequences)
end



# This is a helper function used in the various
# join functions. It takes a seqeunce ID and event ID,
# as well as vectors of sequence and event IDs we
# have already seen. It returns a boolean.
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

# @code_warntype already_seen([1, 1, 1, 2], [10, 15, 20, 10], [1, 2, 3], [10, 20, 15])



# This function executes a temporal join for those cases
# in which both id-lists are for sequence patterns.
function temporal_join(l1, l2, ::Type{Val{:sequence}}, ::Type{Val{:sequence}}, num_sequences)
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
                # elseif l1.eids[i] > l2.eids[j] && !already_seen(l1.sids[i], l1.eids[i], sids2, eids2)
                elseif l2.eids[j] < l1.eids[i] && !already_seen(l2.sids[j], l1.eids[i], sids2, eids2)
                    push!(sids2, l2.sids[j])
                    push!(eids2, l1.eids[i])
                elseif l1.eids[i] == l2.eids[j] && !already_seen(l1.sids[i], l1.eids[i], sids3, eids3) && suffix(l1.patrn) ≠ suffix(l2.patrn)
                    push!(sids3, l1.sids[i])
                    push!(eids3, l1.eids[i])
                end
            end
        end
    end
    seq_patrn1 = [l1.patrn; [[suffix(l2.patrn)]]]
    event_patrn::Array{Array{String, 1}, 1} = [l1.patrn[1:end-1]; [sort([l1.patrn[end]; suffix(l2.patrn)])]]
    seq_patrn2 = [l2.patrn; [[suffix(l1.patrn)]]]

    idlist_arr = IDList[IDList(seq_patrn1,
                               sids1,
                               eids1,
                               :sequence,
                               num_sequences),
                        IDList(seq_patrn2,
                               sids2,
                               eids2,
                               :sequence,
                               num_sequences),
                        IDList(event_patrn,
                               sids3,
                               eids3,
                               :event,
                               num_sequences)]
    return idlist_arr
end




# This function executes the temporal join for cases in which
# one id-list is for an event pattern and the other is for a
# sequence pattern.
function temporal_join(l1, l2, ::Type{Val{:event}}, ::Type{Val{:sequence}}, num_sequences)
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
    pattern = [l1.patrn; [[suffix(l2.patrn)]]]

    return IDList[IDList(pattern, sids, eids, :sequence, num_sequences)]
end


temporal_join(l1, l2, ::Type{Val{:sequence}}, ::Type{Val{:event}}, num_sequences) = temporal_join(l2, l1, Val{:event}, Val{:sequence}, num_sequences)



# The first merging operation executes both equality and
# temporal joins on id-lists with atoms of length 1.
function first_merge!(l1::IDList, l2::IDList, eq_sids, eq_eids, tm_sids, tm_eids)
    for i = 1:length(l1.sids)
        for j = 1:length(l2.sids)
            if l1.sids[i] == l2.sids[j]
                # equality join
                if l1.eids[i] == l2.eids[j] && suffix(l1) ≠ suffix(l2)
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


# Given two id-lists, this function executes the first
# merge operation. An array of merged id-list (k = 2)
# is returned.
function first_merge(l1::IDList, l2::IDList, num_sequences, minsupp)
    eq_sids = Array{Int, 1}(0)
    tm_sids = Array{Int, 1}(0)

    eq_eids = Array{Int, 1}(0)
    tm_eids = Array{Int, 1}(0)

    first_merge!(l1, l2, eq_sids, eq_eids, tm_sids, tm_eids)

    event_patrn = [l1.patrn[1:end-1]; [sort([l1.patrn[end]; suffix(l2.patrn)])]]
    seq_patrn = [l1.patrn; [[suffix(l2.patrn)]]]

    event_idlist = IDList(event_patrn, eq_sids, eq_eids, :event, num_sequences)
    seq_idlist = IDList(seq_patrn, tm_sids, tm_eids, :sequence, num_sequences)

    merged_idlists = Array{IDList, 1}(0)

    if !isempty(event_idlist) && event_idlist.supp ≥ minsupp
        push!(merged_idlists, event_idlist)
    end
    if !isempty(seq_idlist) && seq_idlist.supp ≥ minsupp
        push!(merged_idlists, seq_idlist)
    end
    return merged_idlists
end


# This function wraps all our join functions.
function merge_idlists(l1, l2, num_sequences)
    if l1.typ == l2.typ == :event                     # both event patterns
        idlist_arr = IDList[equality_join(l1, l2, num_sequences)]
    else
        idlist_arr = temporal_join(l1, l2, Val{l1.typ}, Val{l2.typ}, num_sequences)
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
alist = first_idlist(seq_arr, "a", 2)
clist = first_idlist(seq_arr, "c", 2)
dlist = first_idlist(seq_arr, "d", 2)

@code_warntype first_idlist(seq_arr, "d", 2)

cdlist = first_merge(clist, dlist, 2, 0.1)
adlist = first_merge(alist, dlist, 2, 0.1)

@code_warntype temporal_join(cdlist[1], adlist[1], Val{:sequence}, Val{:sequence}, 2)

@code_warntype equality_join(cdlist[1], adlist[1], 2)



# This function is our workhorse for the spade() function
# below. It is only called starting at `F[3]`. Given `f`,
# which is the vector of IDLists `F[k-1]`, this function
# generates `F[k]` by merging the IDList in `f`. It modifies
# `F` in place.
function spade!(f, F, num_sequences, minsupp)
    n = length(f)
    f_tmp = Array{Array{IDList, 1}, 1}(0)

    for i = 1:n
        for j = i:n
            # If both are event patterns, we will only merge
            # id-lists when the suffixes are not identical.
            if f[i].typ == f[j].typ == :event && suffix(f[i]) == suffix(f[j])
                continue
            elseif prefix(f[i]) == prefix(f[j])
                idlist_arr = merge_idlists(f[i], f[j], num_sequences)
                filter!(x -> x.supp ≥ minsupp, idlist_arr)

                if !allempty(idlist_arr)
                    push!(f_tmp, idlist_arr)
                end
            end
        end
    end
    if !isempty(f_tmp)
        fk = reduce(vcat, f_tmp)
        push!(F, unique(fk))
    end
end



"""
Given a vector of `Sequence` objects, this function executes the SPADE
algorithm (Zaki, 2001). We can set `minsupp` to be our desired minimum level
of support for a pattern. And we can set `max_length` to control the maximum
number of items in a given pattern. The return value is an array of arrays,
`F`, where each element of `F` is an array of IDList objects of length `k`.
For example, `F[2]` has an array of all IDLists with patterns of length 2 (e.g.,
{A, B} or {B => C})
"""
function spade(seqs::Array{Sequence, 1}, minsupp = 0.1, max_length = 4)
    F = Array{Array{IDList, 1}, 1}(0)
    f1 = Array{IDList, 1}(0)
    items = Array{String, 1}(0)
    n_seq = length(seqs)

    for i = 1:n_seq
        append!(items, unique_items(seqs[i]))
    end
    uniq_items = unique(items)

    for itm in uniq_items
        push!(f1, first_idlist(seqs, itm, n_seq))
    end
    push!(F, f1)
    push!(F, Array{IDList,1}(0))

    n = length(F[1])

    # first merge is handled differently
    for j = 1:n
        for k = 1:n
            idlist_arr = first_merge(F[1][j], F[1][k], n_seq, minsupp)
            if idlist_arr ≠ nothing
                append!(F[2], idlist_arr)
            end
        end
    end
    F[2] = unique(F[2])
    i = 3

    # We persist until arriving at max_length or
    # until F[k] was empty on most recent iteration
    while i ≤ max_length && length(F) == i - 1
        spade!(F[i-1], F, n_seq, minsupp)
        i += 1
    end

    return F
end



# NOTE: The gen_rules1() function is quite inefficient. In
# particular, it's runtime is O(n*m*2^k) where k is the number
# of elements in the pattern, m is the number of patterns for a
# given pattern length k, and n is the number of different pattern
# lengths. Additionally, though this corresponds to the pseudocode
# Zaki provides in his orginal paper, it is not the implementation
# that appears in the arulesSequence package.

function gen_rules1(F::Array{Array{IDList, 1}, 1}, min_conf)
    supp_count = count_patterns(F)
    rules = String[]

    # Check the confidence for all sub-patterns
    # from all of our frequent patterns
    for k = 1:length(F)
        for i = 1:length(F[k])
            sub_patrns = gen_combin_subpatterns(F[k][i].patrn)
            for s in sub_patrns
                if s ≠ ""
                    cnt = get(supp_count, s, 0)
                    conf = isfinite(cnt) ? F[k][i].supp_cnt/cnt : -Inf

                    if conf ≥ min_conf
                        push!(rules, "$s => $(pattern_string(F[k][i].patrn))")
                    end
                end
            end
        end
    end
    rules
end

rules = gen_rules1(res, 0)



function create_children(patrn::Array{Array{String,1},1}, uniq_items, supp_count, recurse = true)
    seq_extended_children = Array{PrefixNode,1}(0)
    item_extended_children = Array{PrefixNode,1}(0)

    if recurse
        for item in uniq_items
            seq_extd_patrn = sequence_extension(patrn, item)
            seq_extd_supp = get(supp_count, pattern_string(seq_extd_patrn), 0)

            item_extd_patrn = item_extension(patrn, item)
            item_extd_supp = get(supp_count, pattern_string(item_extd_patrn), 0)

            seq_extd_child = PrefixNode(seq_extd_patrn, seq_extd_supp, create_children(seq_extd_patrn, uniq_items, supp_count, false)[1], create_children(seq_extd_patrn, uniq_items, supp_count, false)[2])

            item_extd_child = PrefixNode(item_extd_patrn, item_extd_supp, create_children(item_extd_patrn, uniq_items, supp_count, false)[1], create_children(item_extd_patrn, uniq_items, supp_count, false)[2])

            push!(seq_extension_children, seq_extd_child)
            push!(item_extension_children, item_extd_child)
        end
    end

    return (seq_extended_children, item_extended_children)
end






function gen_rules_from_root!(node::PrefixNode, uniq_items, rules::Array{String,1}, supp_count, min_conf)

    for nseq in node.seq_extension_children)
        child_patterns = seq_and_item_extension(nseq.patrn, unique_items)

        for l in child_patterns


function build_ptree(F::Array{Array{IDList,1},1}, min_conf, num_uniq_sids)
    supp_count = count_patterns(F)
    uniq_items = String[]

    for k = 1:length(F)
        for i = 1:length(F[k])
            if F[k][i] ∉ uniq_items
                push!(uniq_items, F[k][i])
            end
        end
    end
    node = PrefixNode("{}", num_uniq_sids, uniq_items, uniq_items)
    rules = String[]

    gen_rules_from_root!(node, F, rules, supp_count, min_conf)

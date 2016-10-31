# NOTE: We use a vector of vectors (of string), to represent sequences with
# each nested vector corresponding to a time point. For example, the pattern
# [["a"], ["b", "c"]] has one item in the first time point and two in the
# second. So it corresponds to "a => b,c" in our original implementation.

import Base.isempty


type Sequence
    sid::Int64                          # sequence ID
    eids::Array{Int, 1}                 # event IDs
    items::Array{Array{String, 1}, 1}   # items at each event (e.g., symptoms)
end



# Given a vector of strings, this returns a single
# string with the vector's elements separated by
# commas, with braces at start and end.
function pattern_string(v::Array{String,1})
    out = "{"
    n = length(v)

    for i = 1:n
        if i < n
            out *= "$(v[i]),"
        elseif i == n
            out *= "$(v[i])}"
        end
    end
    out
end


type SeqPattern
    head::String
    tail::Array{String,1}

    function SeqPattern(oldhead, oldtail, addon, typ::Symbol)
        if typ != :initial
            if !isempty(oldhead)
                if typ == :sequence
                    head = string(oldhead, ",", pattern_string(oldtail))
                    res = new(head, [addon])
                elseif typ == :event
                    tail = [oldtail; addon]
                    sort!(tail)
                    res = new(oldhead, tail)
                end
            # If it's not the initation, but the head is empty, then
            # we are either on F[k] = 2, or F[k] > 2 and all joins have
            # been event joins.
            elseif isempty(oldhead)
                if typ == :sequence
                    head = pattern_string(oldtail)
                    res = new(head, [addon])
                elseif typ == :event
                    tail = [oldtail; addon]
                    sort!(tail)
                    res = new(oldhead, tail)
                end
            end
        # For the initiation, we just leave the head empty and
        # include the add-on as the sole element in the tail.
        elseif typ == :initial
            res = new("", [addon])
        end
        return res
    end
end


SeqPattern("{A}", ["D", "E"], "F", :sequence)
SeqPattern("", String[], "F", :initial)
SeqPattern("", ["A"], "B", :event)
SeqPattern("{A}", ["B", "C"], "D", :sequence)


type IDList
    patrn::SeqPattern   # vector of vectors with the elements in `pattern`
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
    pattern::Array{Array{String,1},1}
    # parent::PrefixNode
    seq_ext_children::Array{PrefixNode,1}
    item_ext_children::Array{PrefixNode,1}
    support::Int64

    PrefixNode(pattern) = new(pattern)
end


type SeqRule
    prefix::Array{Array{String,1},1}
    postfix::Array{Array{String,1},1}
    conf::Float64
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

# old method before `SeqPattern`
function suffix(x::Array{Array{String, 1}, 1})
     res = x[end][end]
     res                # returns a string
end


function suffix(x::SeqPattern)
     res = x.tail[end]
     res                # returns a string
end


function prefix(x::SeqPattern)
    if isempty(x.head)
        res = pattern_string(x.tail[1:end-1])
    elseif !isempty(x.head)
        if length(x.tail) > 1
            res = "$(x.head),$(pattern_string(x.tail[1:end-1]))"
        elseif length(x.tail) ≤ 1
            res = x.head
        end
    end

    return res
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
    # return IDList([[pattern]], sids, eids, :initial, num_sequences)
    patrn = SeqPattern("", String[], pattern, :initial)
    return IDList(patrn, sids, eids, :initial, num_sequences)
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
    # pattern::Array{Array{String, 1}, 1} = [l1.patrn[1:end-1]; [sort([l1.patrn[end]; suffix(l2.patrn)])]] # old method
    pattern = SeqPattern(l1.patrn.head, l1.patrn.tail, l2.patrn.tail[end], :event)
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
    sids1 = Array{Int,1}(0)
    eids1 = Array{Int,1}(0)
    sids2 = Array{Int,1}(0)
    eids2 = Array{Int,1}(0)
    sids3 = Array{Int,1}(0)
    eids3 = Array{Int,1}(0)

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
    ## old way before `SeqPattern`
    # seq_patrn1 = [l1.patrn; [[suffix(l2.patrn)]]]
    # event_patrn::Array{Array{String, 1}, 1} = [l1.patrn[1:end-1]; [sort([l1.patrn[end]; suffix(l2.patrn)])]]
    # seq_patrn2 = [l2.patrn; [[suffix(l1.patrn)]]]


    seq_patrn1 = SeqPattern(l1.patrn.head, l1.patrn.tail, l2.patrn.tail[end], :sequence)
    event_patrn = SeqPattern(l1.patrn.head, l1.patrn.tail, l2.patrn.tail[end], :event)
    seq_patrn2 = SeqPattern(l2.patrn.head, l2.patrn.tail, l1.patrn.tail[end], :sequence)

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
    ## old method before `SeqPattern`
    # pattern = [l1.patrn; [[suffix(l2.patrn)]]]
    pattern = SeqPattern(l1.patrn.head, l1.patrn.tail, l2.patrn.tail[end], :sequence)

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
                if l1.eids[i] == l2.eids[j] && suffix(l1.patrn) ≠ suffix(l2.patrn)
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

    ## old method before `SeqPattern`
    # event_patrn = [l1.patrn[1:end-1]; [sort([l1.patrn[end]; suffix(l2.patrn)])]]
    # seq_patrn = [l1.patrn; [[suffix(l2.patrn)]]]
    event_patrn = SeqPattern(l1.patrn.head, l1.patrn.tail, l2.patrn.tail[end], :event)
    seq_patrn = SeqPattern(l1.patrn.head, l1.patrn.tail, l2.patrn.tail[end], :sequence)


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
@time first_idlist(seq_arr, "d", 2);


cdlist = first_merge(clist, dlist, 2, 0.1)
adlist = first_merge(alist, dlist, 2, 0.1)

merge_idlists(adlist[1], cdlist[2], 0.1)

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
            if f[i].typ == f[j].typ == :event && suffix(f[i].patrn) == suffix(f[j].patrn)
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
    spade(seqs, minsupp, maxlength)

Given a vector of `Sequence` objects, this function executes the SPADE
algorithm (Zaki, 2001).

### Arguments
* `seqs`: a vector of `Sequence` objects
* `minsupp`: minimum level of support for a sequential pattern.
* `maxlength`: maximum number of items in a given pattern

The return value is an array of arrays, `F`, where each element of `F` is
an array of `IDList` objects of length `k`. For example, `F[2]` has an array
of all `IDLists` with patterns of length 2 (e.g., {A,B} or {C},{D})
"""
function spade(seqs::Array{Sequence, 1}, minsupp = 0.1, maxlength = 5)
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

    # We persist until arriving at maxlength or
    # until F[k] was empty on most recent iteration
    while i ≤ maxlength && length(F) == i - 1
        spade!(F[i-1], F, n_seq, minsupp)
        i += 1
    end

    return F
end

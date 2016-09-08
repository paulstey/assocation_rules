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
    elems::Array{Array{String, 1}, 1}   # vector of vectors with the elements in `pattern`
    typ::Symbol                         # pattern type is `:initial`, `:sequence` or `:event`
    parents::Array{String, 1}           # just for debugging in the development process
    supp::Float64

    function IDList(pattern, sids, eids, elems, typ, parents, num_sequences)
        res = new(pattern, sids, eids, elems, typ, parents, length(unique(sids))/num_sequences)
        return res
    end
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
suffix(idlist::IDList) = idlist.elems[end]


# This function extracts the prefix
# from the ID list's pattern
function prefix(idlist::IDList)
    if idlist.typ == :sequence
        idx = first(rfind(idlist.pattern, " => "))
        pfix = idlist.pattern[1:idx-1]
    elseif idlist.typ == :event
        idx  = rfind(idlist.pattern, ',')
        pfix = idlist.pattern[1:idx-1]
    end
    return pfix
end


function prefix(x::Array{Array{String, 1}, 1})
    res = x[1:end-1]
    if length(x[end]) > 1
        push!(res, x[end][1:end-1])
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
    return IDList(pattern, sids, eids, [[pattern]], :initial, [pattern], num_sequences)
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
    elements = deepcopy(l1.elems)
    push!(elements[end], suffix(l2.elems))

    return IDList(string(l1.pattern, ",", suffix(l2.elems)), sids, eids, elements, :event, [l1.pattern, l2.pattern], num_sequences)
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
                elseif l1.eids[i] == l2.eids[j] && !already_seen(l1.sids[i], l1.eids[i], sids3, eids3) && suffix(l1.elems) ≠ suffix(l2.elems)
                    push!(sids3, l1.sids[i])
                    push!(eids3, l1.eids[i])
                end
            end
        end
    end
    seq_elems1 = deepcopy(l1.elems)
    push!(seq_elems1, [suffix(l2.elems)])

    event_elems = deepcopy(l1.elems)
    push!(event_elems[end], suffix(l2.elems))

    seq_elems2 = deepcopy(l2.elems)
    push!(seq_elems2, [suffix(l1.elems)])

    idlist_arr = IDList[IDList(string(l1.pattern, " => ", suffix(l2.elems)),
                               sids1,
                               eids1,
                               seq_elems1,
                               :sequence,
                               [l1.pattern, l2.pattern], num_sequences),
                        IDList(string(l2.pattern, " => ", suffix(l1.elems)),
                               sids2,
                               eids2,
                               seq_elems2,
                               :sequence,
                               [l2.pattern, l1.pattern], num_sequences),
                        IDList(string(l1.pattern, ",", suffix(l2.elems)),
                               sids3,
                               eids3,
                               event_elems,
                               :event,
                               [l1.pattern, l2.pattern], num_sequences)]
    return idlist_arr
end

# example from Zaki (2001)
pa_idlist = IDList("P => A", [1, 1, 1, 4, 7, 8, 8, 8, 8, 13, 13, 15, 17, 20], [20, 30, 40, 60, 40, 10, 30, 50, 80, 50, 70, 60, 20, 10], [["P"], ["A"]], :sequence, ["P", "A"], 20)
pf_idlist = IDList("P => F", [1, 1, 3, 5, 8, 8, 8, 8, 11, 13, 16, 20], [70, 80, 10, 70, 30, 40, 50, 80, 30, 10, 80, 20], [["P"], ["F"]], :sequence, ["P", "F"], 20)




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
    elements = deepcopy(l1.elems)
    push!(elements, [suffix(l2.elems)])

    return IDList[IDList(string(l1.pattern, " => ", suffix(l2.elems)), sids, eids, elements, :sequence, [l1.pattern, l2.pattern], num_sequences)]
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

    event_elems = deepcopy(l1.elems)
    push!(event_elems[end], suffix(l2.elems))

    seq_elems = deepcopy(l1.elems)
    push!(seq_elems, [suffix(l2.elems)])

    event_idlist = IDList(string(l1.pattern, ",", suffix(l2.elems)), eq_sids, eq_eids, event_elems, :event, [l1.pattern, l2.pattern], num_sequences)
    seq_idlist = IDList(string(l1.pattern, " => ", suffix(l2.elems)), tm_sids, tm_eids, seq_elems, :sequence, [l1.pattern, l2.pattern], num_sequences)

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
        for k = j:n
            idlist_arr = first_merge(F[1][j], F[1][k], n_seq, minsupp)
            if idlist_arr ≠ nothing
                append!(F[2], idlist_arr)
            end
        end
    end
    i = 3

    # We persist until arriving at max_length or
    # until F[k] was empty on most recent iteration
    while i ≤ max_length && length(F) == i - 1
        spade!(F[i-1], F, n_seq, minsupp)
        i += 1
    end

    return F
end

#

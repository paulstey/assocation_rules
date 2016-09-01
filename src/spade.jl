
include("src/spade_utils.jl")

type Sequence
    sid::Int64                          # sequence ID
    eids::Array{Int, 1}                 # event IDs
    items::Array{Array{String, 1}, 1}   # items at each event (e.g., symptoms)
end


type IDList
    pattern::String
    sids::Array{Int, 1}
    eids::Array{Int, 1}
    elems::Array{String, 1}             # vector of the elements in `pattern`
    typ::Symbol                         # pattern type is `:initial`, `:sequence` or `:event`
    parents::Array{String, 1}           # just for debugging in the development process
    supp::Int

    IDList(pattern, sids, eids, elems, typ, parents) = new(pattern, sids, eids, elems, typ, parents, length(unique(sids)))
end


suffix(idlist::IDList) = idlist.elems[end]

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
    return IDList(pattern, sids, eids, [pattern], :initial, [pattern])
end



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
    return IDList(string(l1.pattern, ",", l2.elems[end]), sids, eids, [l1.elems; string(l2.elems[end])], :event, [l1.pattern, l2.pattern])
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



function temporal_join(l1, l2, ::Type{Val{:sequence}}, ::Type{Val{:sequence}})
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
                elseif l1.eids[i] == l2.eids[j] && !already_seen(l1.sids[i], l1.eids[i], sids3, eids3) && suffix(l1) ≠ suffix(l2)
                    push!(sids3, l1.sids[i])
                    push!(eids3, l1.eids[i])
                end
            end
        end
    end

    idlist_arr = IDList[IDList(string(l1.pattern, " => ", l2.elems[end]),
                               sids1,
                               eids1,
                               [l1.elems; string(l2.elems[end])],
                               :sequence,
                               [l1.pattern, l2.pattern]),
                        IDList(string(l2.pattern, " => ", l1.elems[end]),
                               sids2,
                               eids2,
                               [l2.elems; string(l1.elems[end])],
                               :sequence,
                               [l2.pattern, l1.pattern]),
                        IDList(string(l1.pattern, ",", l2.elems[end]),
                               sids3,
                               eids3,
                               [l1.elems; string(l2.elems[end])],
                               :event,
                               [l1.pattern, l2.pattern])]
    return idlist_arr
end

# example from Zaki (2001)
pa_idlist = IDList("P => A", [1, 1, 1, 4, 7, 8, 8, 8, 8, 13, 13, 15, 17, 20], [20, 30, 40, 60, 40, 10, 30, 50, 80, 50, 70, 60, 20, 10], ["P", "A"], :sequence, ["P", "A"])
pf_idlist = IDList("P => F", [1, 1, 3, 5, 8, 8, 8, 8, 11, 13, 16, 20], [70, 80, 10, 70, 30, 40, 50, 80, 30, 10, 80, 20], ["P", "F"], :sequence, ["P", "F"])

# temporal_join_bothseq(pa_idlist, pf_idlist)



function temporal_join(l1, l2, ::Type{Val{:event}}, ::Type{Val{:sequence}})
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
    return IDList[IDList(string(l1.pattern, " => ", l2.elems[end]), sids, eids, [l1.elems; string(l2.elems[end])], :sequence, [l1.pattern, l2.pattern])]
end


temporal_join(l1, l2, ::Type{Val{:sequence}}, ::Type{Val{:event}}) = temporal_join(l2, l1, Val{:event}, Val{:sequence})



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

    event_idlist = IDList(string(l1.pattern, ",", l2.elems[1]), eq_sids, eq_eids, [l1.elems; l2.elems], :event, [l1.pattern, l2.pattern])
    seq_idlist = IDList(string(l1.pattern, " => ", l2.elems[1]), tm_sids, tm_eids, [l1.elems; l2.elems], :sequence, [l1.pattern, l2.pattern])

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



function merge_idlists(l1, l2)
    if l1.typ == l2.typ == :event                     # both event patterns
        idlist_arr = IDList[equality_join(l1, l2)]
    else
        idlist_arr = temporal_join(l1, l2, Val{l1.typ}, Val{l2.typ})
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

@code_warntype first_idlist(seq_arr, "d")
@code_warntype merge_idlists(alist, clist)

cdlist = first_merge(clist, dlist)
adlist = first_merge(alist, dlist)

@code_warntype temporal_join(cdlist[1], adlist[1], Val{:sequence}, Val{:sequence})




function spade!(f, F, min_n)
    n = length(f)
    f_tmp = Array{Array{IDList, 1}, 1}(0)
    for i = 1:n
        for j = i:n

            # If both are event patterns, we will only merge
            # id-lists when the suffixes are not identical.
            if f[i].typ == f[j].typ == :event && suffix(f[i]) == suffix(f[j])
                continue
            elseif prefix(f[i]) == prefix(f[j])
                idlist_arr = merge_idlists(f[i], f[j])
                filter!(x -> x.supp ≥ min_n, idlist_arr)

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

res = spade(seq_arr, 0.5, 4)


    #


import Base.display
import Base.isempty

type Sequence
    sid::Int64                          # sequence ID
    eids::Array{Int, 1}                 # event IDs
    items::Array{Array{String, 1}, 1}   # items at each event (e.g., symptoms)
end


type IDList
    item::String
    sids::Array{Int, 1}
    eids::Array{Int, 1}
    pattern::Symbol                     # either `:sequence` or `:event` pattern
    supp::Int
end

isempty(x::IDList) = isempty(x.sids)

function first_idlist(seqs::Array{Sequence, 1}, item)
    sids = Array{Int, 1}(0)
    eids = Array{Int, 1}(0)

    for s in seqs
        for j = 1:length(s.eids)
            if item ∈ s.items[j]
                push!(sids, s.sid)
                push!(eids, s.eids[j])
            end
        end
    end
    support = length(unique(sids))
    return IDList(item, sids, eids, :event, support)
end


function display(x::IDList)
    last = x.sids[end]
    nchar = 2 + length(string(last))

    println("$(x.item)")
    for i = 1:length(x.sids)
        println(rpad(x.sids[i], nchar, " "), x.eids[i])
    end
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
    support = length(unique(sids))
    return IDList(string(l1.item, l2.item), sids, eids, :event, support)
end


function already_seen(sid1, eid2, tm_sids, tm_eids)
    if !in(sid1, tm_sids)
        res = false
    elseif !in(eid2, tm_eids)
        res = false
    elseif find(tm_sids .== sid1) == find(tm_eids .== eid2)
        res = true
    else
        res = false
    end
    return res
end


function merge_idlists!(l1::IDList, l2::IDList, eq_sids, eq_eids, tm_sids, tm_eids)
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


function merge_idlists(l1::IDList, l2::IDList)
    eq_sids = Array{Int, 1}(0)
    eq_eids = Array{Int, 1}(0)
    tm_sids = Array{Int, 1}(0)
    tm_eids = Array{Int, 1}(0)

    merge_idlists!(l1, l2, eq_sids, eq_eids, tm_sids, tm_eids)

    # calculate support
    supp1 = length(unique(eq_sids))
    supp2 = length(unique(tm_sids))

    merged_idlists = [IDList(string(l1.item, l2.item), eq_sids, eq_eids, :event, supp1), IDList(string(l1.item, " => ", l2.item), tm_sids, tm_eids, :sequence, supp2)]
    return merged_idlists
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



merge_idlists(clist, dlist)

function unique_items(s::Sequence)
    d = Dict{String, Int64}()
    for i = 1:length(s.items)
        for k in s.items[i]
            d[k] = get(d, k, 0) + 1
        end
    end
    return collect(keys(d))
end




function spade(seqs::Array{Sequence, 1})
    F = Array{Array{IDList, 1}, 1}(0)
    f1 = Array{IDList, 1}(0)
    items = Array{String, 1}(0)

    for i = 1:length(seqs)
        append!(items, unique_items(seqs[i]))
    end
    uniq_items = unique(items)

    for itm in uniq_items
        push!(f1, first_idlist(seqs, itm))
    end
    n = length(f1)
    for i = 1:n
        for j = (i+1):n
            push!(F, merge_idlists(f1[i], f1[j]))
        end
    end
    F
end

spade(seq_arr)

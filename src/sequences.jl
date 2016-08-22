
import Base.display

type Sequence
    sid::Int64                          # sequence ID
    eids::Array{Int, 1}                 # event IDs
    items::Array{Array{String, 1}, 1}   # items at each event (e.g., symptoms)
end


type IDList
    item::String
    sids::Array{Int, 1}
    eids::Array{Int, 1}
    typ::Symbol                         # either `:sequence` or `:event` pattern
end


function first_idlist(seqs::Array{Sequence, 1}, id)
    sids = Array{Int, 1}(0)
    eids = Array{Int, 1}(0)

    for s in seqs
        for j = 1:length(s.eids)
            if id ∈ s.items[j]
                push!(sids, s.sid)
                push!(eids, s.eids[j])
            end
        end
    end
    return IDList(id, sids, eids, :event)
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
    return IDList(string(l1.item, l2.item), sids, eids, :event)
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
first_idlist(seq_arr, "a")



clist = first_idlist(seq_arr, "c")
dlist = first_idlist(seq_arr, "d")

equality_join(clist, dlist)



type SequenceData
    sids::Array{Int, 1}
    eids::Array{Int, 1}
    items::Array{Array{String, 1}, 1}
end


type IDList
    item::String
    sids::Array{Int, 1}
    eids::Array{Int, 1}
end

function first_idlist(dat, id)
    indcs = find(x -> id ∈ x, dat.items)
    id_list = IDList(id, dat.sids[indcs], dat.eids[indcs])
    return id_list
end


function first_idlist2(dat, id)
    indcs = Array{Int, 1}(0)
    for i = 1:length(dat.items)
        if id ∈ dat.items[i]
            push!(indcs, i)
        end
    end
    id_list = IDList(id, dat.sids[indcs], dat.eids[indcs])
    return id_list
end



ds = SequenceData(
    [1, 1, 1, 2, 2, 2],
    [1, 2, 3, 1, 2, 3],
    [["A", "B", "D"], ["A", "E"], ["A", "B", "E"], ["A", "C", "D"], ["A"], ["A", "B", "D"]]
    )

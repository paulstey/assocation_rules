
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
    pattern::Symbol                     # either `:initial`, `:sequence` or `:event` pattern
    supp::Int
end

isempty(x::IDList) = isempty(x.sids)

function allempty(x::Array{IDList, 1})
    res = true
    for i = 1:length(x)
        if !isempty(x[i])
            res = false
        end
    end
    return res
end


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


# function display(x::IDList)
#     if isempty(x)
#         println("$(x.item) has support 0")
#     else
#         last = x.sids[end]
#         nchar = 2 + length(string(last))
#
#         println("$(x.item)")
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
    return IDList(string(l1.item, ",", l2.item), sids, eids, :event, support)
end


function temporal_join(l1, l2, both_sequences = false)
    sids = Array{Int, 1}(0)
    eids = Array{Int, 1}(0)
    n = length(l1.sids)
    m = length(l2.sids)
    if both_sequences
        for i = 1:n
            for j = 1:m
                if l1.sids[i] == l2.sids[j] && l1.eids[i] < l2.eids[j] && !already_seen(l1.sids[i], l2.eids[j], tm_sids, tm_eids)
                    push!(sids, l1.sids[i])
                    push!(eids, l1.eids[i])
                end
            end
        end
    elseif !both_sequences
        if l1.item == l2.item
            error("id-list 1 and id-list 2 are the same")
        else




    support = length(unique(sids))
    return IDList(string(l1.item, ",", l2.item), sids, eids, :sequence, support)
end



function already_seen(sid1, eid2, tm_sids, tm_eids)
    res = false
    n = length(tm_sids)
    for i = 1:n, j = 1:n
        if tm_sids[i] == sid1 && tm_eids[j] == eid2
            res = true
            break
        end
    end
    return res
end


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
    eq_eids = Array{Int, 1}(0)
    tm_sids = Array{Int, 1}(0)
    tm_eids = Array{Int, 1}(0)

    first_merge!(l1, l2, eq_sids, eq_eids, tm_sids, tm_eids)

    # calculate support
    supp1 = length(unique(eq_sids))
    supp2 = length(unique(tm_sids))

    event_idlist = IDList(string(l1.item, ",", l2.item), eq_sids, eq_eids, :event, supp1)
    seq_idlist = IDList(string(l1.item, " => ", l2.item), tm_sids, tm_eids, :sequence, supp2)

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

# Behave like Python's str.rfind() method, gets
# the index of the last instance of `char` in the
# string `s`. Return -1 if `char` is not found.
function rfind(s, char)
    found_indcs = find(x -> x == char, collect(s))
    if isempty(found_indcs)
        last_idx = -1
    else
        last_idx = maximum(found_indcs)
    end
    return last_idx
end


function



function merge_idlists(l1, l2)
    if l1.pattern == :event && l2.pattern == :event
        merged_idlists = equality_join(l1, l2)
    elseif l1.pattern == :event && l2.pattern == :sequence
        merged_idlists = temporal_join(l1, l2)
    elseif l1.pattern == l2.pattern == :sequence








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


function _spade!(f, F)
    if allempty(f)
        return nothing
    else
        n = length(f)
        f_tmp = Array{Array{IDList, 1}, 1}(0)
        for i = 1:n
            for j = (i+1):n
                println(i, " ", j)
                tmp_idlist = first_merge(f[i], f[j])
                if tmp_idlist ≠ nothing
                    push!(f_tmp, tmp_idlist)
                end
            end
        end
        fk = reduce(vcat, f_tmp)
        push!(F, fk)
        # _spade!(fk, F)
    end
end


# only does F[1] and F[2] now.
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
    push!(F, f1)
    i = 1
    push!(F, Array{IDList,1}(0))
    n = length(F[i])

    # first merge is handled differently
    for j = 1:n
        for k = (j+1):n
            z_new = first_merge(F[i][j], F[i][k])
            if z_new ≠ nothing
                append!(F[i+1], z_new)
            end
        end
    end
    display(F)
    i += 1

    F
end

spade(seq_arr)

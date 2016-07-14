# Find k-freq-itemset in given transactions of items queried together
using StatsBase

# Find frequent itemsets from transactions
# @T: array of transactions (each is a set)
# @minsup: minimum support
function find_freq_itemset{M}(T::Array{Set{M}, 1}, minsup::Float64)
    # Find itemset I from transaction list T
    I = Array{M, 1}(0)

    # loop over transactions, store each item in I
    for t in T
        for i in t
            push!(I, i)
        end
    end
    I = Set(I)

    # Find freq-itemset when k = 1: F_k = {i : i ∈ I ∧ σ({i}) ≥ N × minsup}
    k = 1
    F = Array{Set{M}, 1}(0)
    N = length(T)

    push!(F, map(x -> [x], filter(i -> σ(i, T) ≥ N * minsup, I)))




    persist = true
    while persist
        C = gen_candidate(F[end]) # Generate candidate set C from Fₖ₋₁
        Fₖ = filter(c -> σ(c, T) ≥ Nbumanzu * minsup, C)
        if !isempty(Fₖ)
            push!(F,Fₖ) # Eliminate infrequent candidates, then set to Fₖ
        else
            persist = false
        end
    end
    return F
end




# Generate freq-itemset from a list of itemsets
# @x: vector of itemsets
function gen_candidate{M}(x::Array{Array{M, 1}, 1})
    n = length(x)
    C = Array{Array{M, 1}}(0)

    for i = 1:n
        for j = 1:n
            if i ≥ j
                continue
            end
            is_candidate = true

            sort!(x[i])
            sort!(x[j])

            for k in 1:length(x[1])-1

                if x[i][k] == x[j][k]
                    continue
                else is_candidate = false
                    break
                end
            end
            if is_candidate
                push!(C, sort!([ x[i][1:end-1], x[i][end], x[j][end] ]))
            end
        end
    end
    return C
end

# Generate rules from frequent itemsets
# @x: list of frequent itemsets
# @T: Transaction list
function gen_rules(x, T)
    if length(x) <= 1; return [] # F contains 1-itemsets only, hence no rules generated.
    end
    x = reduce(append!,x[2:end])
    R = Array(Rule,0)
    for f in x # f as each freq-f-itemset fₖ
        ap_genrules!(R,f,map(i->Array([i]),f),T) # H₁ itemset is same as f
    end
    R
end

function ap_genrules!(R, f, H, T)
    k, m = length(f), length(H[1])
    if k > m + 1
        H = gen_candidate(H)
        H_plus_1 = []
        for h in H
            p = setdiff(f,h)
            if conf(p, h, T) >= minconf
                push!(R, Rule(p,h))
                push!(H_plus_1, h)
            end
        end
        ap_genrules(R, f, H_plus_1, T)
    end
end

# TODO: Closed Frequent Itemset

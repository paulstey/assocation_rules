# Common types and functions
import Base.==
import Base.in
import Base.unique


type Rule
    p::Array{Int64} # Antecedent
    q::Array{Int64} # Consequent
end

==(x::Rule, y::Rule) = return x.p == y.p && x.q == y.q

in(x::Rule, v::Set{Rule}) = haskey(v.dict, x)

function unique(v::Vector{Rule})
    out = Vector{Rule}(0)
    seen = Set{eltype(v)}()
    for i = 1:length(v)
        if !in(v[i], seen)
            push!(seen, v[i])
            push!(out, v[i])
        end
    end
    return out
end





# Support Count: σ(x) = | {tᵢ|x ⊆ t_i, t_i ∈ T}|
function σ(x, T)
    res = 0
    for t in T
        if x ⊆ t
            res += 1
        end
    end
    return res
end

# Support of rule x -> y, which x does not intersect y.
supp(x, y, T) = σ(union(x, y), T)/length(T)

# Confidence of rule x -> y, which x does not intersect y.
conf(x, y, T) = σ(union(x, y), T)/σ(x, T)

# Common types and functions
import Base.==
import Base.unique


type Rule{T}
    p::Array{T}             # antecedent (rhs)
    q::Array{T}             # consequent (lhs)
end

==(x::Rule, y::Rule) = return x.p == y.p && x.q == y.q

function unique(v::Vector{Rule})
    out = Vector{Rule}(0)
    for i = 1:length(v)
        if !in(v[i], out)
            push!(out, v[i])
        end
    end
    return out
end


# Support Count: σ(x) = | {t_i|x ⊆ t_i, t_i ∈ T}|
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

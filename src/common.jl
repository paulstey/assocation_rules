# Common types and functions
import Base.==
import Base.unique


type Rule
    p::Array            # antecedent (rhs)
    q::Array            # consequent (lhs)
    supp::Float64
    conf::Float64
    lift::Float64
end

==(x::Rule, y::Rule) = x.p == y.p && x.q == y.q

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
function σ(x::Array, T)
    res = 0
    for t in T
        if x ⊆ t
            res += 1
        end
    end
    return res
end


function σ(x::String, T)
    res = 0
    for t in T
        if x in t
            res += 1
        end
    end
    return res
end


# Support of rule x -> y, for which x ∩ y = ∅
function supp(x, y, T)
    den = length(T)
    num = σ(union(x, y), T)
    return num/den
end

# Confidence of rule x -> y, for which x ∩ y = ∅
function conf(x, y, T)
    num = σ(union(x, y), T)
    den = σ(x, T)
    return num/den
end


# Lift of rule x -> y, for which x ∩ y = ∅
# Requires confidence has already been computed
function lift(confidence, y, T)
    den = σ(y, T)/length(T)
    return confidence/den
end

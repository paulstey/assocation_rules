# Utility functions

function make_transactions(X)
    n, p = size(X)
    X = map(string, X)

    out = Array{Array{Any, 1}, 1}(n)
    for i = 1:n
        out[i] = convert(Array{String, 1}, X[i, :])
    end
    return out
end

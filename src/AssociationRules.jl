module AssociationRules

using StatsBase
using Formatting
using Combinatorics
using Base.Threads

import Base.==
import Base.unique
import Base.display
import Base.isempty
import Base.find

export apriori, frequent, make_transactions, spade, make_sequences, sequential_rules

include("apriori.jl")
include("apriori_utils.jl")
include("parallel_tools.jl")
include("spade.jl")
include("spade_utils.jl")
include("sequential_rules.jl")

end # module

# testing FP growth in Julia
using Gallium


n1 = FPNode()
n2 = FPNode("a", 3, n1)
@code_warntype FPNode()
@code_warntype FPNode("a", 3, n1)



transacts = [["a", "b", "c"],
             ["a", "c", "d", "e"],
             ["b", "e"],
             ["b", "a", "c"],
             ["c", "d"],
             ["a", "b"],
             ["d", "c", "e"],
             ["a", "b", "c", "d"],
             ["c", "d", "e"]]

find_frequent_patterns(transacts, 0.001)

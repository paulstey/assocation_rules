library(arules)

a_list <- list(
  c(1, 2, 3),
  c(1, 2, 3),
  c(1, 2, 3),
  c(2, 3, 5), 
  c(1, 3, 4), 
  c(1, 2, 5),    
  c(2, 3, 4), 
  c(1, 4, 5),
  c(3, 4, 5)
)
trans1 <- as(a_list, "transactions")

rules <- apriori(trans1, parameter = list(
  supp = 0.2, conf = 0.01, target = "rules")
)
freq <- apriori(trans1, parameter = list(
  supp = 0.2, conf = 0.01, target = "frequent itemsets")
)

summary(rules)
inspect(rules)

summary(rules)
inspect(rules)



a_matrix <- matrix(
  c(1, 2, 3,
    1, 2, 3,
    1, 2, 3,
    2, 3, 5, 
    1, 3, 4, 
    1, 2, 5,
    2, 3, 4, 
    1, 4, 5,
    3, 4, 5), 
  ncol = 3
)

trans2 <- as(a_matrix, "transactions")

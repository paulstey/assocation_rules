library(arules)

a_list <- list(
  c(1, 2, 3),
  c(1, 2, 3),
  c(1, 2, 3),
  c(1, 2, 5),
  c(1, 3, 4), 
  c(1, 4, 5),
  c(2, 3, 4), 
  c(2, 3, 4),
  c(2, 3, 5),
  c(3, 4, 5)
)
trans1 <- as(a_list, "transactions")

rules <- apriori(trans1, parameter = list(
  supp = 0.2, conf = 0.01, target = "rules")
)
summary(rules)
inspect(rules)

freq <- apriori(trans1, parameter = list(
  supp = 0.2, conf = 0.01, target = "frequent itemsets")
)

summary(freq)
inspect(freq)


a_list <- list(
  c(1, 2),
  c(1, 3),
  c(1, 2, 3),
  c(1, 2, 4), 
  c(1, 3, 4), 
  c(1, 2, 3, 4),    
  c(1, 2, 3, 5), 
  c(2, 4, 5, 6),
  c(1, 3, 5, 6),
  c(2, 3, 4, 5, 6),
  c(1, 3, 4, 5, 6),
  c(2, 3, 4, 5, 6)
)
trans2 <- as(a_list, "transactions")


rules <- apriori(trans2, parameter = list(
  supp = 0.2, conf = 0.01, target = "rules")
)
inspect(rules)

freq <- apriori(trans2, parameter = list(
  supp = 0.2, conf = 0.01, target = "frequent itemsets")
)
inspect(freq)





# using eclat()

a_list3 <- list(
  c(1, 2, 3, 4, 5),
  c(1, 2, 3, 5, 6),
  c(1, 2, 3, 6, 7),
  c(2, 3, 5, 6, 7), 
  c(1, 3, 4, 6, 7), 
  c(1, 2, 5, 7, 8),    
  c(2, 3, 4, 8, 9), 
  c(1, 4, 5, 7, 9),
  c(3, 4, 5, 6, 8)
)
trans3 <- as(a_list3, "transactions")

itemset <- eclat(trans3, parameter = list(
  supp = 0.2)
)

rules <- ruleInduction(itemset, trans3)
inspect(rules)

freq <- apriori(trans3, parameter = list(
  supp = 0.55, conf = 0.01, target = "frequent itemsets")
)

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

# wrapper for arules.R

using RCall


function init_arules()
    R"""
    if (\"arules\" %in% install.packages() == FALSE) {
        install.packages(\"arules\", dependencies = TRUE, repos = \"http://cran.r-project.org\")
    }
    library(arules)

    all_factors <- function(dat) {
        p <- ncol(dat)
        out <- dat
        for (j in 1:p) {
            out[, j] <- factor(dat[, j])
        }
        return(out)
    }
    """
end


function make_transactions(dat::DataFrame, transact_name::String, arules = true)
    @rput dat
    rcode = "
    dat2 <- all_factors(dat)
    $transact_name <- as(dat2, \"transactions\")
    "
    # evaluate the above R code, which generates a transactions
    # whose name is specified by the `transname` argument
    reval(rcode);
end


function apriori(transact_name::String, supp = 0.2, conf = 0.01)
    rcode = "
    rules1 <- apriori($transact_name, parameter = list(supp = $supp,
                                                       conf = $conf,
                                                       target = \"rules\"))
    rules2 <- if (length(rules1) == 0) data.frame() else rules1
    "
    reval(rcode);
    @rget rules2
end

apriori("t1");

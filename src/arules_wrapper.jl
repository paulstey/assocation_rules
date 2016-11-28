# wrapper for arules.R

using RCall


function init_arules()
    R"""
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


function apriori(transact_name, supp = 0.2, conf = 0.01)
    rcode = "
    apriori($transact_name, parameter = list(supp = $supp,
                                             conf = $conf,
                                             target = \"rules\"))
    "
    reval(rcode);
end

apriori("t1");

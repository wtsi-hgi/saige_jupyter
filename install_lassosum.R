r = getOption("repos")
r["CRAN"] = "http://cran.us.r-project.org"
options(repos = r)

# install.packages('cowplot')
# install.packages('Seurat')

if (!requireNamespace("BiocManager", quietly = TRUE))
    install.packages("BiocManager")
library("BiocManager")
BiocManager::install(update=TRUE, ask=FALSE)
remotes::install_github("tshmak/lassosum",
    upgrade = 'never', force = TRUE, quiet = TRUE)


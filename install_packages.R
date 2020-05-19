r = getOption("repos")
r["CRAN"] = "http://cran.us.r-project.org"
options(repos = r)

# install.packages('cowplot')
# install.packages('Seurat')

if (!requireNamespace("BiocManager", quietly = TRUE))
    install.packages("BiocManager")
library("BiocManager")
BiocManager::install(update=TRUE, ask=FALSE)

pkgs <- c(
'RcppArmadillo',
'Matrix',
'pheatmap',
'foreach',
'doMC',
'rms',
'ROCit',
'PCAtools',
'data.table',
'rprojroot',
'rmarkdown',
'rhdf5',
'hdf5r',
'limma',
'reshape2',
'ggplot2',
'broom',
'magrittr',
'dplyr',
'tidyr',
'purrr',
'broom',
'stringr',
'tibble',
'readr',
'openxlsx',
'dendextend',
'RColorBrewer',
'gplots',
'genefilter',
'remotes',
'biomaRt',
'ensembldb',
'tximport',
'GenomicFeatures',
'Gviz',
'ggbio',
'AnnotationHub',
'edgeR',
'DESeq2',
'limma',
'BiocGenerics',
'DelayedArray',
'DelayedMatrixStats',
'S4Vectors',
'SingleCellExperiment',
'SummarizedExperiment',
'batchelor',
'caret',
'apeglm'
)


ap.db <- available.packages(contrib.url(BiocManager::repositories()))
ap <- rownames(ap.db)
fnd <- pkgs %in% ap
pkgs_to_install <- pkgs[fnd]

ok <- BiocManager::install(pkgs_to_install, update=TRUE, ask=FALSE) %in%
    rownames(installed.packages())

if (!all(fnd))
    message("Packages not found in a valid repository (skipped):\n  ",
            paste(pkgs[!fnd], collapse="  \n  "))
if (!all(ok))
    stop("Failed to install:\n  ",
         paste(pkgs_to_install[!ok], collapse="  \n  "))

#remotes::install_github("vqv/ggbiplot",
#    upgrade = 'never', force = TRUE, quiet = TRUE)

#install.packages("devtools")
#devtools::install_github('cole-trapnell-lab/leidenbase', quiet = TRUE)
#devtools::install_github('cole-trapnell-lab/monocle3', quiet = TRUE)

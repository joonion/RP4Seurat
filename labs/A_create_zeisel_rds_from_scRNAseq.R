# Zeisel mouse brain (STRT-Seq)
# https://bioconductor.org/books/3.21/OSCA.workflows/zeisel-mouse-brain-strt-seq.html

# scRNAseq 패키지의 데이터를 SeuratObject 파일로 변환하기

# 1. Bioconductor 패키지 관리자를 설치
if (!requireNamespace("BiocManager", quietly = TRUE)) {
  install.packages("BiocManager")
}

# 2. scRNAseq 설치
BiocManager::install("scRNAseq")

library(scRNAseq)
sce <- ZeiselBrainData()

brain <- CreateSeuratObject(
  counts = SingleCellExperiment::counts(sce),
  project = "ZeiselBrain",
  min.cells = 3,
  min.features = 200,
  meta.data = as.data.frame(SummarizedExperiment::colData(sce))
)

saveRDS(brain, "data/zeisel/zeisel_brain_raw.rds")

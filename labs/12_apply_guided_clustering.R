# 12_apply_guided_clustering.R
# Zeisel mouse brain RDS로 Guided Clustering workflow 다시 실행하기
#
# 입력 파일: data/zeisel/zeisel_brain_raw.rds
# 결과 폴더: output/
#
# 공식 Seurat Guided Clustering Tutorial (확인: 2026-07-13)
# https://satijalab.org/seurat/articles/pbmc3k_tutorial


# ---- 0. 패키지와 입력 파일을 준비합니다 ----
required_packages <- c("Seurat", "dplyr", "ggplot2", "patchwork")

missing_packages <- required_packages[
  !vapply(required_packages, requireNamespace, logical(1), quietly = TRUE)
]

if (length(missing_packages) > 0) {
  stop(
    "먼저 설치해야 하는 패키지: ",
    paste(missing_packages, collapse = ", ")
  )
}

library(Seurat)
library(dplyr)
library(ggplot2)
library(patchwork)

data_path <- "data/zeisel/zeisel_brain_raw.rds"
stopifnot(file.exists(data_path))


# ---- 1. RDS에서 Seurat 객체를 불러옵니다 ----
brain <- readRDS(data_path)

class(brain)
dim(brain)
Assays(brain)
Layers(brain[["RNA"]])
head(brain[[]])

# 기대 결과
# - class: Seurat
# - dimension: 18,913 features x 3,005 cells
# - RNA assay의 counts layer


# ---- 2. 저자 제공 metadata를 확인합니다 ----
names(brain[[]])
table(brain$level1class)
table(brain$level2class)

# level1class와 level2class는 분석 후 결과를 비교할 reference label입니다.
# clustering 전에 이 label을 정답처럼 사용하지 않습니다.


# ---- 3. mouse mitochondrial gene 비율을 계산합니다 ----
# Mouse gene symbol은 일반적으로 mt-로 시작합니다.
sum(grepl("^mt-", rownames(brain)))

brain[["percent.mt"]] <- PercentageFeatureSet(
  brain,
  pattern = "^mt-"
)

head(
  brain[[]][, c("nFeature_RNA", "nCount_RNA", "percent.mt")]
)


# ---- 4. QC 분포를 먼저 확인합니다 ----
qc_violin <- VlnPlot(
  brain,
  features = c("nFeature_RNA", "nCount_RNA", "percent.mt"),
  ncol = 3,
  pt.size = 0
)

qc_scatter_1 <- FeatureScatter(
  brain,
  feature1 = "nCount_RNA",
  feature2 = "nFeature_RNA"
)

qc_scatter_2 <- FeatureScatter(
  brain,
  feature1 = "nCount_RNA",
  feature2 = "percent.mt"
)

qc_violin
qc_scatter_1 + qc_scatter_2

summary(brain$nFeature_RNA)
summary(brain$nCount_RNA)
summary(brain$percent.mt)


# ---- 5. QC 기준을 적용하고 전후 세포 수를 비교합니다 ----
# 아래 값은 이 수업용 Zeisel 객체의 분포를 보고 정한 시작값입니다.
# 다른 데이터에 그대로 복사하지 않습니다.
min_features <- 1000
max_features <- 7500
max_percent_mt <- 25

keep <- brain$nFeature_RNA > min_features &
  brain$nFeature_RNA < max_features &
  brain$percent.mt < max_percent_mt

table(keep, useNA = "ifany")

cells_before_qc <- ncol(brain)

brain <- subset(
  brain,
  subset = nFeature_RNA > min_features &
    nFeature_RNA < max_features &
    percent.mt < max_percent_mt
)

cells_after_qc <- ncol(brain)
c(before = cells_before_qc, after = cells_after_qc)

VlnPlot(
  brain,
  features = c("nFeature_RNA", "nCount_RNA", "percent.mt"),
  ncol = 3,
  pt.size = 0
)


# ---- 6. LogNormalize로 정규화합니다 ----
brain <- NormalizeData(
  brain,
  normalization.method = "LogNormalize",
  scale.factor = 10000
)

Layers(brain[["RNA"]])


# ---- 7. 고변이 유전자 2,000개를 선택합니다 ----
brain <- FindVariableFeatures(
  brain,
  selection.method = "vst",
  nfeatures = 2000
)

top10_variable <- head(VariableFeatures(brain), 10)
top10_variable

variable_plot <- VariableFeaturePlot(brain)
variable_labeled <- LabelPoints(
  plot = variable_plot,
  points = top10_variable,
  repel = TRUE
)

variable_plot + variable_labeled


# ---- 8. 데이터를 scaling하고 PCA를 실행합니다 ----
brain <- ScaleData(
  brain,
  features = VariableFeatures(brain)
)

brain <- RunPCA(
  brain,
  features = VariableFeatures(brain),
  npcs = 30
)

Reductions(brain)
print(brain[["pca"]], dims = 1:5, nfeatures = 5)
VizDimLoadings(brain, dims = 1:2, reduction = "pca")
DimPlot(brain, reduction = "pca") + NoLegend()


# ---- 9. 사용할 PC 수를 확인합니다 ----
ElbowPlot(brain, ndims = 30)
DimHeatmap(
  brain,
  dims = 1:14,
  cells = 500,
  balanced = TRUE
)

# 이 실습에서는 비교 가능한 공통 시작값으로 PC 1~20을 사용합니다.
dims_to_use <- 1:20


# ---- 10. 이웃 그래프를 만들고 cluster를 찾습니다 ----
brain <- FindNeighbors(
  brain,
  dims = dims_to_use
)

brain <- FindClusters(
  brain,
  resolution = 0.5,
  random.seed = 42
)

head(Idents(brain))
table(Idents(brain))


# ---- 11. 같은 PC를 이용해 UMAP을 계산합니다 ----
brain <- RunUMAP(
  brain,
  dims = dims_to_use,
  seed.use = 42
)

cluster_umap <- DimPlot(
  brain,
  reduction = "umap",
  group.by = "seurat_clusters",
  label = TRUE,
  repel = TRUE
) + NoLegend()

cluster_umap


# ---- 12. cluster와 저자 제공 reference label을 나란히 봅니다 ----
reference_umap <- DimPlot(
  brain,
  reduction = "umap",
  group.by = "level1class",
  label = TRUE,
  repel = TRUE
) + NoLegend()

cluster_umap + reference_umap

cluster_reference <- table(
  cluster = Idents(brain),
  reference = brain$level1class
)

cluster_reference
round(prop.table(cluster_reference, margin = 1), 2)


# ---- 13. 모든 cluster의 positive marker를 찾습니다 ----
markers <- FindAllMarkers(
  brain,
  only.pos = TRUE,
  min.pct = 0.25,
  logfc.threshold = 0.25,
  max.cells.per.ident = 100,
  random.seed = 42
)

# max.cells.per.ident = 100은 60분 실습에서 계산 시간을 줄이기 위한
# subsampling 설정입니다. 최종 연구 분석에서는 제거하거나 값을 늘린 뒤
# 전체 세포를 사용한 결과와 비교합니다.

top_markers <- markers |>
  filter(p_val_adj < 0.05) |>
  group_by(cluster) |>
  slice_max(
    order_by = avg_log2FC,
    n = 5,
    with_ties = FALSE
  ) |>
  ungroup()

top_markers |>
  select(cluster, gene, avg_log2FC, pct.1, pct.2, p_val_adj)


# ---- 14. mouse brain marker 발현을 교차 확인합니다 ----
marker_panel <- c(
  "Gad1",     # interneuron
  "Slc17a7",  # excitatory neuron
  "Mbp",      # oligodendrocyte
  "Aldoc",    # astrocyte/ependymal
  "C1qa",     # microglia
  "Pdgfrb"    # mural cell
)

marker_panel %in% rownames(brain)

DotPlot(
  brain,
  features = marker_panel
) + RotatedAxis()

FeaturePlot(
  brain,
  features = marker_panel,
  ncol = 3
)

# top marker에는 초기 고변이 유전자 2,000개 밖의 gene도 포함될 수 있습니다.
# heatmap에 사용할 gene을 명시적으로 scaling합니다.
heatmap_features <- intersect(
  unique(top_markers$gene),
  rownames(brain)
)

brain_heatmap <- ScaleData(
  brain,
  features = heatmap_features,
  verbose = FALSE
)

DoHeatmap(
  brain_heatmap,
  features = heatmap_features
) + NoLegend()


# ---- 15. reference label로 해석을 검증하고 identity를 붙입니다 ----
# 교육용 데이터이므로 marker를 먼저 본 뒤 저자 제공 label과 비교합니다.
# 자신의 연구 데이터에는 이런 reference label이 없을 수 있습니다.
majority_labels <- as.data.frame(cluster_reference) |>
  filter(Freq > 0) |>
  group_by(cluster) |>
  slice_max(Freq, n = 1, with_ties = FALSE) |>
  ungroup()

new_ids <- setNames(
  as.character(majority_labels$reference),
  as.character(majority_labels$cluster)
)

new_ids
brain <- RenameIdents(brain, new_ids)

annotated_umap <- DimPlot(
  brain,
  reduction = "umap",
  label = TRUE,
  repel = TRUE
) + NoLegend()

annotated_umap


# ---- 16. 결과를 재사용할 수 있게 저장합니다 ----
dir.create("output", showWarnings = FALSE, recursive = TRUE)

saveRDS(
  brain,
  file = "output/zeisel_brain_guided_clustering.rds"
)

write.csv(
  markers,
  file = "output/zeisel_brain_markers.csv",
  row.names = FALSE
)

ggsave(
  filename = "output/zeisel_brain_umap.png",
  plot = annotated_umap,
  width = 10,
  height = 7,
  dpi = 300
)

file.exists("output/zeisel_brain_guided_clustering.rds")
file.exists("output/zeisel_brain_markers.csv")
file.exists("output/zeisel_brain_umap.png")


# ---- 실습 A. QC 기준 하나만 바꾸어 결과를 비교합니다 ----
# 1. 원본 RDS를 다시 불러옵니다.
# 2. max_percent_mt를 15 또는 35로 바꿉니다.
# 3. 남은 세포 수와 QC violin plot이 어떻게 달라지는지 기록합니다.


# ---- 실습 B. resolution 하나만 바꾸어 결과를 비교합니다 ----
# brain_test <- FindClusters(
#   brain,
#   resolution = 0.8,
#   random.seed = 42
# )
# table(Idents(brain_test))
# DimPlot(brain_test, reduction = "umap", label = TRUE)


# ---- 실습 C. cluster 하나를 근거와 함께 설명합니다 ----
# 다음 네 가지를 한 문장씩 기록합니다.
# 1. cluster 번호와 세포 수
# 2. top marker 3개
# 3. marker panel에서 확인한 발현
# 4. level1class와의 일치 또는 불일치


# ---- 17. 분석 환경을 기록합니다 ----
stopifnot(ncol(brain) > 0)
stopifnot("percent.mt" %in% names(brain[[]]))
stopifnot(all(c("pca", "umap") %in% Reductions(brain)))

sessionInfo()
packageVersion("Seurat")
packageVersion("SeuratObject")

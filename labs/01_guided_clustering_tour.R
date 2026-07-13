# 01_guided_clustering_tour.R

# ---- 필요한 패키지를 불러옵니다 · 코드 1 ----
library(dplyr)
library(Seurat)
library(patchwork)

# ---- count matrix를 읽습니다 · 코드 2 ----
pbmc.data <- Read10X(
  data.dir = "data/pbmc3k/filtered_gene_bc_matrices/hg19/"
)

# ---- count matrix를 읽습니다 · 코드 3 ----
pbmc.data[c("CD3D", "TCL1A", "MS4A1"), 1:5]

# ---- Seurat 객체를 만듭니다 · 코드 4 ----
pbmc <- CreateSeuratObject(
  counts = pbmc.data,
  project = "pbmc3k",
  min.cells = 3,
  min.features = 200
)
pbmc

# ---- count matrix는 대부분 0입니다 · 코드 5 ----
dense.size <- object.size(as.matrix(pbmc.data))
sparse.size <- object.size(pbmc.data)
dense.size / sparse.size

# ---- 미토콘드리아 유전자 비율을 계산합니다 · 코드 6 ----
pbmc[["percent.mt"]] <- PercentageFeatureSet(
  pbmc,
  pattern = "^MT-"
)

# ---- 미토콘드리아 유전자 비율을 계산합니다 · 코드 7 ----
head(pbmc@meta.data, 5)

# ---- QC 지표의 분포를 시각화합니다 · 코드 8 ----
VlnPlot(
  pbmc,
  features = c("nFeature_RNA", "nCount_RNA", "percent.mt"),
  ncol = 3
)

# ---- QC 지표 사이의 관계도 확인합니다 · 코드 9 ----
plot1 <- FeatureScatter(
  pbmc, feature1 = "nCount_RNA", feature2 = "percent.mt"
)
plot2 <- FeatureScatter(
  pbmc, feature1 = "nCount_RNA", feature2 = "nFeature_RNA"
)
plot1 + plot2

# ---- QC 조건으로 세포를 선택합니다 · 코드 10 ----
pbmc <- subset(
  pbmc,
  subset = nFeature_RNA > 200 &
    nFeature_RNA < 2500 &
    percent.mt < 5
)

# ---- 세포 간 발현량을 비교할 수 있게 정규화합니다 · 코드 11 ----
pbmc <- NormalizeData(
  pbmc,
  normalization.method = "LogNormalize",
  scale.factor = 10000
)

# ---- 세포 간 차이를 잘 보여주는 유전자를 선택합니다 · 코드 12 ----
pbmc <- FindVariableFeatures(
  pbmc,
  selection.method = "vst",
  nfeatures = 2000
)

top10 <- head(VariableFeatures(pbmc), 10)

# ---- 고변이 유전자를 시각화합니다 · 코드 13 ----
plot1 <- VariableFeaturePlot(pbmc)
plot2 <- LabelPoints(
  plot = plot1,
  points = top10,
  repel = TRUE
)
plot1 + plot2

# ---- 유전자별 값의 크기를 맞춥니다 · 코드 14 ----
all.genes <- rownames(pbmc)
pbmc <- ScaleData(pbmc, features = all.genes)

# ---- PCA를 실행합니다 · 코드 15 ----
pbmc <- RunPCA(
  pbmc,
  features = VariableFeatures(object = pbmc)
)

# ---- 어떤 유전자가 PC를 만드는지 확인합니다 · 코드 16 ----
print(pbmc[["pca"]], dims = 1:5, nfeatures = 5)

VizDimLoadings(
  pbmc,
  dims = 1:2,
  reduction = "pca"
)

# ---- PCA 공간의 세포와 유전자를 시각화합니다 · 코드 17 ----
DimPlot(pbmc, reduction = "pca")

DimHeatmap(
  pbmc,
  dims = 1,
  cells = 500,
  balanced = TRUE
)

# ---- 사용할 PC 수를 결정합니다 · 코드 18 ----
ElbowPlot(pbmc)

# ---- 비슷한 세포의 이웃 그래프를 만듭니다 · 코드 19 ----
pbmc <- FindNeighbors(pbmc, dims = 1:10)

# ---- 연결이 조밀한 세포들을 군집으로 나눕니다 · 코드 20 ----
pbmc <- FindClusters(pbmc, resolution = 0.5)

head(Idents(pbmc), 5)

# ---- UMAP을 계산하고 군집을 표시합니다 · 코드 21 ----
pbmc <- RunUMAP(pbmc, dims = 1:10)

DimPlot(pbmc, reduction = "umap")

# ---- 중간 객체를 저장할 수 있습니다 · 코드 22 ----
saveRDS(
  pbmc,
  file = "output/pbmc_tutorial.rds"
)

# ---- 한 군집의 마커를 찾습니다 · 코드 23 ----
cluster2.markers <- FindMarkers(
  pbmc,
  ident.1 = 2
)

head(cluster2.markers, n = 5)

# ---- 지정한 군집끼리 비교할 수도 있습니다 · 코드 24 ----
cluster5.markers <- FindMarkers(
  pbmc,
  ident.1 = 5,
  ident.2 = c(0, 3)
)

# ---- 모든 군집의 양의 마커를 찾습니다 · 코드 25 ----
pbmc.markers <- FindAllMarkers(
  pbmc,
  only.pos = TRUE
)

pbmc.markers %>%
  group_by(cluster) %>%
  dplyr::filter(avg_log2FC > 1)

cluster0.markers <- FindMarkers(
  pbmc,
  ident.1 = 0,
  logfc.threshold = 0.25,
  test.use = "roc",
  only.pos = TRUE
)

# ---- 마커 발현을 여러 방식으로 확인합니다 · 코드 26 ----
VlnPlot(
  pbmc,
  features = c("MS4A1", "CD79A")
)

VlnPlot(
  pbmc,
  features = c("NKG7", "PF4"),
  slot = "counts",
  log = TRUE
)

FeaturePlot(
  pbmc,
  features = c(
    "MS4A1", "GNLY", "CD3E", "CD14", "FCER1A",
    "FCGR3A", "LYZ", "PPBP", "CD8A"
  )
)

# ---- 대표 마커를 heatmap으로 비교합니다 · 코드 27 ----
pbmc.markers %>%
  group_by(cluster) %>%
  dplyr::filter(avg_log2FC > 1) %>%
  slice_head(n = 10) %>%
  ungroup() -> top10

DoHeatmap(pbmc, features = top10$gene) + NoLegend()

# ---- 군집 ID를 세포 유형 이름으로 바꿉니다 · 코드 28 ----
new.cluster.ids <- c(
  "Naive CD4 T", "CD14+ Mono", "Memory CD4 T",
  "B", "CD8 T", "FCGR3A+ Mono",
  "NK", "DC", "Platelet"
)

names(new.cluster.ids) <- levels(pbmc)
pbmc <- RenameIdents(pbmc, new.cluster.ids)

# ---- 이름을 붙인 UMAP을 확인합니다 · 코드 29 ----
DimPlot(
  pbmc,
  reduction = "umap",
  label = TRUE,
  pt.size = 0.5
) + NoLegend()

# ---- 최종 UMAP의 표시 형식을 조정할 수 있습니다 · 코드 30 ----
library(ggplot2)

plot <- DimPlot(
  pbmc,
  reduction = "umap",
  label = TRUE,
  label.size = 4.5
) +
  xlab("UMAP 1") +
  ylab("UMAP 2") +
  theme(
    axis.title = element_text(size = 18),
    legend.text = element_text(size = 18)
  )

plot
# ---- 최종 객체를 저장합니다 · 코드 31 ----
saveRDS(
  pbmc,
  file = "output/pbmc3k_final.rds"
)

# ---- 실습: 객체의 변화를 추적하세요 · 코드 32 ----
pbmc <- NormalizeData(pbmc)
pbmc <- RunPCA(pbmc)
pbmc <- FindNeighbors(pbmc, dims = 1:10)
pbmc <- FindClusters(pbmc, resolution = 0.5)
pbmc <- RunUMAP(pbmc, dims = 1:10)

# ---- 실습: 한 가지 값만 바꿔 비교하세요 · 코드 33 ----
pbmc.test <- FindClusters(pbmc, resolution = 0.8)
DimPlot(pbmc.test, reduction = "umap", label = TRUE)


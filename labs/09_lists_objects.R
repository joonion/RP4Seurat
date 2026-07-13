# 09_lists_objects.R

# ---- 1회차에서 하나의 객체를 계속 사용했습니다 · 코드 1 ----
pbmc <- NormalizeData(pbmc)
pbmc <- RunPCA(pbmc)
pbmc <- FindClusters(pbmc)
pbmc <- RunUMAP(pbmc)

# ---- 리스트는 서로 다른 객체를 함께 담습니다 · 코드 2 ----
analysis_info <- list(
  project = "pbmc3k",
  dimensions = 1:10,
  qc = data.frame(min_features = 200, max_percent_mt = 5),
  marker_genes = c("MS4A1", "NKG7", "LYZ")
)

# ---- 리스트 구조를 먼저 확인합니다 · 코드 3 ----
class(analysis_info)
length(analysis_info)
names(analysis_info)
str(analysis_info)

# ---- [ ], [[ ]], $는 리스트에서 다르게 동작합니다 · 코드 4 ----
analysis_info["project"]
analysis_info[["project"]]
analysis_info$project

# ---- 중첩된 객체는 단계적으로 탐색합니다 · 코드 5 ----
analysis_info$qc
analysis_info$qc$min_features

analysis_info[["qc"]][["min_features"]]

# ---- Seurat는 리스트보다 더 엄격한 복합 객체입니다 · 코드 6 ----
class(pbmc)
pbmc

# ---- 객체를 출력하면 요약 정보를 볼 수 있습니다 · 코드 7 ----
pbmc

# ---- assay는 발현 행렬과 관련 정보를 담습니다 · 코드 8 ----
Assays(pbmc)
DefaultAssay(pbmc)
pbmc[["RNA"]]

# ---- assay는 발현 행렬과 관련 정보를 담습니다 · 코드 9 ----
Layers(pbmc[["RNA"]])

# ---- layer에서 발현 행렬을 가져옵니다 · 코드 10 ----
counts <- LayerData(
  pbmc,
  assay = "RNA",
  layer = "counts"
)

normalized <- LayerData(
  pbmc,
  assay = "RNA",
  layer = "data"
)

# ---- metadata는 세포별 정보를 담습니다 · 코드 11 ----
head(pbmc[[]])
head(pbmc@meta.data)

# ---- metadata는 세포별 정보를 담습니다 · 코드 12 ----
pbmc$nFeature_RNA
pbmc$percent.mt

# ---- reduction은 저차원 좌표를 담습니다 · 코드 13 ----
Reductions(pbmc)
pbmc[["pca"]]
pbmc[["umap"]]

Embeddings(pbmc, reduction = "umap")[1:5, ]

# ---- identity는 현재 세포 그룹을 나타냅니다 · 코드 14 ----
head(Idents(pbmc))
levels(pbmc)
table(Idents(pbmc))

# ---- identity는 현재 세포 그룹을 나타냅니다 · 코드 15 ----
Idents(pbmc) <- "seurat_clusters"

# ---- slot에 직접 접근하기 전에 accessor를 찾습니다 · 코드 16 ----
# 내부 slot 직접 접근
pbmc@meta.data

# 의도가 명확한 accessor
pbmc[[]]
Idents(pbmc)
Embeddings(pbmc, "umap")
LayerData(pbmc, assay = "RNA", layer = "counts")

# ---- 객체를 복사해 안전하게 실험합니다 · 코드 17 ----
pbmc.test <- pbmc
pbmc.test <- FindClusters(pbmc.test, resolution = 0.8)

# ---- 객체를 복사해 안전하게 실험합니다 · 코드 18 ----
table(Idents(pbmc))
table(Idents(pbmc.test))

# ---- saveRDS와 readRDS는 객체 전체를 보존합니다 · 코드 19 ----
saveRDS(pbmc, "output/pbmc3k_final.rds")

pbmc_restored <- readRDS("output/pbmc3k_final.rds")

# ---- saveRDS와 readRDS는 객체 전체를 보존합니다 · 코드 20 ----
class(pbmc_restored)
dim(pbmc_restored)
Reductions(pbmc_restored)

# ---- 객체 접근 오류는 구조부터 확인합니다 · 코드 21 ----
pbmc[["UMAP"]]


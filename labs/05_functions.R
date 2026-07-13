# 05_functions.R

# ---- Seurat 분석은 함수의 연속입니다 · 코드 1 ----
pbmc <- NormalizeData(pbmc)
pbmc <- FindVariableFeatures(pbmc, nfeatures = 2000)
pbmc <- ScaleData(pbmc)
pbmc <- RunPCA(pbmc)

# ---- 괄호 안의 값이 인자입니다 · 코드 2 ----
FindClusters(
  object = pbmc,
  resolution = 0.5
)

# ---- 위치 인자는 순서로 의미를 결정합니다 · 코드 3 ----
round(3.14159, 2)

# ---- 위치 인자는 순서로 의미를 결정합니다 · 코드 4 ----
round(x = 3.14159, digits = 2)

# ---- 이름 있는 인자는 순서를 바꿀 수 있습니다 · 코드 5 ----
round(digits = 2, x = 3.14159)

# ---- 이름 있는 인자는 순서를 바꿀 수 있습니다 · 코드 6 ----
FindClusters(pbmc, resolution = 0.5)

# ---- 기본값은 생략했을 때 사용됩니다 · 코드 7 ----
NormalizeData(pbmc)

# ---- 기본값은 생략했을 때 사용됩니다 · 코드 8 ----
NormalizeData(
  pbmc,
  normalization.method = "LogNormalize",
  scale.factor = 10000
)

# ---- 도움말에서 함수 계약을 읽습니다 · 코드 9 ----
?NormalizeData
args(NormalizeData)

# ---- 반환값을 저장하지 않으면 다음 단계에 남지 않습니다 · 코드 10 ----
# 결과를 화면에 계산하지만 pbmc에는 다시 저장하지 않음
NormalizeData(pbmc)

# 반환된 객체를 pbmc에 다시 저장
pbmc <- NormalizeData(pbmc)

# ---- 어떤 함수는 요약값을 반환합니다 · 코드 11 ----
nrow(pbmc)
ncol(pbmc)
VariableFeatures(pbmc)

# ---- 어떤 함수는 요약값을 반환합니다 · 코드 12 ----
top10 <- head(VariableFeatures(pbmc), 10)

# ---- 함수 호출은 안쪽부터 계산됩니다 · 코드 13 ----
top10 <- head(VariableFeatures(pbmc), 10)

# ---- 긴 함수 호출은 여러 줄로 정렬합니다 · 코드 14 ----
pbmc <- CreateSeuratObject(
  counts = pbmc.data,
  project = "pbmc3k",
  min.cells = 3,
  min.features = 200
)

# ---- 파이프는 왼쪽 결과를 다음 함수로 전달합니다 · 코드 15 ----
pbmc.markers %>%
  group_by(cluster) %>%
  filter(avg_log2FC > 1) %>%
  slice_head(n = 10)

# ---- 함수 이름이 겹치면 패키지를 명시합니다 · 코드 16 ----
dplyr::filter(pbmc.markers, avg_log2FC > 1)
stats::filter(expression_values)

# ---- 오류 메시지에서 함수와 인자를 찾습니다 · 코드 17 ----
FindClusters(pbmc, resoluton = 0.5)

# ---- 간단한 사용자 정의 함수를 만듭니다 · 코드 18 ----
percent <- function(part, total) {
  part / total * 100
}

percent(25, 200)

# ---- 실습 1: 함수 호출 해체하기 · 코드 19 ----
pbmc <- FindVariableFeatures(
  pbmc,
  selection.method = "vst",
  nfeatures = 2000
)

# ---- 실습 2: 도움말로 코드 수정하기 · 코드 20 ----
pbmc <- readRDS("output/pbmc3k_final.rds")
Reductions(pbmc)
DimPlot(pbmc, reduction = "pca")
?DimPlot

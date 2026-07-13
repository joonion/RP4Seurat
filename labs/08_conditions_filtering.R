# 08_conditions_filtering.R

# ---- 1회차의 QC 필터를 해체합니다 · 코드 1 ----
pbmc <- subset(
  pbmc,
  subset = nFeature_RNA > 200 &
    nFeature_RNA < 2500 &
    percent.mt < 5
)

# ---- =와 ==는 역할이 다릅니다 · 코드 2 ----
sample <- "control"       # 값을 저장
sample == "control"       # 같은지 비교

# ---- =와 ==는 역할이 다릅니다 · 코드 3 ----
data <- data.frame(
  sample = c("control", "treatment", "control"),
  value = c(10, 20, 15)
)

library(dplyr)
dplyr::filter(data, sample = "control")   # 잘못된 비교
dplyr::filter(data, sample == "control")  # 올바른 비교

# ---- &는 두 조건을 모두 만족해야 합니다 · 코드 4 ----
n_feature <- c(150, 600, 1200, 2800)

n_feature > 200 & n_feature < 2500

# ---- |는 둘 중 하나를 만족하면 됩니다 · 코드 5 ----
cluster <- c("B", "NK", "Mono", "T")

cluster == "B" | cluster == "NK"
cluster %in% c("B", "NK")

# ---- !는 조건을 반대로 바꿉니다 · 코드 6 ----
is.na(percent_mt)
!is.na(percent_mt)

cluster %in% c("Doublet", "LowQuality")
!(cluster %in% c("Doublet", "LowQuality"))

# ---- 괄호로 조건의 의미를 분명하게 합니다 · 코드 7 ----
keep <-
  nFeature_RNA > 200 &
  nFeature_RNA < 2500 &
  percent.mt < 5

# ---- 괄호로 조건의 의미를 분명하게 합니다 · 코드 8 ----
keep <- sample == "control" &
  (cluster == "B" | cluster == "NK")

# ---- logical 인덱싱으로 행을 필터링합니다 · 코드 9 ----
keep <- cell_meta$nFeature_RNA > 200 &
  cell_meta$nFeature_RNA < 2500 &
  cell_meta$percent.mt < 5

filtered_meta <- cell_meta[keep, ]

# ---- logical 인덱싱으로 행을 필터링합니다 · 코드 10 ----
table(keep)
nrow(filtered_meta)

# ---- subset()으로 데이터 프레임을 필터링합니다 · 코드 11 ----
filtered_meta <- subset(
  cell_meta,
  nFeature_RNA > 200 &
    nFeature_RNA < 2500 &
    percent.mt < 5
)

# ---- Seurat의 subset()은 객체 전체를 함께 줄입니다 · 코드 12 ----
pbmc.filtered <- subset(
  pbmc,
  subset = nFeature_RNA > 200 &
    nFeature_RNA < 2500 &
    percent.mt < 5
)

# ---- 유전자 또는 identity도 선택할 수 있습니다 · 코드 13 ----
pbmc.cd3 <- subset(
  pbmc,
  subset = CD3D > 1
)

b_cells <- subset(
  pbmc,
  idents = "B"
)

# ---- if는 하나의 상황에 따라 흐름을 결정합니다 · 코드 14 ----
cell_count <- ncol(pbmc)

if (cell_count < 1000) {
  message("세포 수가 적습니다.")
} else {
  message("분석을 계속합니다.")
}

# ---- if는 길이 1인 조건을 기대합니다 · 코드 15 ----
percent_mt <- c(2, 6, 3)

if (percent_mt < 5) {
  print("pass")
}

# ---- if는 길이 1인 조건을 기대합니다 · 코드 16 ----
pass_qc <- percent_mt < 5

# ---- NA가 조건에 포함되면 결과도 NA입니다 · 코드 17 ----
percent_mt <- c(2, NA, 6)
percent_mt < 5

# ---- NA가 조건에 포함되면 결과도 NA입니다 · 코드 18 ----
keep <- !is.na(percent_mt) & percent_mt < 5

# ---- 필터 결과를 검증합니다 · 코드 19 ----
before <- ncol(pbmc)
after <- ncol(pbmc.filtered)

c(before = before, after = after, removed = before - after)
summary(pbmc.filtered@meta.data)

# ---- 실습 1: QC 조건 단계별 만들기 · 코드 20 ----
enough_features <- cell_meta$nFeature_RNA > 200
not_too_many <- cell_meta$nFeature_RNA < 2500
low_mito <- cell_meta$percent.mt < 5

# ---- 실습 2: 기준 변화 비교하기 · 코드 21 ----
strict <- nFeature_RNA > 300 & percent.mt < 5
lenient <- nFeature_RNA > 200 & percent.mt < 10


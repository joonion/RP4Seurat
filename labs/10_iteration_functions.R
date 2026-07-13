# 10_iteration_functions.R

# ---- 1회차 코드에도 반복 작업이 숨어 있습니다 · 코드 1 ----
FeaturePlot(
  pbmc,
  features = c("MS4A1", "GNLY", "CD3E", "CD14")
)

# ---- 반복은 같은 구조의 작업을 다시 수행합니다 · 코드 2 ----
genes <- c("MS4A1", "NKG7", "LYZ")

print(genes[1])
print(genes[2])
print(genes[3])

# ---- for는 벡터의 원소를 하나씩 가져옵니다 · 코드 3 ----
genes <- c("MS4A1", "NKG7", "LYZ")

for (gene in genes) {
  print(gene)
}

# ---- 반복 중 값의 변화를 추적합니다 · 코드 4 ----
counts <- c(10, 20, 30)
total <- 0

for (value in counts) {
  total <- total + value
  print(total)
}

# ---- 결과를 저장할 공간을 먼저 준비합니다 · 코드 5 ----
genes <- c("MS4A1", "NKG7", "LYZ")
name_lengths <- numeric(length(genes))

for (i in seq_along(genes)) {
  name_lengths[i] <- nchar(genes[i])
}

name_lengths

# ---- 분석에서는 결과를 리스트에 저장할 수 있습니다 · 코드 6 ----
genes <- c("MS4A1", "NKG7", "LYZ")
plots <- vector("list", length(genes))

for (i in seq_along(genes)) {
  plots[[i]] <- FeaturePlot(pbmc, features = genes[i])
}

names(plots) <- genes

# ---- lapply()는 반복 결과를 리스트로 반환합니다 · 코드 7 ----
plots <- lapply(
  genes,
  function(gene) {
    FeaturePlot(pbmc, features = gene)
  }
)

# ---- 익명 함수는 그 자리에서 정의합니다 · 코드 8 ----
lapply(
  genes,
  function(gene) {
    paste("marker:", gene)
  }
)

# ---- 익명 함수는 그 자리에서 정의합니다 · 코드 9 ----
lapply(genes, \(gene) paste("marker:", gene))

# ---- vapply()는 기대하는 결과 자료형을 확인합니다 · 코드 10 ----
gene_lengths <- vapply(
  genes,
  nchar,
  integer(1)
)

# ---- purrr::map()도 같은 반복 패턴을 표현합니다 · 코드 11 ----
library(purrr)

plots <- map(
  genes,
  ~ FeaturePlot(pbmc, features = .x)
)

# ---- 사용자 정의 함수는 반복되는 의도를 이름으로 만듭니다 · 코드 12 ----
qc_pass <- function(
  n_feature,
  percent_mt,
  min_feature = 200,
  max_feature = 2500,
  max_mt = 5
) {
  n_feature > min_feature &
    n_feature < max_feature &
    percent_mt < max_mt
}

# ---- 함수를 작은 예제로 먼저 검사합니다 · 코드 13 ----
qc_pass(
  n_feature = c(100, 800, 3000),
  percent_mt = c(2, 3, 1)
)

# ---- Seurat 객체를 받는 작은 함수를 만들 수 있습니다 · 코드 14 ----
summarize_qc <- function(object) {
  data.frame(
    cells = ncol(object),
    median_features = median(object$nFeature_RNA),
    median_counts = median(object$nCount_RNA),
    median_percent_mt = median(object$percent.mt)
  )
}

summarize_qc(pbmc)

# ---- 여러 샘플에 같은 요약 함수를 적용합니다 · 코드 15 ----
sample_list <- list(
  control = control_pbmc,
  treated = treated_pbmc
)

qc_tables <- lapply(sample_list, summarize_qc)
qc_summary <- do.call(rbind, qc_tables)

# ---- 함수 안에서 전역 객체에 의존하지 않습니다 · 코드 16 ----
# 피하기: 함수 밖 pbmc에 고정
plot_gene <- function(gene) {
  FeaturePlot(pbmc, features = gene)
}

# 권장: 필요한 객체를 인자로 받기
plot_gene <- function(object, gene) {
  FeaturePlot(object, features = gene)
}

# ---- 오류를 어느 반복에서 만났는지 기록합니다 · 코드 17 ----
for (gene in genes) {
  message("Plotting: ", gene)
  print(FeaturePlot(pbmc, features = gene))
}

# ---- 실습 1: for 반복문으로 QC 요약하기 · 코드 18 ----
qc_columns <- c("nFeature_RNA", "nCount_RNA", "percent.mt")

# ---- 실습 1: for 반복문으로 QC 요약하기 · 코드 19 ----
pbmc[[column_name]]
median(...)

# ---- 실습 2: 마커 plot 함수 만들기 · 코드 20 ----
plot_marker <- function(object, gene) {
  # FeaturePlot을 반환
}


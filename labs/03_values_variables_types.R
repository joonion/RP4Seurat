# 03_values_variables_types.R

# ---- 1회차 코드에는 여러 종류의 값이 있습니다 · 코드 1 ----
pbmc <- CreateSeuratObject(
  counts = pbmc.data,
  project = "pbmc3k",
  min.cells = 3,
  min.features = 200
)

# ---- 숫자는 계산할 수 있습니다 · 코드 2 ----
min_features <- 200
max_features <- 2500
feature_range <- max_features - min_features

resolution <- 0.5
resolution * 2

# ---- 숫자는 계산할 수 있습니다 · 코드 3 ----
typeof(200)
typeof(200L)

# ---- 문자는 따옴표로 감쌉니다 · 코드 4 ----
project_name <- "pbmc3k"
assay_name <- "RNA"
marker_gene <- "MS4A1"

# ---- 문자는 따옴표로 감쌉니다 · 코드 5 ----
# 객체 이름을 찾음
MS4A1

# 문자 MS4A1을 저장
"MS4A1"

# ---- logical은 참과 거짓을 나타냅니다 · 코드 6 ----
only_positive <- TRUE
show_legend <- FALSE

min_features <- 200
min_features < 500
min_features > 1000

# ---- 객체의 자료형을 확인합니다 · 코드 7 ----
project_name <- "pbmc3k"
resolution <- 0.5
only_positive <- TRUE

class(project_name)
typeof(resolution)
is.logical(only_positive)

# ---- 길이는 값의 개수를 알려줍니다 · 코드 8 ----
marker_gene <- "MS4A1"
marker_genes <- c("MS4A1", "GNLY", "CD3E")

length(marker_gene)
length(marker_genes)

# ---- 자료형은 필요할 때 변환할 수 있습니다 · 코드 9 ----
as.character(200)
as.numeric("200")
as.logical(1)

# ---- 자료형은 필요할 때 변환할 수 있습니다 · 코드 10 ----
as.numeric("MS4A1")
# Warning: NAs introduced by coercion

# ---- NA는 값이 없음을 나타냅니다 · 코드 11 ----
qc_score <- NA
is.na(qc_score)

# ---- NA가 있으면 계산 결과도 NA가 될 수 있습니다 · 코드 12 ----
qc_values <- c(100, 200, NA, 400)

mean(qc_values)
mean(qc_values, na.rm = TRUE)

# ---- factor는 범주와 순서를 저장합니다 · 코드 13 ----
cluster <- factor(c("0", "1", "0", "2"))
cluster
levels(cluster)

# ---- factor는 범주와 순서를 저장합니다 · 코드 14 ----
class(Idents(pbmc))
levels(pbmc)

# ---- 같은 모양이라도 자료형이 다를 수 있습니다 · 코드 15 ----
cluster_number <- 2
cluster_label <- "2"

cluster_number + 1
cluster_label + 1

# ---- 함수 인자의 값도 자료형이 정해져 있습니다 · 코드 16 ----
pbmc = readRDS('output/pbmc_tutorial.rds')
FindClusters(
  pbmc,
  resolution = 0.5
)

FindAllMarkers(
  pbmc,
  only.pos = TRUE
)

# ---- 실습 1: 자료형 예측하기 · 코드 17 ----
sample_name <- "PBMC 3K"
cell_count <- 2700
resolution <- 0.5
use_positive_markers <- TRUE
missing_group <- NA

# ---- 실습 2: QC 설정표 만들기 · 코드 18 ----
min_features <- 200
max_features <- 2500
max_percent_mt <- 5
species <- "human"
remove_doublets <- FALSE


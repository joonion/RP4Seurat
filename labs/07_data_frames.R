# 07_data_frames.R

# ---- 1회차에서 metadata를 확인했습니다 · 코드 1 ----
head(pbmc@meta.data, 5)

# ---- 데이터 프레임은 열마다 자료형이 다를 수 있습니다 · 코드 2 ----
cell_meta <- data.frame(
  cell = c("cell1", "cell2", "cell3"),
  nCount_RNA = c(2419, 4903, 980),
  percent_mt = c(3.02, 3.79, 1.22),
  pass_qc = c(TRUE, TRUE, FALSE)
)

# ---- 구조를 먼저 확인합니다 · 코드 3 ----
class(cell_meta)
dim(cell_meta)
names(cell_meta)
str(cell_meta)
head(cell_meta)
summary(cell_meta)

# ---- $로 한 열을 선택합니다 · 코드 4 ----
cell_meta$nCount_RNA
cell_meta$percent_mt

# ---- [[ ]]도 한 열을 벡터로 꺼냅니다 · 코드 5 ----
cell_meta[["nCount_RNA"]]

column_name <- "percent_mt"
cell_meta[[column_name]]

# ---- [ ]는 데이터 프레임 구조를 유지합니다 · 코드 6 ----
cell_meta["nCount_RNA"]
cell_meta[c("nCount_RNA", "percent_mt")]
cell_meta[1:2, c("cell", "percent_mt")]

# ---- 행 이름은 세포 식별자입니다 · 코드 7 ----
rownames(pbmc@meta.data)[1:5]

# ---- 행 이름은 세포 식별자입니다 · 코드 8 ----
all(rownames(pbmc@meta.data) == colnames(pbmc))

# ---- 새 열을 추가할 수 있습니다 · 코드 9 ----
cell_meta$high_mt <- cell_meta$percent_mt >= 5
cell_meta$log_count <- log1p(cell_meta$nCount_RNA)

# ---- 새 열을 추가할 수 있습니다 · 코드 10 ----
pbmc[["percent.mt"]] <- PercentageFeatureSet(pbmc, pattern = "^MT-")

# ---- 조건으로 행을 선택합니다 · 코드 11 ----
cell_meta[cell_meta$percent_mt < 5, ]

keep <- cell_meta$nCount_RNA > 1000 & cell_meta$percent_mt < 5
cell_meta[keep, ]

# ---- tibble은 데이터 프레임의 현대적인 변형입니다 · 코드 12 ----
library(tibble)
cell_tbl <- as_tibble(cell_meta)
cell_tbl

# ---- tibble은 행 이름보다 명시적인 열을 권장합니다 · 코드 13 ----
meta_tbl <- pbmc@meta.data %>%
  rownames_to_column(var = "cell_id") %>%
  as_tibble()

# ---- 기본 요약 통계를 계산합니다 · 코드 14 ----
mean(cell_meta$nCount_RNA)
median(cell_meta$nCount_RNA)
min(cell_meta$percent_mt)
max(cell_meta$percent_mt)
table(cell_meta$pass_qc)

# ---- CSV로 내보내고 다시 읽을 수 있습니다 · 코드 15 ----
write.csv(cell_meta, "output/cell_metadata.csv", row.names = FALSE)
metadata_copy <- read.csv("output/cell_metadata.csv")


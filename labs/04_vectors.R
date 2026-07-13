# 04_vectors.R

# ---- 1회차 코드에서 벡터를 사용했습니다 · 코드 1 ----
features <- c("nFeature_RNA", "nCount_RNA", "percent.mt")
dims <- 1:10
markers <- c("MS4A1", "GNLY", "CD3E", "CD14")

# ---- c()로 값을 결합합니다 · 코드 2 ----
marker_genes <- c("MS4A1", "CD79A", "CD37")
qc_cutoffs <- c(200, 2500, 5)

# ---- c()로 값을 결합합니다 · 코드 3 ----
length(marker_genes)
class(marker_genes)

# ---- 한 벡터는 하나의 기본 자료형을 가집니다 · 코드 4 ----
mixed <- c(200, "MS4A1", TRUE)
mixed
typeof(mixed)

# ---- 연속된 숫자를 간단히 만듭니다 · 코드 5 ----
1:10
seq(from = 0, to = 1, by = 0.2)
rep(0.5, times = 4)

# ---- 위치로 원소를 선택합니다 · 코드 6 ----
markers <- c("MS4A1", "GNLY", "CD3E", "CD14")

markers[1]
markers[c(1, 4)]
markers[2:3]

# ---- 음수 위치는 원소를 제외합니다 · 코드 7 ----
markers[-1]
markers[-c(2, 4)]

# ---- 이름으로 원소를 선택합니다 · 코드 8 ----
qc_cutoffs <- c(
  min_features = 200,
  max_features = 2500,
  max_percent_mt = 5
)

qc_cutoffs["max_percent_mt"]
names(qc_cutoffs)

# ---- 벡터 연산은 모든 원소에 적용됩니다 · 코드 9 ----
counts <- c(1000, 2500, 4000)

counts / 1000
log1p(counts)
counts > 2000

# ---- 비교 결과는 logical 벡터입니다 · 코드 10 ----
n_features <- c(150, 500, 1200, 2800)

n_features > 200
n_features < 2500
n_features > 200 & n_features < 2500

# ---- logical 벡터로 값을 필터링합니다 · 코드 11 ----
n_features <- c(150, 500, 1200, 2800)
keep <- n_features > 200 & n_features < 2500

n_features[keep]

# ---- %in%은 목록에 포함되는지 확인합니다 · 코드 12 ----
genes <- c("CD3D", "MS4A1", "GNLY", "LYZ")
b_cell_markers <- c("MS4A1", "CD79A")

genes %in% b_cell_markers
genes[genes %in% b_cell_markers]

# ---- which()는 TRUE의 위치를 반환합니다 · 코드 13 ----
percent_mt <- c(2.1, 7.3, 1.4, 6.2)
high_mt <- percent_mt >= 5

which(high_mt)
percent_mt[high_mt]

# ---- 결측값은 logical 조건에도 영향을 줍니다 · 코드 14 ----
percent_mt <- c(2.1, NA, 1.4, 6.2)
percent_mt < 5

# ---- 결측값은 logical 조건에도 영향을 줍니다 · 코드 15 ----
keep <- !is.na(percent_mt) & percent_mt < 5
percent_mt[keep]

# ---- 벡터 길이가 다르면 recycling에 주의합니다 · 코드 16 ----
c(1, 2, 3, 4) + c(10, 20)
c(1, 2, 3) + c(10, 20)

# ---- 실습 1: 유전자 목록 다루기 · 코드 17 ----
markers <- c("IL7R", "CCR7", "CD14", "LYZ", "MS4A1", "NKG7")

# ---- 실습 2: QC 조건 만들기 · 코드 18 ----
n_feature <- c(150, 400, 1300, 2700, 800)
percent_mt <- c(3, 2, 7, 1, NA)


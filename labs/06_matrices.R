# 06_matrices.R
library(Seurat)

# ---- 1회차 분석의 출발점은 행렬입니다 · 코드 1 ----
pbmc.data <- Read10X(data.dir = "data/pbmc3k/filtered_gene_bc_matrices/hg19")
pbmc.data[c("CD3D", "TCL1A", "MS4A1"), 1:5]

# ---- 행렬은 같은 자료형의 2차원 구조입니다 · 코드 2 ----
counts <- matrix(
  c(4, 0, 1, 0, 6, 0),
  nrow = 3,
  ncol = 2
)
counts

# ---- 차원을 확인합니다 · 코드 3 ----
dim(counts)
nrow(counts)
ncol(counts)
length(counts)

# ---- 행과 열에 이름을 붙입니다 · 코드 4 ----
rownames(counts) <- c("CD3D", "MS4A1", "NKG7")
colnames(counts) <- c("cell_A", "cell_B")

rownames(counts)
colnames(counts)

# ---- [행, 열] 순서로 선택합니다 · 코드 5 ----
counts[1, 2]
counts[c(1, 3), 1]
counts[, 1]
counts[2, ]

# ---- 이름으로도 선택할 수 있습니다 · 코드 6 ----
counts["MS4A1", "cell_B"]
counts[c("CD3D", "NKG7"), ]
counts[, c("cell_A", "cell_B")]

# ---- drop에 따라 결과 구조가 달라질 수 있습니다 · 코드 7 ----
counts[1, ]
counts[1, , drop = FALSE]

# ---- 행과 열 단위로 요약합니다 · 코드 8 ----
rowSums(counts)
colSums(counts)
rowMeans(counts)
colMeans(counts)

# ---- 조건을 만족하는 값의 개수를 셉니다 · 코드 9 ----
counts > 0
rowSums(counts > 0)
colSums(counts > 0)

# ---- 희소 행렬은 0이 아닌 값만 중심으로 저장합니다 · 코드 10 ----
object.size(pbmc.data)
object.size(as.matrix(pbmc.data))

# ---- 희소 행렬도 기본적인 방식으로 탐색합니다 · 코드 11 ----
class(pbmc.data)
dim(pbmc.data)
pbmc.data[1:5, 1:5]
Matrix::colSums(pbmc.data)

# ---- 행렬 방향을 항상 확인합니다 · 코드 12 ----
dim(pbmc.data)
head(rownames(pbmc.data))
head(colnames(pbmc.data))

# ---- 실습 1: 작은 count matrix 탐색하기 · 코드 13 ----
toy <- matrix(c(2, 0, 3, 0, 5, 1, 0, 0, 4), nrow = 3)
rownames(toy) <- c("CD3D", "MS4A1", "NKG7")
colnames(toy) <- c("cell1", "cell2", "cell3")

# ---- 실습 2: sparse와 dense 비교하기 · 코드 14 ----
sparse_size <- object.size(pbmc.data)
dense_size <- object.size(as.matrix(pbmc.data))
dense_size / sparse_size


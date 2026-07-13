# 02_r_and_rstudio.R

# ---- 1회차 코드에서 다시 볼 부분 · 코드 1 ----
library(Seurat)
pbmc.data <- Read10X(data.dir = "data/pbmc3k/")
pbmc <- CreateSeuratObject(counts = pbmc.data)

# ---- 콘솔은 한 줄씩 즉시 실행합니다 · 코드 2 ----
1 + 2
sqrt(16)

# ---- 스크립트는 분석 과정을 저장합니다 · 코드 3 ----
# 02_r_basics.R
sample_name <- "pbmc3k"
min_features <- 200

sample_name
min_features

# ---- 주석은 코드의 이유를 기록합니다 · 코드 4 ----
# PBMC 3K 분석에서 사용할 최소 검출 유전자 수
min_features <- 200

# ---- 주석은 코드의 이유를 기록합니다 · 코드 5 ----
# 200을 저장한다                 # 피하기
# 저품질 세포의 1차 제외 기준    # 권장

# ---- 객체는 값을 붙잡아 두는 이름입니다 · 코드 6 ----
min_features <- 200
project_name <- "pbmc3k"

# ---- 객체는 값을 붙잡아 두는 이름입니다 · 코드 7 ----
min_features
project_name

# ---- 객체 이름은 의미가 드러나게 씁니다 · 코드 8 ----
# 권장
min_features <- 200
mitochondrial_cutoff <- 5
pbmc_counts <- 2700

# 의미를 알기 어려움
x <- 200
a <- 5
data1 <- 2700

# ---- 작업 디렉터리는 상대 경로의 출발점입니다 · 코드 9 ----
getwd()
list.files()

# ---- 직접 경로를 바꾸기보다 프로젝트를 사용합니다 · 코드 10 ----
# 환경마다 달라지므로 피하기
setwd("C:/Users/name/Desktop/project")

# 프로젝트 루트 기준 상대 경로 권장
counts_path <- "data/pbmc3k/"

# ---- 함수 도움말을 직접 확인합니다 · 코드 11 ----
?CreateSeuratObject
help("CreateSeuratObject")
args(CreateSeuratObject)
example(mean)

# ---- 패키지는 설치와 불러오기가 다릅니다 · 코드 12 ----
# 컴퓨터에 한 번 설치
install.packages("Seurat")

# R 세션을 시작할 때 불러오기
library(Seurat)

# ---- 함수의 소속을 명시할 수도 있습니다 · 코드 13 ----
dplyr::filter(marker_table, avg_log2FC > 1)
Seurat::NormalizeData(pbmc)

# ---- 오류 메시지는 읽을 수 있는 정보입니다 · 코드 14 ----
library(Seuart)

# ---- 실습 2: 도움말에서 답 찾기 · 코드 15 ----
?CreateSeuratObject


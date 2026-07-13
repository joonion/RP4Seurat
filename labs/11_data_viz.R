# 11_data_viz.R

# ---- 1회차에서 marker table을 변환했습니다 · 코드 1 ----
pbmc.markers %>%
  group_by(cluster) %>%
  filter(avg_log2FC > 1) %>%
  slice_head(n = 10) %>%
  ungroup() -> top10

# ---- 파이프는 한 단계의 결과를 다음 단계로 보냅니다 · 코드 2 ----
pbmc.markers |>
  filter(avg_log2FC > 1) |>
  select(cluster, gene, avg_log2FC)

# ---- select()는 열을 선택합니다 · 코드 3 ----
marker_small <- pbmc.markers |>
  select(cluster, gene, avg_log2FC, p_val_adj)

# ---- select()는 열을 선택합니다 · 코드 4 ----
select(pbmc.markers, starts_with("pct"))
select(pbmc.markers, -p_val)

# ---- filter()는 조건에 맞는 행을 선택합니다 · 코드 5 ----
strong_markers <- pbmc.markers |>
  filter(
    avg_log2FC > 1,
    p_val_adj < 0.05,
    pct.1 > 0.25
  )

# ---- mutate()는 열을 만들거나 변환합니다 · 코드 6 ----
marker_labeled <- pbmc.markers |>
  mutate(
    significant = p_val_adj < 0.05,
    pct_difference = pct.1 - pct.2
  )

# ---- arrange()는 행의 순서를 바꿉니다 · 코드 7 ----
marker_ranked <- pbmc.markers |>
  arrange(cluster, desc(avg_log2FC))

# ---- group_by()와 summarise()는 그룹별 요약을 만듭니다 · 코드 8 ----
cluster_summary <- pbmc.markers |>
  group_by(cluster) |>
  summarise(
    marker_count = n(),
    median_log2fc = median(avg_log2FC),
    .groups = "drop"
  )

# ---- slice_max()로 그룹별 상위 항목을 선택합니다 · 코드 9 ----
top_markers <- pbmc.markers |>
  filter(avg_log2FC > 1) |>
  group_by(cluster) |>
  slice_max(
    order_by = avg_log2FC,
    n = 5,
    with_ties = FALSE
  ) |>
  ungroup()

# ---- 단계마다 결과를 확인하면 오류를 빨리 찾습니다 · 코드 10 ----
step1 <- filter(pbmc.markers, avg_log2FC > 1)
dim(step1)

step2 <- group_by(step1, cluster)
step3 <- slice_head(step2, n = 10)

# ---- ggplot2는 세 요소로 읽습니다 · 코드 11 ----
library(ggplot2)
ggplot(
  data = cell_meta,
  mapping = aes(x = nCount_RNA, y = nFeature_RNA)
) +
  geom_point()

# ---- aesthetics는 데이터를 시각 속성에 연결합니다 · 코드 12 ----
ggplot(
  cell_meta,
  aes(
    x = nCount_RNA,
    y = nFeature_RNA,
    color = percent.mt
  )
) +
  geom_point()

# ---- aesthetics는 데이터를 시각 속성에 연결합니다 · 코드 13 ----
geom_point(color = "#2563EB")

# ---- layer를 더해 plot을 완성합니다 · 코드 14 ----
ggplot(cell_meta, aes(nCount_RNA, nFeature_RNA)) +
  geom_point(alpha = 0.5) +
  geom_smooth(method = "lm", se = FALSE) +
  labs(
    x = "Total UMI count",
    y = "Detected genes",
    title = "Cell-level QC"
  ) +
  theme_minimal()

# ---- Seurat 시각화 함수도 ggplot 객체를 반환합니다 · 코드 15 ----
plot <- DimPlot(
  pbmc,
  reduction = "umap",
  group.by = "seurat_clusters",
  label = TRUE
)

class(plot)

# ---- Seurat 시각화 함수도 ggplot 객체를 반환합니다 · 코드 16 ----
plot + labs(title = "PBMC 3K clusters") + NoLegend()

# ---- group.by와 split.by는 질문이 다릅니다 · 코드 17 ----
DimPlot(
  pbmc,
  reduction = "umap",
  group.by = "cell_type"
)

# ---- group.by와 split.by는 질문이 다릅니다 · 코드 18 ----
DimPlot(
  pbmc,
  reduction = "umap",
  group.by = "cell_type",
  split.by = "sample"
)

# ---- FeaturePlot은 발현 위치를 보여줍니다 · 코드 19 ----
FeaturePlot(
  pbmc,
  features = c("MS4A1", "NKG7", "LYZ"),
  order = TRUE,
  min.cutoff = "q10",
  max.cutoff = "q90"
)

# ---- VlnPlot은 그룹별 분포를 보여줍니다 · 코드 20 ----
VlnPlot(
  pbmc,
  features = c("nFeature_RNA", "percent.mt"),
  group.by = "sample",
  pt.size = 0
)

# ---- DotPlot은 여러 유전자와 그룹을 압축해 비교합니다 · 코드 21 ----
DotPlot(
  pbmc,
  features = c("IL7R", "MS4A1", "NKG7", "LYZ"),
  group.by = "cell_type"
) + RotatedAxis()

# ---- plot을 저장할 때 크기를 명시합니다 · 코드 22 ----
umap_plot <- DimPlot(pbmc, reduction = "umap", label = TRUE)

ggsave(
  filename = "output/pbmc3k_umap.png",
  plot = umap_plot,
  width = 10,
  height = 7,
  dpi = 300
)


# Poisson-Editing-for-Shaded-Relief

本仓库用于实现与复现“基于 Poisson 编辑的地形晕渲增强”相关流程，面向低—中起伏地形（如冰川地貌）中细节不清晰的问题，提供从 DEM 预处理到结果分类的完整 MATLAB 脚本集合。

## 1. 项目目标

核心思路是：
1. 从不同光照方位生成（或读取）晕渲图；
2. 使用 Poisson 编辑逐步融合多方向晕渲信息；
3. 输出增强后的栅格与图件，用于地貌解译和分类分析。

仓库中的脚本按研究流程划分为 4 个模块，彼此可独立运行，也可串联使用。

---

## 2. 仓库结构

```text
Poisson-Editing-for-Shaded-Relief/
├── README.md
└── Reliefshading_Github/
    ├── 1_Dome_profile/
    ├── 2_LIC_Generalization/
    ├── 3_Reliefshading/
    └── 4_Mask_Classification/
```

### 2.1 `1_Dome_profile`（剖面与穹顶误差分析）
- `profile_line.m`：读取 5 条剖面 CSV（原始/处理后），批量绘图并导出高分辨率图。
- `fit_dome_effect_surface.m`：用于穹顶误差拟合（配合样本数据使用）。
- 数据示例：
  - `ErrorLine/Line1.csv ... Line5.csv`
  - `No_errorLine/No_line1.csv ... No_line5.csv`
  - `sample.xls`, `validation1.xls`

### 2.2 `2_LIC_Generalization`（LIC 地形泛化）
- `run_LIC_hillshade_comparison.m`：
  - 对 DEM 执行 LIC；
  - 对不同 LIC 长度生成晕渲并对比展示；
  - 导出 LIC 后 DEM。
- `line_integral_convolution.m`：LIC 主算法。
- `generate_hillshade.m`：晕渲生成函数。

> 注意：该模块脚本默认在“项目根目录/data/DEM_Data”读取 DEM。若直接使用当前仓库目录，请根据实际数据位置调整路径变量。

### 2.3 `3_Reliefshading`（Poisson 融合核心）
- `Poisson_hillshade.m`：主流程脚本。
  - 读取多个方位角晕渲（示例命名：`LIC15_300_45_2_1m.tif` 等）；
  - 两阶段执行 Poisson 编辑；
  - 输出 GeoTIFF 与预览图。
- `Possion_edit.m`：Poisson 编辑迭代实现（Gauss-Seidel）。
- `sanitizeHillshade.m` / `minmaxNormalize.m`：栅格清洗与归一化。
- `writeGeoTiffSafe.m`：稳健写出 GeoTIFF。
- `FigurePlotTime.m`：参数敏感性与时间统计绘图。

> 注意：`Poisson_hillshade.m` 中对函数名和数据目录有固定约定，请先核对脚本注释中的输入文件名与目录结构。

### 2.4 `4_Mask_Classification`（掩膜分类与可视化）
- `plot_IOR_classification.m`：
  - 读取 IOR 栅格；
  - 绘制空间分布、直方图和二值分类结果三联图；
  - 导出高分辨率图件。
- 示例输出：`figures/IOR_classification_3panel.png`

---

## 3. 运行环境

建议环境：
- MATLAB R2022a 或更高版本。

常用工具箱/依赖：
- Image Processing Toolbox（图像处理与部分栅格操作）；
- Mapping Toolbox（`readgeoraster` / `geotiffwrite` 等地理栅格 I/O）；
- 可选：`export_fig`（部分脚本会优先调用，用于高质量透明背景导图）。

---

## 4. 快速开始

在 MATLAB 中进入仓库后，可按模块运行：

```matlab
% 1) 剖面对比图
cd('Reliefshading_Github/1_Dome_profile');
profile_line

% 2) LIC 泛化与晕渲对比
cd('../2_LIC_Generalization');
run_LIC_hillshade_comparison

% 3) Poisson 融合
cd('../3_Reliefshading');
Poisson_hillshade

% 4) IOR 分类图
cd('../4_Mask_Classification');
plot_IOR_classification
```

---

## 5. 输入与输出说明（建议）

由于各脚本的路径约定略有差异，建议按以下原则组织数据：
- 输入数据与脚本同目录时，优先使用相对路径；
- 若使用集中数据目录（如 `data/`），统一在脚本开头设置 `projectRoot` 与 `dataDir`；
- 输出目录（如 `figures/`, `output/`, `Poisson_results/`）建议提前创建或在脚本中自动创建。

---

## 6. 常见问题

1. **报错找不到 `.tif` 或 `.csv` 文件**
   检查脚本中的 `fullfile(...)` 路径拼接是否与本地目录一致。

2. **`geotiffwrite` / `readgeoraster` 不可用**
   通常是 Mapping Toolbox 未安装。

3. **`export_fig` 不可用**
   不影响主流程，可切换到 `exportgraphics`。

4. **Poisson 融合速度慢**
   可先调大容差（`tol`）进行快速验证，再做高精度运行。

---

## 7. 引用与说明

如果本仓库对你的研究有帮助，建议在论文中说明：
- 使用了基于 Poisson 编辑的多方位晕渲融合思路；
- 并根据你的数据场景说明参数（如方位角、高度角、`tol`）配置。

如需将此仓库整理为“一键复现版”（统一入口、统一配置、自动检查输入），可在当前脚本基础上进一步封装 `main.m` + `config.m`。

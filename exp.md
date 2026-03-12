# 实验章节设计

## 1. 总体思路

本论文实验部分采用“硬件优先，通信性能支撑”的组织方式。

实验要回答两个核心问题：

1. `Joint CFR-DPD` 相比传统线性化 baseline 是否更优。
2. 在 `Joint CFR-DPD` 固定时，`MIGO / WLS / SWLS` 三种滤波器配置对最终通信性能的影响如何。

正文固定组织为：

- 表 1：功能验证结果与综合（PPA）结果
- 图 1：`SNR-BER`
- 图 2：`SNR-EVM`
- 表 2：关键 SNR 点下的 `BER / EVM` 汇总


## 2. 图设计

### 图 1：SNR-BER

固定滤波器为 `MIGO`，比较六种线性化方式：

- `NoCFR+NoDPD`
- `HC-only`
- `DPD-only`
- `Volterra-only`
- `HC+Volterra`
- `Joint CFR-DPD`

图的作用是回答：在同一滤波前端下，联合模型相比传统 CFR/DPD baseline 是否具有更好的端到端误码性能。


### 图 2：SNR-EVM

固定滤波器仍为 `MIGO`，比较与 BER 图完全相同的六种线性化方式：

- `NoCFR+NoDPD`
- `HC-only`
- `DPD-only`
- `Volterra-only`
- `HC+Volterra`
- `Joint CFR-DPD`

图的作用是补足 BER 的解释能力。BER 反映通信链路最终结果，EVM 更直接反映发射链路线性化质量，因此 `SNR-EVM` 作为本论文的机制图。


## 3. 表设计

### 表 1：功能验证结果与综合（PPA）结果

同一张表中同时覆盖 `MIGO` 与 `Joint CFR-DPD`。

建议列项：

- 模块
- 功能验证状态
- 关键一致性指标
- 时钟目标
- 综合状态
- `total_cells`
- `total_area`
- 备注

其中：

- `Joint CFR-DPD` 的功能验证可使用现有 RTL 顶层回归结果，如 `BER=0`、`vector mismatch=0`、`MAE=0`
- `MIGO` 的功能验证可使用现有 testbench 通过结果
- PPA 统一采用 prototype synthesis 口径，明确说明不是 signoff 结果


### 表 2：关键 SNR 点下的 BER / EVM 汇总

固定线性化方式为 `Joint CFR-DPD`，比较三种滤波器：

- `MIGO`
- `WLS`
- `SWLS`

每个关键 SNR 点下同时给出：

- `BER`
- `EVM`

该表的作用是：

- 用定量数值体现不同滤波器配置在联合线性化下的差异
- 支撑“选择哪种滤波器前端更优”的结论

关键 SNR 点建议从首次完整 sweep 后选取 `3` 个代表点：

- 低 SNR 点
- 中间转折点
- 高 SNR 点


## 4. baseline 与命名规范

论文正文、图题、图例统一使用以下名字：

- `NoCFR+NoDPD`
- `HC-only`
- `DPD-only`
- `Volterra-only`
- `HC+Volterra`
- `Joint CFR-DPD`

与当前代码 backend 的对应关系为：

- `NoCFR+NoDPD` -> `passthrough`
- `HC-only` -> `hc_only`
- `DPD-only` -> `dpd_only`
- `Volterra-only` -> `volterra_only`
- `HC+Volterra` -> `hc_plus_volterra`
- `Joint CFR-DPD` -> `joint_cfr_dpd`

当前默认 BER 实验矩阵中已经存在：

- `migo_joint_cfr_dpd`
- `wls_joint_cfr_dpd`
- `swls_joint_cfr_dpd`
- `migo_no_cfr_dpd`
- `migo_hc_no_dpd`
- `migo_hc_volterra`
- `migo_no_cfr_volterra`

为完成图 1 和图 2 的六线性化对比，还需要额外补一个 `MIGO + NoCFR+NoDPD` case，即：

- 建议新增 case id：`migo_no_cfr_no_dpd`
- 对应 `backend_mode`：`passthrough`


## 5. 数据来源

### 图 1 / 图 2

来源于 `data/BER-SNR/*.mat`，需要至少包含：

- `snr_range`
- `ber_curve_by_method`
- `case_ids`
- `case_configs`

同时需要保证同一批 sweep 能导出或重构：

- `EVM vs SNR`


### 表 2

来源于同一批 `BER / EVM` sweep 结果，从完整 `SNR` 曲线中抽取关键点。


### 表 1

来源于以下结果文件：

- RTL 功能验证日志
- `rtl_ber_eval.csv`
- `qor_summary.csv`
- `stat.rpt`


## 6. 实验结论预期

本章节最终希望形成以下结论链条：

1. `Joint CFR-DPD` 在固定 `MIGO` 前端下，相比传统 CFR / DPD baseline 在 `BER` 和 `EVM` 上具有更优表现。
2. 在 `Joint CFR-DPD` 固定时，`MIGO / WLS / SWLS` 三种滤波器配置会表现出不同的 `BER / EVM` 水平，从而支撑滤波器选择结论。
3. `MIGO` 与 `Joint CFR-DPD` 都能够通过 RTL / synthesis 验证，具备硬件部署可行性。


## 7. 当前状态

当前仓库已经具备的基础条件：

- `Joint CFR-DPD` 的 RTL 功能验证结果
- `Joint CFR-DPD` 的 frontend / mapped synthesis 流程
- BER 多 case 主循环
- `joint_cfr_dpd / hc_only / dpd_only / volterra_only / hc_plus_volterra / passthrough` 后端能力

当前仍需补齐的最小实验项：

- `MIGO + NoCFR+NoDPD` baseline case
- `SNR-EVM` 数据导出与绘图
- 关键 SNR 点的最终选点与汇总

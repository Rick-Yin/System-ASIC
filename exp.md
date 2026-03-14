# 实验章节设计

## 1. 总体思路

本论文实验部分采用“硬件优先，通信性能支撑”的组织方式。

实验要回答两个核心问题：

1. `Joint CFR-DPD` 相比传统线性化 baseline 是否更优。
2. 在 `Joint CFR-DPD` 固定时，`MIGO / WLS / SWLS` 三种滤波器配置对最终通信性能的影响如何。

正文固定组织为：

- 表 1：功能验证结果
- 图 1：`SNR-BER`
- 图 2：`SNR-EVM`
- 表 2：关键 SNR 点下的 `BER / EVM` 汇总


## 2. 图设计

### 图 1：SNR-BER

固定滤波器为 `MIGO`，比较六种线性化方式，并按 `MCS=5 / 9 / 13` 分成三个子图：

- `NoCFR+NoDPD`
- `HC-only`
- `DPD-only`
- `Volterra-only`
- `HC+Volterra`
- `Joint CFR-DPD`

图的作用是回答：在同一滤波前端下，联合模型相比传统 CFR/DPD baseline 是否具有更好的端到端误码性能，并观察该结论在 `QPSK / 16QAM / 64QAM` 下是否稳定。


### 图 2：SNR-EVM

固定滤波器仍为 `MIGO`，比较与 BER 图完全相同的六种线性化方式，并按 `MCS=5 / 9 / 13` 分成三个子图：

- `NoCFR+NoDPD`
- `HC-only`
- `DPD-only`
- `Volterra-only`
- `HC+Volterra`
- `Joint CFR-DPD`

图的作用是补足 BER 的解释能力。BER 反映通信链路最终结果，EVM 更直接反映发射链路线性化质量，因此 `SNR-EVM` 作为本论文的机制图，并用于解释不同调制阶数下的性能差异。


## 3. 表设计

### 表 1：功能验证与关键实现指标

表 1 同时展示功能验证与 `DC + PT` 的关键实现指标，但只保留高信息密度字段，不再放入 `pass/fail`、`total cells`、统一时钟目标这类冗余信息。

表 1 采用统一列布局：

- 模块
- 顶层验证
- 结构级验证
- 单元面积
- 总功耗
- `WNS/WHS`

其中：

- 顶层验证统一展示 `top vector bit-exact` 的“正确数量 / 总数”
- 结构级验证在同一个单元格内按模块分别展开关键子项
- `JCFR-DPD` 结构级列出 `6` 个基础算子
- `MIGO` 结构级列出 `2` 个关键微结构
- 单元面积来自 `DC` 的 mapped/netlist 统计结果
- 总功耗来自 `PT` 基于切换活动的功耗分析结果
- 时序统一压缩为 `WNS / WHS`，分别对应 setup 与 hold 的最差裕量

当前建议的 Markdown 草表如下：

| 模块 | 顶层验证 | 结构级验证 | 单元面积 | 总功耗 | `WNS/WHS` |
|---|---:|---|---:|---:|---:|
| `MIGO` | `512 / 512` | 常数系数乘加路径：`256 / 256`<br>末级舍入与右移输出：`256 / 256` | `待补` | `待补` | `待补` |
| `JCFR-DPD` | `261 / 261` | 有符号饱和：`3110 / 3110`<br>RNE 算术右移：`3221 / 3221`<br>RNE 有符号除法：`3679 / 3679`<br>2 的幂重定标：`8757 / 8757`<br>整数 hard-sigmoid：`5326 / 5326`<br>WKV LUT 查表：`5488 / 5488` | `待补` | `待补` | `待补` |

建议表注明确：

- 顶层验证列中的分母表示 `bit-exact` 对比的输出样本数或输出向量数
- 结构级验证列中的分母表示该验证项对应的定向测试用例总数
- `MIGO` 顶层统计对象为有效输出样本
- `JCFR-DPD` 顶层统计对象为输出向量帧
- 单元面积建议统一为标准单元总面积
- 总功耗建议统一为同一工作点下的 total power
- `WNS/WHS` 建议以 `ns` 为单位，写成 `x.xx / y.yy`


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

当前关键 SNR 点固定为：

- `-5 dB`
- `15 dB`

表 2 的行组织建议为：

- `MCS`
- 调制方式
- 滤波器

其中 `MCS=5 / 9 / 13` 分别对应 `QPSK / 16QAM / 64QAM`。


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

- `migo_no_cfr_no_dpd`
- `migo_hc_no_dpd`
- `migo_no_cfr_dpd`
- `migo_no_cfr_volterra`
- `migo_hc_volterra`
- `migo_joint_cfr_dpd`
- `wls_joint_cfr_dpd`
- `swls_joint_cfr_dpd`


## 5. 数据来源

### 图 1 / 图 2

来源于 `data/BER-SNR/ber_compare_MCS_*.mat`，需要至少包含：

- `snr_range`
- `ber_curve_by_method`
- `evm_curve_by_method`
- `case_ids`
- `case_configs`


### 表 2

来源于同一批 `BER / EVM` sweep 结果，从完整 `SNR` 曲线中抽取 `-5 dB` 和 `15 dB` 两个关键点。


### 表 1

来源于以下结果文件：

- `MIGO` 顶层 bit-exact 日志
- `MIGO` 顶层 bit-exact 汇总：`rtl_vec_eval.csv`
- `MIGO` 微结构验证汇总：`migo_structure_validation.csv`
- `JCFR-DPD` 顶层 bit-exact 日志
- `JCFR-DPD` 顶层 bit-exact 汇总：`rtl_ber_eval.csv`
- `JCFR-DPD` 结构级验证汇总：`l0_equivalence_table.csv`
- `DC` 面积报告：如 `area.rpt`
- `PT` 功耗报告：如 `power_pt.rpt`
- `PT` setup 时序报告：如 `pt_timing_max.rpt`
- `PT` hold 时序报告：如 `pt_timing_min.rpt`


## 6. 实验结论预期

本章节最终希望形成以下结论链条：

1. `Joint CFR-DPD` 在固定 `MIGO` 前端下，相比传统 CFR / DPD baseline 在 `BER` 和 `EVM` 上具有更优表现。
2. 在 `Joint CFR-DPD` 固定时，`MIGO / WLS / SWLS` 三种滤波器配置会表现出不同的 `BER / EVM` 水平，从而支撑滤波器选择结论。
3. `MIGO` 与 `Joint CFR-DPD` 都能够通过顶层与结构级功能验证，从而支撑后续硬件实现结论。


## 7. 当前状态

当前仓库已经具备的基础条件：

- `Joint CFR-DPD` 的 RTL 功能验证结果
- `Joint CFR-DPD` 的 frontend / mapped synthesis 流程
- BER 多 case 主循环
- `joint_cfr_dpd / hc_only / dpd_only / volterra_only / hc_plus_volterra / passthrough` 后端能力

当前仍需补齐的最小实验项：

- 跑完 `MCS=5 / 9 / 13` 三套 sweep 并固化结果
- 生成最终论文图版与表格数值

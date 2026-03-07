# A线落地设计草稿（Stage化联合核 + Exponent Scheduler + Ring Buffer）

## 0. 文档目的
本草稿用于锁定第四章 A 线实现方案，作为后续代码改造、功能验证、PPA 验证和论文写作的统一执行依据。

目标约束：
- 主目标：时序闭合优先（500 MHz，2.0 ns 时钟目标）
- 风险偏好：高风险高收益
- 精度边界：严格等效（BER/EVM 不允许实质退化，仅允许统计波动）
- 章节叙事：跨层协同（算法-定点-微架构-综合）

## 1. 基线快照（当前实现）

### 1.1 关键配置与维度
- 时序目标：`CLK_PERIOD_NS=2.0`，输入/输出延时 0.20 ns（本地仓库不再内置 DC 约束脚本）
- 约束重点：`set_max_transition 0.15`，`set_max_fanout 8`（由外部 DC/PT 脚本管理）
- 联合核维度：
  - `IN_DIM=2`
  - `MODEL_DIM=6`
  - `LAYER_NUM=2`
  - `OUT_DIM=2`
  - `KERNEL_SIZE=4`
  - `HIDDEN_SZ=18`
  - `RES_EXP=-6`, `RES_BITS=8`
  - `IO_EXP_IN=-11`, `IO_EXP_OUT=-11`
  - `WKV_LUT_NUMEL=256`
  - 来源：`vsrc/Joint-CFR-DPD/include/rwkvcnn_pkg.sv`

### 1.2 当前数据路径组织
- 顶层为单 FSM：`S_IDLE -> S_IP -> S_ATT -> S_FFN -> S_OP -> S_OUT`
- 组合密集段集中在 `S_ATT` 与 `S_FFN`：
  - 多段矩阵乘、WKV 更新、门控和残差在单拍中串接
  - `requant_pow2_signed(...)` 调用分散在大量局部路径
- 历史缓存 `att_hist/ffn_hist` 采用逐元素 shift（`for k=0..KERNEL_SIZE-2` 搬移）
- 代码位置：`vsrc/Joint-CFR-DPD/top/rwkvcnn_top.sv`

### 1.3 与第四章指标绑定的基线点
- 论文第四章基线协议：`ssg0p72vm40c`、SAIF/VCD、64QAM、AWGN、SNR 0~35 dB
- 关键 SNR 点（Proposed Joint）：
  - 10 dB: BER `1.677e-2`, EVM `6.360%`
  - 20 dB: BER `2.812e-3`, EVM `3.377%`
  - 30 dB: BER `4.714e-4`, EVM `1.994%`
- 来源：`Latex/Chapter/chap4_SystemImplement.tex`

## 2. A线总体方案

A 线包含 3 个协同改造：
1. Stage 化联合核（打散关键路径）
2. Exponent Scheduler（统一定点指数契约）
3. Ring Buffer 化 history（降低搬移/切换/布线压力）

三者必须一起设计：
- 仅做 Stage 化可能导致定点边界漂移
- 仅做 Ring Buffer 难以显著改善最坏路径
- 仅做指数统一无法解决组合链过长

## 3. 改造一：Stage化联合核

### 3.1 新流水阶段定义（建议 6 段）
- `STG0_IP`: input projection（原 `S_IP`）
- `STG1_TS_MIX`: time-shift depthwise + time-mix（xk/xv/xr）
- `STG2_QKV_GATE`: key/value/receptance 投影 + gate
- `STG3_WKV`: WKV 查表更新 + y_wkv 计算 + state 写回
- `STG4_OUT_MIX`: attention output 投影/FFN 核心乘加与残差
- `STG5_OP`: output projection + 打包输出

说明：
- 首版允许 ATT 与 FFN 保持串行语义，但在 each block 内采用 stage pipeline。
- 第二版可把 ATT/FFN 做交错执行（仅在首版稳定后考虑）。

### 3.2 Stage 边界信号
每段统一使用：
- `stgN_valid`, `stgN_ready`
- `stgN_vec`（向量数据）
- `stgN_meta`（`blk_idx`、`phase(att/ffn)`、exp 标签）

约束：
- 保证单输入帧在流水中严格有序
- 允许 backpressure，禁止丢帧与重放

### 3.3 预期收益
- 将 `S_ATT/S_FFN` 单拍组合链切断为多拍
- 降低 WNS/TNS 压力，提升 2.0 ns 下收敛概率
- 为后续 PPA 对比提供清晰“每 stage 代价”解释维度

## 4. 改造二：Exponent Scheduler（指数调度器）

### 4.1 设计原则
把分散在各处的 `requant_pow2_signed` 指数选择，提升为“阶段契约”。

阶段契约字段：
- `exp_in`: 输入指数
- `exp_mid`: 中间乘加指数（含 guard-bit 预算）
- `exp_out`: 输出指数
- `bits_out`: 输出位宽
- `sat_mode`: 饱和策略（signed/unsigned）

### 4.2 首版契约表（固定值，后续可微调）
- STG0_IP:
  - `exp_in = IO_EXP_IN`
  - `exp_mid = IO_EXP_IN + INPUT_PROJ_W_EXP`
  - `exp_out = RES_EXP`
  - `bits_out = RES_BITS`
- STG1_TS_MIX:
  - `exp_in = RES_EXP`
  - `exp_out = RES_EXP`
- STG2_QKV_GATE:
  - key 路径输出到 `WKV_LOG_EXP`
  - value/receptance 路径分别到 `EXP_V / EXP_R`
- STG3_WKV:
  - LUT 查表、`aa/bb` 更新在固定 `A_BITS/B_BITS` 范围
  - `y_wkv` 输出到 `EXP_V`
- STG4_OUT_MIX:
  - 输出统一收敛回 `RES_EXP`
- STG5_OP:
  - `exp_out = IO_EXP_OUT`

### 4.3 落地策略
- 不改数学公式，只改“何时 requant / 在哪段 requant”。
- 首版全部契约硬编码于顶层参数与常量表，避免引入额外运行时控制。
- 二版再考虑自动求 exp（来自离线统计）。

## 5. 改造三：Ring Buffer化 history

### 5.1 现状问题
当前 `att_hist/ffn_hist` 每拍执行线性 shift：
- 切换活动高
- 扇出与布线压力大
- 不利于时序

### 5.2 目标结构
- 数据阵列保留：`hist[layer][channel][KERNEL_SIZE]`
- 新增头指针：`hist_head_att[layer][channel]`, `hist_head_ffn[layer][channel]`
- 写入：只写 `head`
- 读取：按 `(head + offset) mod KERNEL_SIZE` 取样

### 5.3 行为等效定义
- 逻辑上与“左移一位 + 尾写入当前样本”完全等效
- 等效验证通过标准：逐拍比较 `xx[c]` 与后续路径输出一致

## 6. 代码改造清单（后续实施蓝图）

### 6.1 主要文件
- `vsrc/Joint-CFR-DPD/top/rwkvcnn_top.sv`（核心重构）
- `vsrc/Joint-CFR-DPD/common/quant_utils_pkg.sv`（必要时新增 helper，不破坏旧接口）
- `flow/filelists/joint.f`（若新增模块需登记）

### 6.2 建议新增模块（可选）
- `vsrc/Joint-CFR-DPD/core/exp_scheduler.sv`
- `vsrc/Joint-CFR-DPD/core/history_ring.sv`
- `vsrc/Joint-CFR-DPD/core/pipeline_stage_regs.sv`

### 6.3 实施顺序（必须按序）
1. Phase A：只做 Stage 切分，不改 history，不改 exp 规则
2. Phase B：引入 Exponent Scheduler 契约化
3. Phase C：替换为 Ring Buffer
4. Phase D：联合回归与 PPA 评估

## 7. 功能验证计划

### 7.1 验证分层
- L0（算子级）：`requant`, `hardsigmoid`, `wkv_lut_lookup` 单元向量测试
- L1（阶段级）：每个 stage 输出和基线版中间量比较
- L2（顶层级）：端到端 in/out 序列一致性

### 7.2 判据
- 严格等效目标：
  - 中间向量与输出向量 bit-exact
  - 若存在不可避免重排，仅允许在预定义定点容差内（需记录并解释）
- 协议一致：valid/ready 下无死锁、无丢包、无重复输出

### 7.3 建议测试集
- 随机输入（覆盖幅度边界、符号切换）
- 峰值输入（接近饱和）
- 长序列输入（覆盖 WKV 状态累积）
- 回放第四章仿真激励窗口

## 8. PPA验证计划

### 8.1 DC流程
外部 DC/PT flow（本仓库仅保留本地 Yosys 预综合流）：
- 外部服务器上的目标 `run_*.tcl`
- 外部服务器上的约束与库配置
- DC/PT 路径只做综合与时序分析；功能验证不再走 VCS 重跑

### 8.2 指标
- 时序：WNS、TNS、violating paths
- 面积：comb/sequential/total
- 功耗：internal/switching/leakage/total

### 8.3 验收阈值（A线）
- 必达：2.0ns 下可收敛或显著改善 TNS
- 必达：BER/EVM 不实质退化
- 优选：在时序改善基础上不显著增大面积/功耗

## 9. 风险与回滚

风险1：Stage 切分引入控制复杂度导致吞吐下降
- 回滚：先固定 4-stage 简化版本

风险2：指数契约导致局部精度下降
- 回滚：将该路径恢复为旧版 requant 规则

风险3：Ring Buffer 索引错误导致隐性功能偏差
- 回滚：保留 shift 版本编译开关（`ifdef HIST_SHIFT_BASELINE`）

## 10. 第四章写作映射（实现完成后）

写作结构建议：
1. 结构重构：从单状态串行到阶段化流水
2. 定点一致性：指数调度器如何保证跨层等效
3. 存储组织：Ring Buffer 如何降低实现代价
4. 实验结果：功能等效 + PPA + BER/EVM 三位一体

建议新增图表：
- 图A：Stage 化联合核数据流图
- 图B：Exponent Scheduler 契约表
- 图C：Shift vs Ring Buffer 数据访问示意
- 表A：改造前后 WNS/TNS/Area/Power 对比
- 表B：关键 SNR 点 BER/EVM 对比

## 11. 执行日志模板（后续代码阶段使用）
- [日期] 完成 Phase A，提交基线对比报告
- [日期] 完成 Phase B，提交指数契约差异报告
- [日期] 完成 Phase C，提交 Ring Buffer 等效报告
- [日期] 完成 Phase D，提交最终 QoR 与系统指标汇总

---

本草稿是 A 线代码实施的冻结输入。后续任何改动应先更新本文件中的“契约表/验收阈值/回滚策略”。

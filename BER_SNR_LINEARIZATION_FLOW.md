# BER-SNR 联合滤波/线性化实验流程

本文档对应当前 `msrc/main.m` 的实现：滤波器在 MATLAB 中重建，CFR/DPD 部分通过 `MATLAB -> CSV/JSON -> Python -> CSV/JSON -> MATLAB` 外挂执行，然后继续走 PA、信道和接收机，最终输出 BER 曲线。

## 1. 当前实验矩阵

`msrc/utils/buildDefaultBerExperimentCases.m` 里默认启用 8 个 case：

- `migo_no_cfr_no_dpd`
- `migo_hc_no_dpd`
- `migo_no_cfr_dpd`
- `migo_no_cfr_volterra`
- `migo_hc_volterra`
- `migo_joint_cfr_dpd`
- `wls_joint_cfr_dpd`
- `swls_joint_cfr_dpd`

它们分别组合了：

- 滤波器：`MIGO / WLS / SWLS`
- 线性化模式：`joint_cfr_dpd / dpd_only / hc_only / hc_plus_volterra / volterra_only`

## 2. 目录约定

推荐把 BER 实验相关输入整理成下面的结构：

```text
System-ASIC/
├── data/
│   ├── ber_coeff_workspace/
│   │   ├── MIGO/run_summary.json
│   │   ├── WLS/run_summary.json
│   │   └── SWLS/run_summary.json
│   └── linear_backend_exchange/
│       └── <case_id>/iter_001/
│           ├── input_signal.csv
│           ├── input_meta.json
│           ├── output_signal.csv
│           └── output_meta.json
├── msrc/
│   ├── main.m
│   └── utils/
└── psrc/
    └── ber_linear_backend.py
```

其中：

- `data/ber_coeff_workspace/` 放滤波器设计结果，只需要 `run_summary.json`
- 当前 `main.m` 也会优先尝试从 `msrc/FilterInfo/method-*/run_summary.json` 自动解析三份滤波器结果
- `data/linear_backend_exchange/` 是运行时中间文件，不需要手工维护，已在 `.gitignore` 中忽略

## 3. 运行前准备

### 3.1 滤波器结果

可选的两种放置方式：

1. 复制到 `data/ber_coeff_workspace/`：

- `data/ber_coeff_workspace/MIGO/run_summary.json`
- `data/ber_coeff_workspace/WLS/run_summary.json`
- `data/ber_coeff_workspace/SWLS/run_summary.json`

2. 保持在 `msrc/FilterInfo/method-*/run_summary.json`，由 `main.m` 自动探测。

如果你不想用这两种默认路径，也可以在 `msrc/main.m` 的 `config.filterExternalJsons` 里填绝对路径。

### 3.2 联合 CFR-DPD 模型

`joint_cfr_dpd` case 默认读取：

- `vsrc/rom/manifest.json`
- `vsrc/rom/bin/`

也就是量化后 joint 模型的 manifest 和二进制权重。如果这两部分缺失，`joint_cfr_dpd` case 无法运行。

### 3.3 Python 依赖

`psrc/ber_linear_backend.py` 至少依赖：

- `numpy`
- `torch`（仅 `joint_cfr_dpd` 需要）

## 4. 执行方式

在 MATLAB 中进入 `msrc/` 后运行：

```matlab
main
```

当前主流程是：

1. 读取三份外部滤波器 `run_summary.json`
2. 依次运行 `MCS=5 / 9 / 13`
3. 为每个 case 选择激活的 FIR 系数
4. `Transmitter` 生成 `tx_sum` 与参考星座
5. `applyLinearizationBackend` 把 `tx_sum` 写成 `CSV/JSON`
6. Python 后端执行 `joint_cfr_dpd / passthrough / hc / dpd / volterra`
7. MATLAB 读回 `tx_lin`
8. `PA -> Channel -> Receiver`
9. 扫描整条 `SNR` 范围并同时保存 `BER` 与 `EVM`
10. 生成图 1、图 2 与表 2 对应的论文产物

注意：当前实现是“每个 `MCS × case × iter` 只调用一次 Python 后端”，然后同一份 `tx_lin` 复用于全部 SNR 点，所以 SNR 扫描不会重复跑 CFR/DPD。

## 5. 产物输出

### 5.1 中间交换文件

每个 case 每次迭代都会在 `data/linear_backend_exchange/` 下生成：

- `input_signal.csv`
- `input_meta.json`
- `output_signal.csv`
- `output_meta.json`

这部分用于：

- 检查 MATLAB/Python 接口是否一致
- 单独调试某个 case 的线性化效果
- 固化和复现实验输入输出

### 5.2 BER 汇总文件

`saveData` 会在 `data/BER-SNR/` 下写出 `ber_compare_MCS_<mcs>_seed_<seed>.mat`，核心内容包括：

- `snr_range`
- `ber_curve_by_method`
- `evm_curve_by_method`
- `method_names`
- `case_ids`
- `compare_results`
- `case_configs`

其中 `method_names` 现在实际对应 case 名称。

## 6. 各 backend 的含义

- `joint_cfr_dpd`：调用量化 joint 模型
- `hc_only`：仅做 hard clipping
- `dpd_only`：当前是基于已知 PA 模型的迭代逆补偿，不是 LUT-DPD
- `volterra_only`：仅做 Volterra 预失真
- `hc_plus_volterra`：先 hard clipping，再 Volterra

## 7. 目前已经打通到什么程度

当前代码层面已经完成：

- 外部 `MIGO / WLS / SWLS` 滤波器加载
- `MCS=5 / 9 / 13` 批量主循环
- BER / EVM 多 case 主循环
- MATLAB/Python 文件交换接口
- `passthrough / hc_only / dpd_only / volterra_only / hc_plus_volterra / joint_cfr_dpd` Python 后端可执行
- 图 1、图 2、表 2 的产物生成脚本

如果后续你要继续往链路里加入更多 baseline，建议直接扩展：

- `msrc/utils/buildDefaultBerExperimentCases.m`
- `psrc/ber_linear_backend.py`

这样不会破坏当前主循环结构。

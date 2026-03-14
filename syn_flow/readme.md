# DC / PT Flow 使用说明

当前 `syn_flow` 目录只保留两套设计共用的新 Synopsys flow：

- `migo`
- `joint_cfr`

## 目录结构

```text
syn_flow/
├── common/
│   ├── dc_main.tcl
│   ├── pt_main.tcl
│   ├── run_dc.sh
│   └── run_pt.sh
├── designs/
│   ├── migo/
│   │   ├── config.tcl
│   │   ├── constraints.sdc
│   │   └── tb/tb_migo_saif.sv
│   └── joint_cfr/
│       ├── config.tcl
│       ├── constraints.sdc
│       └── tb/tb_joint_saif.sv
├── run_migo_dc.sh
├── run_migo_pt.sh
├── run_joint_dc.sh
└── run_joint_pt.sh
```

## 整体流程

两套设计都走同一条主流程：

1. **DC 综合**
   - 读取 `flow/filelists/*.f`
   - 按设计配置加载 `top`、约束、库、搜索路径
   - 执行 `compile_ultra -no_autoungroup`
   - 导出：
     - `mapped/<top>-mapped.v`
     - `mapped/<top>-mapped.ddc`
     - `mapped/<top>-mapped.sdc`
   - 生成 QoR / area / timing / constraints 报告

2. **门级仿真生成 SAIF**
   - `migo`：使用 `syn_flow/designs/migo/tb/tb_migo_saif.sv`
   - `joint_cfr`：使用 `syn_flow/designs/joint_cfr/tb/tb_joint_saif.sv`
   - `joint_cfr` 在仿真前会自动调用：
     - `python3 psrc/gen_golden_from_rwkv_quan.py`
   - VCS 编译门级网表 + 标准单元仿真模型 + testbench
   - 运行仿真并导出 `power/<top>.saif`

3. **PT 时序 / 功耗分析**
   - 读取 DC 导出的 `mapped.v` 与 `mapped.sdc`
   - 读取门级仿真导出的 SAIF
   - 输出：
     - `reports/pt_timing_max.rpt`
     - `reports/pt_timing_min.rpt`
     - `reports/pt_constraints.rpt`
     - `reports/power_pt.rpt`
     - `reports/switching_activity.rpt`

## 运行产物位置

每次运行都会创建：

```text
syn_flow/runs/<design>/
├── dc/
├── logs/
├── mapped/
├── power/
└── reports/
```

其中：

- `logs/`：`dc_shell`、`vcs`、`pt_shell` 日志
- `mapped/`：综合后网表、DDC、SDC
- `power/`：SAIF、门级仿真输出
- `reports/`：DC/PT 报告

除此之外，脚本在每次 `DC` / `PT` 成功后还会自动导出一份稳定副本到：

```text
report/syn/
├── dc/
│   ├── data.csv
│   └── <design>/
└── pt/
    ├── data.csv
    └── <design>/
```

其中：

- `report/syn/dc/data.csv` 只保留 `DC` 能直接给出的列：
  `模块 / 单元面积`
- `report/syn/pt/data.csv` 只保留 `PT` 能直接给出的列：
  `模块 / 总功耗 / WNS/WHS`
- 每个 `<design>/data.csv`：对应该设计当前 run 的单行摘要
- `dc/` 子目录导出 DC 产物：`mapped/`、`dc_shell.log`、DC 报告
- `pt/` 子目录导出 PT 产物：`power/`、`vcs/pt` 日志、PT 报告

## 运行前环境

默认脚本是按你之前服务器的风格写的，会优先使用：

- `BSUB_PREFIX="bsub -Is -XF"`
- `DC_SHELL_BIN=/tools/synopsys/syn/R-2020.09-SP3a/bin/dc_shell`
- `PT_SHELL_BIN=/tools/synopsys/prime/V-2023.12/bin/pt_shell`
- `VCS_BIN=vcs`

还需要准备库相关环境变量：

- `TARGET_LIB`：DC/PT 使用的 `.db` 库
- `LINK_LIB`：可选，默认等于 `TARGET_LIB`
- `SEARCH_PATHS`：可选，多个路径用冒号 `:` 分隔
- `SIM_LIB_FILES`：VCS 门级仿真所需 Verilog 标准单元模型，多个文件用冒号 `:` 分隔

示例：

```bash
export TARGET_LIB=/path/to/stdcell.db
export LINK_LIB=$TARGET_LIB
export SIM_LIB_FILES=/path/to/stdcell.v
```

如果你要在非 LSF 环境直接跑，可以把：

```bash
export BSUB_PREFIX=""
```

## 如何执行

### 1) MIGO：先跑 DC

```bash
bash syn_flow/run_migo_dc.sh 2.0
```

### 2) MIGO：再跑 PT

```bash
bash syn_flow/run_migo_pt.sh
```

### 2.5) MIGO：本地 `iverilog` 快速功能回归

如果你只是想快速确认 `migo` RTL + testbench 在开源仿真器下可跑通，可以直接执行：

```bash
bash syn_flow/designs/migo/tb/run_migo_iverilog.sh
```

输出位置：

- 编译日志：`report/func/migo/logs/iverilog_compile.log`
- 仿真日志：`report/func/migo/logs/tb_migo_saif.log`
- 输入向量：`report/func/migo/vectors/input_samples.vec`
- golden 向量：`report/func/migo/vectors/golden_output.vec`
- 输出向量：`report/func/migo/build/migo_output.vec`
- bit-exact 摘要：`report/func/migo/rtl_vec_eval.csv`

### 2.5.1) MIGO：结构级功能回归

如果你要补 `MIGO` 的结构级功能验证，可执行：

```bash
bash syn_flow/designs/migo/tb/run_migo_struct_iverilog.sh
```

输出位置：

- 结构级日志：`report/func/migo/structure/logs/`
- 结构级向量：`report/func/migo/structure/vectors/`
- 结构级汇总：`report/func/migo/migo_structure_validation.csv`

### 2.6) 清理本地生成文件

如果你想清掉本地仿真 / Yosys / 报表产物，执行：

```bash
bash clean_generated.sh
```

会删除：

- `flow/yosys/out/`
- `flow/yosys/reports/`
- `vsrc/Joint-CFR-DPD/tb/*/{build,logs,vectors}`
- `syn_flow/designs/migo/tb/{build,logs}`
- `report/`

### 3) Joint-CFR：先跑 DC

```bash
bash syn_flow/run_joint_dc.sh 2.0
```

### 4) Joint-CFR：再跑 PT

```bash
bash syn_flow/run_joint_pt.sh
```

## 推荐执行顺序

建议你每次都按下面顺序：

### MIGO

```bash
bash syn_flow/run_migo_dc.sh 2.0
bash syn_flow/run_migo_pt.sh
```

### Joint-CFR

```bash
bash syn_flow/run_joint_dc.sh 2.0
bash syn_flow/run_joint_pt.sh
```

## 各脚本职责

- `syn_flow/run_migo_dc.sh`
  - MIGO 的 DC 入口
- `syn_flow/run_migo_pt.sh`
  - MIGO 的 PT 入口
- `syn_flow/run_joint_dc.sh`
  - Joint-CFR 的 DC 入口
- `syn_flow/run_joint_pt.sh`
  - Joint-CFR 的 PT 入口
- `syn_flow/common/run_dc.sh`
  - 共享 shell 封装，负责建运行目录、传环境变量、调用 `dc_shell`
- `syn_flow/common/run_pt.sh`
  - 共享 shell 封装，负责 VCS 门级仿真、生成 SAIF、调用 `pt_shell`
- `syn_flow/common/dc_main.tcl`
  - 共享 DC Tcl 主流程
- `syn_flow/common/pt_main.tcl`
  - 共享 PT Tcl 主流程

## 设计差异

### MIGO

- 顶层来自 `flow/filelists/migo.f`
- 单输入流 FIR
- SAIF 激励由 `tb_migo_saif.sv` 自动生成
- 不依赖外部 golden vector

### Joint-CFR

- 顶层来自 `flow/filelists/joint.f`
- valid/ready 接口
- 使用现有 top vector 回放
- PT 前自动生成 / 刷新 golden 向量

## 常见问题

### 1. PT 报缺少标准单元仿真模型

说明没有设置：

```bash
export SIM_LIB_FILES=/path/to/stdcell.v
```

### 2. PT 报找不到 run 目录

说明还没有先跑对应设计的 DC，或者 `syn_flow/runs/<design>/` 被清掉了。

先查看：

```bash
find syn_flow/runs -maxdepth 2 -type d | sort
```

### 3. Joint-CFR 门级仿真前向量不对

先单独执行：

```bash
python3 psrc/gen_golden_from_rwkv_quan.py
```

再重新跑：

```bash
bash syn_flow/run_joint_pt.sh
```

## 当前建议

当前建议每个设计只保留一份稳定输出目录：

```bash
bash syn_flow/run_migo_dc.sh 2.0
bash syn_flow/run_migo_pt.sh

bash syn_flow/run_joint_dc.sh 2.0
bash syn_flow/run_joint_pt.sh
```

这样每套设计的结果都会稳定落在固定目录下；再次运行同一设计时，会覆盖上一轮结果。

如果你需要论文 `exp.md` 表 1 的综合相关字段，优先直接读取：

- `report/syn/dc/data.csv` 中的 `单元面积`
- `report/syn/pt/data.csv` 中的 `总功耗`、`WNS/WHS`

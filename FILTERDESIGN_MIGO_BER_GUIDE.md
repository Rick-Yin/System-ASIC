# `FilterDesign-MIGO` 系数生成与 `msrc` BER 对比指南

这份指南对应 `msrc/main.m` 当前的外部滤波器比较模式。`main.m` 会一次性读取 `MIGO`、`WLS`、`SWLS` 三份 `run_summary.json`，将其中的 `solved_var.hq` 作为发端成形滤波器和收端匹配滤波器的公共 FIR 系数，然后在同一条系统链路下输出三条 BER 曲线。

## 1. 本次实验的等效滤波器规格

`msrc` 原始链路使用的滤波器是 `rcosdesign(rolloff, span, sps, 'sqrt')` 生成的 SRRC，其中 `rolloff = 0.25`、`span = 10`、`sps = 16`、`Fs_total = 200e6`。为了复用当前 `FilterDesign-MIGO` 的 Type-I lowpass 设计流程，这里采用由 SRRC 带宽导出的等效低通规格，而不是直接拟合 SRRC 的过渡形状。

根据当前参数，等效通带与阻带边界为：

- `f_p = (1 - rolloff) / (2 * sps) * Fs_total = 4.6875 MHz`
- `f_s = (1 + rolloff) / (2 * sps) * Fs_total = 7.8125 MHz`

换算为 `FilterDesign-MIGO` 使用的归一化参数：

- `wp_pi = f_p / (Fs_total / 2) = 0.046875`
- `width_pi = (f_s - f_p) / (Fs_total / 2) = 0.03125`

为了保持 `msrc` 中现有抽样和群时延关系不变，滤波器长度固定为 `N = span * sps + 1 = 161`，量化位宽固定为 `Q_bit = 8`。

## 2. 在 `FilterDesign-MIGO` 中生成三份系数

进入设计工程目录：

```powershell
cd D:\Materials\Master\Dissertation\Final\Code\MIGO\FilterDesign-MIGO\src
```

### 2.1 运行 WLS

```powershell
python main.py method=WLS N=161 Q_bit=8 wp_pi=0.046875 width_pi=0.03125
```

说明：当前仓库里的 WLS 实现按默认配置运行即可，不建议在这一步继续暴露权重调参，因为现有代码中的权重参数命名并不完全一致，默认命令更稳。

### 2.2 运行 SWLS

```powershell
python main.py method=SWLS N=161 Q_bit=8 wp_pi=0.046875 width_pi=0.03125 LAMBDA=0.01 EPS=0.001
```

这组参数作为当前实验的默认稀疏化配置，用于获得一组可直接参与 BER 比较的 8-bit 系数。

### 2.3 运行 MIGO

```powershell
python main.py method=MIGO N=161 Q_bit=8 wp_pi=0.046875 width_pi=0.03125 delta_hat_p=0.18 delta_hat_s=0.24 alpha_p=0.1 alpha_s=0.1 lam1=1.2 lam2=1.0 E_TopK=4 E_d_max=2 E_e_max=4 mio_rel_gap=0.01
```

这组参数沿用当前工程中更稳定的一组默认超参数，重点是让 MIGO 在可行性、收敛稳定性和后续硬件友好性之间取得平衡。`E_TopK = 4`、`E_d_max = 2`、`E_e_max = 4` 对应当前实验采用的保守图结构设置。

## 3. 找到三份 `run_summary.json`

每次命令执行成功后，结果会落在：

```text
D:\Materials\Master\Dissertation\Final\Code\MIGO\FilterDesign-MIGO\result\method-...\
```

每个结果目录下都包含：

- `run_summary.json`
- `optimized_filter.png`

`msrc` 只读取 `run_summary.json` 中的 `solved_var.hq`，不需要手工复制系数数组，也不需要从图中抄录。

## 4. 在 `msrc/main.m` 中填写 JSON 路径

打开 `msrc/main.m`，找到下面这段配置：

```matlab
config.filterExternalJsons = struct( ...
    "MIGO", "", ...
    "WLS", "", ...
    "SWLS", "" ...
);
```

把三条空字符串替换成你刚生成的三个 `run_summary.json` 的绝对路径。例如：

```matlab
config.filterExternalJsons = struct( ...
    "MIGO", "D:\Materials\Master\Dissertation\Final\Code\MIGO\FilterDesign-MIGO\result\method-migo-...\run_summary.json", ...
    "WLS",  "D:\Materials\Master\Dissertation\Final\Code\MIGO\FilterDesign-MIGO\result\method-wls-...\run_summary.json", ...
    "SWLS", "D:\Materials\Master\Dissertation\Final\Code\MIGO\FilterDesign-MIGO\result\method-swls-...\run_summary.json" ...
);
```

`main.m` 会自动检查以下条件：

- 三个路径不能为空
- `run_summary.json` 必须存在
- `solved_var.hq` 的 tap 数必须等于 `161`
- 系数必须为实数、有限值、并满足对称 FIR 约束

任何一项不满足都会直接报错，避免误把错误系数送进 BER 测试。

## 5. 运行 BER 对比

在 MATLAB 中运行：

```matlab
cd('D:\Materials\Master\Dissertation\Final\Code\System-ASIC\msrc');
main
```

当前 `main.m` 的行为是：

1. 依次读取 `MIGO`、`WLS`、`SWLS` 三份外部 FIR
2. 用同一组系数同时替换发端成形滤波器和收端匹配滤波器
3. 分别完成整条 `SNR -> BER` 扫描
4. 在同一张图上绘制三条 BER 曲线
5. 将汇总结果保存到 `data\BER-SNR\ber_compare_MCS_...mat`

保存文件中包含：

- `snr_range`
- `ber_curve_by_method`
- `method_names`
- `compare_results`

## 6. 论文中建议怎么写这一节

这一节建议明确说明：由于当前外部优化器实现的是 Type-I lowpass FIR 设计，而系统原始滤波器是 SRRC，因此实验中采用了“由 SRRC 带宽导出的等效低通规格”来统一生成 `MIGO`、`WLS`、`SWLS` 三组定点 FIR，并将它们成对用于发端成形和收端匹配滤波，以比较不同定点 FIR 设计策略在完整通信系统链路中的 BER 表现。

同时，本节只报告 `MIGO` 的硬件相关结果是合理的。原因是面积、时序和 FPGA 资源对比已经在前文完成，这一节的重点转为系统级 BER 验证。`WLS` 和 `SWLS` 在这里承担 BER 参照组角色，而 `MIGO` 则额外补充其结构性硬件指标，用于说明该方法在保持系统性能可接受的同时仍具备较好的实现友好性。

如果后续你要把“等效低通替代”进一步升级为“直接拟合 SRRC 目标响应”的设计流程，那就需要扩展 `FilterDesign-MIGO` 的目标函数定义，而不是继续沿用当前这份指南。

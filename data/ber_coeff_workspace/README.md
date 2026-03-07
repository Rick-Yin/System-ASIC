# BER Coefficient Workspace

将 `FilterDesign-MIGO` 中最终用于 BER-SNR 的关键产物复制到这里，推荐最小布局：

```text
data/ber_coeff_workspace/
├── MIGO/
│   └── run_summary.json
├── WLS/
│   └── run_summary.json
└── SWLS/
    └── run_summary.json
```

`msrc/ConfigParams.m` 在 `filterExternalJsons` 未显式填写时，会优先按上面的目录约定自动查找三份 `run_summary.json`。

只需要复制实验复现必需的关键结果，不需要整仓复制 `FilterDesign-MIGO`。

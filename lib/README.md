# Local Synthesis Library

This repository keeps only the minimum library files needed for local
`yosys` mapping and optional gate-level simulation:

- `lib/gscl45nm/gscl45nm.lib` (Yosys/ABC mapping)
- `lib/gscl45nm/gscl45nm.v` (optional gate-level simulation model)

The full FreePDK45 package was removed from the repo to keep the workspace
lean. If you need full PDK collateral (LEF/DB/TF/OA, etc.), manage it
externally and point tools to your local installation.

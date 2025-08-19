# Instructions for MICRO-2025 Artifact Evaluation

## Notice:
We have updated the artifacts after the artifacts-evaluation PDF submission with several bug-fix, leading to improved performance in FPGA-based experiments (from 7.8 MHz to 13.2 MHz). These improvements are reflected in the latest README.md and code inside this repository. Note these updates do not affect any of the core claims, experimental design, or conclusions of the submitted paper.

## 1. Installation
To facilitate artifact evaluation, we provide a **ready-to-use** remote environment with Xilinx VU19P FPGA, x86-64 Ubuntu server and all necessary software dependencies pre-installed. Please follow login credentials and instructions in Artifacts Submission PDF. The experiments can also be reproduced with the following hardware/software dependencies:
> * Hardware: x86-64 Ubuntu servers with 128 GB RAM, Xilinx VU19P FPGA, Cadence Palladium(optional)
> * Software: Vivado 2020.2, Mill 0.12.3

Get latest version from Github, and run `make init` to startup.
## 2. Experiment workflow
### Exp1. FPGA-based Cp-simulation Speed with XiangShan.
The experiment demonstrates DiffTest-H's co-simulation speed on Xilinx VU19P FPGA. We highly recommend reviewers to use the **Step 0 Quick Start**, which directly leverages our pre-built bitstream, host, and workloads for reliable results in minutes.

#### Steps 0 (Recommended): Quick start with pre-built bitstream, host, workload
```shell
make write_bitstream LOCAL_ENV=1
make write_ddr
make fpga-run
```
Then we can get a performance report like [here](#3-evaluation-and-expected-results)

#### Steps 1-5 (Optional, Advanced Users Only)
For reviewers who want to fully rebuild the flow (time-consuming, >15 hours for Step 3), we also provide the following steps. Note these steps are note required for artifact evaluation, the provided pre-built artifacts already match the paper's experiments and results.

Steps 1: Generate RTL from Chisel.
```shell
make fpga-rtl DUT=XiangShan
```

Step 2: Build Host Executable Binary
```shell
# Host path: $(DUT)/difftest/build/fpga-host
make fpga-host DUT=XiangShan
```

Step 3: Generate Bitstream via Vivado.
```shell
## Re-compile with Vivado
make vivado     # Setup vivado project
make bitstream  # Synthesis, Implementation, Generate Bitstream
```

Step 4: Write bitstream and workload to FPGA.
```shell
## Step1: Write bitstream to FPGA
# LOCAL_ENV: 1 to use local scripts with sudo permission
#            0 to add sudo permission manually
# FPGA_BIT_HOME: Directory of bitstream
make write_bitstream LOCAL_ENV=1 FPGA_BIT_HOME=...
## Step2: Write workload to FPGA DDR
make write_ddr WORKLOAD=microbench
```

Step 5: Run XiangShan Co-simulation
```shell
# HOST: path of fpga-host, use pre-built if not specify
make fpga-run HOST=./XiangShan/difftest/build/fpga-host WORKLOAD=microbench
```

### Exp2. (Optional) Palladium-based Optimization Breakdown with XiangShan/NutShell
The experiment demonstrates incremental impacts of optimization.

Step 1: Generate RTL from Chisel.
```shell
## DIFF_CONFIG options:
#   Z       for Baseline,
#   EBI     for Batch,
#   EBIN    for Batch+NonBlock
#   EBINSD  for Batch+NonBlock+Squash
## DUT options: XiangShan or NutShell
make sim-rtl DUT=XiangShan DIFF_CONFIG=EBINSD
```

Step 2: Compile for Palladium.
```shell
## Build on Palladium, requiring XCELIUM,IXCOM,VXE...
make pldm-build DUT=XiangShan
```

Step 3: Run XiangShan/NutShell Co-simulation
```shell
## WORKLOAD options: linux or microbench
make pldm-run DUT=XiangShan WORKLOAD=linux
```

## 3. Evaluation and expected results
Please check `reference/` folder for detailed log. Below is some critical results of the three sets of experiments.

(1) Result of Exp1: FPGA-based co-simulation speed with XiangShan.

```shell
Core 0: HIT GOOD TRAP at pc = 0x80003856
Core-0 instrCnt = 1731543183, cycleCnt = 1437460832, IPC = 1.204585
Run time: 108 s 873 ms
Simulation speed: 13203.10 KHz
```

(2) Result of Exp2: Palladium-based simulation speed with different optimizatio, detailed in `reference/perf-log`.

```shell
## Speed of XiangShan-PLDM
Simulation speed: 6.49 KHz     # Baseline
Simulation speed: 23.84 KHz    # Batch
Simulation speed: 71.22 KHz    # Batch+NonBlock
Simulation speed: 478.12 KHz   # Batch+NonBlock+Squash

## Speed of NutShell-PLDM
Simulation speed: 13.67 KHz    # Baseline
Simulation speed: 101.65 KHz   # Batch
Simulation speed: 389.09 KHz   # Batch+NonBlock
Simulation speed: 1030.93 KHz  # Batch+NonBlock+Squash

## Speed of XiangShan-FPGA
Simulation speed: 1278.07 KHz  # Batch
Simulation speed: 2198.00 KHz  # Batch+NonBlock
Simulation speed: 13203.10 KHz # Batch+NonBlock+Squash
```

## 4. Notes
DiffTest-H is developed in the open-source community and will keep updating latest code and document. Any feedback and issues are welcome via Github or author emails.
Due to license restricts, we cannot publicly provide Palladium. However, we are delighted to assist reviewers in reproducing Palladium-related experiments.
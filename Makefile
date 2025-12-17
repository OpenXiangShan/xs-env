#***************************************************************************************
# Copyright (c) 2024-2025 Beijing Institute of Open Source Chip (BOSC)
# Copyright (c) 2020-2025 Institute of Computing Technology, Chinese Academy of Sciences
#
# XiangShan is licensed under Mulan PSL v2.
# You can use this software according to the terms and conditions of the Mulan PSL v2.
# You may obtain a copy of Mulan PSL v2 at:
#          http://license.coscl.org.cn/MulanPSL2
#
# THIS SOFTWARE IS PROVIDED ON AN "AS IS" BASIS, WITHOUT WARRANTIES OF ANY KIND,
# EITHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO NON-INFRINGEMENT,
# MERCHANTABILITY OR FIT FOR A PARTICULAR PURPOSE.
#
# See the Mulan PSL v2 for more details.
#***************************************************************************************

## Environments.
XS_PROJECT_ROOT = $(abspath .)

# DUT should be XiangShan or NutShell
DUT ?= XiangShan
DUT_HOME = $(XS_PROJECT_ROOT)/$(DUT)
DIFF_HOME = $(DUT_HOME)/difftest

FPGA_HOME = $(XS_PROJECT_ROOT)/env-scripts/fpga_diff
FPGA_PRJ_HOME = $(FPGA_HOME)/xs_kmh
FPGA_PRJ = $(FPGA_PRJ_HOME)/xs_kmh.xpr

# Ready-to-use bitstream, workload, host
FPGA_WORKLOAD_HOME = $(XS_PROJECT_ROOT)/reference/fpga-workload
FPGA_BIT_HOME ?= $(XS_PROJECT_ROOT)/reference/fpga-bit
WORKLOAD ?= microbench
HOST ?= $(FPGA_WORKLOAD_HOME)/fpga-host
ENABLE_CHI ?= 0

# Set LOCAL_ENV = 1 to use local scripts with sudo permission
LOCAL_ENV ?= 0
ifeq ($(LOCAL_ENV), 1)
PCIE_SCRIPTS_DIR = /home/tools
else
PCIE_SCRIPTS_DIR = ./fpga_scripts
endif

export NEMU_HOME=$(XS_PROJECT_ROOT)/NEMU
export NOOP_HOME=$(DUT_HOME)
init:
	git lfs pull
	git submodule update --init --recursive NEMU NutShell env-scripts
	git submodule update --init XiangShan && make -C XiangShan init

## Generate RTL from Chisel
fpga-rtl:
ifneq ($(DUT), XiangShan)
	$(error Currenly only support FPGA-Difftest with XiangShan)
endif
ifeq ($(ENABLE_CHI), 1)
	$(MAKE) -C $(DUT_HOME) verilog CONFIG=XSNoCTopConfig  PLDM=1 FPGA_DIFF=1 PLDM_ARGS="--difftest-config H" -j16
	python $(DIFF_HOME)/scripts/st_tools/interface.py $(DUT_HOME)/build/rtl/XSTop.sv --core --fpga
	NOOP_HOME=$(DIFF_HOME) $(MAKE) -C $(DIFF_HOME) difftest_verilog PROFILE=$(DUT_HOME)/build/generated-src/difftest_profile.json NUM_CORES=1 CONFIG=ESBIF
	python $(DIFF_HOME)/scripts/st_tools/interface.py $(DIFF_HOME)/build/rtl/GatewayEndpoint.sv
	cp -r $(DIFF_HOME)/src/test/vsrc/fpga $(DUT_HOME)/build/
	cp -r $(DIFF_HOME)/build $(DUT_HOME)
else
	$(MAKE) -C $(DUT_HOME) verilog DEBUG_ARGS="--difftest-config ESBIF --difftest-exclude Vec" FPGA=1 WITH_CHISELDB=0 WITH_CONSTANTIN=0 CONFIG=FpgaDiffDefaultConfig
	cp -r $(DIFF_HOME)/src/test/vsrc/fpga $(DUT_HOME)/build/
endif

NUM_CORES ?= 1
sim-rtl:
ifeq ($(DUT), XiangShan)
	$(MAKE) -C $(DUT_HOME) sim-verilog CONFIG=DefaultConfig PLDM=1 PLDM_ARGS="--difftest-config $(DIFF_CONFIG) --fpga-platform" WITH_CHISELDB=0 WITH_CONSTANTIN=0 NUM_CORES=$(NUM_CORES)
endif
ifeq ($(DUT), NutShell)
	$(MAKE) -C $(DUT_HOME) sim-verilog MILL_ARGS="--difftest-config $(DIFF_CONFIG)"
endif

## Build for Palladium
fpga-host:
	NOOP_HOME=$(DIFF_HOME) $(MAKE) -C $(DIFF_HOME) fpga-host FPGA=1 DIFFTEST_PERFCNT=1 RELEASE=1

pldm-build:
	$(MAKE) -C $(DUT_HOME) pldm-build DIFFTEST_PERFCNT=1 WITH_CHISELDB=0 WITH_CONSTANTIN=0

## Simulate same Palladium/FPGA framework with Verilator
simv-build:
	$(MAKE) -C $(DUT_HOME) simv VCS=verilator DIFFTEST_PERFCNT=1 WITH_CHISELDB=0 WITH_CONSTANTIN=0

## Run co-simulation for FPGA/Palladium/Verilator
RUN_LOG ?= /dev/null

fpga-run:
	vivado -mode tcl -source fpga_scripts/reset_cpu.tcl -tclargs $(FPGA_BIT_HOME)/xs_fpga_top_debug.ltx
	@mkdir -p $(dir $(RUN_LOG))
	$(HOST) --diff $(FPGA_WORKLOAD_HOME)/riscv64-nemu-interpreter-so -i $(FPGA_WORKLOAD_HOME)/$(WORKLOAD).bin | tee $(RUN_LOG)

pldm-run:
	@mkdir -p $(dir $(RUN_LOG))
	$(MAKE) -C $(DUT_HOME) pldm-run PLDM_EXTRA_ARGS="+diff=$(DUT_HOME)/ready-to-run/riscv64-nemu-interpreter-so +workload=$(DUT_HOME)/ready-to-run/$(WORKLOAD).bin" | tee $(RUN_LOG)

simv-run:
	@mkdir -p $(dir $(RUN_LOG))
	$(DUT_HOME)/build/simv +diff=$(DUT_HOME)/ready-to-run/riscv64-nemu-interpreter-so +workload=$(DUT_HOME)/ready-to-run/$(WORKLOAD).bin +e=0 | tee $(RUN_LOG)

## Setup Vivado project
vivado:
	$(MAKE) -C $(FPGA_HOME) update_core_flist CORE_DIR=$(DUT_HOME)/build
	$(MAKE) -C $(FPGA_HOME) add_sys_option CORE_DIR=$(DUT_HOME)/build
	$(MAKE) -C $(FPGA_HOME) vivado CPU=kmh

open_vivado:
	vivado $(FPGA_PRJ)
## Synthesis, Implementation and Generate Bitstream
bitstream:
	$(MAKE) -C $(FPGA_HOME) bitstream

write_bitstream:
	sudo $(PCIE_SCRIPTS_DIR)/pcie-remove.sh
	vivado -mode tcl -source fpga_scripts/write_bitstream.tcl -tclargs $(FPGA_BIT_HOME)
	sudo $(PCIE_SCRIPTS_DIR)/pcie-rescan.sh

write_ddr:
	vivado -mode tcl -source fpga_scripts/reset_ddr.tcl -tclargs $(FPGA_BIT_HOME)/xs_fpga_top_debug.ltx
	vivado -mode tcl -source fpga_scripts/jtag_write_ddr.tcl -tclargs $(FPGA_WORKLOAD_HOME)/$(WORKLOAD).txt

clean-rtl:
	$(MAKE) -C $(DUT_HOME) clean

clean-vivado:
	rm -rf $(FPGA_PRJ_HOME)

clean-all: clean-rtl clean-vivado

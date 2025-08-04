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

FPGA_HOME = $(XS_PROJECT_ROOT)/env-scripts/xs_kmh_fpga_diff
FPGA_PRJ_HOME = $(FPGA_HOME)/xs_kmh
FPGA_PRJ = $(FPGA_PRJ_HOME)/xs_kmh.xpr

# Ready-to-use bitstream, workload, host
FPGA_WORKLOAD_HOME = $(XS_PROJECT_ROOT)/reference/fpga-workload
FPGA_BIT_HOME ?= $(XS_PROJECT_ROOT)/reference/fpga-bit
WORKLOAD ?= microbench
HOST ?= $(FPGA_WORKLOAD_HOME)/fpga-host

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
	$(MAKE) -C $(DUT_HOME) verilog CONFIG=FpgaDiffMinimalConfig PLDM=1 FPGA_DIFF=1 PLDM_ARGS="--difftest-config H" -j16
	python $(DIFF_HOME)/scripts/st_tools/interface.py $(DUT_HOME)/build/rtl/XSTop.sv --core --fpga
	NOOP_HOME=$(DIFF_HOME) $(MAKE) -C $(DIFF_HOME) difftest_verilog PROFILE=$(DUT_HOME)/build/generated-src/difftest_profile.json NUM_CORES=1 CONFIG=ESBIF
	python $(DIFF_HOME)/scripts/st_tools/interface.py $(DUT_HOME)/build/rtl/GatewayEndpoint.sv
	cp -r $(DIFF_HOME)/src/test/vsrc/fpga $(DUT_HOME)/build/
	cp -r $(DIFF_HOME)/build $(DUT_HOME)


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
	NOOP_HOME=$(DIFF_HOME) $(MAKE) -C $(DIFF_HOME) fpga-host FPGA=1 DIFFTEST_PERFCNT=1

pldm-build:
	$(MAKE) -C $(DUT_HOME) pldm-build DIFFTEST_PERFCNT=1 WITH_CHISELDB=0 WITH_CONSTANTIN=0

## Simulate same Palladium/FPGA framework with Verilator
simv-build:
	$(MAKE) -C $(DUT_HOME) simv VCS=verilator DIFFTEST_PERFCNT=1 WITH_CHISELDB=0 WITH_CONSTANTIN=0

## Run co-simulation for FPGA/Palladium/Verilator
fpga-run:
	vivado -mode tcl -source fpga_scripts/reset_cpu.tcl -tclargs $(FPGA_BIT_HOME)/xs_fpga_top_debug.ltx
	$(HOST) --diff $(FPGA_WORKLOAD_HOME)/riscv64-nemu-interpreter-so -i $(FPGA_WORKLOAD_HOME)/$(WORKLOAD).bin

pldm-run:
	$(MAKE) -C $(DUT_HOME) pldm-run PLDM_EXTRA_ARGS="+diff=$(DUT_HOME)/ready-to-run/riscv64-nemu-interpreter-so +workload=$(DUT_HOME)/ready-to-run/$(WORKLOAD).bin"

simv-run:
	$(DUT_HOME)/build/simv +diff=$(DUT_HOME)/ready-to-run/riscv64-nemu-interpreter-so +workload=$(DUT_HOME)/ready-to-run/$(WORKLOAD).bin +e=0

## Setup Vivado project
vivado:
	$(MAKE) -C $(FPGA_HOME) update_core_flist
	$(MAKE) -C $(FPGA_HOME) kmh
	vivado $(FPGA_PRJ)

write_bitstream:
	sudo $(PCIE_SCRIPTS_DIR)/pcie-remove.sh
	vivado -mode tcl -source fpga_scripts/write_bitstream.tcl -tclargs $(FPGA_BIT_HOME)
	sudo $(PCIE_SCRIPTS_DIR)/pcie-rescan.sh

write_ddr:
	vivado -mode tcl -source fpga_scripts/reset_ddr.tcl -tclargs $(FPGA_BIT_HOME)/xs_fpga_top_debug.ltx
	vivado -mode tcl -source fpga_scripts/jtag_write_ddr.tcl -tclargs $(FPGA_WORKLOAD_HOME)/$(WORKLOAD).txt

clean-dut:
	$(MAKE) -C $(DUT_HOME) clean

clean-vivado:
	rm -rf $(FPGA_PRJ_HOME)

clean-all: clean-dut clean-vivado

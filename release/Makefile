# usage: make release / make full-release

# ------------------------------------------------------------------------------
# release config
# ------------------------------------------------------------------------------

RELEASE_NEMU_CONFIG=riscv64-xs-southlake

RELEASE_PATH=./build
RELEASE_SRC_PATH=./build/src
RELEASE_RTL_PATH=./build/rtl
RELEASE_SIM_RTL_PATH=./build/simrtl
RELEASE_TEST_PATH=./build/test
RELEASE_DIFFTEST_PATH=./build/difftest
RELEASE_LINUX_PATH=./build/linux
RELEASE_BIN_PATH=./build/bin
RELEASE_DOC_PATH=./build/doc

TEMP_PATH=./temp

# RELEASE_DOC_SOURCE=

RELEASE_PACKAGE_NAME=xiangshan-release-$(shell date '+%Y-%m-%d')

# ------------------------------------------------------------------------------
# release
# ------------------------------------------------------------------------------

release:
	$(MAKE) full-release
	$(MAKE) package
	$(MAKE) regression
	# vcs regression should be run manually 

package:
	@echo release package name: $(RELEASE_PACKAGE_NAME)
	tar -zcf $(RELEASE_PACKAGE_NAME).tar.gz ./build

# release rtl, sim rtl
rtl-release: rtl-release-parallel-rtl rtl-release-parallel-simrtl
	$(MAKE) build-release-emu

# release TBs, toolchains
misc-release:
	$(MAKE) release-linux-src
	$(MAKE) baremetal-testcases-print
	$(MAKE) baremetal-testcases-noprint
	$(MAKE) release-toolchain
	$(MAKE) release-testcases

# release source code, release-rtl, sim rtl, TBs, toolchains, and linux src
# will rebuild emu, which may take a long period of time
full-release:
	$(MAKE) full-release-step1
	$(MAKE) full-release-step2

full-release-step1: 
	$(MAKE) release-src
	$(MAKE) release-difftest
full-release-step2: misc-release rtl-release

# release source code, TBs, toolchains, and linux src
# will not build rtl, sim rtl and emu
env-release:
	$(MAKE) full-release-step1
	$(MAKE) misc-release

$(TEMP_PATH):
	mkdir -p $(TEMP_PATH)
$(RELEASE_PATH):
	mkdir -p $(RELEASE_PATH)
$(RELEASE_SRC_PATH):
	mkdir -p $(RELEASE_SRC_PATH)
$(RELEASE_RTL_PATH):
	mkdir -p $(RELEASE_RTL_PATH)
$(RELEASE_SIM_RTL_PATH):
	mkdir -p $(RELEASE_SIM_RTL_PATH) 
$(RELEASE_TEST_PATH):
	mkdir -p $(RELEASE_TEST_PATH) 
$(RELEASE_LINUX_PATH):
	mkdir -p $(RELEASE_LINUX_PATH) 
$(RELEASE_BIN_PATH):
	mkdir -p $(RELEASE_BIN_PATH) 
$(RELEASE_DOC_PATH):
	mkdir -p $(RELEASE_DOC_PATH) 

# ------------------------------------------------------------------------------
# release RTL and core sim model
# ------------------------------------------------------------------------------

# release rtl, simtop and extra files
# if you have generated $(SIM_TOP_V) without setting RELEASE = 1, make clean first
release-rtl: $(RELEASE_RTL_PATH)
	$(MAKE) -C $(NOOP_HOME) verilog-release RELEASE=1
	cp -r $(NOOP_HOME)/bosc_XSTop-Release*/* $(RELEASE_RTL_PATH)

release-simtop: $(RELEASE_SIM_RTL_PATH)
	$(MAKE) -C $(NOOP_HOME) sim-verilog-release RELEASE=1
	cp -r $(NOOP_HOME)/SimTop-Release*/* $(RELEASE_SIM_RTL_PATH)

release-legacy-emu: $(RELEASE_BIN_PATH)
	$(MAKE) -C $(NOOP_HOME) emu RELEASE=1 EMU_THREADS=8 -j16
	cp $(NOOP_HOME)/build/emu $(RELEASE_BIN_PATH)/emu

# use released file and filelist to build emu
build-release-emu: $(RELEASE_DIFFTEST_PATH)
	$(MAKE) -C $(RELEASE_DIFFTEST_PATH) emu USE_RELEASE="-F $(abspath $(RELEASE_RTL_PATH)/bosc_XSTop.f) -F $(abspath $(RELEASE_SIM_RTL_PATH)/SimTop.f)" RELEASE=1
	cp $(RELEASE_DIFFTEST_PATH)/../build/emu $(RELEASE_BIN_PATH)

# use released file and filelist to build simv
build-release-simv:
	$(MAKE) -C $(RELEASE_DIFFTEST_PATH) simv USE_RELEASE="-F $(abspath $(RELEASE_RTL_PATH)/bosc_XSTop.f) -F $(abspath $(RELEASE_SIM_RTL_PATH)/SimTop.f)" RELEASE=1

# release-sim-rtl: $(RELEASE_SIM_RTL_PATH) $(RELEASE_BIN_PATH)
# 	$(MAKE) -C $(NOOP_HOME) emu RELEASE=1 EMU_THREADS=8 -j16
# 	cp $(NOOP_HOME)/build/*.v $(RELEASE_SIM_RTL_PATH)   # RTL code
# 	cp $(NOOP_HOME)/build/emu $(RELEASE_BIN_PATH)

rtl-release-parallel-rtl: $(TEMP_PATH) $(RELEASE_RTL_PATH)
	cp -r $(NOOP_HOME) $(TEMP_PATH)/_rtl_build
	$(MAKE) release-rtl NOOP_HOME=$(abspath $(TEMP_PATH)/_rtl_build)

rtl-release-parallel-simrtl: $(TEMP_PATH)
	cp -r $(NOOP_HOME) $(TEMP_PATH)/_simrtl_build
	$(MAKE) release-simtop NOOP_HOME=$(abspath $(TEMP_PATH)/_simrtl_build)
	$(MAKE) release-legacy-emu NOOP_HOME=$(abspath $(TEMP_PATH)/_simrtl_build)

# ------------------------------------------------------------------------------
# release REF model
# ------------------------------------------------------------------------------

release-nemu:
	$(MAKE) $(RELEASE_BIN_PATH)/riscv64-nemu-interpreter
	$(MAKE) $(RELEASE_BIN_PATH)/riscv64-nemu-interpreter-so
	$(MAKE) $(RELEASE_BIN_PATH)/riscv64-nemu-interpreter-debug
	$(MAKE) $(RELEASE_BIN_PATH)/riscv64-nemu-interpreter-debug-so

$(RELEASE_BIN_PATH)/riscv64-nemu-interpreter: $(RELEASE_BIN_PATH)
	$(MAKE) -C $(NEMU_HOME) clean-all
	$(MAKE) -C $(NEMU_HOME) $(RELEASE_NEMU_CONFIG)_defconfig
	$(MAKE) -C $(NEMU_HOME) -j
	cp $(NEMU_HOME)/build/riscv64-nemu-interpreter $(RELEASE_BIN_PATH)

$(RELEASE_BIN_PATH)/riscv64-nemu-interpreter-so: $(RELEASE_BIN_PATH)
	$(MAKE) -C $(NEMU_HOME) clean-all
	$(MAKE) -C $(NEMU_HOME) $(RELEASE_NEMU_CONFIG)-ref_defconfig
	$(MAKE) -C $(NEMU_HOME) -j
	cp $(NEMU_HOME)/build/riscv64-nemu-interpreter-so $(RELEASE_BIN_PATH)
	
$(RELEASE_BIN_PATH)/riscv64-nemu-interpreter-debug: $(RELEASE_BIN_PATH)
	$(MAKE) -C $(NEMU_HOME) clean-all
	$(MAKE) -C $(NEMU_HOME) $(RELEASE_NEMU_CONFIG)-debug_defconfig
	$(MAKE) -C $(NEMU_HOME) -j
	cp $(NEMU_HOME)/build/riscv64-nemu-interpreter $(RELEASE_BIN_PATH)/riscv64-nemu-interpreter-debug

$(RELEASE_BIN_PATH)/riscv64-nemu-interpreter-debug-so: $(RELEASE_BIN_PATH)
	$(MAKE) -C $(NEMU_HOME) clean-all
	$(MAKE) -C $(NEMU_HOME) $(RELEASE_NEMU_CONFIG)-ref-debug_defconfig
	$(MAKE) -C $(NEMU_HOME) -j
	cp $(NEMU_HOME)/build/riscv64-nemu-interpreter-so $(RELEASE_BIN_PATH)/riscv64-nemu-interpreter-debug-so

regression-nemu:
	$(MAKE) -C $(NEMU_HOME) clean-all
	$(MAKE) -C $(NEMU_HOME) $(RELEASE_NEMU_CONFIG)-ref_defconfig
	$(MAKE) -C $(NEMU_HOME) -j

# ------------------------------------------------------------------------------
# release testcases
# ------------------------------------------------------------------------------

$(RELEASE_PATH)/build-test.mk: test-list.csv $(RELEASE_PATH)
	awk -F ',' -f build-test.awk test-list.csv > $(RELEASE_PATH)/build-test.mk

$(RELEASE_PATH)/run-test.mk: test-list.csv $(RELEASE_PATH) release-testcases
	awk -F ',' -f run-test.awk test-list.csv > $(RELEASE_PATH)/run-test.mk

baremetal-testcases: $(RELEASE_PATH)/build-test.mk $(RELEASE_TEST_PATH)
	@echo AM_HOME=$(AM_HOME)
	$(MAKE) -C $(AM_HOME) clean
	$(MAKE) -f $(RELEASE_PATH)/build-test.mk all -j1

baremetal-testcases-print:
	rm -rf $(RELEASE_TEST_PATH)
	$(MAKE) baremetal-testcases
	mv $(RELEASE_TEST_PATH) $(RELEASE_TEST_PATH)-print

baremetal-testcases-noprint:
	rm -rf $(RELEASE_TEST_PATH)
	$(MAKE) baremetal-testcases NOPRINT=1
	mv $(RELEASE_TEST_PATH) $(RELEASE_TEST_PATH)-noprint

gcpt-testcases:
	@echo $@ TODO

release-testcases: baremetal-testcases gcpt-testcases

# ------------------------------------------------------------------------------
# release source code
# ------------------------------------------------------------------------------

release-src: $(RELEASE_SRC_PATH) clean-submodule
	cp -r $(NOOP_HOME) $(RELEASE_SRC_PATH)
	cp -r $(NEMU_HOME) $(RELEASE_SRC_PATH)
	cp -r $(AM_HOME) $(RELEASE_SRC_PATH)
	cp ../*.sh $(RELEASE_SRC_PATH)
	cp ../README.md $(RELEASE_SRC_PATH)
	cp -r ../.git $(RELEASE_SRC_PATH)

release-linux-src: $(RELEASE_LINUX_PATH)
	# $(MAKE) -C resources clean # clean linux
	cp -r ./resources $(RELEASE_LINUX_PATH)

# ------------------------------------------------------------------------------
# release toolchain
# ------------------------------------------------------------------------------

release-toolchain: release-nemu
	@echo $@ TODO

# ------------------------------------------------------------------------------
# release difftest
# ------------------------------------------------------------------------------

# just copy difftest top
release-difftest: $(RELEASE_DIFFTEST_PATH)

$(RELEASE_DIFFTEST_PATH):
	cp -r $(NOOP_HOME)/difftest $(RELEASE_DIFFTEST_PATH)

# ------------------------------------------------------------------------------
# release document
# ------------------------------------------------------------------------------

release-doc: $(RELEASE_DOC_PATH)
	# cp $(NOOP_HOME)/build/*.dts $(RELEASE_DOC_PATH) # DTS
	# cp $(NOOP_HOME)/build/*.csv $(RELEASE_DOC_PATH) # MBIST list

# ------------------------------------------------------------------------------
# regression
# ------------------------------------------------------------------------------

regression: $(RELEASE_PATH)/run-test.mk regression-nemu $(RELEASE_BIN_PATH)/emu
	$(MAKE) -f $(RELEASE_PATH)/run-test.mk all RELEASE_BIN_PATH=$(RELEASE_BIN_PATH)
	# $(MAKE) build-release-emu # test if splited rtl and simtop can generate emu

$(RELEASE_BIN_PATH)/emu:
	build-release-emu

# TODO: support vcs regression

# ------------------------------------------------------------------------------
# clean
# ------------------------------------------------------------------------------

clean-test:
	rm -rf $(RELEASE_TEST_PATH)

clean-submodule:
	$(MAKE) -C $(NEMU_HOME) clean-all
	$(MAKE) -C $(NOOP_HOME) clean
	$(MAKE) -C $(NOOP_HOME) clean-release
	$(MAKE) -C $(AM_HOME) clean
	rm -rf $(NOOP_HOME)/out

clean: $(RELEASE_PATH) $(TEMP_PATH)
	rm -rf $(RELEASE_PATH)
	rm -rf $(TEMP_PATH)

.PHONY: clean release
.DEFAULT: release

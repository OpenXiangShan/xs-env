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
RELEASE_LINUX_PATH=./build/linux
RELEASE_BIN_PATH=./build/bin
RELEASE_DOC_PATH=./build/doc

RELEASE_PACKAGE_NAME=xiangshan-release-$(shell date '+%Y-%m-%d')

# ------------------------------------------------------------------------------
# release
# ------------------------------------------------------------------------------

# release sim rtl, TBs, toolchains
release: release-sim-rtl release-testcases release-toolchain release-doc

# release source code, release-rtl, sim rtl, TBs, toolchains, and linux src
full-release:
	$(MAKE) release-src
	$(MAKE) release-linux-src
	$(MAKE) release-rtl
	$(MAKE) release

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

release-sim-rtl: $(RELEASE_SIM_RTL_PATH) $(RELEASE_BIN_PATH)
	$(MAKE) -C $(NOOP_HOME) emu RELEASE=1 EMU_THREADS=8 -j16
	cp $(NOOP_HOME)/build/*.v $(RELEASE_SIM_RTL_PATH)   # RTL code
	cp $(NOOP_HOME)/build/emu $(RELEASE_BIN_PATH)

release-rtl: $(RELEASE_RTL_PATH)
	$(MAKE) -C $(NOOP_HOME) verilog RELEASE=1
	cp -r $(NOOP_HOME)/XSTop-Release*/* $(RELEASE_RTL_PATH)

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
	# rvtest cases TODO

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
# release document
# ------------------------------------------------------------------------------

release-doc: release-sim-rtl $(RELEASE_DOC_PATH)
	cp $(NOOP_HOME)/build/*.f $(RELEASE_DOC_PATH)   # SIM RTL filelist
	cp $(NOOP_HOME)/build/*.dts $(RELEASE_DOC_PATH) # DTS

# ------------------------------------------------------------------------------
# regression
# ------------------------------------------------------------------------------

regression: $(RELEASE_PATH)/run-test.mk regression-nemu release-sim-rtl
	$(MAKE) -f $(RELEASE_PATH)/run-test.mk all

# ------------------------------------------------------------------------------
# misc
# ------------------------------------------------------------------------------

all:
	$(MAKE) full-release
	$(MAKE) package
	$(MAKE) regression
	# $(MAKE) -C $(NOOP_HOME) simv 
	# vcs regression should be run manually 

package:
	@echo release package name: $(RELEASE_PACKAGE_NAME)
	tar -zcf $(RELEASE_PACKAGE_NAME).tar.gz ./build

# ------------------------------------------------------------------------------
# clean
# ------------------------------------------------------------------------------

clean-test:
	rm -rf $(RELEASE_TEST_PATH)

clean-submodule:
	$(MAKE) -C $(NEMU_HOME) clean-all
	$(MAKE) -C $(NOOP_HOME) clean
	$(MAKE) -C $(AM_HOME) clean
	rm -rf $(NOOP_HOME)/out

clean:
	rm -rf $(RELEASE_PATH)

.PHONY: clean release
.DEFAULT: release

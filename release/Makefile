# release config

RELEASE_NEMU_CONFIG=riscv64-xs-southlake

RELEASE_PATH=./build
RELEASE_CODE_PATH=./build/code
RELEASE_TEST_PATH=./build/test
RELEASE_BIN_PATH=./build/bin

# usage: make release

release: release-code release-testcases release-toolchain release-doc

$(RELEASE_PATH):
	mkdir -p $(RELEASE_PATH)
$(RELEASE_CODE_PATH):
	mkdir -p $(RELEASE_CODE_PATH) 
$(RELEASE_TEST_PATH):
	mkdir -p $(RELEASE_TEST_PATH) 
$(RELEASE_BIN_PATH):
	mkdir -p $(RELEASE_BIN_PATH) 

# release RTL and core sim model

release-code: $(RELEASE_CODE_PATH) $(RELEASE_BIN_PATH)
	# $(MAKE) -C $(NOOP_HOME) verilog
	$(MAKE) -C $(NOOP_HOME) emu RELEASE=1
	cp $(NOOP_HOME)/build/SimTop.v $(RELEASE_CODE_PATH)
	cp $(NOOP_HOME)/build/emu $(RELEASE_BIN_PATH)

# release REF

release-nemu: \
  $(RELEASE_BIN_PATH)/riscv64-nemu-interpreter \
  $(RELEASE_BIN_PATH)/riscv64-nemu-interpreter-so \

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
	
# release testcases

$(RELEASE_PATH)/test.mk: test-list.csv $(RELEASE_PATH)
	awk -F ',' -f test-list.awk test-list.csv > $(RELEASE_PATH)/test.mk

baremetal-testcases: $(RELEASE_PATH)/test.mk $(RELEASE_TEST_PATH)
	@echo AM_HOME=$(AM_HOME)
	$(MAKE) -C $(AM_HOME) clean
	$(MAKE) -f $(RELEASE_PATH)/test.mk all
	# rvtest cases TODO

gcpt-testcases:
	@echo $@ TODO

release-testcases: baremetal-testcases gcpt-testcases

# release toolchain

release-toolchain: release-nemu
	@echo $@ TODO

# release document

release-doc:
	@echo $@ TODO


clean:
	rm -rf $(RELEASE_PATH)

.PHONY: clean release
.DEFAULT: release
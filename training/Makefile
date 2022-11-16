# This script prepares a debug training package for beginners

# Usage:
# `make` to package a debug training case
# `make clean`

# Parameters:
TRAINING_CASE_NAME ?= nameundefined

# For example:
# modify source code, insert a bug
# git commit that bug, do not push it online
# `make TRAINING_CASE_NAME=stlf-error`
# by default, a DefaultConfig XiangShan emu will be included in release 

# ----------------------------------------------------------------------

TRAINING_CASE_HOME = $(shell realpath ${XS_PROJECT_ROOT}/../training-case-$(TRAINING_CASE_NAME))
REMOVE_COMMENT_AWK_SCRIPT = $(shell realpath ./remove-cmtmsg.awk)

all: compress_case
	@echo packaged case: $(TRAINING_CASE_HOME)/../training-case-$(TRAINING_CASE_NAME).tar.gz
	@echo case and solution: $(TRAINING_CASE_HOME)	

$(TRAINING_CASE_HOME):
	mkdir -p $(TRAINING_CASE_HOME)

build_emu:
	$(MAKE) -C ${NOOP_HOME} emu -j16 EMU_TRACE=1 EMU_THREADS=16

package_solution: $(TRAINING_CASE_HOME) build_emu
	@echo sloution position: $(TRAINING_CASE_HOME)/solution
	mkdir -p $(TRAINING_CASE_HOME)/solution
	cp -r ${XS_PROJECT_ROOT}/* $(TRAINING_CASE_HOME)/solution
	rm -rf $(TRAINING_CASE_HOME)/solution/XiangShan/out
	rm -rf $(TRAINING_CASE_HOME)/solution/XiangShan/.vscode
	rm -rf $(TRAINING_CASE_HOME)/solution/XiangShan/.metals
	rm -rf $(TRAINING_CASE_HOME)/solution/XiangShan/.bloop
	rm -rf $(TRAINING_CASE_HOME)/solution/XiangShan/.bsp
	rm -rf $(TRAINING_CASE_HOME)/solution/XiangShan/.coursier
	rm -rf $(TRAINING_CASE_HOME)/solution/XiangShan/.scala_dependencies
	rm -rf $(TRAINING_CASE_HOME)/solution/XiangShan/.worksheet
	rm -rf $(TRAINING_CASE_HOME)/solution/XiangShan/mill.rdiB
	rm -rf $(TRAINING_CASE_HOME)/solution/XiangShan/build/emu-compile
	rm -rf $(TRAINING_CASE_HOME)/solution/XiangShan/build/*.fir
	cd $(TRAINING_CASE_HOME)/solution/XiangShan/build; gawk -f $(REMOVE_COMMENT_AWK_SCRIPT) SimTop.v > SimTopNocmtmsg.v

package_case: $(TRAINING_CASE_HOME) package_solution
	@echo case position: $(TRAINING_CASE_HOME)/case
	cp -r $(TRAINING_CASE_HOME)/solution $(TRAINING_CASE_HOME)/case
	find $(TRAINING_CASE_HOME)/case -name .git | xargs rm -rf
	rm -rf $(TRAINING_CASE_HOME)/case/XiangShan/build/SimTop.v

compress_case: package_case
	cd $(TRAINING_CASE_HOME)/; tar zcvf $(TRAINING_CASE_HOME)/training-case-$(TRAINING_CASE_NAME).tar.gz ./case

compress_all: package_case
	cd $(TRAINING_CASE_HOME); tar zcvf $(TRAINING_CASE_HOME)/../training-case-$(TRAINING_CASE_NAME).tar.gz ./*

clean:
	rm -rf $(TRAINING_CASE_HOME)

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
	mv $(TRAINING_CASE_HOME)/solution/XiangShan/build/emu $(TRAINING_CASE_HOME)/solution/XiangShan/
	rm -rf $(TRAINING_CASE_HOME)/solution/XiangShan/build
	mkdir $(TRAINING_CASE_HOME)/solution/XiangShan/build
	mv $(TRAINING_CASE_HOME)/solution/XiangShan/emu $(TRAINING_CASE_HOME)/solution/XiangShan/build

package_case: $(TRAINING_CASE_HOME) package_solution
	@echo case position: $(TRAINING_CASE_HOME)/case
	cp -r $(TRAINING_CASE_HOME)/solution $(TRAINING_CASE_HOME)/case
	find $(TRAINING_CASE_HOME)/case -name .git | xargs rm -rf

compress_case: package_case
	tar zcvf $(TRAINING_CASE_HOME)/training-case-$(TRAINING_CASE_NAME).tar.gz $(TRAINING_CASE_HOME)/case

compress_all: package_case
	tar zcvf $(TRAINING_CASE_HOME)/../training-case-$(TRAINING_CASE_NAME).tar.gz $(TRAINING_CASE_HOME)

clean:
	rm -rf $(TRAINING_CASE_HOME)

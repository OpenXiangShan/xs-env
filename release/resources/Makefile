linux: riscv-linux riscv-pk riscv-rootfs
	export RISCV_ROOTFS_HOME=$(pwd)/riscv-rootfs
	mkdir riscv-pk/build -p
	$(MAKE) -C riscv-pk bbl

riscv-linux:
	@echo make $@ TBD
riscv-pk:
	@echo make $@ TBD
riscv-rootfs:
	@echo make $@ TBD

init:
	@echo make $@ TBD

clean:
	$(MAKE) -C riscv-rootfs clean
	$(MAKE) -C riscv-linux clean
	$(MAKE) -C riscv-pk clean
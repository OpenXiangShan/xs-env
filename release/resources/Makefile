linux: riscv-linux riscv-pk riscv-rootfs
	mkdir riscv-pk/build -p
	export RISCV_ROOTFS_HOME=$(pwd)/riscv-rootfs; $(MAKE) -C riscv-pk bbl

riscv-linux:
	git clone https://github.com/OpenXiangShan/riscv-linux
	cd riscv-linux; git checkout southlake
riscv-pk:
	git clone https://github.com/OpenXiangShan/riscv-pk
	cd riscv-pk; git checkout southlake
riscv-rootfs:
	git clone https://github.com/OpenXiangShan/riscv-rootfs
	cd riscv-rootfs; git checkout southlake

clean:
	$(MAKE) -C riscv-rootfs clean
	$(MAKE) -C riscv-linux clean
	$(MAKE) -C riscv-pk clean
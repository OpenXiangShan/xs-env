linux: riscv-linux riscv-pk riscv-rootfs
	mkdir riscv-pk/build -p
	export RISCV_ROOTFS_HOME=$(pwd)/riscv-rootfs; $(MAKE) -C riscv-pk bbl

riscv-linux:
	git clone -b southlake --depth=1 https://github.com/OpenXiangShan/riscv-linux
riscv-pk:
	git clone -b southlake --depth=1 https://github.com/OpenXiangShan/riscv-pk
riscv-rootfs:
	git clone -b southlake --depth=1 https://github.com/OpenXiangShan/riscv-rootfs

clean:
	$(MAKE) -C riscv-rootfs clean
	$(MAKE) -C riscv-linux clean
	$(MAKE) -C riscv-pk clean
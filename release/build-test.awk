# ----------------------------------------------------------------------
# S/N,name,make dir,arch,extra build args,test type,extra sim args,notes
# $1  $2   $3       $4   $5               $6        $7             $8   
# ----------------------------------------------------------------------

BEGIN {
    print ".PHONY: all"
    print ".DEFAULT: all"
    TESTSN = -1
}

{
    if(NR>1){
        if(TESTSN != $1){
            printf("build/test/%s-%s:\n", $1, $2)
            printf("	mkdir -p ./build/test/%s-%s\n", $1, $2); // mkdir
            TESTSN = $1
            TESTLIST[$1] = "./build/test/" $1 "-" $2
        }
        if($6 == "am" || $6 == "am-flash"){ # am build rules
            printf("	$(MAKE) -C $(AM_HOME) clean\n");               // clean am
            printf("	$(MAKE) -C %s clean\n", $3);                   // clean am
            printf("	$(MAKE) -C %s ARCH=%s %s\n", $3, $4, $5);      // make test
            printf("	cp -r %s/* ./build/test/%s-%s\n", $3, $1, $2); // copy test
        }
        if($6 == "rvtest"){
            printf("	@echo ./build/test/%s-%s should be manually released\n", $1, $2);
        }
        if($6 == "linux"){
            printf("	mkdir -p ./build/test/%s-%s/build\n", $1, $2); // mkdir
            printf("	# $(MAKE) -C resources clean\n"); // clean linux
            printf("	$(MAKE) -C resources linux\n"); // make test
            printf("	cp -r ./resources/riscv-pk/build/bbl.bin ./build/test/%s-%s/build\n", $1, $2); // copy test
            printf("	cp -r ./resources/riscv-pk/build/bbl.txt ./build/test/%s-%s/build\n", $1, $2); // copy dasm
            printf("	cp -r ./resources/riscv-pk/build/vmlinux.txt ./build/test/%s-%s/build\n", $1, $2); // copy dasm
        }
    }
}

END {
    printf("all: \n");
    for(i = 1; i < NR; i++){
        printf("	$(MAKE) -f ./build/build-test.mk %s\n", TESTLIST[i]);
    }
    printf("\n");
}

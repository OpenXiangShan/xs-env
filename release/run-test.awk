# -------------------------------------------------
# S/N,name,make dir,arch,extra args,test type,notes
# $1  $2   $3       $4   $5         $6   
# -------------------------------------------------

BEGIN {
    print ".PHONY: all"
    print ".DEFAULT: all"
    TESTSN = -1
}

{
    if(NR>1){
        if(TESTSN != $1){
            printf("test-%s-%s:\n", $1, $2)
            TESTSN = $1
            TESTLIST[$1] = "test-" $1 "-" $2
        }
        if($6 == "am"){ # am test rules
            printf("	$(NOOP_HOME)/build/emu -i $(shell find ./build/test/%s-%s/build/*.bin) 2>&1 | grep \"GOOD TRAP\"\n", $1, $2);      // make test
        }
        if($6 == "am-flash"){ 
        }
        if($6 == "rvtest"){ 
        }
    }
}

END {
    printf("all: \\\n");
    for(i = 1; i < NR; i++){
        printf("  %s\\\n", TESTLIST[i]);
    }
    printf("\n");
}

# ----------------------------------------------------------------------
# S/N,name,make dir,arch,extra build args,test type,extra sim args,notes
# $1  $2   $3       $4   $5               $6        $7             $8   
# ----------------------------------------------------------------------

# run this srript after test case gen

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
        if($6 == "am" || $6 == "linux"){ # memory based test rules
            search_target = "./build/test/" $1 "-" $2 "/build/*.bin"
            find_cmd = "find " search_target
            sim_parameter = $7
            cmd = find_cmd " | awk -f run-mem-test.awk -v SIM_PARAMETER=" sim_parameter " > __awk_temp__"
            system(cmd)
            system("cat __awk_temp__")
            system("rm __awk_temp__")
        }
        if($6 == "am-flash"){ # flash based test rules
            search_target = "./build/test/" $1 "-" $2 "/build/*.bin"
            find_cmd = "find " search_target
            sim_parameter = $7
            cmd = find_cmd " | awk -f run-flash-test.awk -v SIM_PARAMETER=" sim_parameter " > __awk_temp__"
            system(cmd)
            system("cat __awk_temp__")
            system("rm __awk_temp__")
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

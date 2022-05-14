{
    printf("	$(NOOP_HOME)/build/emu -i %s -F %s %s 2>&1 | grep \"GOOD TRAP\"\n", $0, $0, SIM_PARAMETER);
}

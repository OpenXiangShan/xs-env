{
    printf("	$(RELEASE_BIN_PATH)/emu -i %s -F %s %s 2>&1 | grep \"GOOD TRAP\"\n", $0, $0, SIM_PARAMETER);
}

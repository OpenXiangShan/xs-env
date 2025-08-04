#!/bin/bash
set -e
echo 1 > /sys/bus/pci/rescan
echo "Rescan PCI device successfully"
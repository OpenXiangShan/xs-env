#!/bin/bash
set -e

# Find BDF id of first xdma PCIE
BDF=$(lspci -D | grep -i xilinx | awk '{print $1}' | head -n 1)

if [ -z "$BDF" ]; then
  echo "Warning: No Xilinx PCI device found."
  exit 0
fi

# Remove PCIE of xdma
echo "PCI device BDF id: $BDF"
echo 1 > /sys/bus/pci/devices/$BDF/remove
echo "Removing PCI device at $BDF"

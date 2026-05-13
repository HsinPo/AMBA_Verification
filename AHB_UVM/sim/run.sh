#!/bin/bash

# 1. clean
if [ -d "work" ]; then
    rm -rf work
fi

# 2. establish
vlib work

# 3. compile (Interface -> RTL -> VIP Package -> Test -> Top)
vlog +incdir+../vip +incdir+../tb \
     ../vip/ahb_if.sv \
     ../rtl/*.v \
     ../vip/ahb_pkg.sv \
     ../tb/tb_top.sv

# 4. simulate
vsim -voptargs=+acc +UVM_TESTNAME=ahb_base_test -do "add wave -r /*; run -all; wave zoom full" tb_top
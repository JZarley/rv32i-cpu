#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -lt 1 ]; then
    echo "Usage: $0 MODULE"
    exit 1
fi

MODULE="$1"
SEED=${2:-1}

if [ "$#" -ge 2 ]; then
    shift 2
else
    shift 1
fi

SIM_ARGS=("$@")

DEPS=(
    rtl/riscv_pkg.sv
    rtl/rv32i_core.sv
    rtl/data_memory.sv
    rtl/branch_compare.sv
    rtl/alu.sv
    rtl/decoder.sv
    rtl/imm_gen.sv
    rtl/regfile.sv
)
RTL="rtl/${MODULE}.sv"
TB="tb/${MODULE}_tb.sv"
TB_TOP="${MODULE}_tb"
SIM="obj_dir/V${MODULE}_tb"
NETLIST="results/synth_${MODULE}.v"
SV2V_OUT="results/${MODULE}_sv2v.v"

if [ ! -f "$RTL" ]; then
    echo "Missing RTL: $RTL"
    exit 1
fi

if [ ! -f "$TB" ]; then
    echo "Missing testbench: $TB"
    exit 1
fi

for dep in "${RTL_DEPS[@]}"; do
    if [ ! -f "$dep" ]; then
        echo "Missing RTL dependency: $dep"
        exit 1
    fi
done

mkdir -p results

echo "[1/4] Linting $MODULE"
if ! verilator --lint-only "${DEPS[@]}" "$RTL" > results/lint.log 2>&1; then
    cat results/lint.log
    exit 1
fi

echo "[2/4] Building simulation"
if ! verilator --binary --timing --assert --trace \
    "${DEPS[@]}" \
    "$RTL" \
    "$TB" \
    --top-module "$TB_TOP" > results/build.log 2>&1; then
    cat results/build.log
    exit 1
fi

echo "[3/4] Running simulation (seed=$SEED)"
if ! "./$SIM" +verilator+seed+"$SEED" \
    "${SIM_ARGS[@]}" \
    > results/sim.log 2>&1; then
    cat results/sim.log
    exit 1
fi

echo "[4/4] Synthesizing $MODULE"

if ! sv2v \
    "${DEPS[@]}" \
    "$RTL" \
    > "$SV2V_OUT"; then
    echo "sv2v conversion failed"
    exit 1
fi

if ! yosys -p "
    read_verilog $SV2V_OUT;
    synth -top $MODULE;
    write_verilog $NETLIST
" > results/synthesis.log 2>&1; then
    cat results/synthesis.log
    exit 1
fi

echo "PASS: $MODULE"
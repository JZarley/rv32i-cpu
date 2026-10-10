#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

LIBERTY="${LIBERTY:-$ROOT/lib/NangateOpenCellLibrary_typical.lib}"
if [[ ! -f "$LIBERTY" ]]; then
    echo "Liberty library not found: $LIBERTY" >&2
    exit 1
fi

for cmd in sv2v yosys sta; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo "Missing tool: $cmd" >&2
        exit 1
    fi
done

for variant in stall memex; do
    case "$variant" in
        stall) top=rv32i_core ;;
        memex) top=rv32i_core_memex ;;
    esac

    out="results/compare/$variant"
    mkdir -p "$out"
    echo "== $variant: SystemVerilog conversion =="
    sv2v \
        rtl/riscv_pkg.sv \
        rtl/branch_compare.sv \
        rtl/alu.sv \
        rtl/decoder.sv \
        rtl/imm_gen.sv \
        rtl/regfile.sv \
        "rtl/${top}.sv" \
        > "$out/core.v"

    echo "== $variant: Nangate mapping =="
    yosys -l "$out/synthesis.log" -p "
        read_verilog $out/core.v;
        synth -top $top;
        dfflibmap -liberty $LIBERTY;
        abc -D 10000 -liberty $LIBERTY;
        stat -liberty $LIBERTY;
        write_verilog -simple-lhs $out/mapped.v;
    " > /dev/null

    echo "== $variant: cell totals =="
    grep -E 'Number of cells:|Chip area for top module' "$out/synthesis.log" | tail -2

    for delay in 0 1 2 3; do
        echo "== $variant: STA, DMEM input delay $delay ns =="
        LIBERTY="$LIBERTY" NETLIST="$out/mapped.v" TOP="$top" DMEM_DELAY="$delay" \
            sta -exit scripts/sta_compare_cpu.tcl > "$out/sta_mem${delay}ns.log"
    done
done

echo "Reports saved under results/compare/{stall,memex}/"

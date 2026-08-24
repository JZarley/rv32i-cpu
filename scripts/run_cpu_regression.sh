#!/usr/bin/env bash
set -euo pipefail

TESTS=(
    "smoke 4"
    "memory_smoke 6"
    "alu_reg 15"
    "alu_imm 12"
    "upper_imm 4"
    "branches 23"
    "jumps 6"
    "subword_memory 35"
    "sum_loop 38"
)

for ((i = 0; i < ${#TESTS[@]}; i++)); do
    read -r program instr_count <<< "${TESTS[$i]}"

    echo
    echo "========================================"
    echo "Running $program ($instr_count instructions)"
    echo "========================================"

    if [ "$i" -eq $((${#TESTS[@]} - 1)) ]; then
        ./scripts/run_cpu_test.sh "$program" "$instr_count"
    else
        ./scripts/run_cpu_test.sh "$program" "$instr_count" --no-synth
    fi
done

echo
echo "========================================"
echo "PASS: ${#TESTS[@]}/${#TESTS[@]} CPU tests"
echo "========================================"
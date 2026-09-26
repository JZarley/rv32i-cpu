#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -lt 2 ] || [ "$#" -gt 4 ]; then
    echo "Usage: $0 PROGRAM INSTRUCTION_COUNT [--no-synth] [--check-sort]"
    exit 1
fi

PROGRAM="$1"
INSTR_COUNT="$2"

FLOW_ARGS=()
SIM_ARGS=()

for arg in "${@:3}"; do
    case "$arg" in
        --no-synth)
            FLOW_ARGS+=(--no-synth)
            ;;
        --check-sort)
            SIM_ARGS+=(+CHECK_SORT)
            ;;
        *)
            echo "Unknown option: $arg"
            exit 1
            ;;
    esac
done

ASM="programs/${PROGRAM}.S"
OBJ="programs/${PROGRAM}.o"
ELF="programs/${PROGRAM}.elf"
BIN="programs/${PROGRAM}.bin"
HEX="programs/${PROGRAM}.hex"

SPIKE_LOG="results/spike_${PROGRAM}.log"
RTL_LOG="results/sim.log"

if [ ! -f "$ASM" ]; then
    echo "Missing program: $ASM"
    exit 1
fi

mkdir -p results

echo "[1/7] Assembling $PROGRAM"

riscv32-unknown-elf-as \
    -march=rv32i \
    -mabi=ilp32 \
    "$ASM" \
    -o "$OBJ"

echo "[2/7] Linking $PROGRAM"

riscv32-unknown-elf-ld \
    -m elf32lriscv \
    -N \
    -Ttext=0x80000000 \
    -e _start \
    "$OBJ" \
    -o "$ELF"

echo "[3/7] Extracting binary"

riscv32-unknown-elf-objcopy \
    -O binary \
    -j .text \
    "$ELF" \
    "$BIN"

echo "[4/7] Generating RTL hex image"

python3 scripts/bin_to_hex.py \
    "$BIN" \
    "$HEX"

echo "[5/7] Running Spike"

spike \
    --isa=rv32i \
    --pc=0x80000000 \
    --instructions="$INSTR_COUNT" \
    -l \
    --log-commits \
    --log="$SPIKE_LOG" \
    "$ELF"

echo "[6/7] Running RTL"

./scripts/run_flow.sh rv32i_system 1 "${FLOW_ARGS[@]}" "+PROGRAM_HEX=$HEX" "+INSTR_COUNT=$INSTR_COUNT" "${SIM_ARGS[@]}"

echo "[7/7] Comparing architectural traces"

python3 scripts/compare_traces.py \
    "$SPIKE_LOG" \
    "$RTL_LOG"

echo "PASS: $PROGRAM"
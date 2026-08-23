#!/usr/bin/env python3

import re
import sys
from pathlib import Path


SPIKE_BASE_RE = re.compile(
    r"core\s+\d+:\s+\d+\s+"
    r"0x([0-9a-fA-F]+)\s+"
    r"\(0x([0-9a-fA-F]+)\)"
    r"(.*)"
)

SPIKE_RD_RE = re.compile(
    r"^\s*x(\d+)\s+0x([0-9a-fA-F]+)"
)

SPIKE_MEM_RE = re.compile(
    r"\bmem\s+0x([0-9a-fA-F]+)"
    r"(?:\s+0x([0-9a-fA-F]+))?"
)

RTL_RE = re.compile(
    r"COMMIT\s+"
    r"pc=([0-9a-fA-F]+)\s+"
    r"instr=([0-9a-fA-F]+)"
    r"(.*)"
)

RTL_RD_RE = re.compile(
    r"\brd=(\d+)\s+rd_data=([0-9a-fA-F]+)"
)

RTL_MEM_RE = re.compile(
    r"\bmem_addr=([0-9a-fA-F]+)"
    r"(?:\s+mem_wdata=([0-9a-fA-F]+)"
    r"\s+mem_wstrb=([0-9a-fA-F]+))?"
)


def parse_spike(path):
    commits = []

    for line in Path(path).read_text().splitlines():
        match = SPIKE_BASE_RE.fullmatch(line.strip())

        if not match:
            continue

        pc, instr, rest = match.groups()

        rd = None
        rd_data = None
        mem_addr = None
        mem_wdata = None

        rd_match = SPIKE_RD_RE.search(rest)
        if rd_match:
            rd = int(rd_match.group(1))
            rd_data = int(rd_match.group(2), 16)

        mem_match = SPIKE_MEM_RE.search(rest)
        if mem_match:
            mem_addr = int(mem_match.group(1), 16)

            if mem_match.group(2) is not None:
                mem_wdata = int(mem_match.group(2), 16)

        commits.append({
            "pc": int(pc, 16),
            "instr": int(instr, 16),
            "rd": rd,
            "rd_data": rd_data,
            "mem_addr": mem_addr,
            "mem_wdata": mem_wdata,
        })

    return commits


def parse_rtl(path):
    commits = []

    for line in Path(path).read_text().splitlines():
        match = RTL_RE.fullmatch(line.strip())

        if not match:
            continue

        pc, instr, rest = match.groups()

        rd = None
        rd_data = None
        mem_addr = None
        mem_wdata = None

        rd_match = RTL_RD_RE.search(rest)
        if rd_match:
            rd = int(rd_match.group(1))
            rd_data = int(rd_match.group(2), 16)

        mem_match = RTL_MEM_RE.search(rest)
        if mem_match:
            mem_addr = int(mem_match.group(1), 16)

            if mem_match.group(2) is not None:
                mem_wdata = int(mem_match.group(2), 16)

        commits.append({
            "pc": int(pc, 16),
            "instr": int(instr, 16),
            "rd": rd,
            "rd_data": rd_data,
            "mem_addr": mem_addr,
            "mem_wdata": mem_wdata,
        })

    return commits


def main():
    if len(sys.argv) != 3:
        print(f"Usage: {sys.argv[0]} SPIKE_LOG RTL_LOG")
        sys.exit(1)

    spike = parse_spike(sys.argv[1])
    rtl = parse_rtl(sys.argv[2])

    if len(spike) != len(rtl):
        print(
            f"FAIL: commit count mismatch: "
            f"Spike={len(spike)}, RTL={len(rtl)}"
        )
        sys.exit(1)

    for i, (expected, actual) in enumerate(zip(spike, rtl)):
        if expected != actual:
            print(f"FAIL: mismatch at commit {i}")
            print(f"Spike: {expected}")
            print(f"RTL:   {actual}")
            sys.exit(1)

    print(f"PASS: {len(spike)} commits matched")


if __name__ == "__main__":
    main()
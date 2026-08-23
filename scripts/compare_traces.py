#!/usr/bin/env python3

import re
import sys
from pathlib import Path


SPIKE_RE = re.compile(
    r"core\s+\d+:\s+\d+\s+"
    r"0x([0-9a-fA-F]+)\s+"
    r"\(0x([0-9a-fA-F]+)\)"
    r"(?:\s+x(\d+)\s+0x([0-9a-fA-F]+))?"
)

RTL_RE = re.compile(
    r"COMMIT\s+"
    r"pc=([0-9a-fA-F]+)\s+"
    r"instr=([0-9a-fA-F]+)"
    r"(?:\s+rd=(\d+)\s+rd_data=([0-9a-fA-F]+))?"
)


def parse_spike(path):
    commits = []

    for line in Path(path).read_text().splitlines():
        match = SPIKE_RE.fullmatch(line.strip())

        if not match:
            continue

        pc, instr, rd, rd_data = match.groups()

        commits.append({
            "pc": int(pc, 16),
            "instr": int(instr, 16),
            "rd": int(rd) if rd is not None else None,
            "rd_data": int(rd_data, 16) if rd_data is not None else None,
        })

    return commits


def parse_rtl(path):
    commits = []

    for line in Path(path).read_text().splitlines():
        match = RTL_RE.fullmatch(line.strip())

        if not match:
            continue

        pc, instr, rd, rd_data = match.groups()

        commits.append({
            "pc": int(pc, 16),
            "instr": int(instr, 16),
            "rd": int(rd) if rd is not None else None,
            "rd_data": int(rd_data, 16) if rd_data is not None else None,
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
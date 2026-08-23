from pathlib import Path
import sys

if len(sys.argv) != 3:
    print(f"Usage: {sys.argv[0]} input.bin output.hex")
    sys.exit(1)

input_path = Path(sys.argv[1])
output_path = Path(sys.argv[2])

data = input_path.read_bytes()

if len(data) % 4 != 0:
    raise ValueError("Binary size is not a multiple of 4 bytes")

with output_path.open("w") as f:
    for i in range(0, len(data), 4):
        word = int.from_bytes(data[i:i+4], byteorder="little")
        f.write(f"{word:08x}\n")
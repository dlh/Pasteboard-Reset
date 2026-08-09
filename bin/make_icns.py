#!/usr/bin/env python3
import struct
import sys
from pathlib import Path


PNG_SIGNATURE = b"\x89PNG\r\n\x1a\n"


def read_png(path):
    data = path.read_bytes()
    if not data.startswith(PNG_SIGNATURE):
        raise ValueError(f"{path} is not a PNG file")
    return data


def main(argv):
    if len(argv) != 3:
        print("usage: make_icns.py APPICONSET_DIR OUTPUT_ICNS", file=sys.stderr)
        return 2

    appiconset_dir = Path(argv[1])
    output_path = Path(argv[2])
    entries = [
        (b"icp4", appiconset_dir / "AppIcon-16.png"),
        (b"icp5", appiconset_dir / "AppIcon-32.png"),
        (b"icp6", appiconset_dir / "AppIcon-32@2x.png"),
        (b"ic07", appiconset_dir / "AppIcon-128.png"),
        (b"ic08", appiconset_dir / "AppIcon-256.png"),
        (b"ic09", appiconset_dir / "AppIcon-512.png"),
        (b"ic10", appiconset_dir / "AppIcon-512@2x.png"),
    ]

    chunks = []
    for icon_type, path in entries:
        data = read_png(path)
        chunks.append(icon_type + struct.pack(">I", len(data) + 8) + data)

    payload = b"".join(chunks)
    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_bytes(b"icns" + struct.pack(">I", len(payload) + 8) + payload)
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))

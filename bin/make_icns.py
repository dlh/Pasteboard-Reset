#!/usr/bin/env python3
import argparse
import struct
from pathlib import Path


def make_chunk(chunk_type: bytes, payload: bytes) -> bytes:
    return chunk_type + struct.pack(">I", len(payload) + 8) + payload


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("appiconset_dir", type=Path)
    parser.add_argument("output_path", type=Path)
    args = parser.parse_args()

    entries: list[tuple[bytes, Path]] = [
        (b"icp4", args.appiconset_dir / "AppIcon-16.png"),
        (b"icp5", args.appiconset_dir / "AppIcon-32.png"),
        (b"icp6", args.appiconset_dir / "AppIcon-32@2x.png"),
        (b"ic07", args.appiconset_dir / "AppIcon-128.png"),
        (b"ic08", args.appiconset_dir / "AppIcon-256.png"),
        (b"ic09", args.appiconset_dir / "AppIcon-512.png"),
        (b"ic10", args.appiconset_dir / "AppIcon-512@2x.png"),
    ]

    payload = b"".join(
        [
            make_chunk(icon_type, path.read_bytes())
            for icon_type, path in entries
        ]
    )
    args.output_path.parent.mkdir(parents=True, exist_ok=True)
    args.output_path.write_bytes(make_chunk(b"icns", payload))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

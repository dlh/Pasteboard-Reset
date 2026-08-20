#!/usr/bin/env python3
"""Verify the NSLocalizedString keys used in a sources directory and the
entries in a Localizable.strings file match exactly, in both directions."""

import argparse
import re
import sys
from pathlib import Path

CALL_RE = re.compile(r'NSLocalizedString\(\s*@"((?:[^"\\]|\\.)*)"')
ENTRY_RE = re.compile(r'^"((?:[^"\\]|\\.)*)"\s*=')


def unescape(literal: str) -> str:
    return literal.replace('\\"', '"').replace("\\\\", "\\")


def used_keys(sources_dir: Path) -> dict[str, str]:
    keys: dict[str, str] = {}
    for path in sorted(sources_dir.glob("*.m")):
        text = path.read_text()
        for match in CALL_RE.finditer(text):
            key = unescape(match.group(1))
            lineno = text.count("\n", 0, match.start()) + 1
            keys.setdefault(key, f"{path}:{lineno}")
    return keys


def declared_keys(strings_file: Path) -> set[str]:
    keys: set[str] = set()
    for line in strings_file.read_text().splitlines():
        match = ENTRY_RE.match(line.strip())
        if match:
            keys.add(unescape(match.group(1)))
    return keys


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--sources-dir",
        type=Path,
        required=True,
        help="Directory containing .m files to scan for NSLocalizedString calls",
    )
    parser.add_argument(
        "--strings-file",
        type=Path,
        required=True,
        help="Localizable.strings file to check against",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    sources_dir: Path = args.sources_dir
    strings_file: Path = args.strings_file

    code_keys = used_keys(sources_dir)
    strings_keys = declared_keys(strings_file)

    missing = {key: location for key, location in code_keys.items() if key not in strings_keys}
    unused = sorted(strings_keys - code_keys.keys())

    if missing:
        print(f"Missing from {strings_file}:", file=sys.stderr)
        for key, location in sorted(missing.items()):
            print(f'  "{key}" ({location})', file=sys.stderr)

    if unused:
        print(f"Unused in {sources_dir}:", file=sys.stderr)
        for key in unused:
            print(f'  "{key}"', file=sys.stderr)

    if missing or unused:
        return 1

    print(f"{strings_file} matches the NSLocalizedString keys used in {sources_dir}.")
    return 0


if __name__ == "__main__":
    sys.exit(main())

#!/usr/bin/env python3
# This script is part of the Solvro/devops-utils project, licensed under the MIT license:
# https://github.com/Solvro/devops-utils
#
# Copyright (C) 2025 mini_bomba
import hashlib
import pathlib
import re
import sys
from io import BufferedIOBase

HASH_REGEX = re.compile(r"^[0-9a-f]{64}$", re.IGNORECASE)


def hash_file(file: BufferedIOBase) -> str:
    if sys.version_info.major >= 3 and sys.version_info.minor >= 11:
        return hashlib.file_digest(file, "sha256").hexdigest()
    hasher = hashlib.sha256()
    while (data := file.read(1024)) != b"":
        hasher.update(data)
    return hasher.hexdigest()


if len(sys.argv) < 2:
    print("Usage: procscan <path to sample executable or hex sha256 hash of the sample>", file=sys.stderr)
    exit(1)

if HASH_REGEX.match(sys.argv[1]) is not None:
    sample_hash = sys.argv[1].lower()
else:
    try:
        with open(sys.argv[1], "rb") as f:
            sample_hash = hash_file(f)
    except OSError as e:
        print(f"Failed to read the sample executable: {e}", file=sys.stderr)
        exit(1)

# now scan the existing processes
for proc_dir in pathlib.Path("/proc").iterdir():
    if not (proc_dir.name.isdigit() and proc_dir.is_dir()):
        continue

    # check the cmdline file - if empty = kworker
    try:
        if len((proc_dir / "cmdline").read_bytes()) == 0:
            continue
    except OSError as e:
        print(f"Failed to read the cmdline of PID {proc_dir.name}: {e}", file=sys.stderr)
        continue

    try:
        with (proc_dir / "exe").open("rb") as f:
            proc_hash = hash_file(f)
    except OSError as e:
        print(f"Failed to read the executable of PID {proc_dir.name}: {e}", file=sys.stderr)
        continue

    if proc_hash == sample_hash:
        print(f"PID {proc_dir.name} matched the sample executable!")

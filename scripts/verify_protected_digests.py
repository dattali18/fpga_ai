#!/usr/bin/env python3
"""Verify SHA-256 digests of all protected planner-owned files (and optional oracle manifests)."""

from __future__ import annotations

import argparse
import hashlib
import re
import sys
from pathlib import Path

EXPECTED_COMBINED_BOOTSTRAP_SHA256 = (
    "e10a800fe0a2a1407ee46656bc4a73d4eb2373cefd43641d20b7e3d2482a129c"
)


def sha256_file(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(65536), b""):
            h.update(chunk)
    return h.hexdigest()


def parse_manifest_lines(lines: list[str]) -> dict[str, str]:
    entries: dict[str, str] = {}
    for raw in lines:
        line = raw.strip()
        if not line or line.startswith("#"):
            continue
        parts = line.split(None, 1)
        if len(parts) != 2 or len(parts[0]) != 64:
            raise ValueError(f"Malformed SHA-256 manifest line: {raw!r}")
        digest, rel_path = parts[0].lower(), parts[1].strip()
        entries[rel_path] = digest
    return entries


def load_bootstrap_manifest(cap_doc: Path) -> dict[str, str]:
    text = cap_doc.read_text(encoding="utf-8")
    match = re.search(r"```text\n(.*?)\n```", text, re.S)
    if not match:
        raise RuntimeError(f"Missing SHA-256 manifest block in {cap_doc}")
    return parse_manifest_lines(match.group(1).splitlines())


def discover_protected_bootstrap_files(repo_root: Path) -> set[str]:
    found: set[str] = set()
    for single in ("AGENTS.md", "START_PROMPT.md"):
        p = repo_root / single
        if p.is_file():
            found.add(single)
    for folder in (".agents", "context"):
        base = repo_root / folder
        if base.is_dir():
            for p in base.rglob("*"):
                if p.is_file():
                    found.add(p.relative_to(repo_root).as_posix())
    return found


def verify_manifest(repo_root: Path, expected: dict[str, str], label: str) -> list[str]:
    errors: list[str] = []
    for rel_path, exp_hash in sorted(expected.items()):
        target = repo_root / rel_path
        if not target.is_file():
            errors.append(f"[{label}] MISSING protected file: {rel_path}")
            continue
        got_hash = sha256_file(target)
        if got_hash != exp_hash:
            errors.append(
                f"[{label}] DIGEST MISMATCH: {rel_path} (expected {exp_hash}, got {got_hash})"
            )
    return errors


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--repo-root",
        type=Path,
        default=Path(__file__).resolve().parent.parent,
        help="Repository root directory",
    )
    parser.add_argument(
        "--extra-manifest",
        type=Path,
        default=None,
        help="Optional sha256sum-formatted manifest for planner-approved golden reference (AC1)",
    )
    args = parser.parse_args()
    repo_root: Path = args.repo_root.resolve()

    cap_doc = repo_root / "research/ENVIRONMENT_CAPABILITY.md"
    if not cap_doc.is_file():
        print(f"ERROR: Missing baseline manifest document: {cap_doc}", file=sys.stderr)
        return 2

    bootstrap_expected = load_bootstrap_manifest(cap_doc)
    errors = verify_manifest(repo_root, bootstrap_expected, "bootstrap")

    actual_protected = discover_protected_bootstrap_files(repo_root)
    unexpected = sorted(actual_protected - set(bootstrap_expected.keys()))
    for rel in unexpected:
        errors.append(f"[bootstrap] UNTRACKED file inside protected path: {rel}")

    combined_lines = "".join(
        f"{bootstrap_expected[rel]}  {rel}\n" for rel in sorted(bootstrap_expected)
    ).encode("utf-8")
    combined_digest = hashlib.sha256(combined_lines).hexdigest()
    if combined_digest != EXPECTED_COMBINED_BOOTSTRAP_SHA256:
        errors.append(
            f"[bootstrap] Manifest combined digest tampered: got {combined_digest}, "
            f"expected {EXPECTED_COMBINED_BOOTSTRAP_SHA256}"
        )

    extra_count = 0
    if args.extra_manifest is not None:
        if not args.extra_manifest.is_file():
            errors.append(f"[oracle] Missing extra manifest: {args.extra_manifest}")
        else:
            extra_expected = parse_manifest_lines(
                args.extra_manifest.read_text(encoding="utf-8").splitlines()
            )
            extra_count = len(extra_expected)
            errors.extend(verify_manifest(repo_root, extra_expected, "oracle"))

    if errors:
        for err in errors:
            print(f"FAIL: {err}", file=sys.stderr)
        return 1

    msg = (
        f"PASS: Verified {len(bootstrap_expected)} protected bootstrap files "
        f"(combined SHA-256: {combined_digest})"
    )
    if extra_count:
        msg += f" + {extra_count} oracle files"
    print(msg)
    return 0


if __name__ == "__main__":
    sys.exit(main())

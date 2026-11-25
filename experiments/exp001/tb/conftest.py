"""Spec-neutral pytest session harness for EXP001 (AC1 protected-digest guard & seed hook).

Contains zero assumptions about EXP001 functional math, ports, numerical tolerances, or RTL.
"""

from __future__ import annotations

import os
import subprocess
import sys
from pathlib import Path

import pytest

REPO_ROOT = Path(__file__).resolve().parents[3]
VERIFY_SCRIPT = REPO_ROOT / "scripts/verify_protected_digests.py"


def _verify_digests(stage: str) -> None:
    cmd = [sys.executable, str(VERIFY_SCRIPT), "--repo-root", str(REPO_ROOT)]
    oracle_manifest = os.environ.get("EXP001_ORACLE_MANIFEST", "").strip()
    if oracle_manifest:
        cmd.extend(["--extra-manifest", oracle_manifest])
    proc = subprocess.run(cmd, capture_output=True, text=True, check=False)
    if proc.returncode != 0:
        pytest.fail(
            f"AC1 protected digest verification failed ({stage}):\n"
            f"{proc.stdout}\n{proc.stderr}"
        )


@pytest.fixture(scope="session", autouse=True)
def verify_protected_files_session() -> None:
    """Verify protected bootstrap (and optional AC1 oracle) digests before and after tests."""
    _verify_digests("pre-session")
    yield
    _verify_digests("post-session")


@pytest.fixture(scope="session")
def exp001_seed() -> int:
    """Deterministic default RNG seed for reproducible synthetic test generation."""
    return int(os.environ.get("EXP001_SEED", "20261125"))

#!/usr/bin/env python3
"""Cross-check complex_ref.py against NumPy float32 arithmetic.

complex_ref.py computes exactly with Fractions and rounds once per operation.
This script recomputes every generated vector with NumPy float32 scalar
operations in the same order (no FMA) and compares bit patterns. NaN results
are compared by class only. Requires NumPy; not needed to run the VHDL tests.

Usage: python3 crosscheck_numpy.py [--seed N] [--random-count N]
"""
from __future__ import annotations

import argparse
import sys

import numpy as np

import complex_ref as ref


def f32(bits: int) -> np.float32:
    return np.array([bits], dtype=np.uint32).view(np.float32)[0]


def bits(x: np.float32) -> int:
    return int(np.array([x], dtype=np.float32).view(np.uint32)[0])


def np_add(a_re, a_im, b_re, b_im):
    return bits(f32(a_re) + f32(b_re)), bits(f32(a_im) + f32(b_im))


def np_mul(a_re, a_im, b_re, b_im):
    ar, ai, br, bi = f32(a_re), f32(a_im), f32(b_re), f32(b_im)
    p1, p2, p3, p4 = ar * br, ai * bi, ar * bi, ai * br   # each rounded to float32
    return bits(p1 - p2), bits(p3 + p4)


def same(x: int, y: int) -> bool:
    return (ref.is_nan(x) and ref.is_nan(y)) or x == y


def main(argv=None) -> int:
    p = argparse.ArgumentParser()
    p.add_argument("--seed", type=int, default=20261126)
    p.add_argument("--random-count", type=int, default=2000)
    args = p.parse_args(argv)
    total = bad = 0
    with np.errstate(all="ignore"):
        for name, rop, nop in (("add", ref.c_add, np_add), ("mul", ref.c_mul, np_mul)):
            for cat, operands in ref.operand_sets(name, args.seed, args.random_count).items():
                for ops in operands:
                    r, n = rop(*ops), nop(*ops)
                    total += 1
                    if not (same(r[0], n[0]) and same(r[1], n[1])):
                        bad += 1
                        if bad <= 10:
                            print(f"MISMATCH {name}/{cat} ops={[f'{o:08X}' for o in ops]} "
                                  f"ref={[f'{v:08X}' for v in r]} numpy={[f'{v:08X}' for v in n]}")
    print(f"numpy {np.__version__}: {total} vectors, {bad} mismatches")
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main())

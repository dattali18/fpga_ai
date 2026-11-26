#!/usr/bin/env python3
"""Independent numerical reference for edu_complex_add and edu_complex_mul.

Arithmetic model: IEEE-754 binary32, round to nearest ties-to-even on every
operation, gradual underflow (subnormals), overflow to infinity, no fused
multiply-add.

Each scalar operation is evaluated exactly with Python Fractions and then
rounded once to binary32. This deliberately shares no code or algorithm with
the RTL (which uses ieee.float_pkg). Standard library only.

Complex operations (operation order is part of the contract):
  add: y_re = a_re + b_re
       y_im = a_im + b_im
  mul: y_re = (a_re*b_re) - (a_im*b_im)    each product rounded, then the difference
       y_im = (a_re*b_im) + (a_im*b_re)    each product rounded, then the sum

Usage:
  python3 complex_ref.py --selftest
  python3 complex_ref.py --output DIR [--seed N] [--random-count N]

Vector file line (whitespace separated, '#' lines are comments):
  a_re a_im b_re b_im y_re y_im nan_re nan_im
Words are 8 hex digits (binary32 bit patterns). nan_re/nan_im are 0/1. When a
flag is 1 the expected component is any NaN (payload and sign unspecified); the
hex word then holds the canonical quiet NaN 7FC00000 for readability only.
"""
from __future__ import annotations

import argparse
import random
import struct
import sys
from fractions import Fraction
from pathlib import Path

BIAS = 127
FRAC_BITS = 23
EMIN = -126
EMAX = 127
QNAN = 0x7FC00000
POS_INF = 0x7F800000
NEG_INF = 0xFF800000
NEG_ZERO = 0x80000000
MIN_SUB = Fraction(1, 2 ** 149)


# ------------------------------------------------------------ value model
class Val:
    """Decoded binary32 value: kind in {'nan', 'inf', 'zero', 'fin'}."""
    __slots__ = ("kind", "neg", "q")

    def __init__(self, kind: str, neg: bool = False, q: Fraction = Fraction(0)):
        self.kind, self.neg, self.q = kind, neg, q   # q: signed exact value for 'fin'


def decode(bits: int) -> Val:
    if not 0 <= bits <= 0xFFFFFFFF:
        raise ValueError("32-bit pattern required")
    neg = bool(bits >> 31)
    exp = (bits >> 23) & 0xFF
    frac = bits & 0x7FFFFF
    if exp == 0xFF:
        return Val("nan") if frac else Val("inf", neg)
    if exp == 0 and frac == 0:
        return Val("zero", neg)
    if exp == 0:
        mag = Fraction(frac, 2 ** 149)                              # subnormal
    else:
        mag = Fraction(frac + 2 ** 23) * Fraction(2) ** (exp - BIAS - FRAC_BITS)
    return Val("fin", neg, -mag if neg else mag)


def _round_half_even(x: Fraction) -> int:
    n, r = divmod(x.numerator, x.denominator)
    twice = 2 * r
    if twice > x.denominator or (twice == x.denominator and n % 2 == 1):
        n += 1
    return n


def _floor_log2(a: Fraction) -> int:
    e = a.numerator.bit_length() - a.denominator.bit_length()
    if Fraction(2) ** e > a:
        e -= 1
    return e


def encode_exact(q: Fraction) -> int:
    """Round a non-zero exact rational to binary32 (RNE, subnormals, overflow to inf).

    A result that underflows to zero keeps the sign of q (IEEE-754 6.3).
    """
    if q == 0:
        raise ValueError("exact zero must be handled by the caller (sign rule)")
    neg = q < 0
    a = -q if neg else q
    sign = NEG_ZERO if neg else 0
    e = _floor_log2(a)
    if e < EMIN:                                   # subnormal range, quantum 2^-149
        m = _round_half_even(a / MIN_SUB)
        return sign | m                            # m == 2^23 encodes min normal correctly
    m = _round_half_even(a / Fraction(2) ** (e - FRAC_BITS))
    if m == 2 ** 24:                               # rounding carried into the next binade
        m, e = 2 ** 23, e + 1
    if e > EMAX:
        return sign | POS_INF
    return sign | ((e + BIAS) << 23) | (m - 2 ** 23)


# --------------------------------------------------------------- scalar ops
def f_add(x: int, y: int) -> int:
    a, b = decode(x), decode(y)
    if a.kind == "nan" or b.kind == "nan":
        return QNAN
    if a.kind == "inf" and b.kind == "inf":
        return QNAN if a.neg != b.neg else (NEG_INF if a.neg else POS_INF)
    if a.kind == "inf":
        return NEG_INF if a.neg else POS_INF
    if b.kind == "inf":
        return NEG_INF if b.neg else POS_INF
    if a.kind == "zero" and b.kind == "zero":
        return NEG_ZERO if (a.neg and b.neg) else 0    # RNE: -0 only for (-0)+(-0)
    s = a.q + b.q
    if s == 0:
        return 0                                       # exact cancellation gives +0 in RNE
    return encode_exact(s)


def f_neg(x: int) -> int:
    return x ^ NEG_ZERO


def f_sub(x: int, y: int) -> int:
    return f_add(x, f_neg(y))


def f_mul(x: int, y: int) -> int:
    a, b = decode(x), decode(y)
    neg = a.neg != b.neg
    if a.kind == "nan" or b.kind == "nan":
        return QNAN
    if (a.kind == "inf" and b.kind == "zero") or (a.kind == "zero" and b.kind == "inf"):
        return QNAN
    if a.kind == "inf" or b.kind == "inf":
        return NEG_INF if neg else POS_INF
    if a.kind == "zero" or b.kind == "zero":
        return NEG_ZERO if neg else 0
    return encode_exact(a.q * b.q)


def is_nan(bits: int) -> bool:
    return (bits & 0x7F800000) == 0x7F800000 and (bits & 0x7FFFFF) != 0


# -------------------------------------------------------------- complex ops
def c_add(a_re: int, a_im: int, b_re: int, b_im: int) -> tuple[int, int]:
    return f_add(a_re, b_re), f_add(a_im, b_im)


def c_mul(a_re: int, a_im: int, b_re: int, b_im: int) -> tuple[int, int]:
    re = f_sub(f_mul(a_re, b_re), f_mul(a_im, b_im))
    im = f_add(f_mul(a_re, b_im), f_mul(a_im, b_re))
    return re, im


# ---------------------------------------------------------------- helpers
def fbits(x: float) -> int:
    """Bit pattern of a Python float that is exactly representable in binary32."""
    b = struct.unpack(">I", struct.pack(">f", x))[0]
    if struct.unpack(">f", struct.pack(">I", b))[0] != x:
        raise ValueError(f"{x!r} is not exactly representable in binary32")
    return b


def mk(neg: int, exp: int, frac: int) -> int:
    return (neg << 31) | (exp << 23) | frac


ONE, TWO, HALF = fbits(1.0), fbits(2.0), fbits(0.5)
MAXF = mk(0, 254, 0x7FFFFF)      # largest finite
MINN = mk(0, 1, 0)               # smallest normal
MINS = mk(0, 0, 1)               # smallest subnormal
MAXS = mk(0, 0, 0x7FFFFF)        # largest subnormal
ULP1 = mk(0, 127 - 23, 0)        # 2^-23, one ulp at 1.0
HULP1 = mk(0, 127 - 24, 0)       # 2^-24, half an ulp at 1.0
SNAN = mk(0, 255, 1)             # signalling NaN pattern
QNAN_N = mk(1, 255, 0x400000)    # negative quiet NaN


def selftest() -> None:
    f = fbits
    assert f_add(f(1.5), f(2.25)) == f(3.75)
    assert f_add(f(-0.5), f(0.5)) == 0                       # +0 on exact cancellation
    assert f_add(NEG_ZERO, NEG_ZERO) == NEG_ZERO             # (-0)+(-0) = -0
    assert f_add(NEG_ZERO, 0) == 0
    assert f_add(ONE, HULP1) == ONE                          # tie, even stays
    assert f_add(mk(0, 127, 1), HULP1) == mk(0, 127, 2)      # tie, odd rounds up
    assert f_add(MAXF, MAXF) == POS_INF
    assert f_add(MINS, MINS) == mk(0, 0, 2)
    assert f_add(MAXS, MINS) == MINN                         # subnormal to min normal
    assert is_nan(f_add(POS_INF, NEG_INF))
    assert f_mul(f(1.5), f(-2.0)) == f(-3.0)
    assert f_mul(MINN, HALF) == mk(0, 0, 0x400000)           # exact subnormal
    assert f_mul(MINS, HALF) == 0                            # tie to even -> +0
    assert f_mul(mk(1, 0, 1), HALF) == NEG_ZERO              # -tiny * 0.5 -> -0
    assert f_mul(mk(0, 0, 3), HALF) == mk(0, 0, 2)           # 1.5 quanta -> 2 (even)
    assert f_mul(MAXF, TWO) == POS_INF
    assert is_nan(f_mul(POS_INF, NEG_ZERO))
    assert f_mul(NEG_INF, f(-2.0)) == POS_INF
    assert c_mul(f(1.0), f(2.0), f(3.0), f(4.0)) == (f(-5.0), f(10.0))   # (1+2i)(3+4i)
    assert c_mul(0, ONE, 0, ONE) == (f(-1.0), 0)                         # i * i = -1
    assert c_add(f(1.0), f(-2.0), f(0.5), f(2.0)) == (f(1.5), 0)
    print("PASS: complex_ref selftest")


# ------------------------------------------------------------ vector sets
def rand_normal(rng: random.Random, emin: int, emax: int) -> int:
    return mk(rng.getrandbits(1), rng.randint(emin, emax) + BIAS, rng.getrandbits(23))


def rand_sub(rng: random.Random) -> int:
    return mk(rng.getrandbits(1), 0, rng.randint(1, 0x7FFFFF))


def directed_operands():
    """Ordinary finite values with known or easily checked results."""
    f = fbits
    one_up = mk(0, 127, 1)
    return [
        (f(1.0), f(2.0), f(3.0), f(4.0)),
        (f(1.5), f(-2.25), f(0.5), f(0.75)),
        (f(-1.0), f(0.0), f(1.0), f(0.0)),
        (0, ONE, 0, ONE),                                  # i, i
        (ONE, ONE, ONE, f(-1.0)),                          # conjugate pair
        (f(3.0), f(4.0), f(3.0), f(-4.0)),                 # z * conj(z) = 25
        (f(12.5), f(0.125), f(-12.5), f(0.375)),
        (f(1024.0), f(1.0 / 1024), f(1.0 / 64), f(64.0)),
        (ONE, ONE, HULP1, HULP1),                          # add: tie, stays even
        (one_up, one_up, HULP1, HULP1),                    # add: tie, odd rounds up
        (ONE, ULP1, ONE, f(-1.0)),
        (f(1.0 + 2 ** -12), f(1.0), f(1.0 - 2 ** -12), f(1.0)),
        (0x3DCCCCCD, 0x3E4CCCCD, 0x3E99999A, 0x3ECCCCCD),  # nearest binary32 to 0.1 .. 0.4
        (f(-7.0), f(-9.0), f(-11.0), f(13.0)),
        (f(65504.0), f(-65504.0), f(2.0), f(0.5)),
        (f(2.0 ** 60), f(2.0 ** -60), f(2.0 ** -60), f(2.0 ** 60)),
    ]


def edge_operands():
    """Finite inputs: signed zero, subnormals, underflow, overflow to infinity."""
    return [
        (0, 0, 0, 0), (NEG_ZERO, NEG_ZERO, NEG_ZERO, NEG_ZERO),
        (0, NEG_ZERO, NEG_ZERO, 0), (NEG_ZERO, 0, 0, NEG_ZERO),
        (ONE, f_neg(ONE), f_neg(ONE), ONE),                # add: exact cancellation
        (MINS, MINS, MINS, MINS), (MAXS, MINS, MINS, MAXS),
        (MINN, f_neg(MINS), MINS, MINN),
        (MINN, MINN, HALF, HALF), (MINS, MINS, HALF, HALF),
        (mk(1, 0, 1), mk(0, 0, 3), HALF, f_neg(HALF)),
        (MAXF, MAXF, MAXF, MAXF), (MAXF, f_neg(MAXF), MAXF, MAXF),
        (MAXF, 0, TWO, 0), (MAXF, MAXF, ONE, 0),
        (mk(0, 1, 5), mk(1, 1, 7), mk(0, 126, 9), mk(0, 120, 3)),
        (mk(0, 200, 0x123456), mk(0, 200, 0x654321), mk(0, 200, 1), mk(1, 200, 2)),
        (mk(0, 20, 0x111111), mk(0, 30, 0x222222), mk(0, 25, 0x333333), mk(1, 22, 0x444444)),
        (fbits(2.0 ** -75), fbits(2.0 ** -75), fbits(2.0 ** -75), fbits(2.0 ** -75)),
        (fbits(2.0 ** 64), fbits(2.0 ** 64), fbits(2.0 ** 64), fbits(-(2.0 ** 64))),
    ]


def special_operands():
    """Inputs containing infinities or NaNs."""
    out = []
    for s in (POS_INF, NEG_INF, QNAN, QNAN_N, SNAN):
        out += [(s, 0, ONE, 0), (ONE, s, 0, ONE), (ONE, ONE, s, s), (s, s, NEG_ZERO, 0)]
    out += [
        (POS_INF, 0, NEG_INF, 0),          # add: inf - inf -> NaN
        (POS_INF, POS_INF, POS_INF, NEG_INF),
        (POS_INF, 0, 0, POS_INF),          # mul: inf * 0 terms
        (POS_INF, ONE, ONE, ONE),
        (POS_INF, POS_INF, ONE, ONE),      # mul: inf - inf in the real part
        (NEG_INF, TWO, HALF, MAXF),
    ]
    return out


def random_normal_operands(rng: random.Random, count: int, emin: int, emax: int):
    """Random normal operands; one in eight of each kind biased towards cancellation."""
    out = []
    for i in range(count):
        a_re, a_im = rand_normal(rng, emin, emax), rand_normal(rng, emin, emax)
        b_re, b_im = rand_normal(rng, emin, emax), rand_normal(rng, emin, emax)
        k = i % 8
        if k == 0:                                     # add: near cancellation, real
            b_re = f_neg(a_re) ^ rng.getrandbits(3)
        elif k == 1:                                   # add: near cancellation, imaginary
            b_im = f_neg(a_im) ^ rng.getrandbits(3)
        elif k == 2:                                   # mul: a_re*b_re close to a_im*b_im
            a_im, b_im = a_re, b_re ^ rng.getrandbits(2)
        out.append((a_re, a_im, b_re, b_im))
    return out


def random_bits_operands(rng: random.Random, count: int):
    """Arbitrary 32-bit patterns, with extra weight on subnormals and zeros."""
    out = []
    for _ in range(count):
        ops = []
        for _ in range(4):
            r = rng.random()
            if r < 0.04:
                ops.append(rand_sub(rng))
            elif r < 0.06:
                ops.append(rng.choice([0, NEG_ZERO]))
            else:
                ops.append(rng.getrandbits(32))          # inf/NaN at their natural rate
        out.append(tuple(ops))
    return out


def rows(op, operands):
    lines = []
    for a_re, a_im, b_re, b_im in operands:
        y_re, y_im = op(a_re, a_im, b_re, b_im)
        n_re, n_im = int(is_nan(y_re)), int(is_nan(y_im))
        if n_re:
            y_re = QNAN
        if n_im:
            y_im = QNAN
        lines.append(f"{a_re:08X} {a_im:08X} {b_re:08X} {b_im:08X} "
                     f"{y_re:08X} {y_im:08X} {n_re} {n_im}")
    return lines


CATEGORIES = ("directed", "edge", "special", "random_normal", "random_bits")


def operand_sets(name: str, seed: int, count: int) -> dict:
    rng = random.Random(seed + (0 if name == "add" else 1))
    # add: wide exponent range for alignment/cancellation; mul: range avoids overflow
    emin, emax = (-100, 100) if name == "add" else (-60, 60)
    return {
        "directed": directed_operands(),
        "edge": edge_operands(),
        "special": special_operands(),
        "random_normal": random_normal_operands(rng, count, emin, emax),
        "random_bits": random_bits_operands(rng, count),
    }


def generate(outdir: Path, seed: int, count: int) -> None:
    outdir.mkdir(parents=True, exist_ok=True)
    for name, op in (("add", c_add), ("mul", c_mul)):
        for cat, operands in operand_sets(name, seed, count).items():
            body = rows(op, operands)
            header = [f"# edu_complex_{name} vectors, category={cat}, seed={seed}",
                      "# a_re a_im b_re b_im y_re y_im nan_re nan_im"]
            (outdir / f"{name}_{cat}.txt").write_text("\n".join(header + body) + "\n")
            print(f"{name}_{cat}.txt: {len(body)} vectors")


def main(argv=None) -> int:
    p = argparse.ArgumentParser(description="binary32 complex add/mul reference")
    p.add_argument("--selftest", action="store_true", help="run built-in checks only")
    p.add_argument("--output", type=Path, help="directory for vector files")
    p.add_argument("--seed", type=int, default=20261126)
    p.add_argument("--random-count", type=int, default=2000)
    args = p.parse_args(argv)
    selftest()
    if args.output is not None:
        generate(args.output, args.seed, args.random_count)
    return 0


if __name__ == "__main__":
    sys.exit(main())

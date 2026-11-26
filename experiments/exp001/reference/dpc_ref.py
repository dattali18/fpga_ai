#!/usr/bin/env python3
"""EXP001 golden reference: digital pulse compression (DPC), binary32.

Contract (experiments/exp001/docs/DPC_SPECIFICATION.md):

    y[n] = sum_{k=0}^{P-1} conj(r[k]) * x[n + k],   n = 0 .. N_RG-1,
    x[m] = 0 for m >= N_RG.

x: N_RG received complex samples, r: P pulse-reference samples (any windowing or
scaling already applied by the user), y: N_RG compressed outputs. Every real and
imaginary part is IEEE-754 binary32.

Two expected results are produced:

* exact: computed with rational arithmetic (fractions.Fraction), no rounding.
  The acceptance gate compares hardware outputs with it using a proven error bound
  that holds for any summation order.
* seq32: binary32 with round-to-nearest-even on every operation, in the contract
  order: product t = conj(r[k]) * x[n+k] as edu_complex_mul (four rounded
  products, rounded subtract/add), then acc = acc + t for k = 0 .. P-1 starting at
  +0. Hardware is expected to match it bit for bit.

Standard library only. NumPy is used solely by the optional cross-checks in
--selftest. This file is frozen by SHA-256 (ORACLE_MANIFEST.sha256) before any RTL
exists and is never imported by RTL or testbench code.

CLI:
    python3 dpc_ref.py --selftest
    python3 dpc_ref.py --output DIR           # vector files for all fixtures
    python3 dpc_ref.py --check VECTORS DUMP   # judge a hardware output dump (M2b)
"""
from __future__ import annotations

import argparse
import cmath
import math
import random
import struct
import sys
from fractions import Fraction
from pathlib import Path

SEED = 20261126
FIXTURES = [(8, 3), (8, 8), (5, 8), (1, 1), (64, 16), (256, 64)]   # (N_RG, P)

# ---------------------------------------------------------------- binary32 core
BIAS, FRAC_BITS, EMIN, EMAX = 127, 23, -126, 127
NEG_ZERO, POS_INF, NEG_INF = 0x80000000, 0x7F800000, 0xFF800000
MIN_SUB = Fraction(1, 2 ** 149)
U = Fraction(1, 2 ** 24)


def is_finite(bits: int) -> bool:
    return (bits & 0x7F800000) != 0x7F800000


def value(bits: int) -> Fraction:
    """Exact value of a finite binary32 pattern (signed zero -> 0)."""
    if not is_finite(bits):
        raise ValueError(f"non-finite input {bits:08X} is outside the contract")
    exp = (bits >> 23) & 0xFF
    frac = bits & 0x7FFFFF
    mag = Fraction(frac, 2 ** 149) if exp == 0 else \
        Fraction(frac + 2 ** 23) * Fraction(2) ** (exp - BIAS - FRAC_BITS)
    return -mag if bits >> 31 else mag


def _rne(x: Fraction) -> int:
    n, r = divmod(x.numerator, x.denominator)
    if 2 * r > x.denominator or (2 * r == x.denominator and n % 2):
        n += 1
    return n


def round32(q: Fraction) -> int:
    """Round a non-zero rational to binary32, RNE, subnormals, overflow to inf."""
    neg = q < 0
    a = -q if neg else q
    sign = NEG_ZERO if neg else 0
    e = a.numerator.bit_length() - a.denominator.bit_length()
    if Fraction(2) ** e > a:
        e -= 1
    if e < EMIN:
        return sign | _rne(a / MIN_SUB)            # 2^23 encodes the min normal correctly
    m = _rne(a / Fraction(2) ** (e - FRAC_BITS))
    if m == 2 ** 24:
        m, e = 2 ** 23, e + 1
    if e > EMAX:
        return sign | POS_INF
    return sign | ((e + BIAS) << 23) | (m - 2 ** 23)


def f_add(x: int, y: int) -> int:
    """binary32 addition of finite operands, IEEE signed-zero rules (RNE)."""
    s = value(x) + value(y)
    if s != 0:
        return round32(s)
    if value(x) == 0 and value(y) == 0:
        return NEG_ZERO if (x == NEG_ZERO and y == NEG_ZERO) else 0
    return 0                                       # exact cancellation -> +0


def f_mul(x: int, y: int) -> int:
    p = value(x) * value(y)
    if p == 0:
        return NEG_ZERO if ((x ^ y) >> 31) else 0
    return round32(p)


def f_neg(x: int) -> int:
    return x ^ NEG_ZERO


def cmul32(a_re: int, a_im: int, b_re: int, b_im: int) -> tuple[int, int]:
    """Same evaluation order as the validated edu_complex_mul."""
    re = f_add(f_mul(a_re, b_re), f_neg(f_mul(a_im, b_im)))
    im = f_add(f_mul(a_re, b_im), f_mul(a_im, b_re))
    return re, im


# ----------------------------------------------------------- DPC definitions
Cplx = tuple[int, int]          # (re_bits, im_bits)


def dpc_seq32(x: list[Cplx], r: list[Cplx]) -> list[Cplx]:
    n_rg, p = len(x), len(r)
    out = []
    for n in range(n_rg):
        acc_re, acc_im = 0, 0                      # +0, +0
        for k in range(p):
            xr, xi = x[n + k] if n + k < n_rg else (0, 0)
            t_re, t_im = cmul32(r[k][0], f_neg(r[k][1]), xr, xi)   # conj(r[k]) * x[n+k]
            acc_re, acc_im = f_add(acc_re, t_re), f_add(acc_im, t_im)
        out.append((acc_re, acc_im))
    return out


def dpc_exact(x: list[Cplx], r: list[Cplx]):
    """Exact y and the magnitude sums S used by the error bound."""
    n_rg, p = len(x), len(r)
    xv = [(value(a), value(b)) for a, b in x] + [(Fraction(0), Fraction(0))] * p
    rv = [(value(a), -value(b)) for a, b in r]                    # conj
    res = []
    for n in range(n_rg):
        y_re = y_im = s_re = s_im = Fraction(0)
        for k in range(p):
            cr, ci = rv[k]
            xr, xi = xv[n + k]
            y_re += cr * xr - ci * xi
            y_im += cr * xi + ci * xr
            s_re += abs(cr * xr) + abs(ci * xi)
            s_im += abs(cr * xi) + abs(ci * xr)
        res.append((y_re, y_im, s_re, s_im))
    return res


def tolerance(p: int, s: Fraction) -> Fraction:
    """|y_hw - y| <= g*S + (P+2)*2^-149,  g = (P+2)u / (1 - (P+2)u), u = 2^-24.

    Each term passes through at most P+2 roundings (one multiply, one
    subtract/add inside the complex product, at most P accumulations), whatever
    the summation order; the second term covers underflow.
    """
    m = p + 2
    g = m * U / (1 - m * U)
    return g * s + m * MIN_SUB


# ------------------------------------------------------------------ stimuli
def b32(v: float) -> int:
    """Nearest binary32 bit pattern of a Python float (RNE via struct)."""
    return struct.unpack(">I", struct.pack(">f", v))[0]


def c32(z: complex) -> Cplx:
    return b32(z.real), b32(z.imag)


def chirp_pulse(p: int, bw: float = 0.8) -> list[Cplx]:
    """Hamming-windowed linear FM pulse, unit energy (public textbook waveform)."""
    if p == 1:
        return [c32(1 + 0j)]
    z = []
    for k in range(p):
        w = 0.54 - 0.46 * math.cos(2 * math.pi * k / (p - 1))
        z.append(w * cmath.exp(1j * math.pi * bw * (k - p / 2) ** 2 / p))
    e = math.sqrt(sum(abs(v) ** 2 for v in z))
    return [c32(v / e) for v in z]


def random_pulse(rng: random.Random, p: int) -> list[Cplx]:
    return [c32(complex(rng.uniform(-1, 1), rng.uniform(-1, 1))) for _ in range(p)]


def impulse(n_rg: int, m0: int) -> list[Cplx]:
    return [c32(1 + 0j) if m == m0 else (0, 0) for m in range(n_rg)]


def uniform(rng: random.Random, n_rg: int) -> list[Cplx]:
    return [c32(complex(rng.uniform(-1, 1), rng.uniform(-1, 1))) for _ in range(n_rg)]


def wide_range(rng: random.Random, n_rg: int) -> list[Cplx]:
    """Finite values with magnitudes 2^-20 .. 1, random signs (alignment/cancellation)."""
    def one():
        return rng.choice((-1, 1)) * rng.uniform(1, 2) * 2.0 ** rng.randint(-21, -1)
    return [c32(complex(one(), one())) for _ in range(n_rg)]


def chirp_echo(rng: random.Random, n_rg: int, pulse: list[Cplx]) -> list[Cplx]:
    """Two echoes of the pulse (delays N/5 and N/2, amplitudes 1 and 0.3) plus noise."""
    p = len(pulse)
    rv = [complex(struct.unpack(">f", struct.pack(">I", a))[0],
                  struct.unpack(">f", struct.pack(">I", b))[0]) for a, b in pulse]
    x = [complex(rng.gauss(0, 0.05), rng.gauss(0, 0.05)) for _ in range(n_rg)]
    for d, amp in ((n_rg // 5, 1.0), (n_rg // 2, 0.3)):
        for k in range(p):
            if d + k < n_rg:
                x[d + k] += amp * rv[k]
    return [c32(v) for v in x]


def transactions(n_rg: int, p: int):
    """Ordered transactions for one fixture: (name, pulse or None (= keep), x)."""
    rng = random.Random(SEED * 1000 + n_rg * 7 + p)
    chirp = chirp_pulse(p)
    other = random_pulse(rng, p)
    return [
        ("impulse_first", chirp, impulse(n_rg, 0)),
        ("impulse_last", None, impulse(n_rg, n_rg - 1)),
        ("impulse_mid", None, impulse(n_rg, n_rg // 2)),
        ("chirp_echo", None, chirp_echo(rng, n_rg, chirp)),
        ("uniform", None, uniform(rng, n_rg)),
        ("reload_wide", other, wide_range(rng, n_rg)),
        ("uniform_after_reload", None, uniform(rng, n_rg)),
    ]


# ------------------------------------------------------------- vector files
def write_vectors(outdir: Path) -> None:
    """One file per fixture, VHDL-friendly tagged lines:

        T <i>          start of transaction i
        R <re> <im>    P pulse samples k = 0..P-1 (only when the pulse is (re)loaded)
        X <re> <im>    N_RG input samples
        Y <re> <im>    N_RG expected outputs (seq32, bit exact)
    """
    outdir.mkdir(parents=True, exist_ok=True)
    index = []
    for n_rg, p in FIXTURES:
        lines = [f"# EXP001 DPC vectors N_RG={n_rg} P={p} seed={SEED}",
                 "# T i | R re im (P lines, pulse load) | X re im (N_RG) | Y re im (N_RG)"]
        pulse = None
        for i, (name, new_pulse, x) in enumerate(transactions(n_rg, p)):
            lines.append(f"# transaction {i}: {name}")
            lines.append(f"T {i}")
            if new_pulse is not None:
                pulse = new_pulse
                lines += [f"R {a:08X} {b:08X}" for a, b in pulse]
            lines += [f"X {a:08X} {b:08X}" for a, b in x]
            lines += [f"Y {a:08X} {b:08X}" for a, b in dpc_seq32(x, pulse)]
        name = f"dpc_n{n_rg}_p{p}.txt"
        (outdir / name).write_text("\n".join(lines) + "\n")
        index.append(name)
        print(f"{name}: {len(transactions(n_rg, p))} transactions")
    (outdir / "INDEX.txt").write_text("\n".join(index) + "\n")


def read_vectors(path: Path):
    """Parse a vector file back into [(pulse, x, y_expected)]."""
    txs, pulse, cur = [], None, None
    for line in path.read_text().splitlines():
        if not line or line[0] == "#":
            continue
        tag, *f = line.split()
        if tag == "T":
            cur = {"R": [], "X": [], "Y": []}
            txs.append(cur)
        else:
            cur[tag].append((int(f[0], 16), int(f[1], 16)))
    out = []
    for t in txs:
        if t["R"]:
            pulse = t["R"]
        out.append((pulse, t["X"], t["Y"]))
    return out


# -------------------------------------------------------------- judging
def judge(pulse, x, y_hw):
    """Gate (error bound vs exact) and bit-exact (vs seq32) for one transaction."""
    exact = dpc_exact(x, pulse)
    seq = dpc_seq32(x, pulse)
    p = len(pulse)
    gate_fail, bit_fail, worst = [], [], Fraction(0)
    for n, ((er, ei, sr, si), (hr, hi), s) in enumerate(zip(exact, y_hw, seq)):
        for part, hv, ev, sv in (("re", hr, er, sr), ("im", hi, ei, si)):
            if not is_finite(hv):
                gate_fail.append((n, part, "non-finite"))
                continue
            err, tol = abs(value(hv) - ev), tolerance(p, sv)
            worst = max(worst, err / tol)
            if err > tol:
                gate_fail.append((n, part, float(err), float(tol)))
        if (hr, hi) != s:
            bit_fail.append((n, f"{hr:08X} {hi:08X}", f"{s[0]:08X} {s[1]:08X}"))
    return gate_fail, bit_fail, worst


def check_dump(vectors: Path, dump: Path) -> int:
    """DUMP: one line per output 'O <re> <im>' in transaction order."""
    ys = [tuple(int(v, 16) for v in l.split()[1:3])
          for l in dump.read_text().splitlines() if l.startswith("O ")]
    total_gate = total_bit = 0
    worst = Fraction(0)
    pos = 0
    for i, (pulse, x, _) in enumerate(read_vectors(vectors)):
        y_hw = ys[pos:pos + len(x)]
        pos += len(x)
        if len(y_hw) != len(x):
            print(f"FAIL transaction {i}: {len(y_hw)} outputs, expected {len(x)}")
            return 1
        g, b, w = judge(pulse, x, y_hw)
        total_gate += len(g)
        total_bit += len(b)
        worst = max(worst, w)
        for item in (g[:3] + b[:3]):
            print(f"  transaction {i}: {item}")
    if pos != len(ys):
        print(f"FAIL: {len(ys) - pos} extra outputs in dump")
        return 1
    print(f"gate failures={total_gate} bit-exact mismatches={total_bit} "
          f"worst err/tol={float(worst):.4f}")
    return 0 if (total_gate == 0 and total_bit == 0) else 1


# ------------------------------------------------------------------ selftest
def selftest() -> None:
    one, two = b32(1.0), b32(2.0)
    # 1. hand example: x = [1+2j, 3-1j], r = [1+1j]: y = conj(r)*x
    y = dpc_seq32([(one, two), (b32(3.0), b32(-1.0))], [(one, one)])
    assert y == [(b32(3.0), b32(1.0)), (b32(2.0), b32(-4.0))], y
    # 2. tail is zero padded: N=2, P=2, r = [1, 1] -> y = [x0+x1, x1]
    y = dpc_seq32([(one, 0), (two, 0)], [(one, 0), (one, 0)])
    assert [value(a) for a, _ in y] == [3, 2]
    # 3. impulse at m0 returns conj(r[m0-n]) exactly (alignment property)
    for n_rg, p in FIXTURES:
        pulse = chirp_pulse(p)
        for m0 in {0, n_rg - 1, n_rg // 2}:
            y = dpc_seq32(impulse(n_rg, m0), pulse)
            for n in range(n_rg):
                k = m0 - n
                want = (value(pulse[k][0]), -value(pulse[k][1])) if 0 <= k < p else (0, 0)
                assert (value(y[n][0]), value(y[n][1])) == want, (n_rg, p, m0, n)
    # 4. seq32 passes its own gate on every fixture transaction; bound is not vacuous
    worst = Fraction(0)
    for n_rg, p in FIXTURES:
        pulse = None
        for _, new_pulse, x in transactions(n_rg, p):
            pulse = new_pulse or pulse
            g, b, w = judge(pulse, x, dpc_seq32(x, pulse))
            assert not g and not b, (n_rg, p, g[:2])
            worst = max(worst, w)
    assert worst < 1
    # 5. a single dropped term must fail the gate (sensitivity)
    n_rg, p = 64, 16
    rng = random.Random(1)
    pulse, x = chirp_pulse(p), uniform(rng, n_rg)
    bad = dpc_seq32(x, pulse)
    t_re, t_im = cmul32(pulse[0][0], f_neg(pulse[0][1]), x[10][0], x[10][1])
    bad[10] = (f_add(bad[10][0], f_neg(t_re)), f_add(bad[10][1], f_neg(t_im)))
    g, _, _ = judge(pulse, x, bad)
    assert g, "gate did not detect a missing term"
    print(f"PASS: dpc_ref selftest (worst seq32 err/tol = {float(worst):.4f})")
    # 6. optional independent cross-checks with NumPy
    try:
        import numpy as np
    except ImportError:
        print("SKIP: numpy cross-checks (numpy not installed)")
        return
    f32 = lambda bits: np.array([bits], np.uint32).view(np.float32)[0]
    nchk = 0
    for n_rg, p in FIXTURES:
        pulse = None
        for _, new_pulse, x in transactions(n_rg, p):
            pulse = new_pulse or pulse
            xa = np.array([complex(f32(a), f32(b)) for a, b in x])
            ra = np.array([complex(f32(a), f32(b)) for a, b in pulse])
            # numpy.correlate(a, v, 'full')[n + P - 1] = sum_k a[n+k] * conj(v[k])
            full = np.correlate(xa, ra, "full")[p - 1:p - 1 + n_rg]
            ex = dpc_exact(x, pulse)
            for n in range(n_rg):
                d = abs(complex(float(ex[n][0]), float(ex[n][1])) - full[n])
                assert d <= 1e-12 * (1 + float(ex[n][2] + ex[n][3])), (n_rg, p, n, d)
            # float32 sequential loop in the same order must equal seq32 bit for bit
            seq = dpc_seq32(x, pulse)
            with np.errstate(all="ignore"):
                for n in range(n_rg):
                    ar = ai = np.float32(0)
                    for k in range(p):
                        cr, ci = f32(pulse[k][0]), -f32(pulse[k][1])
                        xr, xi = (f32(x[n + k][0]), f32(x[n + k][1])) if n + k < n_rg \
                            else (np.float32(0), np.float32(0))
                        tr = np.float32(cr * xr) - np.float32(ci * xi)
                        ti = np.float32(cr * xi) + np.float32(ci * xr)
                        ar, ai = np.float32(ar + tr), np.float32(ai + ti)
                    got = tuple(int(np.array([v], np.float32).view(np.uint32)[0]) for v in (ar, ai))
                    assert got == seq[n], (n_rg, p, n, got, seq[n])
            nchk += 1
    print(f"PASS: numpy {np.__version__} cross-checks ({nchk} transactions: "
          "numpy.correlate vs exact, float32 loop vs seq32 bit exact)")


def main(argv=None) -> int:
    ap = argparse.ArgumentParser(description="EXP001 DPC golden reference")
    ap.add_argument("--selftest", action="store_true")
    ap.add_argument("--output", type=Path)
    ap.add_argument("--check", nargs=2, type=Path, metavar=("VECTORS", "DUMP"))
    a = ap.parse_args(argv)
    if a.check:
        return check_dump(*a.check)
    if a.selftest or a.output is None:
        selftest()
    if a.output is not None:
        write_vectors(a.output)
    return 0


if __name__ == "__main__":
    sys.exit(main())

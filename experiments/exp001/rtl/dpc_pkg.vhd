-- dpc_pkg.vhd
-- Helpers for the EXP001 digital pulse compression (DPC) component.
-- VHDL-2008, IEEE standard packages only (ieee.float_pkg). No vendor IP.
--
-- Arithmetic helpers are the same correctly rounded binary32 operations, with
-- the same explicit float_pkg parameters, as the validated
-- experiments/edu_complex_arithmetic/rtl/edu_complex_mul.vhd (D-059):
-- round to nearest ties-to-even, 3 guard bits, check_error, denormalize.
--
-- cmac() is one multiply-accumulate step of the DPC contract (G3):
--   t      = conj(r) * x   (conj = sign flip of Im r, exact)
--   t_re   = sub(mul(cr, xr), mul(ci, xi))
--   t_im   = add(mul(cr, xi), mul(ci, xr))       cr = Re r, ci = -Im r
--   acc'   = add(acc, t)                         per part
-- Seven rounded operations per part pair, in exactly this order.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.fixed_float_types.all;   -- round_type literals (round_nearest)
use ieee.float_pkg.all;

package dpc_pkg is

  subtype t_word is std_logic_vector(31 downto 0);   -- binary32 bit pattern

  constant C_ZERO_WORD : t_word := (others => '0');  -- +0.0

  -- ceil(log2(n)) for n >= 1 (0 for n = 1).
  function clog2(n : positive) return natural;
  -- Address width for a memory of n words: at least 1 bit.
  function addr_width(n : positive) return positive;

  -- Flip the sign bit: exact negation, used for conj().
  function negate(v : t_word) return t_word;

  -- One DPC multiply-accumulate step (see header). Returns re & im (63..32 = re).
  function cmac(acc_re, acc_im, r_re, r_im, x_re, x_im : t_word)
    return std_logic_vector;

end package dpc_pkg;

package body dpc_pkg is

  constant C_EXP_W  : natural := 8;    -- binary32 exponent width
  constant C_FRAC_W : natural := 23;   -- binary32 fraction width
  constant C_GUARD  : natural := 3;    -- guard bits used by float_pkg rounding

  function clog2(n : positive) return natural is
    variable w : natural := 0;
    variable p : positive := 1;
  begin
    while p < n loop
      p := p * 2;
      w := w + 1;
    end loop;
    return w;
  end function clog2;

  function addr_width(n : positive) return positive is
  begin
    if clog2(n) < 1 then
      return 1;
    end if;
    return clog2(n);
  end function addr_width;

  function negate(v : t_word) return t_word is
    variable r : t_word := v;
  begin
    r(31) := not v(31);
    return r;
  end function negate;

  function to_f32(v : t_word) return float32 is
  begin
    return to_float(v, C_EXP_W, C_FRAC_W);
  end function to_f32;

  -- Each helper is one correctly rounded binary32 operation.
  function f_mul(l, r : float32) return float32 is
  begin
    return multiply(l, r,
                    round_style => round_nearest,
                    guard       => C_GUARD,
                    check_error => true,
                    denormalize => true);
  end function f_mul;

  function f_add(l, r : float32) return float32 is
  begin
    return add(l, r,
               round_style => round_nearest,
               guard       => C_GUARD,
               check_error => true,
               denormalize => true);
  end function f_add;

  function f_sub(l, r : float32) return float32 is
  begin
    return subtract(l, r,
                    round_style => round_nearest,
                    guard       => C_GUARD,
                    check_error => true,
                    denormalize => true);
  end function f_sub;

  function cmac(acc_re, acc_im, r_re, r_im, x_re, x_im : t_word)
    return std_logic_vector is
    variable cr, ci, xr, xi : float32;
    variable p_rr, p_ii     : float32;   -- cr*xr, ci*xi
    variable p_ri, p_ir     : float32;   -- cr*xi, ci*xr
    variable t_re, t_im     : float32;
    variable y              : std_logic_vector(63 downto 0);
  begin
    cr := to_f32(r_re);
    ci := to_f32(negate(r_im));            -- conj(r): exact sign flip
    xr := to_f32(x_re);
    xi := to_f32(x_im);

    p_rr := f_mul(cr, xr);
    p_ii := f_mul(ci, xi);
    p_ri := f_mul(cr, xi);
    p_ir := f_mul(ci, xr);

    t_re := f_sub(p_rr, p_ii);
    t_im := f_add(p_ri, p_ir);

    y(63 downto 32) := to_slv(f_add(to_f32(acc_re), t_re));
    y(31 downto 0)  := to_slv(f_add(to_f32(acc_im), t_im));
    return y;
  end function cmac;

end package body dpc_pkg;

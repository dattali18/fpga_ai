-- edu_complex_mul.vhd
-- Educational complex multiplier, IEEE-754 binary32 components.
-- VHDL-2008, IEEE standard packages only (ieee.float_pkg). No vendor IP.
--
--   y = a * b
--   y_re = (a_re * b_re) - (a_im * b_im)
--   y_im = (a_re * b_im) + (a_im * b_re)
--
-- Evaluation order is part of the contract: the four products are each
-- rounded to binary32, then one rounded subtraction (real) and one rounded
-- addition (imaginary). Six rounded operations in total; no fused
-- multiply-add and no three-multiplier (Gauss/Karatsuba) form, both of which
-- would give different rounding.
--
-- Numerical policy (stated explicitly in every call): round to nearest
-- ties-to-even, subnormals supported, special values (Inf, NaN) handled,
-- 3 guard bits.
--
-- Interface: identical to edu_complex_add. One registered output stage,
-- latency 1 clock cycle; out_valid follows in_valid; synchronous active-high
-- rst clears out_valid only; data registers are not reset and hold when
-- in_valid = '0'.

library ieee;
use ieee.std_logic_1164.all;
use ieee.fixed_float_types.all;   -- round_type literals (round_nearest)
use ieee.float_pkg.all;

entity edu_complex_mul is
  port (
    clk       : in  std_logic;
    rst       : in  std_logic;
    in_valid  : in  std_logic;
    a_re      : in  std_logic_vector(31 downto 0);
    a_im      : in  std_logic_vector(31 downto 0);
    b_re      : in  std_logic_vector(31 downto 0);
    b_im      : in  std_logic_vector(31 downto 0);
    out_valid : out std_logic;
    y_re      : out std_logic_vector(31 downto 0);
    y_im      : out std_logic_vector(31 downto 0)
  );
end entity edu_complex_mul;

architecture rtl of edu_complex_mul is

  constant C_EXP_W  : natural := 8;    -- binary32 exponent width
  constant C_FRAC_W : natural := 23;   -- binary32 fraction width
  constant C_GUARD  : natural := 3;    -- guard bits used by float_pkg rounding

  function to_f32(v : std_logic_vector(31 downto 0)) return float32 is
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

begin

  -- Valid flag: the only reset state.
  valid_p : process (clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        out_valid <= '0';
      else
        out_valid <= in_valid;
      end if;
    end if;
  end process valid_p;

  -- Result registers: loaded only for valid inputs, never reset.
  data_p : process (clk)
    variable ar, ai, br, bi : float32;
    variable p_rr, p_ii     : float32;   -- a_re*b_re, a_im*b_im
    variable p_ri, p_ir     : float32;   -- a_re*b_im, a_im*b_re
  begin
    if rising_edge(clk) then
      if in_valid = '1' then
        ar := to_f32(a_re);
        ai := to_f32(a_im);
        br := to_f32(b_re);
        bi := to_f32(b_im);

        p_rr := f_mul(ar, br);
        p_ii := f_mul(ai, bi);
        p_ri := f_mul(ar, bi);
        p_ir := f_mul(ai, br);

        y_re <= to_slv(f_sub(p_rr, p_ii));
        y_im <= to_slv(f_add(p_ri, p_ir));
      end if;
    end if;
  end process data_p;

end architecture rtl;

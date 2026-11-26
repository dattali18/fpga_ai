-- edu_complex_add.vhd
-- Educational complex adder, IEEE-754 binary32 components.
-- VHDL-2008, IEEE standard packages only (ieee.float_pkg). No vendor IP.
--
--   y = a + b
--   y_re = a_re + b_re
--   y_im = a_im + b_im
--
-- Numerical policy (stated explicitly in the calls below, not left to
-- package defaults): round to nearest ties-to-even, subnormals supported,
-- special values (Inf, NaN) handled, 3 guard bits. Each component is a single
-- correctly rounded binary32 addition; there is no shared rounding between the
-- real and imaginary parts.
--
-- Interface: one registered output stage, latency 1 clock cycle.
--   in_valid = '1' at a rising edge -> y_re/y_im take the result of the
--   inputs sampled at that edge and out_valid = '1' after it.
--   in_valid = '0' -> out_valid = '0' and y_re/y_im hold their last value.
--   rst = '1' (synchronous, active high) clears out_valid only.
-- Data registers are not reset; y_re/y_im are meaningful only when
-- out_valid = '1'.

library ieee;
use ieee.std_logic_1164.all;
use ieee.fixed_float_types.all;   -- round_type literals (round_nearest)
use ieee.float_pkg.all;

entity edu_complex_add is
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
end entity edu_complex_add;

architecture rtl of edu_complex_add is

  constant C_EXP_W   : natural := 8;    -- binary32 exponent width
  constant C_FRAC_W  : natural := 23;   -- binary32 fraction width
  constant C_GUARD   : natural := 3;    -- guard bits used by float_pkg rounding

  -- One correctly rounded binary32 addition with the policy fixed above.
  function fp_add(l, r : std_logic_vector(31 downto 0)) return std_logic_vector is
    variable fl, fr, fy : float32;
  begin
    fl := to_float(l, C_EXP_W, C_FRAC_W);
    fr := to_float(r, C_EXP_W, C_FRAC_W);
    fy := add(fl, fr,
              round_style => round_nearest,
              guard       => C_GUARD,
              check_error => true,
              denormalize => true);
    return to_slv(fy);
  end function fp_add;

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
  begin
    if rising_edge(clk) then
      if in_valid = '1' then
        y_re <= fp_add(a_re, b_re);
        y_im <= fp_add(a_im, b_im);
      end if;
    end if;
  end process data_p;

end architecture rtl;

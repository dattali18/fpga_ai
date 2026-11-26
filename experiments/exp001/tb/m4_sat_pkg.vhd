-- m4_sat_pkg.vhd
-- EXP001 M4 verification aid (not RTL, not synthesized): saturating shift amount
-- for simulating GHDL VHDL netlists (M4-TOOL-002, D-082).
--
-- Problem: ghdl --synth --out=vhdl writes the float_pkg normalisation shifts as
--   shift_left (unsigned (a), to_integer (unsigned (s)))
-- with a 32-bit shift amount s. When s >= 2**31, numeric_std.to_integer fails a
-- bound check (VHDL natural is 31 bits), although the synthesized hardware just
-- shifts everything out.
--
-- Fix: run_m4.sh rewrites, inside shift_left/shift_right calls only,
--   to_integer (unsigned (s))  ->  sat_shift (s)
-- sat_shift returns min(s, 2**30). Why the meaning is unchanged: numeric_std
-- shift_left/shift_right of an unsigned vector of length W by any amount >= W give
-- the same result (all zeros), and every vector in the netlist is far shorter than
-- 2**30 bits. Amounts below 2**30 are passed through unchanged. Vectors with
-- metavalues ('U', 'X', ...) take exactly the original path (to_integer, which
-- warns and returns 0), so behaviour before reset is unchanged too.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package m4_sat_pkg is
  constant C_SAT_SHIFT : natural := 2 ** 30;
  function sat_shift(v : std_logic_vector) return natural;
end package m4_sat_pkg;

package body m4_sat_pkg is

  function sat_shift(v : std_logic_vector) return natural is
    constant C_LEN : natural := v'length;
    variable u     : unsigned(C_LEN - 1 downto 0);
  begin
    u := unsigned(v);
    if is_x(v) then
      return to_integer(u);                     -- original behaviour (warn, 0)
    end if;
    if C_LEN > 30 then
      if u(C_LEN - 1 downto 30) /= 0 then
        return C_SAT_SHIFT;                     -- amount >= 2**30: saturate
      end if;
      return to_integer(u(29 downto 0));
    end if;
    return to_integer(u);
  end function sat_shift;

end package body m4_sat_pkg;

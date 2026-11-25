-- Minimal IEEE-754 binary32 registered scalar adder using VHDL-2008 ieee.float_pkg.
-- Toolchain simulation and synthesis smoke test only; independent of EXP001 requirements.

library ieee;
use ieee.std_logic_1164.all;
use ieee.float_pkg.all;

entity smoke_fp32_add is
  port (
    clk    : in  std_logic;
    rst    : in  std_logic;
    a_bits : in  std_logic_vector(31 downto 0);
    b_bits : in  std_logic_vector(31 downto 0);
    y_bits : out std_logic_vector(31 downto 0)
  );
end entity smoke_fp32_add;

architecture rtl of smoke_fp32_add is
begin
  p_add : process(clk)
    variable v_a   : float32;
    variable v_b   : float32;
    variable v_sum : float32;
  begin
    if rising_edge(clk) then
      if rst = '1' then
        y_bits <= (others => '0');
      else
        v_a    := to_float(a_bits, 8, 23);
        v_b    := to_float(b_bits, 8, 23);
        v_sum  := v_a + v_b;
        y_bits <= to_slv(v_sum);
      end if;
    end if;
  end process p_add;
end architecture rtl;

-- edu_register.vhd
-- Introductory 8-bit register: synchronous active-high reset (priority)
-- and clock enable. VHDL-2008, IEEE standard packages only.
--
-- Behaviour at each rising edge of clk (matches golden.py next_state):
--   rst = '1'           -> q <= x"00"
--   rst = '0', en = '1' -> q <= d
--   otherwise           -> q holds

library ieee;
use ieee.std_logic_1164.all;

entity edu_register is
  port (
    clk : in  std_logic;
    rst : in  std_logic;
    en  : in  std_logic;
    d   : in  std_logic_vector(7 downto 0);
    q   : out std_logic_vector(7 downto 0)
  );
end entity edu_register;

architecture rtl of edu_register is
begin

  reg_p : process (clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        q <= (others => '0');
      elsif en = '1' then
        q <= d;
      end if;
    end if;
  end process reg_p;

end architecture rtl;

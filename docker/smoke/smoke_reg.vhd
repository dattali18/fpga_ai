-- Minimal vendor-independent VHDL-2008 registered pass-through entity.
-- Toolchain smoke test only; completely independent of EXP001 DSP requirements.

library ieee;
use ieee.std_logic_1164.all;

entity smoke_reg is
  generic (
    G_WIDTH : positive := 8
  );
  port (
    clk   : in  std_logic;
    rst   : in  std_logic;
    d_in  : in  std_logic_vector(G_WIDTH - 1 downto 0);
    q_out : out std_logic_vector(G_WIDTH - 1 downto 0)
  );
end entity smoke_reg;

architecture rtl of smoke_reg is
begin
  p_reg : process(clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        q_out <= (others => '0');
      else
        q_out <= d_in;
      end if;
    end if;
  end process p_reg;
end architecture rtl;

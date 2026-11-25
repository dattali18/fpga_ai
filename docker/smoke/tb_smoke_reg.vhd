-- Standalone VHDL-2008 testbench for smoke_reg (pure GHDL verification).

library ieee;
use ieee.std_logic_1164.all;

entity tb_smoke_reg is
end entity tb_smoke_reg;

architecture sim of tb_smoke_reg is
  constant C_WIDTH : positive := 8;
  signal clk       : std_logic := '0';
  signal rst       : std_logic := '1';
  signal d_in      : std_logic_vector(C_WIDTH - 1 downto 0) := (others => '0');
  signal q_out     : std_logic_vector(C_WIDTH - 1 downto 0);
  signal sim_done  : boolean := false;
begin
  u_dut : entity work.smoke_reg
    generic map (
      G_WIDTH => C_WIDTH
    )
    port map (
      clk   => clk,
      rst   => rst,
      d_in  => d_in,
      q_out => q_out
    );

  p_clk : process
  begin
    while not sim_done loop
      clk <= '0';
      wait for 5 ns;
      clk <= '1';
      wait for 5 ns;
    end loop;
    wait;
  end process p_clk;

  p_stim : process
  begin
    rst  <= '1';
    d_in <= x"A5";
    wait until rising_edge(clk);
    wait until falling_edge(clk);
    assert q_out = x"00"
      report "Reset check failed: expected 0x00, got 0x" & to_hstring(q_out)
      severity failure;

    rst  <= '0';
    d_in <= x"5A";
    wait until rising_edge(clk);
    wait until falling_edge(clk);
    assert q_out = x"5A"
      report "Vector 1 failed: expected 0x5A, got 0x" & to_hstring(q_out)
      severity failure;

    d_in <= x"C3";
    wait until rising_edge(clk);
    wait until falling_edge(clk);
    assert q_out = x"C3"
      report "Vector 2 failed: expected 0xC3, got 0x" & to_hstring(q_out)
      severity failure;

    report "PASS: tb_smoke_reg completed." severity note;
    sim_done <= true;
    wait;
  end process p_stim;
end architecture sim;

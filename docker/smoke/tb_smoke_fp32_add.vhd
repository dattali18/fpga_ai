-- Standalone VHDL-2008 testbench for smoke_fp32_add (ieee.float_pkg verification).

library ieee;
use ieee.std_logic_1164.all;

entity tb_smoke_fp32_add is
end entity tb_smoke_fp32_add;

architecture sim of tb_smoke_fp32_add is
  type t_vec is record
    a   : std_logic_vector(31 downto 0);
    b   : std_logic_vector(31 downto 0);
    exp : std_logic_vector(31 downto 0);
  end record t_vec;

  type t_vec_array is array (natural range <>) of t_vec;

  constant C_VECS : t_vec_array := (
    -- 1.5 + 2.25 = 3.75
    0 => (a => x"3FC00000", b => x"40100000", exp => x"40700000"),
    -- -0.5 + 0.5 = +0.0
    1 => (a => x"BF000000", b => x"3F000000", exp => x"00000000"),
    -- 1.25 + (-3.5) = -2.25
    2 => (a => x"3FA00000", b => x"C0600000", exp => x"C0100000"),
    -- 12.5 + 0.125 = 12.625
    3 => (a => x"41480000", b => x"3E000000", exp => x"414A0000")
  );

  signal clk      : std_logic := '0';
  signal rst      : std_logic := '1';
  signal a_bits   : std_logic_vector(31 downto 0) := (others => '0');
  signal b_bits   : std_logic_vector(31 downto 0) := (others => '0');
  signal y_bits   : std_logic_vector(31 downto 0);
  signal sim_done : boolean := false;
begin
  u_dut : entity work.smoke_fp32_add
    port map (
      clk    => clk,
      rst    => rst,
      a_bits => a_bits,
      b_bits => b_bits,
      y_bits => y_bits
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
    rst    <= '1';
    a_bits <= C_VECS(0).a;
    b_bits <= C_VECS(0).b;
    wait until rising_edge(clk);
    wait until falling_edge(clk);
    assert y_bits = x"00000000"
      report "Reset check failed: expected 0x00000000, got 0x" & to_hstring(y_bits)
      severity failure;

    rst <= '0';
    for i in C_VECS'range loop
      a_bits <= C_VECS(i).a;
      b_bits <= C_VECS(i).b;
      wait until rising_edge(clk);
      wait until falling_edge(clk);
      assert y_bits = C_VECS(i).exp
        report "FP32 vector " & integer'image(i) & " mismatch: expected 0x" &
               to_hstring(C_VECS(i).exp) & ", got 0x" & to_hstring(y_bits)
        severity failure;
    end loop;

    report "PASS: tb_smoke_fp32_add completed." severity note;
    sim_done <= true;
    wait;
  end process p_stim;
end architecture sim;

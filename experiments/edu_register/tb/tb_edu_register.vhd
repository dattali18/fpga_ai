-- tb_edu_register.vhd
-- Self-checking testbench for edu_register. VHDL-2008, IEEE/std packages only.
--
-- Method: inputs are changed on the falling edge, q is checked shortly after
-- the following rising edge against a reference model that mirrors
-- golden.py next_state(q, d, reset, enable). Every check also compares
-- against an explicit literal expected value for the scenario.
-- Ends with a PASS note, or a failure-severity assertion if any check failed.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use std.env.all;

entity tb_edu_register is
end entity tb_edu_register;

architecture sim of tb_edu_register is

  constant CLK_PERIOD : time := 10 ns;
  constant CHECK_DLY  : time := 1 ns;  -- sample point after rising edge

  signal clk  : std_logic := '0';
  signal rst  : std_logic := '0';
  signal en   : std_logic := '0';
  signal d    : std_logic_vector(7 downto 0) := (others => '0');
  signal q    : std_logic_vector(7 downto 0);
  signal done : boolean := false;

  -- Reference model, same priority as golden.py: reset, then enable, else hold.
  function next_state(qv, dv : std_logic_vector(7 downto 0);
                      reset, enable : std_logic)
    return std_logic_vector is
  begin
    if reset = '1' then
      return x"00";
    elsif enable = '1' then
      return dv;
    else
      return qv;
    end if;
  end function next_state;

begin

  dut : entity work.edu_register
    port map (clk => clk, rst => rst, en => en, d => d, q => q);

  clk_p : process
  begin
    while not done loop
      clk <= '0';
      wait for CLK_PERIOD / 2;
      clk <= '1';
      wait for CLK_PERIOD / 2;
    end loop;
    wait;
  end process clk_p;

  stim_p : process
    variable model  : std_logic_vector(7 downto 0) := (others => 'U');
    variable errors : natural := 0;
    variable checks : natural := 0;

    -- Apply inputs on falling edge, advance one rising edge, then check q
    -- against both the reference model and the scenario's literal expectation.
    procedure step (
      constant r_i      : in std_logic;
      constant e_i      : in std_logic;
      constant d_i      : in std_logic_vector(7 downto 0);
      constant expected : in std_logic_vector(7 downto 0);
      constant tag      : in string) is
    begin
      wait until falling_edge(clk);
      rst <= r_i;
      en  <= e_i;
      d   <= d_i;
      wait for CHECK_DLY;
      assert q = model
        report tag & ": q changed before rising edge"
        severity failure;
      wait until rising_edge(clk);
      model := next_state(model, d_i, r_i, e_i);
      wait for CHECK_DLY;
      checks := checks + 1;
      if q /= expected or q /= model then
        errors := errors + 1;
      end if;
      assert q = expected
        report tag & ": q=" & to_hstring(q) & " expected=" & to_hstring(expected)
        severity error;
      assert q = model
        report tag & ": q=" & to_hstring(q) & " model=" & to_hstring(model)
        severity error;
    end procedure step;

    -- Check that q stays stable between edges (no change before next edge).
    procedure check_stable (constant expected : in std_logic_vector(7 downto 0);
                            constant tag      : in string) is
    begin
      wait until falling_edge(clk);
      checks := checks + 1;
      if q /= expected then
        errors := errors + 1;
      end if;
      assert q = expected
        report tag & ": q changed between edges, q=" & to_hstring(q)
               & " expected=" & to_hstring(expected)
        severity error;
    end procedure check_stable;

  begin
    -- 1. Reset (enable low): q must go to zero from undefined power-up state.
    step('1', '0', x"A5", x"00", "T1 reset, en=0");
    step('1', '0', x"A5", x"00", "T1 reset held");

    -- 2. Capture: single enabled write.
    step('0', '1', x"3C", x"3C", "T2 capture");
    check_stable(x"3C", "T2 stable after capture");

    -- 3. Hold: enable low, d changes every cycle, q must not follow.
    step('0', '0', x"FF", x"3C", "T3 hold d=FF");
    step('0', '0', x"00", x"3C", "T3 hold d=00");
    step('0', '0', x"C3", x"3C", "T3 hold d=C3");

    -- 4. Consecutive writes: enable held high, new value every cycle.
    step('0', '1', x"01", x"01", "T4 write 01");
    step('0', '1', x"02", x"02", "T4 write 02");
    step('0', '1', x"80", x"80", "T4 write 80");
    step('0', '1', x"FF", x"FF", "T4 write FF");
    step('0', '1', x"55", x"55", "T4 write 55");
    step('0', '1', x"AA", x"AA", "T4 write AA");

    -- 5. Reset priority: rst and en both high, d non-zero -> q must be zero.
    step('1', '1', x"5A", x"00", "T5 reset priority over enable");
    -- Reload, then assert both again with d = FF (all bits would be set by en).
    step('0', '1', x"77", x"77", "T5 reload");
    step('1', '1', x"FF", x"00", "T5 reset priority, d=FF");
    step('1', '1', x"FF", x"00", "T5 reset priority held");

    -- 6. Reset from non-zero with enable low.
    step('0', '1', x"E7", x"E7", "T6 load");
    step('1', '0', x"18", x"00", "T6 reset, en=0");

    -- 7. Hold after reset, then capture after reset release.
    step('0', '0', x"99", x"00", "T7 hold zero after reset");
    step('0', '1', x"99", x"99", "T7 capture after reset release");

    -- Summary
    done <= true;
    assert errors = 0
      report "FAIL: " & integer'image(errors) & " of " & integer'image(checks)
             & " checks failed"
      severity failure;
    report "PASS: all " & integer'image(checks) & " checks passed" severity note;
    finish;
  end process stim_p;

end architecture sim;

-- tb_edu_complex_mul.vhd
-- Self-checking, vector-driven testbench for edu_complex_mul.
-- VHDL-2008, std/IEEE packages only.
--
-- Expected results come only from reference/complex_ref.py (exact rational
-- arithmetic, one IEEE-754 rounding per operation). Nothing here models the
-- arithmetic. One vector file per run (generic G_VECTOR_FILE); each line is
--   a_re a_im b_re b_im y_re y_im nan_re nan_im
-- with 8-digit hex words and 0/1 NaN flags. Lines starting with '#' are
-- comments. A flag of 1 means "any NaN" for that component; otherwise the
-- 32-bit result must match exactly (including the sign of zero).
--
-- Timing: inputs change on the falling edge; outputs are checked 1 ns after
-- the next rising edge (latency 1). Vectors are applied back to back, one per
-- clock. Mismatches are counted (severity error, first 20 printed); a non-zero
-- count ends the run with severity failure. After the vectors, interface
-- checks cover hold (in_valid = '0') and reset of out_valid.

library ieee;
use ieee.std_logic_1164.all;

use std.textio.all;
use std.env.all;

entity tb_edu_complex_mul is
  generic (
    G_VECTOR_FILE : string := "mul_directed.txt"
  );
end entity tb_edu_complex_mul;

architecture sim of tb_edu_complex_mul is

  constant CLK_PERIOD : time    := 10 ns;
  constant CHECK_DLY  : time    := 1 ns;
  constant MAX_PRINT  : natural := 20;

  subtype t_word is std_logic_vector(31 downto 0);

  signal clk       : std_logic := '0';
  signal rst       : std_logic := '1';
  signal in_valid  : std_logic := '0';
  signal a_re      : t_word    := (others => '0');
  signal a_im      : t_word    := (others => '0');
  signal b_re      : t_word    := (others => '0');
  signal b_im      : t_word    := (others => '0');
  signal out_valid : std_logic;
  signal y_re      : t_word;
  signal y_im      : t_word;
  signal done      : boolean   := false;

  function is_nan(v : t_word) return boolean is
  begin
    return v(30 downto 23) = "11111111" and v(22 downto 0) /= (22 downto 0 => '0');
  end function is_nan;

  -- Exact bit match, or class match when the reference expects NaN.
  function matches(got, exp : t_word; nan_flag : integer) return boolean is
  begin
    if nan_flag = 1 then
      return is_nan(got);
    end if;
    return got = exp;
  end function matches;

begin

  dut : entity work.edu_complex_mul
    port map (
      clk => clk, rst => rst, in_valid => in_valid,
      a_re => a_re, a_im => a_im, b_re => b_re, b_im => b_im,
      out_valid => out_valid, y_re => y_re, y_im => y_im);

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
    file     vf      : text;
    variable fstat   : file_open_status;
    variable l       : line;
    variable good    : boolean;
    variable v_are, v_aim, v_bre, v_bim, v_yre, v_yim : t_word;
    variable n_re, n_im : integer;
    variable vectors : natural := 0;
    variable checks  : natural := 0;
    variable errors  : natural := 0;
    variable line_no : natural := 0;
    variable held_re, held_im : t_word;

    procedure fail_parse(field : string) is
    begin
      assert false
        report G_VECTOR_FILE & ":" & integer'image(line_no) &
               ": cannot parse field " & field
        severity failure;
    end procedure fail_parse;

    procedure check(cond : boolean; msg : string) is
    begin
      checks := checks + 1;
      if not cond then
        errors := errors + 1;
        if errors <= MAX_PRINT then
          report "MISMATCH " & msg severity error;
        end if;
      end if;
    end procedure check;

  begin
    -------------------------------------------------------------- reset
    rst <= '1';
    in_valid <= '1';                       -- reset must win over in_valid
    wait until rising_edge(clk);
    wait until rising_edge(clk);
    wait for CHECK_DLY;
    check(out_valid = '0', "out_valid not cleared by reset");
    wait until falling_edge(clk);
    rst <= '0';
    in_valid <= '0';

    ------------------------------------------------------------ vectors
    file_open(fstat, vf, G_VECTOR_FILE, read_mode);
    assert fstat = open_ok
      report "cannot open vector file " & G_VECTOR_FILE severity failure;

    while not endfile(vf) loop
      readline(vf, l);
      line_no := line_no + 1;
      next when l = null or l'length = 0;
      next when l(l'low) = '#';

      hread(l, v_are, good); if not good then fail_parse("a_re");   end if;
      hread(l, v_aim, good); if not good then fail_parse("a_im");   end if;
      hread(l, v_bre, good); if not good then fail_parse("b_re");   end if;
      hread(l, v_bim, good); if not good then fail_parse("b_im");   end if;
      hread(l, v_yre, good); if not good then fail_parse("y_re");   end if;
      hread(l, v_yim, good); if not good then fail_parse("y_im");   end if;
      read(l, n_re, good);   if not good then fail_parse("nan_re"); end if;
      read(l, n_im, good);   if not good then fail_parse("nan_im"); end if;

      -- drive on the falling edge
      wait until falling_edge(clk);
      a_re <= v_are; a_im <= v_aim; b_re <= v_bre; b_im <= v_bim;
      in_valid <= '1';

      -- check after the rising edge (latency 1)
      wait until rising_edge(clk);
      wait for CHECK_DLY;
      vectors := vectors + 1;
      check(out_valid = '1', "out_valid low, line " & integer'image(line_no));
      check(matches(y_re, v_yre, n_re),
            "y_re line " & integer'image(line_no) & ": a=(" &
            to_hstring(v_are) & "," & to_hstring(v_aim) & ") b=(" &
            to_hstring(v_bre) & "," & to_hstring(v_bim) & ") got=" & to_hstring(y_re) & " exp=" & to_hstring(v_yre) &
            " nan_expected=" & integer'image(n_re));
      check(matches(y_im, v_yim, n_im),
            "y_im line " & integer'image(line_no) & ": a=(" &
            to_hstring(v_are) & "," & to_hstring(v_aim) & ") b=(" &
            to_hstring(v_bre) & "," & to_hstring(v_bim) & ") got=" & to_hstring(y_im) & " exp=" & to_hstring(v_yim) &
            " nan_expected=" & integer'image(n_im));
    end loop;
    file_close(vf);
    assert vectors > 0 report "no vectors in " & G_VECTOR_FILE severity failure;

    ------------------------------------------------- interface checks
    -- Hold: in_valid = '0' with new operands; outputs must not change.
    held_re := y_re;
    held_im := y_im;
    wait until falling_edge(clk);
    in_valid <= '0';
    a_re <= x"3F800000"; a_im <= x"40000000";      -- 1.0, 2.0
    b_re <= x"40400000"; b_im <= x"40800000";      -- 3.0, 4.0
    for i in 1 to 3 loop
      wait until rising_edge(clk);
      wait for CHECK_DLY;
      check(out_valid = '0', "out_valid high without in_valid");
      check(y_re = held_re and y_im = held_im, "outputs changed while in_valid = '0'");
    end loop;

    -- Reset clears out_valid even with in_valid = '1'.
    wait until falling_edge(clk);
    in_valid <= '1';
    rst <= '1';
    wait until rising_edge(clk);
    wait for CHECK_DLY;
    check(out_valid = '0', "out_valid high during reset");

    -- Release reset: next valid input is processed normally.
    wait until falling_edge(clk);
    rst <= '0';
    wait until rising_edge(clk);
    wait for CHECK_DLY;
    check(out_valid = '1', "out_valid low after reset release");

    ------------------------------------------------------------ summary
    done <= true;
    report G_VECTOR_FILE & ": " & integer'image(vectors) & " vectors, " &
           integer'image(checks) & " checks, " & integer'image(errors) & " errors"
      severity note;
    assert errors = 0
      report "FAIL: " & G_VECTOR_FILE severity failure;
    report "PASS: " & G_VECTOR_FILE severity note;
    finish;
  end process stim_p;

end architecture sim;

-- tb_dpc.vhd
-- Self-checking, vector-driven testbench for the EXP001 DPC component (M2b).
-- VHDL-2008, std/IEEE packages only. Plain GHDL testbench (D-065).
--
-- Expected results come only from the vector file written by the frozen golden
-- reference experiments/exp001/reference/dpc_ref.py (spec G1). Nothing here
-- models the arithmetic. Lines of the vector file:
--   T <i>          start of transaction i
--   R <re> <im>    P pulse samples (only when the pulse is (re)loaded)
--   X <re> <im>    N_RG input samples
--   Y <re> <im>    N_RG expected outputs (bit exact)
-- Every output is written to G_DUMP_FILE as "O <re> <im>" for dpc_ref.py --check.
--
-- Timing: inputs are driven on the falling edge; transfers and outputs are
-- sampled at the rising edge (pre-edge values, i.e. the values the DUT sees).
-- With G_STALL_PCT > 0, random idle cycles are inserted on ref_valid and
-- in_valid (a raised valid is held until its transfer) and random out_ready = 0
-- cycles are inserted.
--
-- Protocol checks (each counted as a check):
--   * output data and out_last stable while out_valid = 1 and out_ready = 0,
--     and out_valid not withdrawn before the transfer;
--   * out_last = 1 exactly on the last output of each block;
--   * before any pulse is loaded, in_valid = 1 for 5 cycles produces no transfer;
--   * from the last input transfer of a block until its last output transfer,
--     in_ready = 0 (and ref_ready = 0);
--   * directed priority check (planner addition): after the first pulse load,
--     ref_valid = 1 and in_valid = 1 are offered in the same idle cycle; exactly
--     one transfer (the ref one) must happen. The pulse load is then completed
--     with the same pulse and the block runs as normal;
--   * after the final transaction, rst for one edge, then in_ready = 0.
-- Cycle report (G_STALL_PCT = 0): CYCLES t=<i> latency=<c> period=<c or NA>.

library ieee;
use ieee.std_logic_1164.all;
use ieee.math_real.all;

use std.textio.all;
use std.env.all;

entity tb_dpc is
  generic (
    G_N_RG        : positive := 8;
    G_P           : positive := 3;
    G_LANES       : positive := 1;
    G_VECTOR_FILE : string   := "dpc_n8_p3.txt";
    G_DUMP_FILE   : string   := "dump_n8_p3.txt";
    G_STALL_PCT   : natural  := 0;     -- 0 to 100
    G_SEED        : natural  := 1
  );
end entity tb_dpc;

architecture sim of tb_dpc is

  constant CLK_PERIOD : time    := 10 ns;
  constant MAX_PRINT  : natural := 20;
  constant MAX_TX     : natural := 64;

  subtype t_word is std_logic_vector(31 downto 0);
  type t_words is array (natural range <>) of t_word;
  type t_ints is array (0 to MAX_TX - 1) of integer;

  signal clk       : std_logic := '0';
  signal rst       : std_logic := '1';
  signal ref_valid : std_logic := '0';
  signal ref_ready : std_logic;
  signal ref_re    : t_word    := (others => '0');
  signal ref_im    : t_word    := (others => '0');
  signal in_valid  : std_logic := '0';
  signal in_ready  : std_logic;
  signal in_re     : t_word    := (others => '0');
  signal in_im     : t_word    := (others => '0');
  signal out_valid : std_logic;
  signal out_ready : std_logic := '0';
  signal out_re    : t_word;
  signal out_im    : t_word;
  signal out_last  : std_logic;
  signal done      : boolean   := false;

begin

  assert G_STALL_PCT <= 100 report "G_STALL_PCT must be 0..100" severity failure;

  dut : entity work.dpc
    generic map (G_N_RG => G_N_RG, G_P => G_P, G_LANES => G_LANES)
    port map (
      clk => clk, rst => rst,
      ref_valid => ref_valid, ref_ready => ref_ready, ref_re => ref_re, ref_im => ref_im,
      in_valid => in_valid, in_ready => in_ready, in_re => in_re, in_im => in_im,
      out_valid => out_valid, out_ready => out_ready, out_re => out_re, out_im => out_im,
      out_last => out_last);

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

  main_p : process
    file     vf : text;
    file     df : text;
    variable fstat : file_open_status;
    variable l, ol : line;
    variable good  : boolean;
    variable ch    : character;
    variable line_no : natural := 0;
    variable pending_t : boolean := false;   -- a 'T' line was consumed already

    -- current transaction
    variable r_re_v, r_im_v : t_words(0 to G_P - 1);
    variable x_re_v, x_im_v : t_words(0 to G_N_RG - 1);
    variable y_re_v, y_im_v : t_words(0 to G_N_RG - 1);
    variable nr, nx, ny     : natural;
    variable have_tx        : boolean;
    variable pulse_ever     : boolean := false;

    -- counters
    variable cycle   : natural := 0;
    variable n_tx    : natural := 0;
    variable outputs : natural := 0;
    variable checks  : natural := 0;
    variable errors  : natural := 0;
    variable first_in : t_ints := (others => -1);
    variable last_out : t_ints := (others => -1);

    -- randomness
    variable seed1 : positive := 1 + (G_SEED mod 2147483561);
    variable seed2 : positive := 1 + ((G_SEED * 7 + 13) mod 2147483397);

    procedure stall(result : out boolean) is
      variable u : real;
    begin
      if G_STALL_PCT = 0 then
        result := false;
      else
        uniform(seed1, seed2, u);
        result := u * 100.0 < real(G_STALL_PCT);
      end if;
    end procedure stall;

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

    procedure fail_parse(msg : string) is
    begin
      assert false
        report G_VECTOR_FILE & ":" & integer'image(line_no) & ": " & msg
        severity failure;
    end procedure fail_parse;

    procedure read_pair(a, b : out t_word) is
      variable ok : boolean;
    begin
      hread(l, a, ok);
      if not ok then fail_parse("cannot parse first word"); end if;
      hread(l, b, ok);
      if not ok then fail_parse("cannot parse second word"); end if;
    end procedure read_pair;

    -- Read the next transaction into r_*/x_*/y_*; have_tx = false at end of file.
    procedure read_tx is
      variable in_tx : boolean := pending_t;
      variable a, b  : t_word;
    begin
      nr := 0; nx := 0; ny := 0;
      pending_t := false;
      while not endfile(vf) loop
        readline(vf, l);
        line_no := line_no + 1;
        next when l = null or l'length = 0;
        ch := l(l'low);
        next when ch = '#';
        if ch = 'T' then
          if in_tx then
            pending_t := true;
            exit;
          end if;
          in_tx := true;
        else
          read(l, ch);                                -- consume the tag
          read_pair(a, b);
          case ch is
            when 'R' =>
              if nr >= G_P then fail_parse("too many R lines"); end if;
              r_re_v(nr) := a; r_im_v(nr) := b; nr := nr + 1;
            when 'X' =>
              if nx >= G_N_RG then fail_parse("too many X lines"); end if;
              x_re_v(nx) := a; x_im_v(nx) := b; nx := nx + 1;
            when 'Y' =>
              if ny >= G_N_RG then fail_parse("too many Y lines"); end if;
              y_re_v(ny) := a; y_im_v(ny) := b; ny := ny + 1;
            when others =>
              fail_parse("unknown tag " & ch);
          end case;
        end if;
      end loop;
      have_tx := in_tx;
      if in_tx then
        if nx /= G_N_RG or ny /= G_N_RG or not (nr = 0 or nr = G_P) then
          fail_parse("transaction " & integer'image(n_tx) & " has wrong line counts");
        end if;
      end if;
    end procedure read_tx;

    -- transaction state
    variable ri, xi, oi       : natural;
    variable ref_pend, in_pend : boolean;      -- valid raised, transfer pending
    variable s                : boolean;
    variable prio_todo        : boolean;
    variable prio_cycle       : boolean;
    variable inputs_done      : boolean;
    variable held_valid       : boolean;       -- previous edge: out_valid = 1, out_ready = 0
    variable held_re, held_im : t_word;
    variable held_last        : std_logic;
    variable tx_cycles        : natural;
    variable limit            : natural;
    variable ref_x, in_x      : boolean;

  begin
    ---------------------------------------------------------------- reset
    rst <= '1';
    wait until rising_edge(clk);
    wait until rising_edge(clk);
    wait until falling_edge(clk);
    rst <= '0';

    file_open(fstat, vf, G_VECTOR_FILE, read_mode);
    assert fstat = open_ok report "cannot open vector file " & G_VECTOR_FILE severity failure;
    file_open(fstat, df, G_DUMP_FILE, write_mode);
    assert fstat = open_ok report "cannot open dump file " & G_DUMP_FILE severity failure;

    ---------------------------------- no block accepted before any pulse
    in_valid <= '1';
    in_re <= x"3F800000";
    in_im <= x"3F800000";
    for c in 1 to 5 loop
      wait until rising_edge(clk);
      cycle := cycle + 1;
      check(in_ready = '0', "in_ready = 1 before any pulse was loaded (cycle " &
                            integer'image(c) & ")");
      wait until falling_edge(clk);
    end loop;
    in_valid <= '0';

    -- Generous watchdog per transaction (cycles).
    limit := 1000 + 20 * (G_P + G_N_RG * (G_P + 4));

    ------------------------------------------------------- transactions
    loop
      read_tx;
      exit when not have_tx;
      assert n_tx < MAX_TX report "too many transactions" severity failure;
      if nr = G_P then
        pulse_ever := true;
      end if;
      assert pulse_ever report "first transaction has no pulse" severity failure;

      ri := 0; xi := 0; oi := 0;
      if nr = 0 then
        ri := G_P;                                  -- pulse kept
      end if;
      ref_pend := false; in_pend := false;
      prio_todo := (n_tx = 0);
      inputs_done := false;
      held_valid := false;
      tx_cycles := 0;

      while oi < G_N_RG loop
        -- (we are just after a rising edge; move to the falling edge and drive)
        wait until falling_edge(clk);
        prio_cycle := false;

        -- pulse stream
        if ri < G_P then
          if not ref_pend then
            stall(s);
            if not s then
              ref_re <= r_re_v(ri); ref_im <= r_im_v(ri);
              ref_valid <= '1';
              ref_pend := true;
            else
              ref_valid <= '0';
            end if;
          end if;
        else
          ref_valid <= '0';
        end if;

        -- input stream: only after the pulse load is complete
        if ri = G_P and xi < G_N_RG then
          if prio_todo and not in_pend then
            -- directed priority check: offer ref (k = 0 again) and in together
            ref_re <= r_re_v(0); ref_im <= r_im_v(0);
            ref_valid <= '1';
            in_re <= x_re_v(0); in_im <= x_im_v(0);
            in_valid <= '1';
            ri := 0;                                -- the pulse is reloaded
            ref_pend := true;
            prio_cycle := true;
            prio_todo := false;
          elsif not in_pend then
            stall(s);
            if not s then
              in_re <= x_re_v(xi); in_im <= x_im_v(xi);
              in_valid <= '1';
              in_pend := true;
            else
              in_valid <= '0';
            end if;
          end if;
        else
          in_valid <= '0';
        end if;

        -- output stream
        stall(s);
        if s then out_ready <= '0'; else out_ready <= '1'; end if;

        -- rising edge: evaluate pre-edge values
        wait until rising_edge(clk);
        cycle := cycle + 1;
        tx_cycles := tx_cycles + 1;

        ref_x := ref_valid = '1' and ref_ready = '1';
        in_x  := in_valid = '1' and in_ready = '1';

        if prio_cycle then
          check(ref_ready = '1', "priority: ref_ready = 0 in idle (tx " & integer'image(n_tx) & ")");
          check(in_ready = '0', "priority: in_ready = 1 while ref_valid = 1 (tx " & integer'image(n_tx) & ")");
          check(ref_x and not in_x, "priority: transfer other than exactly the ref one");
          in_pend := false;                         -- withdraw the in offer
        end if;

        if inputs_done then
          check(in_ready = '0', "in_ready = 1 while block " & integer'image(n_tx) &
                                " is processed (output " & integer'image(oi) & ")");
          check(ref_ready = '0', "ref_ready = 1 while block " & integer'image(n_tx) &
                                 " is processed (output " & integer'image(oi) & ")");
        end if;

        if ref_x then
          ri := ri + 1;
          ref_pend := false;
        end if;
        if in_x and not prio_cycle then
          if xi = 0 then
            first_in(n_tx) := cycle;
          end if;
          xi := xi + 1;
          in_pend := false;
          if xi = G_N_RG then
            inputs_done := true;
          end if;
        end if;

        -- outputs
        if out_valid = '1' then
          if held_valid then
            check(out_re = held_re and out_im = held_im and out_last = held_last,
                  "output changed while out_valid = 1 and out_ready = 0 (tx " &
                  integer'image(n_tx) & ", n = " & integer'image(oi) & ")");
          end if;
          if out_ready = '1' then
            if oi >= G_N_RG then
              check(false, "extra output in tx " & integer'image(n_tx));
            else
              check(out_re = y_re_v(oi) and out_im = y_im_v(oi),
                    "tx " & integer'image(n_tx) & " n = " & integer'image(oi) &
                    " got=(" & to_hstring(out_re) & "," & to_hstring(out_im) &
                    ") exp=(" & to_hstring(y_re_v(oi)) & "," & to_hstring(y_im_v(oi)) & ")");
              if oi = G_N_RG - 1 then
                check(out_last = '1', "out_last = 0 on the last output of tx " & integer'image(n_tx));
              else
                check(out_last = '0', "out_last = 1 on output " & integer'image(oi) &
                                      " of tx " & integer'image(n_tx));
              end if;
              write(ol, string'("O ") & to_hstring(out_re) & " " & to_hstring(out_im));
              writeline(df, ol);
              oi := oi + 1;
              outputs := outputs + 1;
              last_out(n_tx) := cycle;
            end if;
            held_valid := false;
          else
            held_valid := true;
            held_re := out_re; held_im := out_im; held_last := out_last;
          end if;
        else
          if held_valid then
            check(false, "out_valid withdrawn before transfer (tx " & integer'image(n_tx) & ")");
          end if;
          held_valid := false;
        end if;

        if tx_cycles > limit then
          report "watchdog: tx " & integer'image(n_tx) & " stuck after " &
                 integer'image(tx_cycles) & " cycles (ri=" & integer'image(ri) &
                 " xi=" & integer'image(xi) & " oi=" & integer'image(oi) & ")"
            severity failure;
        end if;
      end loop;

      n_tx := n_tx + 1;
    end loop;
    file_close(vf);

    wait until falling_edge(clk);
    ref_valid <= '0';
    in_valid  <= '0';
    out_ready <= '1';

    ------------------------------------------- reset forgets the pulse
    rst <= '1';
    wait until rising_edge(clk);
    cycle := cycle + 1;
    wait until falling_edge(clk);
    rst <= '0';
    in_valid <= '1';
    wait until rising_edge(clk);
    cycle := cycle + 1;
    check(in_ready = '0', "in_ready = 1 after reset (pulse not forgotten)");
    check(out_valid = '0', "out_valid = 1 after reset");
    wait until falling_edge(clk);
    in_valid <= '0';

    ---------------------------------------------------------- report
    if G_STALL_PCT = 0 then
      for t in 0 to n_tx - 1 loop
        write(ol, string'("CYCLES t=") & integer'image(t) &
                  " latency=" & integer'image(last_out(t) - first_in(t) + 1) & " period=");
        if t + 1 < n_tx then
          write(ol, integer'image(first_in(t + 1) - first_in(t)));
        else
          write(ol, string'("NA"));
        end if;
        writeline(output, ol);
      end loop;
    end if;

    file_close(df);
    check(n_tx > 0, "no transactions in " & G_VECTOR_FILE);

    write(ol, G_VECTOR_FILE & ": " & integer'image(n_tx) & " transactions, " &
              integer'image(outputs) & " outputs, " & integer'image(checks) &
              " checks, " & integer'image(errors) & " errors");
    writeline(output, ol);

    done <= true;
    if errors > 0 then
      report "FAIL: " & G_VECTOR_FILE & " (" & integer'image(errors) & " errors)"
        severity failure;
    end if;
    write(ol, string'("PASS: ") & G_VECTOR_FILE);
    writeline(output, ol);
    finish;
  end process main_p;

end architecture sim;

-- tb_edu_fifo.vhd
-- Self-checking, vector-driven testbench for edu_fifo. VHDL-2008, std/IEEE only.
--
-- Expected values come exclusively from the planner's independent oracle
-- (golden.py) via G_VECTOR_FILE; nothing here models the RTL algorithm.
-- Line format (whitespace separated):
--   rst wr_valid wr_data rd_ready expected_wr_ready expected_rd_valid expected_rd_data
-- Control fields: integer 0/1. Data fields: exactly G_WIDTH binary digits, MSB first.
--
-- Per vector: drive inputs with clk low, settle, check wr_ready/rd_valid
-- (rd_data only when expected_rd_valid = 1), rising edge, settle, clk low.
-- After the vectors, a directed midcycle reset check shows that reset is
-- synchronous: the flags drop while rst = '1', but without a rising edge the
-- non-empty head survives once rst is released.

library ieee;
use ieee.std_logic_1164.all;

use std.textio.all;
use std.env.all;

entity tb_edu_fifo is
  generic (
    G_WIDTH       : positive := 8;
    G_DEPTH       : positive := 4;
    G_VECTOR_FILE : string   := "vectors.txt"
  );
end entity tb_edu_fifo;

architecture sim of tb_edu_fifo is

  constant SETTLE : time := 1 ns;

  subtype t_word is std_logic_vector(G_WIDTH-1 downto 0);

  signal clk      : std_logic := '0';
  signal rst      : std_logic := '0';
  signal wr_valid : std_logic := '0';
  signal wr_ready : std_logic;
  signal wr_data  : t_word    := (others => '0');
  signal rd_valid : std_logic;
  signal rd_ready : std_logic := '0';
  signal rd_data  : t_word;

  constant CFG : string := "G_WIDTH=" & integer'image(G_WIDTH) &
                           " G_DEPTH=" & integer'image(G_DEPTH) &
                           " file=" & G_VECTOR_FILE;

  function to_sl(i : integer) return std_logic is
  begin
    if i = 1 then
      return '1';
    else
      return '0';
    end if;
  end function to_sl;

  -- Directed test words: alternating patterns (width-agnostic, width 1 safe).
  function pattern(first : bit) return t_word is
    variable v : t_word;
    variable b : bit := first;
  begin
    for i in v'range loop
      v(i) := to_stdulogic(b);
      b    := not b;
    end loop;
    return v;
  end function pattern;

begin

  dut : entity work.edu_fifo
    generic map (G_WIDTH => G_WIDTH, G_DEPTH => G_DEPTH)
    port map (
      clk => clk, rst => rst,
      wr_valid => wr_valid, wr_ready => wr_ready, wr_data => wr_data,
      rd_valid => rd_valid, rd_ready => rd_ready, rd_data => rd_data);

  stim_p : process
    file     vf      : text;
    variable fstat   : file_open_status;
    variable l       : line;
    variable good    : boolean;
    variable cycle   : natural := 0;
    variable i_rst, i_wv, i_rr, e_wr, e_rv : integer;
    variable i_wd, e_rd : bit_vector(G_WIDTH-1 downto 0);
    variable word_a, word_b : t_word;

    procedure fail_parse(field : string) is
    begin
      assert false
        report "vector parse error, field " & field & ", cycle " &
               integer'image(cycle) & ", " & CFG
        severity failure;
    end procedure fail_parse;

    procedure edge is
    begin
      clk <= '1';
      wait for SETTLE;
      clk <= '0';
      wait for SETTLE;
    end procedure edge;

    procedure chk(cond : boolean; what : string) is
    begin
      assert cond
        report "MISMATCH " & what & " at cycle " & integer'image(cycle) &
               ", " & CFG
        severity failure;
    end procedure chk;

  begin
    clk <= '0';
    wait for SETTLE;

    ---------------------------------------------------------------- vectors
    file_open(fstat, vf, G_VECTOR_FILE, read_mode);
    assert fstat = open_ok
      report "cannot open vector file, " & CFG severity failure;

    while not endfile(vf) loop
      readline(vf, l);
      next when l = null or l'length = 0;   -- tolerate blank lines

      read(l, i_rst, good); if not good then fail_parse("rst");               end if;
      read(l, i_wv,  good); if not good then fail_parse("wr_valid");          end if;
      read(l, i_wd,  good); if not good then fail_parse("wr_data");           end if;
      read(l, i_rr,  good); if not good then fail_parse("rd_ready");          end if;
      read(l, e_wr,  good); if not good then fail_parse("expected_wr_ready"); end if;
      read(l, e_rv,  good); if not good then fail_parse("expected_rd_valid"); end if;
      read(l, e_rd,  good); if not good then fail_parse("expected_rd_data");  end if;

      if cycle = 0 then
        assert i_rst = 1
          report "first vector must assert reset, " & CFG severity failure;
      end if;

      -- drive with clk low, then settle
      rst      <= to_sl(i_rst);
      wr_valid <= to_sl(i_wv);
      wr_data  <= to_stdlogicvector(i_wd);
      rd_ready <= to_sl(i_rr);
      wait for SETTLE;

      chk(wr_ready = to_sl(e_wr),
          "wr_ready: got " & to_string(wr_ready) & " exp " & integer'image(e_wr));
      chk(rd_valid = to_sl(e_rv),
          "rd_valid: got " & to_string(rd_valid) & " exp " & integer'image(e_rv));
      if e_rv = 1 then
        chk(rd_data = to_stdlogicvector(e_rd),
            "rd_data: got " & to_string(rd_data) & " exp " & to_string(e_rd));
      end if;

      edge;
      cycle := cycle + 1;
    end loop;
    file_close(vf);

    assert cycle > 0 report "vector file empty, " & CFG severity failure;
    report "vectors: " & integer'image(cycle) & " cycles passed, " & CFG
      severity note;

    ------------------------------------------------- directed midcycle reset
    -- Independent of the vectors: start from a known reset, load one or two
    -- words, then pulse rst while clk stays low.
    word_a := pattern('1');
    word_b := pattern('0');

    rst <= '1'; wr_valid <= '0'; rd_ready <= '0';
    wait for SETTLE;
    edge;                                           -- synchronous reset
    rst <= '0';
    wait for SETTLE;
    chk(rd_valid = '0' and wr_ready = '1', "directed: empty after reset");

    wr_valid <= '1'; wr_data <= word_a;             -- push A
    wait for SETTLE;
    chk(wr_ready = '1', "directed: accept A");
    edge;
    if G_DEPTH > 1 then                             -- push B (not at depth 1)
      wr_data <= word_b;
      wait for SETTLE;
      chk(wr_ready = '1', "directed: accept B");
      edge;
    end if;
    wr_valid <= '0';
    wait for SETTLE;
    chk(rd_valid = '1' and rd_data = word_a, "directed: head A before reset pulse");

    -- assert reset with clk low: interface flags gated
    rst <= '1';
    wait for SETTLE;
    chk(rd_valid = '0', "directed: rd_valid gated during reset");
    chk(wr_ready = '0', "directed: wr_ready gated during reset");

    -- release reset without any rising edge: state must be intact
    rst <= '0';
    wait for SETTLE;
    chk(rd_valid = '1', "directed: rd_valid restored, no edge seen");
    chk(rd_data = word_a, "directed: head unchanged after midcycle reset, got " &
                          to_string(rd_data));
    if G_DEPTH <= 2 then
      chk(wr_ready = '0', "directed: still full after midcycle reset");
    else
      chk(wr_ready = '1', "directed: not full after midcycle reset");
    end if;

    -- contrast: reset sampled at a rising edge empties the queue
    rst <= '1';
    wait for SETTLE;
    edge;
    rst <= '0';
    wait for SETTLE;
    chk(rd_valid = '0' and wr_ready = '1', "directed: empty after sampled reset");

    report "PASS: vectors and directed midcycle reset, " & CFG severity note;
    finish;
  end process stim_p;

end architecture sim;

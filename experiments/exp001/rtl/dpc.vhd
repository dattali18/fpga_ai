-- dpc.vhd
-- EXP001 digital pulse compression (DPC) component, G_LANES >= 1 (M2c).
-- VHDL-2008, IEEE standard packages only. No vendor primitives or IP.
--
-- Contract: experiments/exp001/docs/DPC_SPECIFICATION.md (G2-G5).
--   y[n] = sum_{k=0}^{P-1} conj(r[k]) * x[n+k],  n = 0..N_RG-1,  x[m] = 0 for m >= N_RG
-- Numerical order (G3), per lane: acc = +0, then acc = acc + t_k for
-- k = 0..P-1, every operation a correctly rounded binary32 operation
-- (dpc_pkg.cmac). Results are therefore identical for every G_LANES.
--
-- Architecture (G5, L = G_LANES lanes):
--   Outputs are computed in groups n0 = 0, L, 2L, ...; lane j computes y[n0 + j].
--   At step k every lane uses the same conj(r[k]); lane j uses x[n0 + j + k].
--   These L samples form a sliding window: registers w[0..L-2] plus the sample
--   read from memory in the current cycle (lane L-1). One sample read and one
--   pulse read per cycle, whatever L is.
--   S_IDLE     wait for a pulse load (ref) or, once a pulse is loaded, a block (in)
--   S_LOAD_REF receive pulse samples k = 1..P-1 (k = 0 is accepted in S_IDLE)
--   S_LOAD_IN  receive input samples 1..N_RG-1 (sample 0 is accepted in S_IDLE)
--   S_FILL     L-1 cycles: read x[n0 .. n0+L-2] into the window (skipped for L = 1)
--   S_COMPUTE  P cycles: one multiply-accumulate per lane per cycle, combinational
--              between registers (no pipelining); the window shifts by one
--   S_OUT      transfer the v = min(L, N_RG - n0) valid lane results in order,
--              then the next group (S_FILL) or, after y[N_RG-1], S_IDLE
--   Lanes with n0 + j >= N_RG (last group, L not dividing N_RG) compute but are
--   never output.
--   The lane accumulators are the result buffer (D-077): the accumulator input is
--   +0 at k = 0, so no clear cycle is needed, and in S_OUT the output is
--   acc(j_out), selected by the registered lane counter j_out.
--
-- Cycle count (out_ready = 1), D-076:
--   latency = 2*N_RG + ceil(N_RG/L) * (P + L - 1);  period = latency (+ P when the
--   next block starts with a pulse load).
--
-- Handshake (G4): a transfer happens at a rising edge with valid = ready = 1.
--   ref_ready = 1 in S_IDLE and S_LOAD_REF.
--   in_ready  = 1 in S_LOAD_IN, and in S_IDLE when a pulse is loaded and
--               ref_valid = 0.
--   COMBINATIONAL PATH (D-069, approved by the planner): in S_IDLE, in_ready
--   depends on ref_valid, so a pulse load takes priority over a block when both
--   are offered in the same cycle and exactly one transfer (the ref one)
--   happens. Ready may depend on valid; no valid output depends on any ready.
--   out_valid, out_last, out_re and out_im depend only on registers (state,
--   n0, j_out, acc), so they are stable while out_valid = 1 and out_ready = 0.
--
-- Reset: synchronous, active high. Returns to S_IDLE and forgets the pulse
-- (pulse_loaded = 0). Storage, window and accumulators are not reset.
--
-- Memories (FIFO-DEFECT-001 lesson): sample memory padded to 2**addr_width(N_RG)
-- words, pulse memory padded to 2**addr_width(P) words, fixed-width unsigned
-- addresses with explicit wrap, plain indexed asynchronous reads, synchronous
-- writes, no reset.
--
-- Zero padding: the sample index idx (n0 .. G*L + P - 2) and n0 are kept in
-- counters of addr_width(N_RG + P + L) bits. idx is compared with N_RG BEFORE it
-- is truncated to a memory address; for idx >= N_RG the all-zero sample
-- +0 + j(+0) enters the window and the multiply-accumulate is still performed.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.dpc_pkg.all;

entity dpc is
  generic (
    G_N_RG  : positive;          -- samples per block
    G_P     : positive;          -- pulse length
    G_LANES : positive := 1      -- 1 <= G_LANES <= G_N_RG
  );
  port (
    clk, rst                     : in  std_logic;
    ref_valid                    : in  std_logic;
    ref_ready                    : out std_logic;
    ref_re, ref_im               : in  std_logic_vector(31 downto 0);
    in_valid                     : in  std_logic;
    in_ready                     : out std_logic;
    in_re, in_im                 : in  std_logic_vector(31 downto 0);
    out_valid                    : out std_logic;
    out_ready                    : in  std_logic;
    out_re, out_im               : out std_logic_vector(31 downto 0);
    out_last                     : out std_logic
  );
end entity dpc;

architecture rtl of dpc is

  -- Elaboration-time check (simulation and synthesis).
  function check_lanes(lanes, n_rg : positive) return boolean is
  begin
    assert lanes >= 1 and lanes <= n_rg
      report "G_LANES must satisfy 1 <= G_LANES <= G_N_RG"
      severity failure;
    return lanes <= n_rg;
  end function check_lanes;
  constant C_LANES_OK : boolean := check_lanes(G_LANES, G_N_RG);

  constant C_L      : positive := G_LANES;
  constant C_XAW    : positive := addr_width(G_N_RG);              -- sample address width
  constant C_RAW    : positive := addr_width(G_P);                 -- pulse address width
  constant C_LAW    : positive := addr_width(C_L);                 -- lane index width
  constant C_IW     : positive := addr_width(G_N_RG + G_P + C_L);  -- n0, idx, n0 + j
  constant C_XDEPTH : positive := 2 ** C_XAW;
  constant C_RDEPTH : positive := 2 ** C_RAW;

  constant C_X_LAST : unsigned(C_XAW - 1 downto 0) := to_unsigned(G_N_RG - 1, C_XAW);
  constant C_R_LAST : unsigned(C_RAW - 1 downto 0) := to_unsigned(G_P - 1, C_RAW);
  constant C_L_LAST : unsigned(C_LAW - 1 downto 0) := to_unsigned(C_L - 1, C_LAW);
  constant C_F_LAST : unsigned(C_LAW - 1 downto 0) := to_unsigned(maximum(C_L - 2, 0), C_LAW);  -- unused for L = 1
  constant C_N_LAST : unsigned(C_IW - 1 downto 0)  := to_unsigned(G_N_RG - 1, C_IW);
  constant C_N_RG   : unsigned(C_IW - 1 downto 0)  := to_unsigned(G_N_RG, C_IW);
  constant C_L_IW   : unsigned(C_IW - 1 downto 0)  := to_unsigned(C_L, C_IW);

  type t_mem_x  is array (0 to C_XDEPTH - 1) of t_word;
  type t_mem_r  is array (0 to C_RDEPTH - 1) of t_word;
  type t_lanes  is array (0 to C_L - 1) of t_word;
  -- Window registers w[0..L-2]: exactly L-1 entries (at least 1 so the type is
  -- never null). For L >= 2 every entry is written; for L = 1 none is written or
  -- read. A partly written array would leave GHDL synthesis with 'Z' constants
  -- for the unwritten entry (DPC-DEFECT-002).
  constant C_WN : positive := maximum(C_L - 1, 1);
  type t_window is array (0 to C_WN - 1) of t_word;

  -- Bounded lane select (FIFO-DEFECT-001 lesson): j_out has 2**C_LAW codes but only
  -- L lanes exist, so the select is an explicit mux with a defined default
  -- instead of an indexed read with unallocated branches.
  function select_lane(a : t_lanes; sel : unsigned) return t_word is
    variable r : t_word := a(0);
  begin
    for i in a'range loop
      if sel = to_unsigned(i, sel'length) then
        r := a(i);
      end if;
    end loop;
    return r;
  end function select_lane;

  signal x_re_mem, x_im_mem : t_mem_x;
  signal r_re_mem, r_im_mem : t_mem_r;

  type t_state is (S_IDLE, S_LOAD_REF, S_LOAD_IN, S_FILL, S_COMPUTE, S_OUT);
  signal state        : t_state := S_IDLE;
  signal pulse_loaded : std_logic := '0';

  signal wr_x  : unsigned(C_XAW - 1 downto 0) := (others => '0');  -- sample write address
  signal wr_r  : unsigned(C_RAW - 1 downto 0) := (others => '0');  -- pulse write address
  signal k     : unsigned(C_RAW - 1 downto 0) := (others => '0');  -- pulse index
  signal f     : unsigned(C_LAW - 1 downto 0) := (others => '0');  -- fill step
  signal j_out : unsigned(C_LAW - 1 downto 0) := (others => '0');  -- output lane
  signal n0    : unsigned(C_IW - 1 downto 0)  := (others => '0');  -- first output of the group
  signal idx   : unsigned(C_IW - 1 downto 0)  := (others => '0');  -- sample index read now

  -- Window registers w[0..L-2] and lane accumulators.
  signal w_re, w_im     : t_window := (others => C_ZERO_WORD);
  signal acc_re, acc_im : t_lanes := (others => C_ZERO_WORD);

  -- Lane operands: ops(j) = w(j) for j < L-1, the current memory read for j = L-1.
  signal ops_re, ops_im : t_lanes;

  -- Handshake decode.
  signal ref_ready_i, in_ready_i : std_logic;
  signal ref_xfer, in_xfer       : std_logic;
  signal out_valid_i, out_xfer   : std_logic;
  signal n_out                   : unsigned(C_IW - 1 downto 0);   -- n0 + j_out

  -- Asynchronous memory reads.
  signal x_rd_re, x_rd_im : t_word;
  signal r_rd_re, r_rd_im : t_word;

begin

  ---------------------------------------------------------------- handshake
  ref_ready_i <= '1' when state = S_IDLE or state = S_LOAD_REF else '0';
  in_ready_i  <= '1' when state = S_LOAD_IN or
                          (state = S_IDLE and pulse_loaded = '1' and ref_valid = '0')
                 else '0';
  out_valid_i <= '1' when state = S_OUT else '0';

  ref_xfer <= ref_valid and ref_ready_i;
  in_xfer  <= in_valid and in_ready_i;
  out_xfer <= out_valid_i and out_ready;

  n_out <= n0 + resize(j_out, C_IW);

  ref_ready <= ref_ready_i;
  in_ready  <= in_ready_i;
  out_valid <= out_valid_i;
  out_re    <= select_lane(acc_re, j_out);
  out_im    <= select_lane(acc_im, j_out);
  out_last  <= '1' when state = S_OUT and n_out = C_N_LAST else '0';

  ------------------------------------------------------------------ storage
  mem_wr_p : process (clk)
  begin
    if rising_edge(clk) then
      if ref_xfer = '1' then
        r_re_mem(to_integer(wr_r)) <= ref_re;
        r_im_mem(to_integer(wr_r)) <= ref_im;
      end if;
      if in_xfer = '1' then
        x_re_mem(to_integer(wr_x)) <= in_re;
        x_im_mem(to_integer(wr_x)) <= in_im;
      end if;
    end if;
  end process mem_wr_p;

  -- Asynchronous reads. idx is compared with N_RG before truncation (zero padding).
  r_rd_re <= r_re_mem(to_integer(k));
  r_rd_im <= r_im_mem(to_integer(k));
  x_rd_re <= x_re_mem(to_integer(idx(C_XAW - 1 downto 0))) when idx < C_N_RG else C_ZERO_WORD;
  x_rd_im <= x_im_mem(to_integer(idx(C_XAW - 1 downto 0))) when idx < C_N_RG else C_ZERO_WORD;

  ------------------------------------------------------------ lane operands
  ops_p : process (all)
  begin
    for j in 0 to C_L - 2 loop
      ops_re(j) <= w_re(j);
      ops_im(j) <= w_im(j);
    end loop;
    ops_re(C_L - 1) <= x_rd_re;
    ops_im(C_L - 1) <= x_rd_im;
  end process ops_p;

  ------------------------------------------------------------ control + MACs
  ctrl_p : process (clk)
    variable mac    : std_logic_vector(63 downto 0);
    variable a_re   : t_word;
    variable a_im   : t_word;
  begin
    if rising_edge(clk) then
      if rst = '1' then
        state        <= S_IDLE;
        pulse_loaded <= '0';
        wr_x         <= (others => '0');
        wr_r         <= (others => '0');
        k            <= (others => '0');
        f            <= (others => '0');
        j_out        <= (others => '0');
        n0           <= (others => '0');
        idx          <= (others => '0');
      else
        case state is

          when S_IDLE =>
            -- Pulse load has priority (in_ready = 0 while ref_valid = 1).
            if ref_xfer = '1' then
              if wr_r = C_R_LAST then              -- P = 1: load complete
                wr_r         <= (others => '0');
                pulse_loaded <= '1';
              else
                wr_r  <= wr_r + 1;
                state <= S_LOAD_REF;
              end if;
            elsif in_xfer = '1' then
              if wr_x = C_X_LAST then              -- N_RG = 1: block complete
                wr_x  <= (others => '0');
                n0    <= (others => '0');
                idx   <= (others => '0');
                k     <= (others => '0');
                f     <= (others => '0');
                if C_L = 1 then state <= S_COMPUTE; else state <= S_FILL; end if;
              else
                wr_x  <= wr_x + 1;
                state <= S_LOAD_IN;
              end if;
            end if;

          when S_LOAD_REF =>
            if ref_xfer = '1' then
              if wr_r = C_R_LAST then
                wr_r         <= (others => '0');   -- explicit wrap
                pulse_loaded <= '1';
                state        <= S_IDLE;
              else
                wr_r <= wr_r + 1;
              end if;
            end if;

          when S_LOAD_IN =>
            if in_xfer = '1' then
              if wr_x = C_X_LAST then
                wr_x  <= (others => '0');          -- explicit wrap
                n0    <= (others => '0');
                idx   <= (others => '0');
                k     <= (others => '0');
                f     <= (others => '0');
                if C_L = 1 then state <= S_COMPUTE; else state <= S_FILL; end if;
              else
                wr_x <= wr_x + 1;
              end if;
            end if;

          when S_FILL =>
            -- Shift x[idx] into the window: w(j) <= ops(j+1).
            for j in 0 to C_L - 2 loop
              w_re(j) <= ops_re(j + 1);
              w_im(j) <= ops_im(j + 1);
            end loop;
            idx <= idx + 1;
            if f = C_F_LAST then
              f     <= (others => '0');
              state <= S_COMPUTE;
            else
              f <= f + 1;
            end if;

          when S_COMPUTE =>
            -- One multiply-accumulate per lane, k = 0..P-1 in order; acc = +0 at k = 0.
            for j in 0 to C_L - 1 loop
              if k = 0 then
                a_re := C_ZERO_WORD;
                a_im := C_ZERO_WORD;
              else
                a_re := acc_re(j);
                a_im := acc_im(j);
              end if;
              mac := cmac(a_re, a_im, r_rd_re, r_rd_im, ops_re(j), ops_im(j));
              acc_re(j) <= mac(63 downto 32);
              acc_im(j) <= mac(31 downto 0);
            end loop;
            for j in 0 to C_L - 2 loop              -- window slides by one
              w_re(j) <= ops_re(j + 1);
              w_im(j) <= ops_im(j + 1);
            end loop;
            idx <= idx + 1;
            if k = C_R_LAST then
              k     <= (others => '0');
              j_out <= (others => '0');
              state <= S_OUT;
            else
              k <= k + 1;
            end if;

          when S_OUT =>
            if out_xfer = '1' then
              if n_out = C_N_LAST then             -- y[N_RG-1] transferred
                j_out <= (others => '0');
                n0    <= (others => '0');
                state <= S_IDLE;
              elsif j_out = C_L_LAST then          -- next group
                j_out <= (others => '0');
                n0    <= n0 + C_L_IW;
                idx   <= n0 + C_L_IW;
                if C_L = 1 then state <= S_COMPUTE; else state <= S_FILL; end if;
              else
                j_out <= j_out + 1;
              end if;
            end if;

        end case;
      end if;
    end if;
  end process ctrl_p;

end architecture rtl;

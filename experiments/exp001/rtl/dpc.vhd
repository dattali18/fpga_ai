-- dpc.vhd
-- EXP001 digital pulse compression (DPC) component, baseline G_LANES = 1 (M2b).
-- VHDL-2008, IEEE standard packages only. No vendor primitives or IP.
--
-- Contract: experiments/exp001/docs/DPC_SPECIFICATION.md (G2-G5).
--   y[n] = sum_{k=0}^{P-1} conj(r[k]) * x[n+k],  n = 0..N_RG-1,  x[m] = 0 for m >= N_RG
-- Numerical order (G3): acc = +0, then acc = acc + t_k for k = 0..P-1, every
-- operation a correctly rounded binary32 operation (dpc_pkg.cmac).
--
-- Architecture (G5, one lane):
--   S_IDLE     wait for a pulse load (ref) or, once a pulse is loaded, a block (in)
--   S_LOAD_REF receive pulse samples k = 1..P-1 (k = 0 is accepted in S_IDLE)
--   S_LOAD_IN  receive input samples 1..N_RG-1 (sample 0 is accepted in S_IDLE)
--   S_COMPUTE  P cycles per output: one multiply-accumulate per cycle,
--              combinational between registers (no pipelining in M2b)
--   S_OUT      hold y[n] in the output register until it is transferred,
--              then compute y[n+1]; after y[N_RG-1] return to S_IDLE
--
-- Handshake (G4): a transfer happens at a rising edge with valid = ready = 1.
--   ref_ready = 1 in S_IDLE and S_LOAD_REF.
--   in_ready  = 1 in S_LOAD_IN, and in S_IDLE when a pulse is loaded and
--               ref_valid = 0.
--   COMBINATIONAL PATH (D-069, approved by the planner): in S_IDLE, in_ready
--   depends on ref_valid, so a pulse load takes priority over a block when both
--   are offered in the same cycle and exactly one transfer (the ref one)
--   happens. Ready may depend on valid; no valid output depends on any ready.
--   out_valid, out_last, out_re and out_im come only from registers, so they are
--   stable while out_valid = 1 and out_ready = 0.
--
-- Reset: synchronous, active high. Returns to S_IDLE, clears out_valid and
-- forgets the pulse (pulse_loaded = 0). Storage is not reset.
--
-- Memories (FIFO-DEFECT-001 lesson): sample memory padded to 2**addr_width(N_RG)
-- words, pulse memory padded to 2**addr_width(P) words, fixed-width unsigned
-- addresses with explicit wrap, plain indexed asynchronous reads, synchronous
-- writes, no reset.
--
-- Zero padding: the sample index n + k (up to N_RG + P - 2) is kept in its own
-- counter idx, wide enough for N_RG + P - 1. It is compared with N_RG BEFORE it
-- is truncated to a memory address; for idx >= N_RG the all-zero sample +0 + j(+0)
-- is used and the multiply-accumulate is still performed.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.dpc_pkg.all;

entity dpc is
  generic (
    G_N_RG  : positive;          -- samples per block
    G_P     : positive;          -- pulse length
    G_LANES : positive := 1      -- M2b supports 1 only
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
  function check_lanes(lanes : positive) return boolean is
  begin
    assert lanes = 1
      report "G_LANES > 1 is M2c"
      severity failure;
    return lanes = 1;
  end function check_lanes;
  constant C_LANES_OK : boolean := check_lanes(G_LANES);

  constant C_XAW    : positive := addr_width(G_N_RG);           -- sample address width
  constant C_RAW    : positive := addr_width(G_P);              -- pulse address width
  constant C_IW     : positive := addr_width(G_N_RG + G_P);     -- n and n+k, holds N_RG+P-1
  constant C_XDEPTH : positive := 2 ** C_XAW;
  constant C_RDEPTH : positive := 2 ** C_RAW;

  constant C_X_LAST : unsigned(C_XAW - 1 downto 0) := to_unsigned(G_N_RG - 1, C_XAW);
  constant C_R_LAST : unsigned(C_RAW - 1 downto 0) := to_unsigned(G_P - 1, C_RAW);
  constant C_N_LAST : unsigned(C_IW - 1 downto 0)  := to_unsigned(G_N_RG - 1, C_IW);
  constant C_N_RG   : unsigned(C_IW - 1 downto 0)  := to_unsigned(G_N_RG, C_IW);

  type t_mem_x is array (0 to C_XDEPTH - 1) of t_word;
  type t_mem_r is array (0 to C_RDEPTH - 1) of t_word;

  signal x_re_mem, x_im_mem : t_mem_x;
  signal r_re_mem, r_im_mem : t_mem_r;

  type t_state is (S_IDLE, S_LOAD_REF, S_LOAD_IN, S_COMPUTE, S_OUT);
  signal state        : t_state := S_IDLE;
  signal pulse_loaded : std_logic := '0';

  signal wr_x   : unsigned(C_XAW - 1 downto 0) := (others => '0');  -- sample write address
  signal wr_r   : unsigned(C_RAW - 1 downto 0) := (others => '0');  -- pulse write address
  signal k      : unsigned(C_RAW - 1 downto 0) := (others => '0');  -- pulse index
  signal n      : unsigned(C_IW - 1 downto 0)  := (others => '0');  -- output index
  signal idx    : unsigned(C_IW - 1 downto 0)  := (others => '0');  -- n + k

  signal acc_re, acc_im : t_word := C_ZERO_WORD;
  signal y_re, y_im     : t_word := C_ZERO_WORD;

  -- Handshake decode.
  signal ref_ready_i, in_ready_i : std_logic;
  signal ref_xfer, in_xfer       : std_logic;
  signal out_valid_i, out_xfer   : std_logic;

  -- Datapath operands (asynchronous memory reads).
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

  ref_ready <= ref_ready_i;
  in_ready  <= in_ready_i;
  out_valid <= out_valid_i;
  out_re    <= y_re;
  out_im    <= y_im;
  out_last  <= '1' when state = S_OUT and n = C_N_LAST else '0';

  ------------------------------------------------------------------ storage
  -- Synchronous writes, no reset. Addresses are full-width unsigned counters
  -- into power-of-two arrays, so every address value is allocated.
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

  ------------------------------------------------------------ control + MAC
  ctrl_p : process (clk)
    variable mac : std_logic_vector(63 downto 0);
  begin
    if rising_edge(clk) then
      if rst = '1' then
        state        <= S_IDLE;
        pulse_loaded <= '0';
        wr_x         <= (others => '0');
        wr_r         <= (others => '0');
        k            <= (others => '0');
        n            <= (others => '0');
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
                wr_x   <= (others => '0');
                n      <= (others => '0');
                idx    <= (others => '0');
                k      <= (others => '0');
                acc_re <= C_ZERO_WORD;
                acc_im <= C_ZERO_WORD;
                state  <= S_COMPUTE;
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
                wr_x   <= (others => '0');         -- explicit wrap
                n      <= (others => '0');
                idx    <= (others => '0');
                k      <= (others => '0');
                acc_re <= C_ZERO_WORD;             -- acc = +0
                acc_im <= C_ZERO_WORD;
                state  <= S_COMPUTE;
              else
                wr_x <= wr_x + 1;
              end if;
            end if;

          when S_COMPUTE =>
            -- One multiply-accumulate per cycle, k = 0..P-1 in order.
            mac := cmac(acc_re, acc_im, r_rd_re, r_rd_im, x_rd_re, x_rd_im);
            if k = C_R_LAST then
              y_re  <= mac(63 downto 32);
              y_im  <= mac(31 downto 0);
              k     <= (others => '0');
              state <= S_OUT;
            else
              acc_re <= mac(63 downto 32);
              acc_im <= mac(31 downto 0);
              k      <= k + 1;
              idx    <= idx + 1;
            end if;

          when S_OUT =>
            if out_xfer = '1' then
              if n = C_N_LAST then
                n     <= (others => '0');
                state <= S_IDLE;
              else
                n      <= n + 1;
                idx    <= n + 1;                   -- n+1 + k with k = 0
                acc_re <= C_ZERO_WORD;             -- acc = +0
                acc_im <= C_ZERO_WORD;
                state  <= S_COMPUTE;
              end if;
            end if;

        end case;
      end if;
    end if;
  end process ctrl_p;

end architecture rtl;

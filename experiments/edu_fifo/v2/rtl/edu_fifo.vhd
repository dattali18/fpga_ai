-- edu_fifo.vhd  (V2 candidate)
-- Educational synchronous first-word-fall-through FIFO.
-- VHDL-2008, IEEE standard packages only. No vendor IP.
-- Entity, generics and ports are identical to V1; the cycle contract is unchanged.
--
-- V2 change versus V1: storage is a padded power-of-two array indexed directly
-- by fixed-width unsigned pointers, so every address value maps to an allocated
-- word (no unallocated read/write branch), and the read is a plain dynamic index
-- intended to be kept as a memory object instead of V1's explicit compare mux.
-- See DESIGN.md for rationale, rejected alternatives and risks.
--
-- Shared control (both branches), evaluated before the rising edge:
--   rd_valid = (rst = 0) and count > 0
--   wr_ready = (rst = 0) and (count < G_DEPTH or (rd_valid and rd_ready))
--   pop      = rd_valid and rd_ready
--   push     = wr_valid and wr_ready
-- Simultaneous pop and push: old head removed, new word appended, count unchanged.
-- No empty bypass. Synchronous reset clears pointers and count, never storage.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity edu_fifo is
  generic (
    G_WIDTH : positive := 8;
    G_DEPTH : positive := 4
  );
  port (
    clk      : in  std_logic;
    rst      : in  std_logic;
    wr_valid : in  std_logic;
    wr_ready : out std_logic;
    wr_data  : in  std_logic_vector(G_WIDTH-1 downto 0);
    rd_valid : out std_logic;
    rd_ready : in  std_logic;
    rd_data  : out std_logic_vector(G_WIDTH-1 downto 0)
  );
end entity edu_fifo;

architecture rtl of edu_fifo is

  subtype t_word  is std_logic_vector(G_WIDTH-1 downto 0);
  subtype t_count is natural range 0 to G_DEPTH;

  -- Smallest a with 2**a >= n (n >= 1). Elaboration-time only.
  function clog2(n : positive) return natural is
    variable a : natural  := 0;
    variable p : positive := 1;
  begin
    while p < n loop
      p := p * 2;
      a := a + 1;
    end loop;
    return a;
  end function clog2;

  signal count      : t_count := 0;
  signal rd_valid_i : std_logic;
  signal wr_ready_i : std_logic;
  signal pop        : std_logic;
  signal push       : std_logic;

begin

  ---------------------------------------------------------------- control
  -- Flags gated during reset, independent of stored state (unchanged from V1).
  rd_valid_i <= '1' when rst = '0' and count /= 0 else '0';
  wr_ready_i <= '1' when rst = '0' and
                         (count /= G_DEPTH or (rd_valid_i = '1' and rd_ready = '1'))
                else '0';

  pop  <= rd_valid_i and rd_ready;
  push <= wr_valid and wr_ready_i;

  rd_valid <= rd_valid_i;
  wr_ready <= wr_ready_i;

  count_p : process (clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        count <= 0;
      elsif push = '1' and pop = '0' then
        count <= count + 1;
      elsif pop = '1' and push = '0' then
        count <= count - 1;
      end if;
    end if;
  end process count_p;

  ------------------------------------------------------- depth 1: register
  -- One word needs no address. Push into the empty slot or full replacement
  -- (pop and push on the same edge) both load wr_data; the pre-edge rd_data is
  -- still the old word, so ordering is preserved.
  g_d1 : if G_DEPTH = 1 generate
    signal head : t_word;                -- storage: intentionally not reset
  begin
    head_p : process (clk)
    begin
      if rising_edge(clk) then
        if push = '1' then
          head <= wr_data;
        end if;
      end if;
    end process head_p;

    rd_data <= head;
  end generate g_d1;

  ------------------------------------------- depth >= 2: padded memory array
  g_mem : if G_DEPTH > 1 generate
    constant C_AW    : positive := clog2(G_DEPTH);      -- >= 1 here
    constant C_WORDS : positive := 2**C_AW;             -- >= G_DEPTH
    constant C_LAST  : unsigned(C_AW-1 downto 0) := to_unsigned(G_DEPTH-1, C_AW);

    subtype t_ptr is unsigned(C_AW-1 downto 0);
    type t_mem is array (0 to C_WORDS-1) of t_word;

    -- Explicit modulo-G_DEPTH increment; never reaches words G_DEPTH..C_WORDS-1.
    function wrap_inc(p : t_ptr) return t_ptr is
    begin
      if p = C_LAST then
        return (others => '0');
      else
        return p + 1;
      end if;
    end function wrap_inc;

    signal mem    : t_mem;               -- storage: intentionally not reset
    signal rd_ptr : t_ptr := (others => '0');
    signal wr_ptr : t_ptr := (others => '0');
  begin

    -- Write port: single synchronous port, enable = push (already 0 in reset).
    mem_wr_p : process (clk)
    begin
      if rising_edge(clk) then
        if push = '1' then
          mem(to_integer(wr_ptr)) <= wr_data;
        end if;
      end if;
    end process mem_wr_p;

    -- Read port: asynchronous, full-range address (C_WORDS = 2**C_AW).
    -- Required for first-word fall-through: rd_data is observed before the edge.
    rd_data <= mem(to_integer(rd_ptr));

    ptr_p : process (clk)
    begin
      if rising_edge(clk) then
        if rst = '1' then
          rd_ptr <= (others => '0');
          wr_ptr <= (others => '0');
        else
          if pop = '1' then
            rd_ptr <= wrap_inc(rd_ptr);
          end if;
          if push = '1' then
            wr_ptr <= wrap_inc(wr_ptr);
          end if;
        end if;
      end if;
    end process ptr_p;

  end generate g_mem;

end architecture rtl;

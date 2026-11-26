-- edu_fifo.vhd
-- Educational synchronous first-word-fall-through FIFO.
-- VHDL-2008, IEEE standard packages only. No vendor IP.
--
-- Architecture:
--   * circular storage mem(0 to G_DEPTH-1), not reset
--   * rd_ptr / wr_ptr in 0..G_DEPTH-1 with explicit modulo-depth wrap
--     (compare-and-clear, so non-power-of-two depths and depth 1 work)
--   * occupancy counter count in 0..G_DEPTH
--   * combinational head read: rd_data = mem(rd_ptr)
--   * wr_ready / rd_valid combinationally gated to '0' while rst = '1'
--   * synchronous active-high reset clears pointers and count only
--
-- Cycle contract (rst = '0'), evaluated before the rising edge:
--   rd_valid = count > 0
--   wr_ready = count < G_DEPTH or (rd_valid and rd_ready)
--   pop      = rd_valid and rd_ready
--   push     = wr_valid and wr_ready
-- Simultaneous pop and push: the old head is removed and the new word is
-- appended; count is unchanged. No empty bypass.

library ieee;
use ieee.std_logic_1164.all;

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

  subtype t_word is std_logic_vector(G_WIDTH-1 downto 0);
  type t_mem is array (0 to G_DEPTH-1) of t_word;
  subtype t_ptr is natural range 0 to G_DEPTH-1;
  subtype t_count is natural range 0 to G_DEPTH;

  -- Explicit modulo-G_DEPTH increment (valid for any positive depth).
  function wrap_inc(p : t_ptr) return t_ptr is
  begin
    if p = G_DEPTH-1 then
      return 0;
    else
      return p + 1;
    end if;
  end function wrap_inc;

  signal mem    : t_mem;              -- storage: intentionally not reset
  signal rd_ptr : t_ptr   := 0;
  signal wr_ptr : t_ptr   := 0;
  signal count  : t_count := 0;

  signal rd_valid_i : std_logic;
  signal wr_ready_i : std_logic;
  signal pop        : std_logic;
  signal push       : std_logic;

begin

  -- Flags: gated during reset, independent of stored state.
  rd_valid_i <= '1' when rst = '0' and count /= 0 else '0';
  wr_ready_i <= '1' when rst = '0' and
                         (count /= G_DEPTH or (rd_valid_i = '1' and rd_ready = '1'))
                else '0';

  pop  <= rd_valid_i and rd_ready;
  push <= wr_valid and wr_ready_i;

  rd_valid <= rd_valid_i;
  wr_ready <= wr_ready_i;
  -- Explicit bounded read mux: no unallocated address branch.
  read_p : process (all)
  begin
    rd_data <= (others => '0');
    for i in 0 to G_DEPTH-1 loop
      if rd_ptr = i then
        rd_data <= mem(i);
      end if;
    end loop;
  end process read_p;

  -- Storage write. push is already '0' during reset (wr_ready gated), so the
  -- array needs no reset branch.
  mem_p : process (clk)
  begin
    if rising_edge(clk) then
      if push = '1' then
        mem(wr_ptr) <= wr_data;
      end if;
    end if;
  end process mem_p;

  -- Control state: synchronous reset dominates.
  ctrl_p : process (clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        rd_ptr <= 0;
        wr_ptr <= 0;
        count  <= 0;
      else
        if pop = '1' then
          rd_ptr <= wrap_inc(rd_ptr);
        end if;
        if push = '1' then
          wr_ptr <= wrap_inc(wr_ptr);
        end if;
        if push = '1' and pop = '0' then
          count <= count + 1;
        elsif pop = '1' and push = '0' then
          count <= count - 1;
        end if;
      end if;
    end if;
  end process ctrl_p;

end architecture rtl;

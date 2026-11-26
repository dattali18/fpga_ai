# EDU_FIFO V2 candidate: design

Scope: change the storage implementation only. The entity, generics, ports and every
item of the `SPECIFICATION.md` cycle contract stay as in V1.

## Evidence reviewed

| Source | Finding used |
|---|---|
| `v1/RESULTS.md` F-FIFO-003, `benchmark.csv` | 0 retained memory objects in all 22 configurations. RTLIL cells grow roughly linearly with depth (21 → 1824 for depths 1 → 256 at width 32). |
| F-FIFO-005 and the V1 diff | The original `rd_data <= mem(rd_ptr)` with exactly `G_DEPTH` words failed strict structural checks at non-power-of-two depths. The pointer is `ceil(log2 D)` bits wide but only `D` words exist, which leaves an unallocated read branch. V1 replaced the read with a compare-and-select loop. That passes, but it is no longer a memory read. |
| V1 TB diff (`G_DEPTH <= 2`) | The directed midcycle check fills depth 2 completely. V2 matches it, since depth 2 has two words and `wr_ready = 0` when full. |

Inference: to keep a memory object, the read must be a plain dynamic index **and**
every address value must hit an allocated word.

## Architecture

| Block | Implementation |
|---|---|
| Control (shared) | `count` in `0..G_DEPTH`. `rd_valid`, `wr_ready`, `pop` and `push` are identical to V1, including the combinational reset gating. |
| `G_DEPTH = 1` | One register `head`, loaded on `push`. `rd_data <= head`. |
| `G_DEPTH ≥ 2` | `C_AW = clog2(G_DEPTH)`, `C_WORDS = 2**C_AW`. `mem(0..C_WORDS-1)` has one synchronous write port (enable `push`, address `wr_ptr`) and one asynchronous read port (`rd_data <= mem(to_integer(rd_ptr))`). Pointers are `unsigned(C_AW-1 downto 0)` and wrap explicitly from `G_DEPTH-1` to 0. |

## State transitions (rising edge)

| Condition | `count` | `rd_ptr` | `wr_ptr` | storage |
|---|---|---|---|---|
| `rst = 1` | 0 | 0 | 0 | unchanged |
| pop only | −1 | wrap_inc | – | – |
| push only | +1 | – | wrap_inc | `mem(wr_ptr) ← wr_data` |
| pop and push | unchanged | wrap_inc | wrap_inc | `mem(wr_ptr) ← wr_data` |
| neither | – | – | – | – |

`push` and `pop` are both 0 while `rst = 1`, so reset never writes storage.

## Memory semantics

- **Read is asynchronous.** The contract requires `rd_data` to be valid *before* the
  edge in the same cycle that `rd_valid` rises, with no extra latency. A synchronous
  read would add a cycle and change the observable behaviour.
- **Read-during-write at the same address** happens only when the FIFO is full and
  pop and push occur together (`wr_ptr = rd_ptr`). The pre-edge read returns the old
  head; the write lands at the edge. This is full replacement. It needs no
  transparent or bypass behaviour from the memory.
- **Pointers never reach padding words.** `wrap_inc` clears at `G_DEPTH-1`, so words
  `G_DEPTH..C_WORDS-1` are never written or read while `rd_valid = 1`. Their contents
  are unspecified and never observed.
- **Storage is never reset.** Words are 'U' in simulation until written. That is only
  visible while `rd_valid = 0`, which the contract leaves unspecified.

## Boundary cases

| Case | Handling |
|---|---|
| Depth 1 | Register branch. Full replacement loads `head` at the edge while the old value is still on `rd_data` beforehand. `wr_ready = 1` when full only if `rd_ready = 1`. |
| Depth 2 | `C_AW = 1`, 2 words, no padding. |
| Power-of-two depth | No padding; `wrap_inc` equals natural overflow but is kept explicit. |
| Non-power-of-two depth | Padded. Overhead for the benchmark depths: 3→4, 5→8, 15→16, 31→32, 63→64, 127→128 words. Worst case approaches 2× at `2^k+1`. |
| Empty push | Written to `mem(wr_ptr)`. `rd_valid` rises only after the edge, when `count` becomes 1. No bypass. |
| Stall (`rd_valid = 1`, `rd_ready = 0`) | `rd_ptr` is held, and no write can target `rd_ptr` unless the FIFO is full, which would require a pop. So `rd_data` is stable. |
| Midcycle reset (no edge) | Only the flags are gated. `count`, the pointers and storage are untouched, so the head returns when `rst` falls. |

## Decisions and rejected alternatives

| ID | Decision | Rationale |
|---|---|---|
| V2-D1 | Pad storage to `2**clog2(G_DEPTH)` words | This directly removes the unallocated-address branch identified in F-FIFO-005 while keeping a plain indexed read. The cost is unused words at non-power-of-two depths. |
| V2-D2 | Use `unsigned` pointers of fixed width `C_AW` | This makes the address width equal the memory's address space by construction, instead of relying on how the tool sizes `natural range 0 to D-1`. |
| V2-D3 | Use a separate register branch for depth 1 | This avoids a 0-bit address (null range) and padding a single word to two. V1 had no memory object at depth 1 either. |
| V2-D4 | Keep reset gating and `count`-based flags exactly as in V1 | These carry the contract. Keeping them identical leaves the storage path as the only difference between the designs. |
| V2-D5 | Put the write port in its own process with no reset branch | This is the conventional memory template. Reset cannot write because `push` is gated. |
| Rejected | Exact `G_DEPTH` words with a plain index | This is the original failure (F-FIFO-005). |
| Rejected | Exact words with an address clamp or range guard on the read | The guard adds back an extra branch around the read, which risks the same mux-ification as V1. |
| Rejected | Synchronous-read memory with a prefetch or output register | This needs a bypass or skid path to keep the same-cycle `rd_data` and depth-1 replacement behaviour. It adds a second storage path and risks changing capacity or ordering. Much more complex for an educational exercise. |
| Rejected | Separate full/empty flags or a wrap bit instead of `count` | `count` is already verified, and the alternatives give no clear benefit without measurement. |
| Rejected | Vendor attributes such as `ram_style` | Vendor-specific, and they prove nothing in a generic Yosys flow. |

## Risks and assumptions

- **NOT RUN.** I have no GHDL/Yosys measurement, so I don't know whether GHDL 4.1.0
  `--synth` emits an async-read memory that Yosys 0.33 keeps as a `$mem`/`$mem_v2`
  object in the planner's memory-preserving view. If it does not, that is a measured
  outcome; the contract is not changed to get inference.
- Padded memories at non-power-of-two depths report more memory bits than
  `storage_bits`. The planner's metrics should distinguish the two.
- A retained memory object does **not** mean BRAM. An asynchronous read normally maps
  to LUTRAM or flip-flops on FPGA targets. I make no resource, timing or frequency
  claims.
- `clog2` uses a `while` loop on a generic. I assume it is evaluated at elaboration
  time by GHDL simulation and synthesis.
- I assume the planner's strict checks are the same commands as V1, and that the
  memory count comes from a view that does not run `memory_map`.

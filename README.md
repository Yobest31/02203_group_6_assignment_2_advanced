# 02203 Group 6 – Assignment 2 (Advanced): Sobel Edge Detection Accelerator

VHDL implementation of a hardware accelerator that runs a 3×3 Sobel edge-detection
filter over a greyscale image stored in on-chip memory. The design processes
**4 pixels per clock cycle** by packing four 8-bit pixels into each 32-bit memory word.

## Repository contents

| File | Description |
|------|-------------|
| [sobel_pkg.vhd](sobel_pkg.vhd) | Shared package. Defines `quad_kernel_t`, an 18-element array of 8-bit pixels (a 3-row × 6-column window). |
| [sobel.vhd](sobel.vhd) | Sobel ALU (`sobel`). Computes four output pixels in parallel from one 3×6 window, registered output. |
| [pixel_acc_vhd_fsm.vhd](pixel_acc_vhd_fsm.vhd) | Control FSM (`pixel_fsm`). Drives memory reads/writes, the line buffer and the ALU enable. |

## Image format

The default generics target a **352 × 288** (CIF) 8-bit greyscale image:

- 4 pixels per 32-bit word → `IMG_WIDTH = 352 / 4 = 88` words per row
- `BUF_DEPTH = 88 × 288 = 25 344` words per image
- `BUF_AW = 15` address bits (2¹⁵ = 32 768 ≥ 25 344)

## Architecture overview

```
           ibuf_rd_addr / rd_en                       obuf_wr_addr / wr_en
 ┌──────────┐ ─────────────► ┌─────────────┐  3×6 window  ┌────────┐ 32-bit ┌───────────┐
 │  Input   │   32-bit word  │ Line buffer │ ───────────► │ sobel  │ ─────► │  Output   │
 │  memory  │ ─────────────► │  (3 rows)   │ quad_kernel_t│  ALU   │        │  memory   │
 └──────────┘                └─────────────┘              └────────┘        └───────────┘
       ▲                            ▲  lb_* control           ▲ alu_en           ▲
       └────────────────────────────┴──────── pixel_fsm ──────┴──────────────────┘
```

### `sobel` – Sobel ALU

- **Input** `pixels_in : quad_kernel_t` – a window of 3 rows × 6 columns, laid out
  row-major (index = `row * 6 + col`).
- **Output** `pixels_out : std_logic_vector(31 downto 0)` – four filtered pixels,
  output pixel 0 in bits `7:0`, pixel 3 in bits `31:24`.
- For each output `i` (0–3) the 3×3 neighbourhood starts at column `i`:

  ```
  tl tm tr      Gx = (tr + 2·mr + br) − (tl + 2·ml + bl)
  ml  ·  mr     Gy = (bl + 2·bm + br) − (tl + 2·tm + tr)
  bl bm br      |G| ≈ |Gx| + |Gy|, saturated to 255
  ```

- Arithmetic is done in 12-bit signed values. The maximum magnitude is 2040, so it fits.
- Latency: **1 clock cycle**, with an asynchronous active-low reset (`rst_n`).

### `pixel_fsm` – Control FSM

#### Generics

| Generic | Default | Meaning |
|---------|---------|---------|
| `BUF_AW` | 15 | Address width of the input/output buffers |
| `BUF_DEPTH` | 25344 | Number of 32-bit words in the image |
| `IMG_WIDTH` | 88 | Words per image row (must be ≥ 3) |
| `EDGE_MIRROR` | `true` | `true`: produce a full-size output by mirroring border rows/columns. `false`: skip the first and last rows (`BUF_DEPTH − 2·IMG_WIDTH` outputs) |
| `OUT_BASE` | 0 | First output-buffer address (must be 0 when `EDGE_MIRROR = true`) |

#### Ports

| Port | Dir | Description |
|------|-----|-------------|
| `clk`, `rst_n` | in | Clock and asynchronous active-low reset |
| `start` | in | Starts processing one image (sampled in `IDLE`) |
| `finish` | out | One-cycle pulse when the image is done |
| `ibuf_rd_en`, `ibuf_rd_addr` | out | Input memory read (1-cycle read latency assumed) |
| `obuf_wr_en`, `obuf_wr_addr` | out | Output memory write |
| `lb_shift_en` | out | Shift one word into the line buffer |
| `lb_flush` | out | Dummy shifts after the last read, to flush the line buffer |
| `lb_first_row`, `lb_last_row` | out | Current row is the top/bottom image row (mirror mode only) |
| `lb_first_w`, `lb_last_w` | out | Current word is the first/last word of a row (mirror mode only) |
| `alu_en` | out | Window is valid; the ALU result is written one cycle later |

#### States

| State | Action |
|-------|--------|
| `IDLE` | Wait for `start`, reset counters, start the sequential read of the input buffer |
| `LOAD_ROW0` | Read the first image row (and flag it as `lb_first_row` in mirror mode) |
| `FILL_ROW1` | Keep filling the line buffer until the first valid window (`FIRST_K` shifts) |
| `FIRST_W` | First word of an output row |
| `MID_W` | Middle words of an output row |
| `LAST_W` | Last word of an output row. Go to the next row, or to `LAST_ROW`/`FIN` |
| `LAST_ROW` | Mirror mode only: emit the bottom row using the flushed (dummy) shifts |
| `FIN` | Pulse `finish`, return to `IDLE` |

#### Pipeline timing

1. `ibuf_rd_en` → data valid one cycle later (`rd_valid`) → `lb_shift_en`.
2. After `FIRST_K` shifts (`IMG_WIDTH+1` in mirror mode, `2·IMG_WIDTH+1` otherwise)
   every further shift gives a valid window → `alu_en`.
3. `obuf_wr_en` is `alu_en` delayed by one cycle, which matches the 1-cycle ALU latency.
   `obuf_wr_addr` counts up from `OUT_BASE`.
4. After the last read, `lb_flush` gives `N_DUMMY` extra shifts (`IMG_WIDTH+1` in
   mirror mode, 1 otherwise) to push the final windows out of the line buffer.

## Simulation / synthesis

Compile order (the package must be compiled first):

```
sobel_pkg.vhd
sobel.vhd
pixel_acc_vhd_fsm.vhd
```

Example with GHDL:

```sh
ghdl -a --std=08 sobel_pkg.vhd sobel.vhd pixel_acc_vhd_fsm.vhd
```

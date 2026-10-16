# Interfacing-of-OV7670-and-testing-its-working-with-matlab

# OV7670 Camera Capture on FPGA (Verilog) with UART Streaming to MATLAB

An FPGA design that configures an **OV7670** camera over SCCB (I²C-like), captures one **320×240 RGB444** frame into on-chip memory, and sends it over **UART** to a PC. A MATLAB script then rebuilds the image from the raw bytes.

```
OV7670 ──► SCCB config FSM ──► camera registers
   │
   └─ pclk/vs/hs/d[7:0] ──► Frame capture (BRAM 76800 x 12-bit) ──► UART TX (115200) ──► MATLAB ──► Image
```

## Features

- SCCB register configuration of 76 OV7670 registers by a Verilog FSM (about 10 kHz SCL)
- Readback verification of every register written (the FSM reads each register back and compares it)
- QVGA (320×240) RGB444 capture, stored as 12 bits per pixel (76,800 pixels)
- 10 MHz `xclk` generated from the 100 MHz system clock
- UART transmitter at 115200 baud, 8N1, using a divider of 868 clocks per bit
- MATLAB script to receive, decode and display the image, and to dump binary/RGB text grids

## Repository Structure

| File | Description |
|------|-------------|
| `top.v` | Top-level module that connects the camera, SCCB FSM and UART |
| `fsm.v` | SCCB (I²C-like) master that writes the config table and verifies it by readback |
| `ov7670.v` | `xclk` generation, VSYNC/HREF capture FSM, frame memory |
| `uart.v` | UART transmitter that reads the frame memory and sends it byte by byte (also contains `topp`, the baud tick generator) |
| `constraints.xdc` | Pin constraints |
| `receive_image.m` | MATLAB script to receive and reconstruct the image |

## Hardware Required

- Arty S7-25 FPGA board (100 MHz clock on pin R2)
- OV7670 camera module (the no-FIFO version)
- 4.7 kΩ pull-ups on SDA and SCL, unless your module already has them
- USB-UART connection to the PC (the script uses `COM5`)

## Pin Mapping

| Signal | Pin | Direction | Description |
|--------|-----|-----------|-------------|
| `clk` | R2 | in | 100 MHz system clock (SSTL135) |
| `reset` | H14 | in | Active-high reset |
| `start_cfg` | H18 | in | Starts camera configuration |
| `start_cam` | G18 | in | Starts frame capture |
| `uart_start` | M5 | in | Starts UART image transmission |
| `sda` | T18 | inout | SCCB data |
| `scl` | P16 | inout | SCCB clock |
| `xclk` | P18 | out | Clock to camera (10 MHz) |
| `pclk` | R14 | in | Pixel clock from camera |
| `vs` | N15 | in | VSYNC |
| `hs` | R18 | in | HREF |
| `d[7:0]` | L17, M16, L18, M17, M14, M18, N14, N18 | in | Camera data bus (d[0] to d[7]) |
| `pwdn` | P1 | out | Camera power-down |
| `ret` | P14 | out | Camera reset |
| `tx` | R12 | out | UART TX |
| `fsm_led` | E18 | out | ON when all registers are written and verified |
| `cam_led` | F13 | out | ON when the frame is captured |
| `uart_led` | E13 | out | UART status LED |

## How It Works

### 1. SCCB Configuration (`fsm.v`)
- The register table (`addr[]` / `data[]`) holds 76 entries: reset, RGB444 output format, QVGA window, scaling, gamma curve, matrix coefficients and AGC/AEC.
- For each entry the FSM:
  1. Writes it to the camera (device address `0x42`).
  2. Reads it back (device address `0x43`).
  3. Compares the readback with the expected value.
- `fsm_led` turns ON when all entries are written and verified. If a mismatch occurs, the FSM stops in the error state with the LED OFF.

### 2. Frame Capture (`ov7670.v`)
- Waits for `start_cam`, then skips 10 frames on VSYNC falling edges so the camera's auto-exposure can settle.
- Writes pixels on `pclk` while HREF is high. Two bytes make one pixel, stored as 12 bits:
  `mem[addr] = {byte1[7:4], byte1[3:0], byte2[7:4]}` = `{R[3:0], G[3:0], B[3:0]}`
- Captures 76,800 pixels (320×240), then turns on `cam_led`.
- Memory is 76,800 × 12 bits (about 900 kbit), so choose an FPGA with enough BRAM.

### 3. UART Transmission (`uart.v`)
- Reads each pixel from memory, then left-aligns it in 16 bits as `{pixel[11:0], 4'b0}`.
- Sends **2 bytes per pixel, low byte first, then high byte**, with 8N1 framing at 115200 baud.
- Total transfer is **153,600 bytes** (76,800 × 2).

### 4. PC Side (MATLAB)
- Reads 153,600 bytes from the serial port and combines each pair into a 16-bit value `(high << 8) + low`.
- Reshapes the values to 240×320 and splits them into R = bits `[15:12]`, G = bits `[11:8]`, B = bits `[7:4]`.
- Scales each 4-bit channel to 8 bits (×17) and displays the result with `imshow`.
- Also writes `binary_grid.txt`, `rgb_segmented_grid.txt` and `rgb_decimal_grid.txt` for debugging.

## Usage

1. Synthesize and program the bitstream (Vivado) with the provided `.xdc`.
2. Connect the OV7670 to the pins above.
3. Press **reset**.
4. Raise **`start_cfg`**. Wait for `fsm_led` to turn ON (camera configured and verified).
5. Raise **`start_cam`**. Wait for `cam_led` to turn ON (frame stored).
6. Run the MATLAB script. Edit `serialport("COM5", 115200)` to match your COM port.
7. Raise **`uart_start`**. The image is streamed and MATLAB displays it.
8. Lower `uart_start` and `start_cam` to return to idle. Repeat for another frame.

> Start the MATLAB script **before** raising `uart_start`, because the read waits for 153,600 bytes (about 13.3 s at 115200 baud).

## Timing Summary

| Item | Value |
|------|-------|
| System clock | 100 MHz |
| `xclk` | 10 MHz |
| SCCB SCL | ~10 kHz |
| UART baud | 115200 (100 MHz / 868) |
| Frame size | 320 × 240 × 12 bit |
| UART transfer time | ~13.3 s per frame |

## Known Limitations / Future Work

- Single-frame capture only, with no live video.
- UART is slow. A faster baud rate (e.g. 921600 or 3 Mbaud) or USB/VGA output would help.
- The memory is written on `pclk` and read on `clk`. This works for a static frame, but add proper synchronization if you capture and read at the same time.
- Colour accuracy depends on the matrix and gamma registers. Tune them for your lighting.
- Add a VGA or HDMI display path to view the frame without the PC.

## Requirements

- Xilinx Vivado
- MATLAB R2019b or later (for `serialport`)

# Custom AXI-Stream Convolution Accelerator on Zynq SoC

## Project Overview
Designed and implemented a custom hardware-accelerated 2D Convolution engine on a Zynq SoC using hardware/software co-design principles. By offloading heavy matrix compute from the ARM Cortex-A9 processor to a custom FPGA IP via a dual-port AXI Direct Memory Access (DMA) pipeline, the system achieved a ~22x performance speedup with 100% data accuracy.

## Repository Structure

```text
CNN_ON_ZYNQ/
├── hdl/                        # Hardware Description Language (Verilog)
│   ├── axi_conv_2d.v           # Top Level Wrapper (AXI Stream Interface)
│   ├── conv_line_buffers.v     # Line Buffers (Row Caching)
│   ├── conv_window_manager.v   # Sliding Window Generation
│   ├── conv_math_core.v        # Arithmetic Core (MAC Units)
│   └── conv_control_unit.v     # Output Formatting & Control
├── sim/                        # Simulation
│   └── tb_axi_conv_2d.v        # SystemVerilog Testbench
├── pynq/                       # Software Driver
│   ├── system.bit              # Generated Bitstream
│   ├── system.hwh              # Hardware Handoff
│   └── test_pynq.py            # Python Driver & Benchmark Script
└── docs/                       # Documentation & Diagrams
    └── system.png              # Block Design
  ```

## System Architecture

### Data Flow

`Input Stream` → `Line Buffers` → `Window Manager` → `Math Core` → `Control Unit` → `Output Stream`

![Block Design Diagram](./system.png)
*Figure 1: Vivado Block Design showing the custom IP integration.*

### The Data Path: Dual High-Performance Interfaces
To maximize memory bandwidth and prevent interconnect bottlenecks, the architecture utilizes split High-Performance (HP) AXI memory interfaces:
* **Memory to PL (Read Path):** The ARM CPU allocates physically contiguous memory in DDR. The AXI DMA reads the image matrix via the dedicated `S_AXI_HP0` port, streaming data into the custom Verilog `axi_conv_2d` IP via AXI4-Stream.
* **PL to Memory (Write Path):** The processed feature map streams out of the IP and is written back to DDR RAM via a secondary, dedicated `S_AXI_HP1` port. 
* **Result:** Read and write transactions occur simultaneously without arbitrating for the same AXI interconnect pathway, significantly improving throughput for continuous data streaming.
* **Configuration:** The ARM CPU configures the DMA registers via the `M_AXI_GP0` port (AXI4-Lite).
* **Dual-Reset Domains:** To prevent AXI bus lock-ups during software-triggered resets, the architecture utilizes isolated reset domains:
  1. **System Interconnect Domain:** The AXI SmartConnect and AXI GPIO are tied to the main system reset, ensuring the CPU never loses connection to the memory-mapped bus.
  2. **Compute Accelerator Domain:** The AXI DMA and Conv2D IP are tied to a secondary Xilinx Processor System Reset block. An AXI GPIO is routed to the `aux_reset_in`, allowing the software to safely reset the compute IPs between runs without crashing the central AXI interconnects.

## Software Stack (PYNQ / Python)
The software driver handles memory allocation, hardware synchronization, and performance benchmarking. 

Key execution sequence:
1. Initialize AXI GPIO to release the hardware's Compute Accelerator Domain from its active-low reset state.
2. Allocate contiguous memory buffers for DMA payloads.
3. Assert a custom software reset via GPIO to safely flush the hardware pipelines.
4. Start DMA Send/Receive channels via the PYNQ driver.
5. Transfer the input matrix and wait for the AXI-Stream `TLAST` interrupt completion.

## Performance Benchmarks
Benchmarking was performed against a pure software implementation running on the Zynq ARM Cortex-A9.

### Without DSP
(First 10 Runs)
It was executed 100 times after running a few preliminary tests.
| Test Run | Hardware Time (ms) | Software Time (ms) | Speedup |  Match |
| :------- | :----------------- | :----------------- | :------ | :--------- |
| 1        | 0.42               | 65.45              | ~155.8x | True       |
| 2        | 0.41               | 65.74              | ~160.3x | True       |
| 3        | 0.41               | 65.44              | ~159.6x | True       |
| 4        | 0.51               | 72.72              | ~142.6x | True       |
| 5        | 0.41               | 65.13              | ~158.9x | True       |
| 6        | 0.41               | 65.54              | ~159.9x | True       |
| 7        | 0.41               | 82.66              | ~201.6x | True       |
| 8        | 0.41               | 71.55              | ~174.5x | True       |
| 9        | 0.41               | 65.15              | ~158.9x | True       |
| 10       | 0.42               | 74.68              | ~177.8x | True       |

### With DSP
| Test Run | Hardware Time (ms) | Software Time (ms) | Speedup |  Match |
| :------- | :----------------- | :----------------- | :------ | :--------- |
| 1        | 0.43               | 65.51              | ~152.3x | True       |
| 2        | 0.46               | 65.08              | ~141.5x | True       |
| 3        | 0.42               | 65.28              | ~155.4x | True       |
| 4        | 0.41               | 83.26              | ~203.1x | True       |
| 5        | 0.42               | 65.23              | ~155.3x | True       |
| 6        | 0.41               | 64.95              | ~158.4x | True       |
| 7        | 0.45               | 83.21              | ~184.9x | True       |
| 8        | 0.42               | 65.20              | ~155.2x | True       |
| 9        | 0.41               | 65.59              | ~160.0x | True       |
| 10       | 0.41               | 82.68              | ~201.7x | True       |


**Average Stable Speedup:** ~22x

- **LUT:** 30%
- **FF:** 21%
- **BRAM:** 4%

## Key Engineering Challenges Solved
* **Memory Bandwidth Optimization:** Identified a potential bottleneck in routing bidirectional DMA traffic through a single HP port. Re-architected the block design to utilize `S_AXI_HP0` and `S_AXI_HP1`, isolating the memory streams.
* **Metastability & AXI Bus Lock-ups:** Diagnosed a system hang as a severed AXI Write Response (BRESP) caused by resetting the SmartConnect mid-transaction. Architected a dual-reset domain solution using multiple Xilinx Processor System Reset blocks to safely isolate the data plane from the control plane.
* **State Machine Synchronization:** Resolved driver-level DMA state errors by correcting the software boot sequence, ensuring the hardware was fully released from reset before the driver attempted to initialize the DMA registers.
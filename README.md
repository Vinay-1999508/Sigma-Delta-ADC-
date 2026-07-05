#  Mixed-Signal Sigma-Delta ADC Pipeline (End-to-End)

A complete, end-to-end mixed-signal engineering project demonstrating the design, simulation, and mathematical optimization of a **Sigma-Delta Analog-to-Digital Converter**. 

This repository documents the full pipeline: starting from a transistor/op-amp level continuous-time analog modulator in **LTspice**, transitioning to a high-speed digital decimation filter written in **Verilog (Vivado)**, and concluding with DSP performance analysis using **Python**.

###  Executive Summary & Key Achievement
The core engineering achievement of this project was identifying and resolving a fundamental architectural bottleneck in the digital DSP back-end. 

Initially, a **1st-order CIC decimation filter** was implemented. However, because the analog front-end was a 2nd-order modulator, the 1st-order digital filter failed to adequately suppress the $+40\text{ dB/decade}$ shaped quantization noise. This resulted in severe spectral leakage and an unusable **Signal-to-Noise Ratio (SNR) of 0.97 dB**.

By applying DSP theory, the digital architecture was upgraded to a **3rd-order CIC filter ($K=3$)**. This provided a steeper roll-off that successfully mathematically matched the analog modulator's noise-shaping profile, increasing the dynamic range utilization to $\pm15,000$ LSBs and boosting the system performance to **52.76 dB SNR** and **8.47 ENOB**.

---

##  Repository Structure (Hub & Spoke)

This repository is divided into distinct engineering domains. Click on any folder to view its dedicated documentation and source files.

* 📁 **[1_Analog_Front_End_LTspice]** - 2nd-Order Continuous-Time Modulator schematics and transient analysis.
* 📁 **[2_Digital_Back_End_Vivado]** - Verilog RTL for the 3rd-order CIC filter, State Machines, and UART Transmitter.
* 📁 **[3_Signal_Processing_Python]** - Python DSP scripts for Blackman-Harris windowing, FFT extraction, and SNR calculations.
* 📁 **[4_Waveforms_and_Screenshots]** - High-resolution timing diagrams, analog transients, and frequency spectrum plots.

---

## 📐 System Architecture

The data pathway bridges the continuous analog domain and the discrete digital domain.

```text
[Analog Domain]                                 [Digital Domain (FPGA/ASIC)]
┌───────────────┐ 10 MHz 1-bit PDM ┌────────────────────────┐ 16-bit PCM  ┌──────────────┐
│  2nd-Order    ├─────────────────►│     3rd-Order CIC      ├────────────►│ UART Serial  │
│  Sigma-Delta  │                  │   Decimation Filter    │ 312.5 kHz   │ Transmitter  │
│  Modulator    │                  │       (OSR = 32)       │             │ (115200 Baud)│
└───────────────┘                  └────────────────────────┘             └──────┬───────┘
    (LTspice)                              (Verilog RTL)                         │
                                                                                 ▼
                                                                           PC / Python DSP

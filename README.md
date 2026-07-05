#  Mixed-Signal Sigma-Delta ADC Pipeline (End-to-End)

A complete, end-to-end mixed-signal engineering project demonstrating the design, simulation, and mathematical optimization of a **Sigma-Delta Analog-to-Digital Converter**. 

This repository documents the full pipeline: starting from a transistor/op-amp level continuous-time analog modulator in **LTspice**, transitioning to a high-speed digital decimation filter written in **Verilog (Vivado)**, and concluding with DSP performance analysis using **Python**.

##  Theoretical Background: Why Sigma-Delta?

### What is a Sigma-Delta ADC?
A Sigma-Delta Analog-to-Digital Converter is a mixed-signal architecture that achieves extremely high resolution by trading analog component complexity for digital processing speed. Instead of trying to measure an exact voltage with highly precise (and expensive) analog components, a $\Sigma\Delta$ ADC samples the signal at a massive speed to generate a 1-bit Pulse-Density Modulated (PDM) stream, and then uses a digital filter to average that stream into a precise multi-bit value.

### Why and Where Are They Used?
* **The Advantage:** They offer the highest resolution (often 16 to 24 bits) and the highest Signal-to-Noise Ratio (SNR) of any ADC architecture, without requiring perfectly matched analog resistors or capacitors. 
* **Applications:** Because they excel at high-resolution conversions of lower-frequency signals, they are the industry standard for **digital audio processing**, precision sensor measurements (thermocouples, weight scales), and biomedical instrumentation (ECG/EEG).

### The Alternatives
If a $\Sigma\Delta$ ADC is not used, engineers typically choose from:
* **SAR ADCs (Successive Approximation Register):** Good for medium speed and medium resolution (e.g., microcontrollers).
* **Flash ADCs:** Extremely fast but very low resolution and high power (e.g., radar, oscilloscopes).
* **Pipeline ADCs:** A middle ground for high bandwidth and medium resolution (e.g., video processing).

---

##  Why This Specific Architecture?

This project utilizes a **2nd-Order Analog Modulator** followed by a **3rd-Order Digital CIC Filter**. This exact circuit flow was chosen based on two fundamental DSP concepts: Oversampling and Noise Shaping.

### 1. Oversampling
By sampling the analog signal much faster than the Nyquist rate, the total quantization noise is spread over a much wider frequency band. 

The OverSampling Ratio (OSR) is defined as:
$$OSR = \frac{f_{s}}{2 f_{B}}$$
*(Where $f_s$ is the sampling frequency and $f_B$ is the signal bandwidth).*

### 2. Noise Shaping (The Analog Modulator)
A standard ADC distributes quantization noise evenly across the frequency spectrum. A $\Sigma\Delta$ modulator uses analog integrators in a feedback loop to act as a high-pass filter for the noise. 
* A 1st-order loop pushes noise up at $+20\text{ dB/decade}$.
* **Our 2nd-order loop** pushes noise up at $+40\text{ dB/decade}$, aggressively clearing the low-frequency baseband so our target audio signal is completely isolated from the noise floor.

### 3. Decimation (The Digital Back-End)
Because the analog modulator shoves all the noise into the high-frequency spectrum, we need a digital low-pass filter to chop that noise off before downsampling (decimating) the signal back to a normal audio rate. 
* A Cascaded Integrator-Comb (CIC) filter is used because it requires **zero multipliers** (only adders and registers), making it incredibly efficient for high-speed FPGA fabric.
* The digital filter order ($K$) must strictly exceed the analog modulator order ($L$) to effectively crush the $+40\text{ dB/decade}$ noise wall. Hence, $K=3$ was mathematically required to resolve the signal.



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
## 📐 Core System Specifications

* **Target Input Signal:** $1\text{ kHz}$ Analog Sine Wave
* **Master System Clock ($f_{clk}$):** $10\text{ MHz}$
* **OverSampling Ratio (OSR):** $32$
* **Decimated Output Rate ($f_s$):** $312.5\text{ kHz}$
* **Digital Word Length:** $16\text{ Bits}$
* **UART Transmission Rate:** $115,200\text{ Baud}$

---

##  Mathematical Foundation & Filter Theory

### 1. Filter Order Matching ($K > L$)
In a Sigma-Delta architecture, the order of the digital decimation filter ($K$) must strictly be greater than the order of the analog modulator ($L$). This ensures the digital filter's roll-off is steep enough to prevent the high-frequency quantization noise from aliasing back into the baseband during downsampling. 

* **Analog Modulator Order:** $L = 2$ (Generates $+40\text{ dB/decade}$ high-pass shaped noise).
* **Initial Filter Order:** $K = 1$  *(Failed: Allowed noise to alias, resulting in 0.97 dB SNR).*
* **Optimized Filter Order:** $K = 3$  *(Succeeded: Provides $-60\text{ dB/decade}$ stopband attenuation, successfully crushing the noise).*

### 2. Output Bit Growth Formula
A Cascaded Integrator-Comb (CIC) filter inherently increases the bit-width of the data as it integrates. To prevent internal register overflow while capturing the full dynamic range, the final output bit-width ($B_{out}$) is calculated mathematically:

$$B_{out} = B_{in} + K \times \log_2(R)$$

Where:
* $B_{in} = 1$ (The 1-bit PDM input stream)
* $K = 3$ (The CIC Filter Order)
* $R = 32$ (The OverSampling Ratio)

$$B_{out} = 1 + 3 \times \log_2(32) = 1 + (3 \times 5) = \mathbf{16 \text{ Bits}}$$

This perfectly aligns the digital output for standard 16-bit PCM audio processing.

### 3. Decimated Output Frequency
The physical frequency at which the 16-bit words are generated is determined by dividing the master clock by the OverSampling Ratio:

$$f_{s} = \frac{f_{clk}}{OSR} = \frac{10\text{ MHz}}{32} = \mathbf{312.5\text{ kHz}}$$

### 4. UART Baud Rate Clock Division
To step down the internal $10\text{ MHz}$ FPGA master clock to a stable serial transmission speed of $115,200\text{ Baud}$, an explicit internal division count is declared:

$$\text{Cycles Per Serial Bit} = \frac{10,000,000\text{ Hz}}{115,200\text{ bps}} \approx \mathbf{87 \text{ Cycles}}$$

By setting the internal counter to $87$, the hardware accurately controls the serial bit duration, preventing timing drift and ensuring compliance with standard PC serial receivers.


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




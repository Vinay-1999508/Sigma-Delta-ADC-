# Signal Processing & DSP Analysis (Python)

This section contains the Python toolchain developed to bridge the analog and digital simulations and to perform rigorous spectral analysis on the final recovered signal.

## Data Ingestion & Pre-Processing

The raw output from the continuous-time analog simulation consists of floating-point time and voltage pairs (e.g., `1.2e-6 5.0V`). Before this can be injected into the Verilog digital filter testbench, it must be converted into a pure, clock-aligned binary stream. 

The preprocessing script parses the analog simulation output, applies a threshold to emulate the 1-bit comparator logic, and generates a strict binary sequence of `1`s and `0`s that perfectly aligns with the $10\text{ MHz}$ sampling boundaries required by the RTL environment.

## Frequency Domain Analysis (FFT)

To accurately measure the performance of the Sigma-Delta ADC pipeline, the 16-bit Pulse-Code Modulated (PCM) data recovered by the digital filter is analyzed in the frequency domain using a Fast Fourier Transform (FFT).

### Windowing (Addressing Spectral Leakage)
Because the target $1\text{ kHz}$ analog signal and the $312.5\text{ kHz}$ decimated digital sampling rate are not perfectly coherent, performing a raw FFT results in severe spectral leakage. This leakage artificially elevates the noise floor across the entire spectrum, which heavily distorts the SNR calculation.

To resolve this, a **Blackman-Harris window** is applied to the time-domain signal before the FFT calculation. This specific window function was selected due to its excellent side-lobe suppression (down to $-92\text{ dB}$). This high dynamic range is critical in Sigma-Delta analysis, as it prevents the fundamental baseband signal from leaking into and masking the shaped high-frequency quantization noise.

### Power Spectral Density (PSD)
The FFT output is normalized and converted into a Power Spectral Density array (scaled in decibels). The frequency bins are plotted from DC up to the Nyquist frequency ($f_s / 2 = 156.25\text{ kHz}$).

## Performance Metrics Calculation

### Signal-to-Noise Ratio (SNR)
The SNR is computed by isolating the fundamental signal power and comparing it to the integrated noise power across the spectrum.

1. **Signal Power ($P_{signal}$):** Extracted by locating the maximum power bin near the $1\text{ kHz}$ target frequency and integrating the energy of the adjacent main-lobe bins (a 5-bin window is utilized to account for the energy spread introduced by the Blackman-Harris window).
2. **Noise Power ($P_{noise}$):** Calculated by summing the power of all other frequency bins in the baseband, explicitly excluding the DC offset bin ($0\text{ Hz}$) and the fundamental signal main-lobe.

The final SNR is calculated as:
$$SNR = 10 \times \log_{10} \left( \frac{P_{signal}}{P_{noise}} \right)$$

### Effective Number of Bits (ENOB)
The ENOB provides a realistic measure of the ADC's actual resolution by translating the measured SNR back into bits, accounting for the quantization noise, thermal noise, and distortion of the entire mixed-signal system. It is calculated using the standard IEEE formula:
$$ENOB = \frac{SNR - 1.76}{6.02}$$

By processing the outputs of the optimized 3rd-order digital back-end through these DSP algorithms, the system confirms a final mathematical performance of **52.76 dB SNR** and **8.47 ENOB**.

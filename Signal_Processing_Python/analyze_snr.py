import numpy as np
import matplotlib.pyplot as plt
from scipy.fft import fft, fftfreq

# 1. Load the data robustly
filename = "recovered_pcm.txt"
raw_data = []

try:
    with open(filename, 'r') as f:
        for line in f:
            line = line.strip()
            if not line: continue
            try: raw_data.append(float(line))
            except ValueError: pass
    data = np.array(raw_data)
except FileNotFoundError:
    print(f"Error: {filename} not found.")
    exit()

# 2. CHOP OFF the first 50 samples (Ignore CIC startup transient)
data = data[50:]

# System Parameters
fs = 312500  
N = len(data)
t = np.arange(N) / fs

# Remove DC offset (Mean)
data = data - np.mean(data)

# Apply a Blackman-Harris window
window = np.blackman(N)
windowed_data = data * window

# 3. Calculate FFT
fft_out = fft(windowed_data)
fft_mag = np.abs(fft_out)[:N//2]
fft_mag_db = 20 * np.log10(fft_mag / np.max(fft_mag))
freqs = fftfreq(N, 1/fs)[:N//2]

# 4. Find Fundamental Frequency (Skip DC bin 0 to avoid false positives)
signal_bin = np.argmax(fft_mag[1:]) + 1 

# 5. Calculate Power CORRECTLY (Sum the main lobe, ~5 bins wide)
signal_power = 0
for i in range(max(1, signal_bin-2), min(len(fft_mag), signal_bin+3)):
    signal_power += fft_mag[i]**2

# Total power (excluding DC bin 0)
total_power = np.sum(fft_mag[1:]**2)
noise_power = total_power - signal_power

# Prevent math domain errors if noise is somehow perfectly zero
if noise_power <= 0:
    noise_power = 1e-10

# 6. Calculate SNR and ENOB
snr_linear = signal_power / noise_power
snr_db = 10 * np.log10(snr_linear)
enob = (snr_db - 1.76) / 6.02

# 7. Print Results
print("=== Sigma-Delta ADC Performance ===")
print(f"Decimated Sampling Rate: {fs/1000:.1f} kHz")
print(f"Fundamental Frequency:   {freqs[signal_bin]:.1f} Hz")
print(f"Measured SNR:            {snr_db:.2f} dB")
print(f"Calculated ENOB:         {enob:.2f} Bits")
print("===================================")

# 8. Plotting
plt.figure(figsize=(12, 6))

plt.subplot(1, 2, 1)
plt.plot(t, data)
plt.title("Recovered PCM Waveform (Time Domain)")
plt.xlabel("Time (s)")
plt.ylabel("Amplitude (LSB)")
plt.grid(True)

plt.subplot(1, 2, 2)
plt.plot(freqs, fft_mag_db)
plt.title("FFT Spectrum (Frequency Domain)")
plt.xlabel("Frequency (Hz)")
plt.ylabel("Magnitude (dBFS)")
plt.grid(True)
plt.xlim(0, 10000) # Zoom in on the lower frequencies to see the signal clearly
plt.ylim(-100, 5)

plt.tight_layout()
plt.show()
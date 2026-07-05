% 2nd-Order Delta-Sigma Modulator Simulation
clear; clc; close all;

%% 1. Setup Parameters
fs = 10e6;           % Sampling frequency (10 MHz, same as the original project)
f_sig = 10e3;        % Input sine wave frequency (10 kHz)
N = 1000;            % Number of samples to simulate
t = (0:N-1) / fs;    % Time vector

%% 2. Generate "Analog" Input Signal
% We use a sine wave with amplitude 0.5 to prevent overloading the modulator
analog_in = 0.5 * sin(2*pi*f_sig*t); 

%% 3. Initialize Variables for the Modulator
int1 = 0;   % Integrator 1 state
int2 = 0;   % Integrator 2 state
v_out = 0;  % Output of the quantizer (+1 or -1)

% Array to store our final 1-bit output stream
bitstream = zeros(1, N); 

%% 4. The Delta-Sigma Loop (Simulating the Hardware)
for i = 1:N
    % The difference between input and feedback
    delta1 = analog_in(i) - v_out; 
    int1 = int1 + delta1;             % First integrator
    
    delta2 = int1 - v_out;
    int2 = int2 + delta2;             % Second integrator
    
    % 1-bit Quantizer (Comparator)
    if int2 >= 0
        v_out = 1;
        bitstream(i) = 1;   % Logic High for our FPGA
    else
        v_out = -1;
        bitstream(i) = 0;   % Logic Low for our FPGA
    end
end

%% 5. Plot the Results
figure;
subplot(2,1,1);
plot(t, analog_in, 'LineWidth', 1.5);
title('Original "Analog" Sine Wave Input');
xlabel('Time (s)'); ylabel('Amplitude');
grid on;

subplot(2,1,2);
stairs(t, bitstream);
title('1-Bit Delta-Sigma Output (The Bitstream)');
xlabel('Time (s)'); ylabel('Logic Level');
axis([0 max(t) -0.2 1.2]);

%% 6. Digital Filtering (Decimation)
% We choose an OverSampling Ratio (OSR) of 32. 
% This means for every 32 bits from the ADC, we output 1 multi-bit sample.
OSR = 32; 

% Step A: Moving Average Filter (Acts like the integrator/comb stages)
% This counts the density of 1s in a moving window
moving_avg = movmean(bitstream, OSR);

% Step B: Scale the signal back to match the original amplitude
% Because our bitstream is 0s and 1s, its average sits between 0 and 1.
% We shift and scale it to map back to our original analog range (-0.5 to +0.5).
decoded_analog = 2 * (moving_avg - 0.5);

% Step C: Decimation (Downsampling)
% We drop the sampling rate from 10 MHz down to (10 MHz / 32) = 312.5 kHz
decimated_signal = decoded_analog(1:OSR:end);
t_decimated = t(1:OSR:end);

%% 7. Plot the Reconstructed Signal
figure;
plot(t, analog_in, 'r--', 'LineWidth', 2); hold on;
plot(t, decoded_analog, 'b-', 'LineWidth', 1.5);
stem(t_decimated, decimated_signal, 'k', 'MarkerFaceColor', 'k');
title('Reconstructing the Analog Signal from the 1-Bit Stream');
xlabel('Time (s)'); ylabel('Amplitude');
legend('Original Analog Input', 'Filtered (Continuous)', 'Decimated Output (FPGA Words)');
grid on;


% 1. Define your sampling frequency
fs = 10e6; % 10 MHz

% 2. Extract the data (Simulink sometimes saves it as a 2D or 3D array)
% This ensures we just get the raw 1D signal vector
data = squeeze(Vout_data); 

% 3. Create a clean white figure window
figure('Color', 'white');

% 4. Calculate and plot the Power Spectral Density
pwelch(data, hanning(8192), [], 8192, fs);

% 5. Force the X-axis to Logarithmic scale
set(gca, 'XScale', 'log');

% 6. Frame the window perfectly (100 Hz to 5 MHz)
xlim([100 5e6]);

% 7. Add professional formatting for your portfolio
title('2nd-Order \Sigma\Delta Modulator Output Spectrum');
xlabel('Frequency (Hz)');
ylabel('Power/Frequency (dB/Hz)');
grid on;
# clean_pdm.py
# Reads LTspice output, samples it at your 10 MHz clock rate, and outputs clean Verilog binary.

input_file = "sigma_delta_bitstream.txt"  # Your raw export from LTspice
output_file = "pdm_stimulus.bin"   # What we will feed to Vivado

# 10 MHz clock = 100ns period. We sample in the middle of the period.
sample_period = 100e-9 
next_sample_time = sample_period / 2.0 

with open(input_file, 'r') as fin, open(output_file, 'w') as fout:
    # Skip header line if LTspice generated one
    next(fin, None) 
    
    for line in fin:
        parts = line.strip().split()
        if len(parts) < 2: continue
        
        try:
            time_val = float(parts[0])
            voltage = float(parts[1])
        except ValueError:
            continue
            
        # Only grab the data point when the LTspice time crosses our 10MHz clock boundary
        if time_val >= next_sample_time:
            # Threshold the analog voltage: >0V becomes 1, <0V becomes 0
            bit = "1" if voltage > 0.0 else "0"
            fout.write(bit + "\n")
            next_sample_time += sample_period

print(f"Done. Saved clean binary sequence to {output_file}")
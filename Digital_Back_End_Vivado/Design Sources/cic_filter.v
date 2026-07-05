`timescale 1ns / 1ps

module cic_filter (
    input wire clk,
    input wire rst,       // FIXED: Changed 'reset' to 'rst' to match top_level.v
    input wire bitstream, // FIXED: Changed 'pdm_in' to 'bitstream'
    output reg signed [15:0] data_out,
    output reg data_valid
);

    // Bit growth formula: B_out = B_in + K * log2(R)
    // B_out = 1 + 3 * log2(32) = 1 + 15 = 16 bits.

    // Map 1-bit PDM (0/1) to (-1/+1) to center the sine wave properly
    wire signed [15:0] pdm_mapped = (bitstream) ? 16'd1 : -16'd1;

    // --------------------------------------------------------
    // Integrator Stages (Running at high-speed 10 MHz clk)
    // --------------------------------------------------------
    reg signed [15:0] int1, int2, int3;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            int1 <= 0;
            int2 <= 0;
            int3 <= 0;
        end else begin
            int1 <= int1 + pdm_mapped;
            int2 <= int2 + int1;
            int3 <= int3 + int2;
        end
    end

    // --------------------------------------------------------
    // Decimation / Downsampling Engine (OSR = 32)
    // --------------------------------------------------------
    reg [4:0] count;
    reg dec_clk;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            count <= 0;
            dec_clk <= 0;
        end else begin
            if (count == 5'd31) begin
                count <= 0;
                dec_clk <= 1'b1;  // Trigger the slow clock
            end else begin
                count <= count + 1;
                dec_clk <= 1'b0;
            end
        end
    end

    // --------------------------------------------------------
    // Comb Stages (Running at decimated rate 312.5 kHz)
    // --------------------------------------------------------
    reg signed [15:0] comb1, comb2, comb3;
    reg signed [15:0] delay1, delay2, delay3;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            comb1 <= 0; comb2 <= 0; comb3 <= 0;
            delay1 <= 0; delay2 <= 0; delay3 <= 0;
            data_out <= 0;
            data_valid <= 0;
        end else begin
            data_valid <= 0; // Default state

            if (dec_clk) begin
                // Comb 1
                comb1 <= int3 - delay1;
                delay1 <= int3;
                
                // Comb 2
                comb2 <= comb1 - delay2;
                delay2 <= comb1;
                
                // Comb 3
                comb3 <= comb2 - delay3;
                delay3 <= comb2;
                
                // Latch to Output
                data_out <= comb3;
                data_valid <= 1'b1; // Pulse valid for 1 clock cycle
            end
        end
    end

endmodule
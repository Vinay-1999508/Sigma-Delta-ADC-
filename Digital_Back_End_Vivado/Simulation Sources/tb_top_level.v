`timescale 1ns / 1ps

module tb_top_level();

    // --------------------------------------------------------
    // Signals
    // --------------------------------------------------------
    reg  clk;
    reg  rst;
    reg  pdm_in;
    wire tx_out;

    // --------------------------------------------------------
    // Memory Array for LTspice Data (adjust size if needed)
    // --------------------------------------------------------
    reg [0:0] pdm_memory [0:19999]; // Array to hold 20,000 bits
    integer i;

    // --------------------------------------------------------
    // Instantiate the Unit Under Test (UUT)
    // --------------------------------------------------------
    top_level uut (
        .clk(clk),
        .rst(rst),
        .bitstream(pdm_in),
        .tx_out(tx_out)
    );

    // --------------------------------------------------------
    // Clock Generation (10 MHz = 100ns period)
    // --------------------------------------------------------
    initial begin
        clk = 0;
        forever #50 clk = ~clk;
    end

    // --------------------------------------------------------
    // Stimulus and Data Injection
    // --------------------------------------------------------
    initial begin
        // 1. Load the clean binary data we generated with Python
        // MAKE SURE pdm_stimulus.bin is in the Vivado simulation directory
        $readmemb("pdm_stimulus.bin", pdm_memory);

        // 2. Initialize system
        rst = 1;
        pdm_in = 0;
        
        // Wait 200ns, then drop reset
        #200;
        rst = 0;
        #100;

        $display("Starting actual LTspice data injection...");

        // 3. Loop through the memory array and feed it to the filter
        for (i = 0; i < 20000; i = i + 1) begin
            // Change the input bit exactly on the falling edge 
            // to ensure stability when the UUT reads it on the rising edge
            @(negedge clk);
            
            // Catch uninitialized memory spaces (if your file has fewer than 20k lines)
            if (pdm_memory[i] === 1'bx) begin
                $display("End of valid data reached at index %d.", i);
                i = 20000; // Break the loop
            end else begin
                pdm_in = pdm_memory[i];
            end
        end

        $display("Data injection complete. Waiting for final UART transmissions...");
        
        // Wait long enough for the final 16-bit word to transmit over UART
        #200000; 
        
        $display("Simulation Finished.");
        $finish;
    end
    integer outfile;
    
    initial begin
        // Create an output file in the same xsim folder
        outfile = $fopen("recovered_pcm.txt", "w");
    end

    // Tap into the internal signals of your top_level module
    always @(posedge clk) begin
        // CRITICAL CHECK: Verify that 'data_valid' and 'saved_cic_data' 
        // are the actual names of the wires inside your top_level.v!
        // (I used 'saved_cic_data' based on your README description of the holding register).
        
        if (uut.cic_valid == 1'b1) begin
            $fdisplay(outfile, "%d", $signed(uut.cic_data)); 
        end
    end
endmodule
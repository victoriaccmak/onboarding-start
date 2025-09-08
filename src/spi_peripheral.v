module spi_peripheral (
    input wire copi,
    input wire ncs,
    input wire sclk,
    output reg [7:0] en_reg_out_7_0,
    output reg [7:0] en_reg_out_15_8,
    output reg [7:0] en_reg_pwm_7_0,
    output reg [7:0] en_reg_pwm_15_8,
    output reg [7:0] pwm_duty_cycle,
    input wire clk,
    input wire rst_n     // reset_n - low to reset
);

    // Registers for flip flops
    reg sclk_sync_ff1;
    reg sclk_sync_ff2;
    reg ncs_sync_ff1;
    reg ncs_sync_ff2;
    reg copi_sync_ff1;
    reg copi_sync_ff2;

    // Registers for the flip flop values
    reg ff_sclk;
    reg ff_ncs;
    reg ff_copi;

    // Cycle counter, read/write, address, and data
    reg [3:0] ff_sclk_counter;
    reg [15:0] bitstream;

    // Flip flops for clk
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Reset all flip flop values to 0
            sclk_sync_ff1 <= 1'b0;
            sclk_sync_ff2 <= 1'b0;
            ncs_sync_ff1 <= 1'b0;
            ncs_sync_ff2 <= 1'b0;
            copi_sync_ff1 <= 1'b0;
            copi_sync_ff2 <= 1'b0;
            ff_sclk <= 1'b0;
            ff_ncs <= 1'b0;
            ff_copi <= 1'b0;
        end else begin
            //Assign the 1st and 2nd flip flop values of sclk, ncs, and copi
            sclk_sync_ff1 <= sclk;
            sclk_sync_ff2 <= sclk_sync_ff1;
            ncs_sync_ff1 <= ncs;
            ncs_sync_ff2 <= ncs_sync_ff1;
            copi_sync_ff1 <= copi;
            copi_sync_ff2 <= copi_sync_ff1;
            
            // Assign the flip flop values of sclk, ncs, and copi
            ff_sclk <= sclk_sync_ff2;
            ff_ncs <= ncs_sync_ff2;
            ff_copi <= copi_sync_ff2;
        end
    end

    // On the negative edge of ncs, initialize the counter to 0
    always @(negedge ff_ncs) begin
        ff_sclk_counter <= 0;
    end

    // Flip flop sclk to read copi at positive edges
    always @(posedge ff_sclk) begin
        // Read the bitstream when ncs is low
        if (!ff_ncs) begin
            bitstream <= bitstream << 1;
            bitstream[0] <= ff_copi;
        end
    end

    // Shift the counter for the cycle at every negative edge (cycle begins at low)
    always @(negedge ff_sclk) begin
        if (!ff_ncs) begin
            ff_sclk_counter <= ff_sclk_counter + 1;
        end
    end

    reg [7:0] address;
    reg [7:0] data;

    // Update the registers once the bitstream is complete ie. when ncs has been pulled up
    always @(posedge ff_ncs) begin
        // Write to the address if the leading bit is 1 (representing a Write operation)
        if (bitstream[15]) begin
            address <= {1'b0, bitstream[14:8]};
            data <= bitstream[7:0];

            if (address == 8'h00) begin
                en_reg_out_7_0 <= data;
            end else if (address == 8'h01) begin
                en_reg_out_15_8 <= data;
            end else if (address == 8'h02) begin
                en_reg_pwm_7_0 <= data;
            end else if (address == 8'h03) begin
                en_reg_pwm_15_8 <= data;
            end else if (address == 8'h04) begin
                pwm_duty_cycle <= data;
            end
        end
    end
endmodule
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
    reg [4:0] ff_sclk_counter;
    reg [15:0] bitstream;

    reg [7:0] address;
    reg [7:0] data;
    reg transaction_ready;

    // Flip flops for clk
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Reset all flip flop values to 0
            sclk_sync_ff1 <= 1'b0;
            sclk_sync_ff2 <= 1'b0;
            ncs_sync_ff1 <= 1'b1;
            ncs_sync_ff2 <= 1'b1;
            copi_sync_ff1 <= 1'b0;
            copi_sync_ff2 <= 1'b0;
            ff_sclk <= 1'b0;
            ff_ncs <= 1'b1;
            ff_copi <= 1'b0;
            ff_sclk_counter <= 0;
            bitstream <= 16'h0000;
            transaction_ready <= 0;
            $display("RST_N: Time=%0t, ff_sclk_counter=%0d, bitstream=%h, ff_copi=%b, ff_ncs=%b, ff_sclk=%b", $time, ff_sclk_counter, bitstream, ff_copi, ff_ncs, ff_sclk);
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

            // Reset bitstream and the counter at nCS falling edge
            if (ff_ncs && !ncs_sync_ff2) begin
                ff_sclk_counter <= 0;
                bitstream <= 16'h0000;
                transaction_ready <= 0;
                $display("Pulling low: Time=%0t, ff_sclk_counter=%0d, bitstream=%h, ff_copi=%b, ff_ncs=%b, ff_sclk=%b", $time, ff_sclk_counter, bitstream, ff_copi, ff_ncs, ff_sclk);
            end

            if (!ff_ncs) begin
                // At every positive ff_sclk edge, get the bitstream and increase the counter
                if (!ff_sclk && sclk_sync_ff2) begin
                    // Read the bitstream when ncs is low
                        $display("Before Positive ff_sclk edge: Time=%0t, ff_sclk_counter=%0d, bitstream=%b, ff_copi=%b, ff_ncs=%b, ff_sclk=%b", $time, ff_sclk_counter, bitstream, ff_copi, ff_ncs, ff_sclk);
                        bitstream <= bitstream << 1;
                        bitstream[0] <= ff_copi;
                        ff_sclk_counter <= ff_sclk_counter + 1;
                        $display("After Positive ff_sclk edge: Time=%0t, ff_sclk_counter=%0d, bitstream=%b, ff_copi=%b, ff_ncs=%b, ff_sclk=%b", $time, ff_sclk_counter, bitstream, ff_copi, ff_ncs, ff_sclk);
                end
            end

            $display("ff_ncs=%b, ncs_sync_ff2=%b, ff_sclk_counter=%0d", ff_ncs, ncs_sync_ff2, ff_sclk_counter);

            // transaction done when nCS is pulled high
            if (!ff_ncs && ncs_sync_ff2 && ff_sclk_counter >= 5'b10000) begin
                $display("TRANSACTION READY");
                address <= {1'b0, bitstream[14:8]};
                data <= bitstream[7:0];
                transaction_ready <= 1'b1;
            end

            // Update registers when transaction is ready
            if (transaction_ready) begin
                $display("bitstream: %b", bitstream);
                $display("address: %b", address);
                $display("data: %b", data);
                if (address == 8'h00) begin
                    $display("1");
                    en_reg_out_7_0 <= data;
                end else if (address == 8'h01) begin
                    $display("2");
                    en_reg_out_15_8 <= data;
                end else if (address == 8'h02) begin
                    $display("3");
                    en_reg_pwm_7_0 <= data;
                end else if (address == 8'h03) begin
                    $display("4");
                    en_reg_pwm_15_8 <= data;
                end else if (address == 8'h04) begin
                    $display("5");
                    pwm_duty_cycle <= data;
                end

                transaction_ready <= 0;
            end
        end
    end

endmodule
`default_nettype none

module spi_peripheral (
    input wire clk,
    input wire rst_n,
    input wire nCS,
    input wire SCLK,
    input wire COPI,
    output reg [7:0] en_reg_out_7_0,
    output reg [7:0] en_reg_out_15_8,
    output reg [7:0] en_reg_pwm_7_0,
    output reg [7:0] en_reg_pwm_15_8,
    output reg [7:0] pwm_duty_cycle
);
    reg [2:0] nCS_sync, SCLK_sync, COPI_sync;
    //[15] -> r/w, [14:8] -> address, [7:0] -> data
    reg [15:0] transaction_data;
    reg [3:0] num_bits;
    // transaction handshake
    reg transaction_complete, transaction_processed;

    localparam [6:0] max_address = 7'h04;

    always @(posedge clk or negedge rst_n) begin
        if(rst_n) begin
            nCS <= 1'b1;
            SCLK <= 1'b0;
            COPI <= 1'b0;
            // en_reg_out_7_0 <= 8'b0;
            // en_reg_out_15_8 <= 8'b0;
            // en_reg_pwm_7_0 <= 8'b0;
            // en_reg_pwm_15_8 <= 8'b0;
            // pwm_duty_cycle <= 8'b0;
            nCS_sync <= 3'b1;
            SCLK_sync <= 3'b0;
            COPI_sync <= 3'b0;
            transaction_data <= 16'b0;
            num_bits <= 3'b0;
            transaction_complete <= 1'b0;
            transaction_processed <= 1'b0;
        end else begin
            //sync nCS take index 2 as final sync
            nCS_sync[0] <= nCS;
            nCS_sync[1] <= nCS_sync[0];
            nCS_sync[2] <= nCS_sync[1];

            //likewise for SCLK
            SCLK_sync[0] <= SCLK;
            SCLK_sync[1] <= SCLK_sync[0];
            SCLK_sync[2] <= SCLK_sync[1];

            //same
            COPI_sync[0] <= COPI;
            COPI_sync[1] <= COPI_sync[0];
            COPI_sync[2] <= COPI_sync[1];

            

            //start bit count logic
            if (!nCS_sync[2] && SCLK[2]) begin
                transaction_data <= {transaction_data[14:0], COPI_sync};
                if (num_bits < 16) begin
                    num_bits = num_bits + 1;
                end
            end

            if(nCS_sync[2]) begin
                transaction_complete <= 1;
                num_bits = 0;
                transaction_data = 16'b0;
            end else if (transaction_processed) begin
                transaction_complete <= 0;
            end


        end
    end


    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            en_reg_out_7_0 <= 8'b0;
            en_reg_out_15_8 <= 8'b0;
            en_reg_pwm_7_0 <= 8'b0;
            en_reg_pwm_15_8 <= 8'b0;
            pwm_duty_cycle <= 8'b0;
        end else if (transaction_complete && !transaction_processed) begin
            if (transaction_data[14:8] == 7'h00) en_reg_out_7_0 <= transaction_data[7:0];
            if (transaction_data[14:8] == 7'h01) en_reg_out_15_8 <= transaction_data[7:0];
            if (transaction_data[14:8] == 7'h02) en_reg_pwm_7_0 <= transaction_data[7:0];
            if (transaction_data[14:8] == 7'h03) en_reg_pwm_15_8 <= transaction_data[7:0];
            if (transaction_data[14:8] == 7'h04) pwm_duty_cycle <= transaction_data[7:0];
            transaction_processed <= 1;
        end else if (!transaction_complete && transaction_processed) begin
            transaction_processed <= 0;
        end

        
    end


endmodule
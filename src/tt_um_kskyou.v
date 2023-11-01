`default_nettype none

module tt_um_kskyou (
    input  wire [7:0] ui_in,    // Dedicated inputs - connected to the input switches
    output wire [7:0] uo_out,   // Dedicated outputs - connected to the 7 segment display
    input  wire [7:0] uio_in,   // IOs: Bidirectional Input path
    output wire [7:0] uio_out,  // IOs: Bidirectional Output path
    output wire [7:0] uio_oe,   // IOs: Bidirectional Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // will go high when the design is enabled
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);

    assign uio_oe = 8'b00000000;
    assign uio_out = 8'b00000000;
    assign uo_out = {1'b0, out};
    
    reg [13:0] D;
    reg [8:0] R;
    wire [15:0] R2 = R * R;
    reg [3:0] state;
    
    reg button1;
    reg button0;
    
    reg [15:0] P;
    reg [15:0] Q;
    
    reg [3:0] watch;
    wire [6:0] out;
    seven_segment dev(P, Q, watch, out);

    always @(posedge clk) begin
        if (!rst_n) begin
            state <= 0;
            D <= 0;
            R <= 0;
            P <= 0;
            Q <= 0;
            watch <= 0;
        end
        else begin
            case (state)
                0: begin
                    if (ui_in [0] == 1 && button0 == 0) begin
                        state <= 1;
                        R <= 0;
                        D <= {uio_in, ui_in[7:2]};
                    end else if (ui_in [1] == 1 && button1 == 0) begin
                        watch <= (watch == 9) ? 0 : watch + 1;
                    end
                end 
                1: begin
                    if (R2 > D) begin
                        state <= 0;
                        watch <= 0;
                        P <= R - 1;
                        Q <= 1;
                        R <= R - 1;
                    end else begin
                        R <= R + 1;
                    end
                end
            endcase
            button0 <= ui_in[0];
            button1 <= ui_in[1];
        end
    end

endmodule

module seven_segment (
    input wire [15:0] P,
    input wire [15:0] Q,
    input wire [3:0] watch,
    output reg [6:0] out
);
    reg [3:0] num;
    
always @(watch, P, Q) begin
    case (watch)
        1: num <= P[15:12];
        2: num <= P[11:8];
        3: num <= P[7:4];
        4: num <= P[3:0];
        6: num <= Q[15:12];
        7: num <= Q[11:8];
        8: num <= Q[7:4];
        9: num <= Q[3:0];
    endcase
end
    
always @(num, watch) begin
    if (watch == 0) begin
        out <= 7'b1110011;
    end else if (watch == 5) begin
        out <= 7'b1100111;
    end else begin
        case (num)
            4'b0000 : out <= 7'b0111111;
            4'b0001 : out <= 7'b0000110;
            4'b0010 : out <= 7'b1011011;
            4'b0011 : out <= 7'b1001111;
            4'b0100 : out <= 7'b1100110;
            4'b0101 : out <= 7'b1101101;  
            4'b0110 : out <= 7'b1111101;
            4'b0111 : out <= 7'b0000111;
            4'b1000 : out <= 7'b1111111;
            4'b1001 : out <= 7'b1101111;
            4'b1010 : out <= 7'b1110111;
            4'b1011 : out <= 7'b1111100;
            4'b1100 : out <= 7'b0111001;
            4'b1101 : out <= 7'b1011110;
            4'b1110 : out <= 7'b1111011;
            4'b1111 : out <= 7'b1110001;
         endcase
     end
end

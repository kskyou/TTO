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
    assign uo_out = out;
    
    reg button1;
    reg button0;
    
    reg [13:0] D; // input D
    reg [15:0] P; // convergent numerator P
    reg [15:0] Q; // convergent denominator D
    
    reg [15:0] Ps; // previous P
    reg [15:0] Qs; // previous Q
    
    reg [3:0] state; // state
    reg [1:0] watch; // output digit, cycle through in state 1
    wire [7:0] out; // seven segment output
    seven_segment dev1(P, Q, watch, out);
    
    reg [7:0] R; // floor(sqrt(D)), compute in state 2, 3
    
    reg [7:0] temp1; // stores loop index for multiplication/ accumulator for division
    reg [15:0] temp2; // stores accummulator for multiplication
    
    reg adder_sel;
    reg [15:0] adder_A;
    reg [15:0] adder_B;
    wire [15:0] adder_C;
    adder dev2(adder_sel, adder_A, adder_B, adder_C);
    
    reg counter_sel;
    reg [7:0] counter_A;
    wire [7:0] counter_C;
    counter dev3(counter_sel, counter_A, counter_C);
    
    // for whatever reason it takes less space leaving the two comparisons seperate instead of combining into one comparator
    wire comp;
    assign comp = ((temp2 [13:0]) > D);
    wire compzero;
    assign compzero = (temp1 != 0);
    wire comp2zero;
    assign comp2zero = ((temp2 [13:0]) >= {6'd0,Z});
    
    reg [7:0] X;
    reg [7:0] Y;
    reg [7:0] Z;
    
    always @(*) begin
        adder_sel = 1'b0;
        adder_A = temp2;
        adder_B = 16'd0;
        counter_sel = 1'b1;
        counter_A = temp1;
        
        case (state)
            2: begin
                counter_A = R;
                if (comp) begin
                    // decrement R
                    // counter_sel = 1'b1; 
                    // counter_A = R;
                    // R <= counter_C;
                end else begin
                    // increment R
                    counter_sel = 1'b0; 
                    // counter_A = R;
                    // R <= counter_C;
                end
            end 
            3: begin
                // decrement temp1
                // counter_sel = 1'b1; 
                // counter_A = temp1;
                // temp1 <= counter_C

                // add R to temp2
                // adder_sel = 1'b0;
                // adder_A = temp2;
                adder_B = {8'd0, R};
                // temp2 <= adder_C
            end
            4: begin
                if (compzero) begin
                    // decrement temp1
                    // counter_sel = 1'b1; 
                    // counter_A = temp1;
                    // temp1 <= counter_C
                
                    // add Z to temp2
                    // adder_sel = 1'b0;
                    // adder_A = temp2;
                    adder_B = {8'd0, Z};
                    // temp2 <= adder_C
                end else begin
                    // update Y to be temp2 - Y
                    adder_sel = 1'b1;
                    // adder_A = temp2;
                    adder_B = {8'd0, Y};
                    // Y <= adder_C
                end
            end
            5: begin
                if (compzero) begin
                    // decrement temp1
                    // counter_sel = 1'b1; 
                    // counter_A = temp1;
                    // temp1 <= counter_C
                
                    // add Y to temp2
                    // adder_sel = 1'b0;
                    // adder_A = temp2;
                    adder_B = {8'd0, Y};
                    // temp2 <= adder_C
                end else begin
                    // update temp2 to be D - temp2
                    adder_sel = 1'b1;
                    adder_A = {2'd0, D};
                    adder_B = temp2;
                    // temp2 <= adder_C
                end
            end
            6: begin
                if (comp2zero) begin
                    // increment temp1
                    counter_sel = 1'b0; 
                    counter_A = temp1;
                    // temp1 <= counter_C
                
                    // subtract Z from temp2
                    adder_sel = 1'b1;
                    //adder_A = temp2;
                    adder_B = {8'd0, Z};
                    // temp2 <= adder_C
                end else begin
                    // update temp2 to be Y+R
                    // adder_sel = 1'b0;
                    adder_A = {8'd0, Y};
                    adder_B = {8'd0, R};
                    // temp2 <= adder_C
                end
            end
            7: begin
                if (comp2zero) begin
                    // increment temp1
                    counter_sel = 1'b0; 
                    // counter_A = temp1;
                    // temp1 <= counter_C
                
                    // subtract Z from temp2
                    adder_sel = 1'b1;
                    // adder_A = temp2;
                    adder_B = {8'd0, Z};
                    // temp2 <= adder_C
                end 
            end
            8: begin
                if (compzero) begin
                    // decrement temp1
                    // counter_sel = 1'b1; 
                    // counter_A = temp1;
                    // temp1 <= counter_C
                
                    // add P to temp2
                    // adder_sel = 1'b0;
                    //adder_A = temp2;
                    adder_B = P;
                    // temp2 <= adder_C
                end else begin
                    // update P to be temp2 + Ps
                    // adder_sel = 1'b0;
                    // adder_A = temp2;
                    adder_B = Ps;
                    // P <= adder_C
                end
            end
            9: begin
                if (compzero) begin
                    // decrement temp1
                    // counter_sel = 1'b1; 
                    // counter_A = temp1;
                    // temp1 <= counter_C
                
                    // add P to temp2
                    // adder_sel = 1'b0;
                    // adder_A = temp2;
                    adder_B = Q;
                    // temp2 <= adder_C
                end else begin
                    // update P to be temp2 + Ps
                    // adder_sel = 1'b0;
                    // adder_A = temp2;
                    adder_B = Qs;
                    // Q <= adder_C
                end
            end
        endcase
    end

    always @(posedge clk) begin
        if (!rst_n) begin
            Ps <= 1;
            Qs <= 0;
            Y <= 0;
            Z <= 1;
            state <= 0;
            watch <= 0;
        end
        else begin
            case (state)
                0: begin // wait until begin calculation
                    if (ui_in [0] == 1 && button0 == 0) begin // begin square root calculation
                        state <= 2;
                        R <= 0;
                        D <= {uio_in, ui_in[7:2]};
                        temp2 <= 0;
                    end 
                end 
                1: begin // wait until next calculation
                    if (ui_in [0] == 1 && button0 == 0) begin // compute next convergent
                        state <= 4;
                        temp1 <= X;
                        temp2 <= 0;
                    end else if (ui_in [1] == 1 && button1 == 0) begin // cycle through digit output
                        watch <= (watch + 1);
                    end
                end
                2: begin // increment R and square until it exceeds D
                    if (comp) begin
                        state <= 1;
                        R <= counter_C;
                        P <= {8'd0,counter_C};
                        Q <= 1;
                        X <= counter_C;
                    end else begin
                        temp2 <= 0;
                        temp1 <= counter_C;
                        R <= counter_C;
                        state <= 3;
                    end;
                end
                3: begin // increment R and square until it exceeds D
                    if (compzero) begin
                        temp1 <= counter_C;
                        temp2 <= adder_C;
                    end else begin
                        state <= 2;
                    end
                end
                4: begin // update y = x*z - y
                    if (compzero) begin
                        temp1 <= counter_C;
                        temp2 <= adder_C;
                    end else begin
                        state <= 5;
                        temp2 <= 0;
                        temp1 <= (adder_C [7:0]);
                        Y <= (adder_C [7:0]);
                    end
                end
                5: begin // compute y*y
                    if (compzero) begin
                        temp1 <= counter_C;
                        temp2 <= adder_C;
                    end else begin
                        state <= 6;
                        temp2 <= adder_C;
                        temp1 <= 0;
                    end
                end
                6: begin // compute (D-y*y) / z
                    if (comp2zero) begin
                        temp1 <= counter_C;
                        temp2 <= adder_C;
                    end else begin
                        state <= 7;
                        temp2 <= adder_C;
                        temp1 <= 0;
                        Z <= temp1;
                    end
                end
                7: begin // compute (R+y) / z
                    if (comp2zero) begin
                        temp1 <= counter_C;
                        temp2 <= adder_C;
                    end else begin
                        state <= 8;
                        X <= temp1;
                        temp2 <= 0;
                        temp1 <= temp1;
                    end
                end
                8: begin // compute P, Ps = P*X + Ps, P
                    if (compzero) begin
                        temp1 <= counter_C;
                        temp2 <= adder_C;
                    end else begin
                        state <= 9;
                        temp1 <= X;
                        temp2 <= 0;
                        P <= adder_C;
                        Ps <= P;
                    end
                end
                9: begin // compute Q, Qs = Q*X + Qs, Q
                    if (compzero) begin
                        temp1 <= counter_C;
                        temp2 <= adder_C;
                    end else begin
                        state <= 1;
                        Q <= adder_C;
                        Qs <= Q;
                        watch <= 0;
                    end
                end
            endcase
            button0 <= ui_in[0];
            button1 <= ui_in[1];
        end
    end
endmodule


module counter (
    input wire counter_sel,
    input wire [7:0] counter_A,
    output wire [7:0] counter_C
);
    assign counter_C = (counter_sel) ? (counter_A - 1) : (counter_A + 1);
endmodule

module adder (
    input wire adder_sel,
    input wire [15:0] adder_A,
    input wire [15:0] adder_B,
    output wire [15:0] adder_C
);
    assign adder_C = (adder_sel) ? (adder_A - adder_B) : (adder_A + adder_B);
endmodule

module seven_segment (
    input wire [15:0] P,
    input wire [15:0] Q,
    input wire [1:0] watch,
    output reg [7:0] out
);
    always @(*) begin
        case (watch)
            0: out = P[15:8];
            1: out = P[7:0];
            2: out = Q[15:8];
            3: out = Q[7:0];
        endcase
    end
endmodule

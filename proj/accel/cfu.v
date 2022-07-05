//                              -*- Mode: Verilog -*-
// Filename        : cfu.v
// Description     : Top module of the CFU
// Purpose         : Contains two sub-modules, the MAC, which is the PE, and the main CFU module

// PE module
module mac (
    input clk, reset, start, 
    input [2:0] sel,
    input [31:0] w,    
    input [31:0] im,  
    output signed [31:0] p   
);
    
    reg signed [31:0] d;    // Holds the output of MAC 
    
    // Next stage pipelined values of the input  offsetted activations 
    reg [7:0] im0;
    reg [7:0] im1; 
    reg [7:0] im2; 
    reg [7:0] im3; 
    reg [7:0] w0; 
    reg [7:0] w1; 
    reg [7:0] w2; 
    reg [7:0] w3;
    
    // Buffer memory of the accelerator needed to swap the accumulator based on the output channel
    reg [31:0] acc1;
    reg [31:0] acc2; 
    reg [31:0] acc3; 
    reg [31:0] acc4; 
    reg [31:0] acc5;
    reg [31:0] acc6; 
    reg [31:0] acc7; 
    reg [31:0] acc8;
    
    // Holds the pipelined product of SIMD computation in case of elements along input depth 
    reg [31:0] prod;
    
     
    always @(posedge clk) 
    begin
    	case({reset, start})
            2'b10, 2'b11:    begin            // All set to zero on reset  
                im0 <= 0;
                im1 <= 0; 
                im2 <= 0; 
                im3 <= 0;
                
                w0 <= 0; 
                w1 <= 0; 
                w2 <= 0; 
                w3 <= 0;
                
                acc1 <= 0; 
                acc2 <= 0; 
                acc3 <= 0; 
                acc4 <= 0; 
                acc5 <= 0; 
                acc6 <= 0; 
                acc7 <= 0; 
                acc8 <= 0; 
            end         
            2'b01:    begin                   // Updating each of the registers in a pipelined fashion 
                im0 <= im[7:0]  + 9'd128; 
                im1 <= im[15:8] + 9'd128;
                im2 <= im[23:16] + 9'd128; 
                im3 <= im[31:24] + 9'd128; 
                	    	
                w0 <= w[7:0]; 
                w1 <= w[15:8]; 
                w2 <= w[23:16]; 
                w3 <= w[31:24];	
                prod <= $signed({1'b0, im0}) * $signed(w0) + $signed({1'b0, im1}) * $signed(w1) + $signed({1'b0, im2}) * $signed(w2) + $signed({1'b0,im3}) * $signed(w3);
                
                case(sel)
                    3'b000: acc1 <= $signed(acc1) + prod; 
                    3'b001: acc2 <= $signed(acc2) + prod; 
                    3'b010: acc3 <= $signed(acc3) + prod; 
                    3'b011: acc4 <= $signed(acc4) + prod;  
                    3'b100: acc5 <= $signed(acc5) + prod; 
                    3'b101: acc6 <= $signed(acc6) + prod; 
                    3'b110: acc7 <= $signed(acc7) + prod; 
                    3'b111: acc8 <= $signed(acc8) + prod;  
                endcase
            end 
            default:    begin                 // Holding the same state is needed while CFU performs other operations 
                im0 <= im0; 
                im1 <= im1;
                im2 <= im2;
                im3 <= im3; 
                 
                w0 <= w0; 
                w1 <= w1; 
                w2 <= w2; 
                w3 <= w3;
                
                acc1 <= $signed(acc1);
                acc2 <= $signed(acc2);
                acc3 <= $signed(acc3); 
                acc4 <= $signed(acc4);  
                acc5 <= $signed(acc5);
                acc6 <= $signed(acc6);
                acc7 <= $signed(acc7); 
                acc8 <= $signed(acc8); 	    
            end 
        endcase
    end 
    
    always @(*) begin                         // Assigning the output based on the input provided by macro
        case(sel)
            3'b000: d = $signed(acc1);
            3'b001: d = $signed(acc2);
            3'b010: d = $signed(acc3); 
            3'b011: d = $signed(acc4);
            3'b100: d = $signed(acc5);
            3'b101: d = $signed(acc6);
            3'b110: d = $signed(acc7); 
            3'b111: d = $signed(acc8);    
        endcase
    end	
    	
    assign p = d;    // Taking the accumulated value as output 
        
endmodule

// CFU module
module Cfu (
    input               cmd_valid,
    output              cmd_ready,
    input      [9:0]    cmd_payload_function_id,
    input      [31:0]   cmd_payload_inputs_0,
    input      [31:0]   cmd_payload_inputs_1,
    output              rsp_valid,
    input               rsp_ready,
    output     [31:0]   rsp_payload_outputs_0,
    input               clk,
    input               reset
);
    
    reg [31:0] output_0;                   // Corresponds to the output of CFU
    reg [31:0] tile_mem_w;                 // Input broadcasted to the PEs 
    reg [31:0] tile_mem [0:63];            // Input tile scratch-pad memory 
    
    // Provides tile_mem addr. to each PE foraccumulation of output 
    reg [7:0] a00, a01, a02, a03, a04, a05, a06, a07, a08, a09, a10, a11, a12, a13, a14, a15; 
    
    reg [7:0] mem_ctr;             // Keeps track of addr. while storing values to tile_mem 
    reg [7:0] id;                  // Used in providing address to each of the PEs     
    reg [3:0] ctr;                 // Keeps track of number of accumulations performed using a given weight tile 
    reg rsp_valid_reg;             // Corresponds to valid signal to be given as output 
    reg mode;                      // Control signal to the PEs, to accumulate the values
     
    wire [31:0] cfu0, cfu1;        // Inputs to the tile_mem provide as inputs to the CFU
    wire [31:0] out [0:15];        // Corresponds to the output of each PE for a given selection of accumulators 
    wire [2:0] func;               // Used to control the operation, 5 for write, 1 to accumulate, 2 to read, 3, 4 to reset counters 
    wire [2:0] sel;                // Selection of the accumulator from the buffer 
    wire ctr_reset;                // Resets the compute counter which changes the activations fed to PEs, reset if new weight tile is accumulated
    wire cfu_reset;                // Acts as a reset signal to the PEs
    wire wr_en;                    // Enable signal to write to input scratch-pad 
    
    // Assignment of several input signals based on the inputs to the CFU  
    assign cmd_ready = ~rsp_valid;
    assign rsp_valid = rsp_valid_reg; 
    assign rsp_payload_outputs_0 = output_0[31:0];  
    assign func = cmd_payload_function_id[5:3]; 
    assign wr_en = cmd_valid && (func == 3'b101); 
    assign cfu0 = cmd_payload_inputs_0[31:0]; 
    assign cfu1 = cmd_payload_inputs_1[31:0];
    assign ctr_reset = ((func == 3'b101) || (func == 3'b010) || (func == 3'b100)) && cmd_valid; 
    assign cfu_reset = ((func == 3'b011) || reset) && cmd_valid; 
    
    // Implementation of Scratchpad memory 
    integer i; 
    initial begin
        for(i = 0; i < 64; i = i + 1)
            tile_mem[i] = 32'h80808080; 
    end

    integer j; 
    always @(posedge clk) begin 
        if(reset) begin 
            for(j = 0; j < 64; j = j + 1)
               tile_mem[j] <= 0; 
            mem_ctr <= 0; 
        end 
        else if(wr_en) begin           
            tile_mem[mem_ctr]         <= cfu0[31:0];
            tile_mem[mem_ctr + 1]     <= cfu1[31:0];
            mem_ctr <= mem_ctr + 2;                   // Addr. automatically incremented, user need not provide the address
       end    	
       else if((func == 3'b100) && cmd_valid)
           mem_ctr <= 0; 
    end
    
    // The ctr maintains the number of accumulations in order to change the inputs fed to PEs accordingly and 
    // halt accumulation once the weight tile is completed. 
    always @(posedge clk) begin
        if(ctr_reset || reset || cfu_reset)
            ctr <= 0;  
        else if (ctr < 12 && cmd_valid)
            ctr <= ctr + 1; 
        else 
            ctr <= ctr; 
    end
    
    // The activation inputs to PEs are decided based on the ctr
    // It also provides a signal to the PE for acccumulation, or else PE remain in previous state
    always @(*) begin 
        if ((func == 3'b001) && cmd_valid) begin 
            if(ctr < 3) begin 
                id = ctr; 
                mode = 1;  
            end 
            else if(ctr < 6) begin 
                id = ctr + 3; 
                mode = 1;
            end 
            else if(ctr < 9) begin 
                id = ctr + 6;
                mode = 1; 
            end 
            else if(ctr < 12) begin 
                id = 36; 
                mode = 1; 
            end 
            else begin 
                id = 0; 
                mode = 0;
            end 
        end 
        else begin
            id = 0; 
            mode = 0; 
        end 
    end 


    // Handshaking of the CFU with the CPU core
    always @(posedge clk) begin
        if (reset) begin
            output_0 <= 32'b0;
            rsp_valid_reg <= 1'b0;
        end 
        else if (rsp_valid_reg) begin
            rsp_valid_reg <= ~rsp_ready;
        end 
        else if (cmd_valid) begin
            case(func) 
                3'b101:    begin 
                    rsp_valid_reg <= 1'b1;
                    output_0 <= 0;
                end
                3'b010:    begin 
                    rsp_valid_reg <= 1'b1; 
                    output_0 <= out[cfu0]; 
                end
                3'b001:    begin   
                    rsp_valid_reg <= 1'b1; 
                    output_0 <= 0;
                end 
                3'b011:    begin 
                    rsp_valid_reg <= 1'b1; 
                    output_0 <= 0; 
                end 
                3'b100:    begin  
                    rsp_valid_reg <= 1'b1; 
                    output_0 <= 0; 
                end 
                default:    begin 
                    rsp_valid_reg <= 1'b1; 
                    output_0 <= 0; 
                end 
            endcase   
        end
    end

    // Calculate the activation address of each PE from the tile_mem
    always @ (posedge clk) begin 
        if(cmd_valid) begin 
            a00 <= id;
            a01 <= id + 1; 
            a02 <= id + 2;           
            a03 <= id + 3; 
            a04 <= id + 6;
            a05 <= id + 7; 
            a06 <= id + 8;
            a07 <= id + 9; 
            a08 <= id + 12;
            a09 <= id + 13; 
            a10 <= id + 14;
            a11 <= id + 15; 
            a12 <= id + 18;
            a13 <= id + 19; 
            a14 <= id + 20;
            a15 <= id + 21; 
            tile_mem_w <= (func == 3'b001) ? cfu0[31:0] : 32'd0;   
        end	  		
    end 
      
    assign sel = (func == 3'b001 || func == 3'b010) ? cfu1[2:0] : 3'd0;        // Selection based on channel being accumulated
    
    
    // Instantiating the PEs   
    mac  m00(.clk(clk), .reset(cfu_reset), .start(mode), .sel(sel), .w(tile_mem_w), .im(tile_mem[a00]),  .p(out[0])); 
    mac  m01(.clk(clk), .reset(cfu_reset), .start(mode), .sel(sel), .w(tile_mem_w), .im(tile_mem[a01]),  .p(out[1])); 
    mac  m02(.clk(clk), .reset(cfu_reset), .start(mode), .sel(sel), .w(tile_mem_w), .im(tile_mem[a02]),  .p(out[2])); 
    mac  m03(.clk(clk), .reset(cfu_reset), .start(mode), .sel(sel), .w(tile_mem_w), .im(tile_mem[a03]),  .p(out[3])); 
    mac  m04(.clk(clk), .reset(cfu_reset), .start(mode), .sel(sel), .w(tile_mem_w), .im(tile_mem[a04]),  .p(out[4])); 
    mac  m05(.clk(clk), .reset(cfu_reset), .start(mode), .sel(sel), .w(tile_mem_w), .im(tile_mem[a05]),  .p(out[5])); 
    mac  m06(.clk(clk), .reset(cfu_reset), .start(mode), .sel(sel), .w(tile_mem_w), .im(tile_mem[a06]),  .p(out[6])); 
    mac  m07(.clk(clk), .reset(cfu_reset), .start(mode), .sel(sel), .w(tile_mem_w), .im(tile_mem[a07]),  .p(out[7])); 
    mac  m08(.clk(clk), .reset(cfu_reset), .start(mode), .sel(sel), .w(tile_mem_w), .im(tile_mem[a08]),  .p(out[8])); 
    mac  m09(.clk(clk), .reset(cfu_reset), .start(mode), .sel(sel), .w(tile_mem_w), .im(tile_mem[a09]),  .p(out[9])); 
    mac  m10(.clk(clk), .reset(cfu_reset), .start(mode), .sel(sel), .w(tile_mem_w), .im(tile_mem[a10]),  .p(out[10])); 
    mac  m11(.clk(clk), .reset(cfu_reset), .start(mode), .sel(sel), .w(tile_mem_w), .im(tile_mem[a11]),  .p(out[11])); 
    mac  m12(.clk(clk), .reset(cfu_reset), .start(mode), .sel(sel), .w(tile_mem_w), .im(tile_mem[a12]),  .p(out[12])); 
    mac  m13(.clk(clk), .reset(cfu_reset), .start(mode), .sel(sel), .w(tile_mem_w), .im(tile_mem[a13]),  .p(out[13])); 
    mac  m14(.clk(clk), .reset(cfu_reset), .start(mode), .sel(sel), .w(tile_mem_w), .im(tile_mem[a14]),  .p(out[14]));     
    mac  m15(.clk(clk), .reset(cfu_reset), .start(mode), .sel(sel), .w(tile_mem_w), .im(tile_mem[a15]),  .p(out[15]));

endmodule

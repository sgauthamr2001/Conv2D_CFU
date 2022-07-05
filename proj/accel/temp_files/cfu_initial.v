module mac (
    input clk, reset, start,
    input [7:0] w,    
    input [7:0] im,  
    output signed [31:0] p   
);
    
    reg signed [31:0] d; 
    wire [7:0] im_scale; 
    assign im_scale = (im + 9'd128); 
    always @(posedge clk) 
    begin
        if (reset)           d <= 0;
        else if (start)      d <= $signed(p) + $signed({1'b0, im_scale}) * $signed(w);
        else                 d <= $signed(p);
    end
    
    assign p = d;    // Taking the accumulated value  
        
endmodule

module Cfu (
    input               cmd_valid,
    output              cmd_ready,
    input      [9:0]    cmd_payload_function_id,
    input      [31:0]   cmd_payload_inputs_0,
    input      [31:0]   cmd_payload_inputs_1,
    output reg          rsp_valid,
    input               rsp_ready,
    output reg [31:0]   rsp_payload_outputs_0,
    input               clk,
    input               reset
);


    assign cmd_ready = ~rsp_valid;

    wire [31:0] cfu0, cfu1;
    wire [2:0] func; 
    
    assign func = cmd_payload_function_id[5:3]; 
	
    wire wr_en; 
    assign wr_en = cmd_valid && (func == 0); 
    assign cfu0 = cmd_payload_inputs_0[31:0]; 
    assign cfu1 = cmd_payload_inputs_1[31:0];

    wire [7:0] w; 
    wire [7:0] a00, a01, a02, a03, a04, a05, a06, a07, 
    a08, a09, a10, a11, a12, a13, a14, a15; 

    reg [3:0] ctr;
    reg [7:0] id; 
    reg mode; 	

    reg [7:0] tile_mem [0:63];
    wire [31:0] out [0:15]; 
    wire [7:0] mem_addr;
    assign mem_addr = cfu1[7:0] * 6;


    integer i; 
    initial begin
        for(i = 0; i < 64; i = i + 1)
            tile_mem[i] = 0; 
    end

    integer j; 
    always @(posedge clk) begin 
        if(reset) begin 
            for(j = 0; j < 64; j = j + 1)
                tile_mem[j] <= 0; 
        end 
        else if(wr_en) begin 
            
            tile_mem[mem_addr + 2]     <= cfu0[7:0];
            tile_mem[mem_addr + 1]     <= cfu0[15:8];
            tile_mem[mem_addr]         <= cfu0[23:16]; 
            tile_mem[mem_addr + 5]     <= cfu1[15:8]; 
            tile_mem[mem_addr + 4]     <= cfu1[23:16];
            tile_mem[mem_addr + 3]     <= cfu1[31:24];
        end 
    end

    wire ctr_reset; 
    wire cfu_reset; 
    
    assign ctr_reset = (func == 3'b000) || (func == 3'b010); 
    assign cfu_reset = (func == 3'b011) || reset; 

    always @(posedge clk) begin
        if(ctr_reset || reset || cfu_reset)
            ctr <= 0;  
        else if (ctr < 9)
            ctr <= ctr + 1; 
        else 
            ctr <= ctr; 
    end

    always @(*) begin 
        if (func == 3'b001) begin 
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


    always @(posedge clk) begin
        if (reset) begin
            rsp_payload_outputs_0 <= 32'b0;
            rsp_valid <= 1'b0;
        end 
        else if (rsp_valid) begin
            rsp_valid <= ~rsp_ready;
        end 
        else if (cmd_valid) begin
            if (func == 3'b000) begin  
                rsp_valid <= 1'b1;
                rsp_payload_outputs_0 <= 0;
            end 
            else if (func == 3'b010) begin 
                rsp_valid <= 1'b1; 
                rsp_payload_outputs_0 <= out[cfu0]; 
            end  
            else if (func == 3'b001) begin
            	if(ctr == 9) begin 
                    rsp_valid <= 1'b1; 
                    rsp_payload_outputs_0 <= 0;
               end 
            end 
            else if (func == 3'b011) begin 
                rsp_valid <= 1'b1; 
                rsp_payload_outputs_0 <= 0; 
            end  
        end
    end

	always @ (posedge clk) begin 

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
	    	w <= ctr + 36; 
	    	
    	end 

    mac  m00(.clk(clk), .reset(cfu_reset), .start(mode), .w(tile_mem[w]), .im(tile_mem[a00]),  .p(out[0])); 
    mac  m01(.clk(clk), .reset(cfu_reset), .start(mode), .w(tile_mem[w]), .im(tile_mem[a01]),  .p(out[1])); 
    mac  m02(.clk(clk), .reset(cfu_reset), .start(mode), .w(tile_mem[w]), .im(tile_mem[a02]),  .p(out[2])); 
    mac  m03(.clk(clk), .reset(cfu_reset), .start(mode), .w(tile_mem[w]), .im(tile_mem[a03]),  .p(out[3])); 
    mac  m04(.clk(clk), .reset(cfu_reset), .start(mode), .w(tile_mem[w]), .im(tile_mem[a04]),  .p(out[4])); 
    mac  m05(.clk(clk), .reset(cfu_reset), .start(mode), .w(tile_mem[w]), .im(tile_mem[a05]),  .p(out[5])); 
    mac  m06(.clk(clk), .reset(cfu_reset), .start(mode), .w(tile_mem[w]), .im(tile_mem[a06]),  .p(out[6])); 
    mac  m07(.clk(clk), .reset(cfu_reset), .start(mode), .w(tile_mem[w]), .im(tile_mem[a07]),  .p(out[7])); 
    mac  m08(.clk(clk), .reset(cfu_reset), .start(mode), .w(tile_mem[w]), .im(tile_mem[a08]),  .p(out[8])); 
    mac  m09(.clk(clk), .reset(cfu_reset), .start(mode), .w(tile_mem[w]), .im(tile_mem[a09]),  .p(out[9])); 
    mac  m10(.clk(clk), .reset(cfu_reset), .start(mode), .w(tile_mem[w]), .im(tile_mem[a10]),  .p(out[10])); 
    mac  m11(.clk(clk), .reset(cfu_reset), .start(mode), .w(tile_mem[w]), .im(tile_mem[a11]),  .p(out[11])); 
    mac  m12(.clk(clk), .reset(cfu_reset), .start(mode), .w(tile_mem[w]), .im(tile_mem[a12]),  .p(out[12])); 
    mac  m13(.clk(clk), .reset(cfu_reset), .start(mode), .w(tile_mem[w]), .im(tile_mem[a13]),  .p(out[13])); 
    mac  m14(.clk(clk), .reset(cfu_reset), .start(mode), .w(tile_mem[w]), .im(tile_mem[a14]),  .p(out[14])); 
    mac  m15(.clk(clk), .reset(cfu_reset), .start(mode), .w(tile_mem[w]), .im(tile_mem[a15]),  .p(out[15]));

endmodule

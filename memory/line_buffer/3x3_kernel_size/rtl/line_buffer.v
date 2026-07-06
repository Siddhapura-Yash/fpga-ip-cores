/*
    assumption image = 512 x 512
    kernel_size = 3 x 3 
    input image = grayscale (8-bit)
*/

module line_buffer #(parameter KERNEL_SIZE = 3, IMAGE_WIDTH = 512, DATA_WIDTH = 8)(
    input clk,
    input rst,
    input [DATA_WIDTH-1:0]data_in,
    input data_in_valid,            //incoming data is valid
    output [(DATA_WIDTH*3) -1 : 0]data_out,
    input read_data
);

(* ram_style = "block" *)
reg [DATA_WIDTH-1:0]mem[0:IMAGE_WIDTH-1];
reg [$clog2(IMAGE_WIDTH)-1 : 0]w_ptr;
reg [$clog2(IMAGE_WIDTH)-1 : 0]r_ptr;

//stores incoming data
always@(posedge clk)
begin
    if(data_in_valid)
    begin
        mem[w_ptr] <= data_in;
    end
end

//increments write pointer when incoming data is valid 
always@(posedge clk)
begin
    if(!rst)
    begin
        w_ptr <= 'b0;
    end
    else if(data_in_valid)
    begin
        if (w_ptr == IMAGE_WIDTH - 1)
        begin
            w_ptr <= {$clog2(IMAGE_WIDTH){1'b0}};   
        end
        else begin
            w_ptr <= w_ptr + 1'b1;
        end
    end
end

//reading data 
reg [DATA_WIDTH-1:0] d0, d1, d2;

always @(posedge clk) begin
    //if read pointer getting out of range then hold previous data
        if (!rst) begin
            d0 <= {DATA_WIDTH{1'b0}};
            d1 <= {DATA_WIDTH{1'b0}};
            d2 <= {DATA_WIDTH{1'b0}};
        end
        else if (read_data && r_ptr+2 <= IMAGE_WIDTH-1) begin
            d0 <= mem[r_ptr];
            d1 <= mem[r_ptr + 1];
            d2 <= mem[r_ptr + 2];
    end
end

assign data_out = {d0,d1,d2};

//incrementing read counter 
always@(posedge clk)
begin
    if(!rst)
    begin
        r_ptr <= {$clog2(IMAGE_WIDTH){1'b0}};
    end
    else if(read_data)
    begin
        if (r_ptr == IMAGE_WIDTH - 1)
        begin
            r_ptr <= {$clog2(IMAGE_WIDTH){1'b0}};
        end
        else
        begin
            r_ptr <= r_ptr + 1'b1;
        end
    end
end

endmodule
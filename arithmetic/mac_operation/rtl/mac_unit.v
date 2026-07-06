module mac #(parameter DATA_WIDTH = 8, KERNEL_SIZE = 3)(
    input clk,
    input rst,
    input [DATA_WIDTH*KERNEL_SIZE*KERNEL_SIZE-1:0]data_in,
    input signed [DATA_WIDTH*KERNEL_SIZE*KERNEL_SIZE-1:0]weight,
    input data_in_valid,

    output reg signed [19:0]data_out,
    output reg data_out_valid
);

(* ram_style = "block" *)
reg signed [19:0]temp[0:KERNEL_SIZE*KERNEL_SIZE-1];

//multiply weight and pixel value
integer i;
always@(*)
begin
    if(data_in_valid)
    begin
        for(i=0; i<KERNEL_SIZE*KERNEL_SIZE; i=i+1)
        begin
            temp[i] = ($signed({1'b0, data_in[i*DATA_WIDTH +: DATA_WIDTH]})) * ($signed(weight[i*DATA_WIDTH +: DATA_WIDTH]));
        end
    end
end

always@(posedge clk)
begin
    if(!rst)
    begin
        data_out <= 'b0;
        data_out_valid <= 1'b0;
    end
    else if(data_in_valid)
    begin
        data_out <= temp[0] + temp[1] + temp[2] + temp[3] + 
                    temp[4] + temp[5] + temp[6] + temp[7] + temp[8]; 
        data_out_valid <= 1'b1;
    end
    else 
    begin
        data_out_valid <= 1'b0;
    end
end

endmodule
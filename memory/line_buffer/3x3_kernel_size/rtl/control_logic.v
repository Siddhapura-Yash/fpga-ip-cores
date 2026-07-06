module control_logic #(parameter DATA_WIDTH = 8, KERNEL_SIZE = 3, IMAGE_WIDTH = 512)(
    input clk,
    input rst,
    input [DATA_WIDTH-1:0]data_in,
    input data_in_valid,
    output reg [DATA_WIDTH*KERNEL_SIZE*KERNEL_SIZE-1:0]data_out,
    output reg data_out_valid
);

reg [$clog2(IMAGE_WIDTH) - 1:0]pixel_counter;
reg [$clog2(IMAGE_WIDTH) - 1:0]read_counter;
reg [1:0]current_line_buffer;
reg [3:0]line_buf_data_valid;
reg [3:0]line_buf_read_data;
reg [1:0]current_read_line_buffer;
reg read_line_buffer;
wire [DATA_WIDTH*KERNEL_SIZE-1:0]line_buf_0_data_out;
wire [DATA_WIDTH*KERNEL_SIZE-1:0]line_buf_1_data_out;
wire [DATA_WIDTH*KERNEL_SIZE-1:0]line_buf_2_data_out;
wire [DATA_WIDTH*KERNEL_SIZE-1:0]line_buf_3_data_out;

localparam TOTAL_COUNT_WIDTH = $clog2(IMAGE_WIDTH*KERNEL_SIZE+1);
reg [TOTAL_COUNT_WIDTH-1:0] total_pixel_counter;
//if pixel is continuosly read and entering same way from camera then don't do anything otherwise add or subtract according 
always@(posedge clk)
begin
    if(!rst)
    begin
        total_pixel_counter <= 'b0;
    end
    else if(data_in_valid && !read_line_buffer)
    begin
        total_pixel_counter <= total_pixel_counter + 1'b1;
    end
    else if(!data_in_valid && read_line_buffer && total_pixel_counter > 0)
    begin
        total_pixel_counter <= total_pixel_counter - 1'b1;
    end
end

always @(posedge clk) begin
    if (!rst)
    begin
        data_out_valid <= 1'b0;
    end
    else
    begin
        data_out_valid <= read_line_buffer && (read_counter < IMAGE_WIDTH - (KERNEL_SIZE - 1));
    end
end

localparam IDLE = 'd0,
           READ_BUFFER = 'd1;
reg [1:0]read_state;

always@(posedge clk)
begin
    if(!rst)
    begin
        read_state <= IDLE;
        read_line_buffer <= 1'b0;
    end
    else 
    begin
        case(read_state)
        IDLE : begin
            if(total_pixel_counter >= IMAGE_WIDTH * 3)
            begin
                read_line_buffer <= 1'b1;
                read_state <= READ_BUFFER;
            end
        end

        READ_BUFFER : begin
            if(read_counter == IMAGE_WIDTH - 1)
            begin
                read_state <= IDLE;
                read_line_buffer <= 1'b0;
            end
        end
        endcase
    end
end

//counting received pixel (will be used to shift between line buffer register for streaming input data)
always@(posedge clk)
begin
    if(!rst)
    begin
        pixel_counter <= 'b0;
    end
    else if(data_in_valid)
    begin
        if (pixel_counter == IMAGE_WIDTH - 1)
        begin
            pixel_counter <= {$clog2(IMAGE_WIDTH){1'b0}};  
        end
        else
        begin
            pixel_counter <= pixel_counter + 1'b1;
        end
    end 
end

//shift between line buffer when it fulls
always@(posedge clk)
begin
    if(!rst)
    begin
        current_line_buffer <= 'b0;
    end
    else if(pixel_counter == IMAGE_WIDTH-1 && data_in_valid)
    begin
        current_line_buffer <= current_line_buffer + 1'b1;
    end
end

//make data valid HIGH of valid line buffer 
always@(*)
begin
    line_buf_data_valid = 4'h0;
    line_buf_data_valid[current_line_buffer] = data_in_valid;
end

//give output from valid line buffer
always@(*)
begin
    case(current_read_line_buffer)
        0 : begin
            // data_out = {line_buf_2_data_out,line_buf_1_data_out,line_buf_0_data_out};
            data_out = {line_buf_0_data_out,line_buf_1_data_out,line_buf_2_data_out};
        end
        1 : begin
            // data_out = {line_buf_3_data_out,line_buf_2_data_out,line_buf_1_data_out};
            data_out = {line_buf_1_data_out,line_buf_2_data_out,line_buf_3_data_out};
        end
        2 : begin
            // data_out = {line_buf_0_data_out,line_buf_3_data_out,line_buf_2_data_out};
            data_out = {line_buf_2_data_out,line_buf_3_data_out,line_buf_0_data_out};
        end
        3 : begin
            // data_out = {line_buf_1_data_out,line_buf_0_data_out,line_buf_3_data_out};
            data_out = {line_buf_3_data_out,line_buf_0_data_out,line_buf_1_data_out};
        end
        default : data_out = 'b0;
    endcase
end

always @(posedge clk) 
begin
    if (!rst)
        read_counter <= 0;
    else if (read_line_buffer) 
    begin
            if (read_counter == IMAGE_WIDTH - 1)
                read_counter <= 0;          // CHANGE: reset added here
            else
                read_counter <= read_counter + 1'b1;
    end
end

always@(posedge clk)
begin
    if(!rst)
    begin
        current_read_line_buffer <= 'b0;
    end
    else if(read_counter == IMAGE_WIDTH - 1 && read_line_buffer)
    begin
        current_read_line_buffer <= current_read_line_buffer + 1'b1;
    end
end

always@(*)
begin
    case(current_read_line_buffer)
    
    0: begin
    line_buf_read_data[0] = read_line_buffer;
    line_buf_read_data[1] = read_line_buffer;
    line_buf_read_data[2] = read_line_buffer;
    line_buf_read_data[3] = 1'b0;
    end

    1: begin
    line_buf_read_data[0] = 1'b0;
    line_buf_read_data[1] = read_line_buffer;
    line_buf_read_data[2] = read_line_buffer;
    line_buf_read_data[3] = read_line_buffer;
    end

    2: begin
    line_buf_read_data[0] = read_line_buffer;
    line_buf_read_data[1] = 1'b0;
    line_buf_read_data[2] = read_line_buffer;
    line_buf_read_data[3] = read_line_buffer;
    end

    3: begin
    line_buf_read_data[0] = read_line_buffer;
    line_buf_read_data[1] = read_line_buffer;
    line_buf_read_data[2] = 1'b0;
    line_buf_read_data[3] = read_line_buffer;
    end
    default: line_buf_read_data = 4'h0;
    endcase

end

line_buffer #(.KERNEL_SIZE(KERNEL_SIZE),
              .IMAGE_WIDTH(IMAGE_WIDTH),
              .DATA_WIDTH(DATA_WIDTH)) 
line_buf_0 (
            .clk(clk),
            .rst(rst),
            .data_in(data_in),
            .data_in_valid(line_buf_data_valid[0]),
            .data_out(line_buf_0_data_out),
            .read_data(line_buf_read_data[0])
);

line_buffer #(.KERNEL_SIZE(KERNEL_SIZE),
              .IMAGE_WIDTH(IMAGE_WIDTH),
              .DATA_WIDTH(DATA_WIDTH)) 
line_buf_1 (
            .clk(clk),
            .rst(rst),
            .data_in(data_in),
            .data_in_valid(line_buf_data_valid[1]),
            .data_out(line_buf_1_data_out),
            .read_data(line_buf_read_data[1])
);

line_buffer #(.KERNEL_SIZE(KERNEL_SIZE),
              .IMAGE_WIDTH(IMAGE_WIDTH),
              .DATA_WIDTH(DATA_WIDTH)) 
line_buf_2 (
            .clk(clk),
            .rst(rst),
            .data_in(data_in),
            .data_in_valid(line_buf_data_valid[2]),
            .data_out(line_buf_2_data_out),
            .read_data(line_buf_read_data[2])
);

line_buffer #(.KERNEL_SIZE(KERNEL_SIZE),
              .IMAGE_WIDTH(IMAGE_WIDTH),
              .DATA_WIDTH(DATA_WIDTH)) 
line_buf_3 (
            .clk(clk),
            .rst(rst),
            .data_in(data_in),
            .data_in_valid(line_buf_data_valid[3]),
            .data_out(line_buf_3_data_out),
            .read_data(line_buf_read_data[3])
);

endmodule
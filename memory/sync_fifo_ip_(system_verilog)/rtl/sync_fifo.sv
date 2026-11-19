module sync_fifo #(
    parameter int unsigned DATA_WIDTH   = 8,
    parameter int unsigned DEPTH        = 8,
    parameter int unsigned PTR_WIDTH    = $clog2(DEPTH)
)(
    input logic                     clk_i,
    input logic                     rst_n_i,
    input logic                     r_en_i,
    input logic                     w_en_i,
    input logic                     mode_i,
    input logic [DATA_WIDTH-1:0]    data_in_i,

    output logic [DATA_WIDTH-1:0]   data_out_o,
    output logic [PTR_WIDTH:0]      data_count_o,
    output logic                    full_o,
    output logic                    empty_o,
    output logic                    rd_valid_o,
    output logic                    overflow_o,
    output logic                    underflow_o
);

logic [$clog2(DEPTH) : 0] w_ptr;
logic [$clog2(DEPTH) : 0] r_ptr;
logic [DATA_WIDTH - 1 : 0] mem [0 : DEPTH - 1];

/* actual memory addresses */
logic [$clog2(DEPTH)-1:0] w_addr;
logic [$clog2(DEPTH)-1:0] r_addr;

logic read_accept;
logic write_accept;

logic [DATA_WIDTH-1:0] rd_data_q;
logic rd_valid_q;

assign w_addr = w_ptr[$clog2(DEPTH)-1:0];
assign r_addr = r_ptr[$clog2(DEPTH)-1:0];

assign read_accept  = r_en_i && !empty_o;
assign write_accept = w_en_i && (!full_o || read_accept);

/* write data */
  always_ff@(posedge clk_i)begin
    if(!rst_n_i)begin
        w_ptr <= {PTR_WIDTH+1{1'b0}};
    end
    else begin
        if(write_accept)begin
            mem[w_addr] <= data_in_i;
            w_ptr <= w_ptr + 1'b1;
        end
    end
  end

always_ff @(posedge clk_i) begin
    if (!rst_n_i) begin
        overflow_o <= 1'b0;
        underflow_o <= 1'b0;
    end
    else begin
        overflow_o  <= w_en_i && !write_accept;
        underflow_o <= r_en_i && !read_accept;
    end
end

/* read data */
always_ff @(posedge clk_i) begin
    if (!rst_n_i) begin
        r_ptr      <= '0;
        rd_data_q  <= '0;
        rd_valid_q <= 1'b0;
    end else begin
        rd_valid_q <= read_accept;
        if (read_accept) begin
            rd_data_q <= mem[r_addr];
            r_ptr     <= r_ptr + 1'b1;
        end
    end
end

assign data_out_o = mode_i ? rd_data_q  : mem[r_addr];
assign rd_valid_o = mode_i ? rd_valid_q : !empty_o;

/* supports simultaneous read and write */
always_ff @(posedge clk_i) begin
    if (!rst_n_i) begin
        data_count_o <= '0;
    end
    else begin
        case ({write_accept, read_accept})
            2'b10: data_count_o <= data_count_o + 1'b1;
            2'b01: data_count_o <= data_count_o - 1'b1;
            default: data_count_o <= data_count_o;
        endcase
    end
end

assign empty_o = (data_count_o == {(PTR_WIDTH+1){1'b0}});
assign full_o  = (data_count_o == (PTR_WIDTH+1)'(DEPTH));

endmodule

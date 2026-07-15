module memory #(
    parameter DATA_WIDTH = 8,
    parameter DEPTH = 8, 
    parameter PTR_WIDTH = 3,
    parameter MODE = 1
) (  
   input                                rclk,
   input                                rrst,
   input                                wclk,
   input                                wrst,
   input                                w_en,
   input                                r_en,
   input                                full,empty,
   input  [PTR_WIDTH : 0]               b_wptr,
   input  [PTR_WIDTH : 0]               b_rptr,
   input  [DATA_WIDTH - 1 : 0]          data_in,
   
   output reg  [DATA_WIDTH - 1 : 0]     data_out,
   output reg                           rd_valid,
   output reg                           overflow,
   output reg                           underflow,
   output reg                           wr_ack,
   output  [PTR_WIDTH:0]                data_count
);
   
  reg [DATA_WIDTH - 1 : 0]mem[0 : DEPTH-1]; 

  assign data_count = b_wptr - b_rptr;

  always @(posedge wclk) begin
      wr_ack   <= 1'b0;
      overflow <= 1'b0;
  
      if (!wrst) begin
          wr_ack   <= 1'b0;
          overflow <= 1'b0;
      end else begin
          if (w_en && !full) begin
              mem[b_wptr[PTR_WIDTH-1:0]] <= data_in;
              wr_ack                     <= 1'b1;
          end else if (w_en && full) begin
              overflow <= 1'b1;
          end
      end
  end
  
  always @(posedge rclk) begin
      rd_valid  <= 1'b0;
      underflow <= 1'b0;
  
      if (!rrst) begin
          rd_valid  <= 1'b0;
          underflow <= 1'b0;
          data_out  <= 'b0;
      end else begin
  
          if (!empty && !MODE)
              data_out <= mem[b_rptr[PTR_WIDTH-1:0]];
  
          if (MODE) begin
              /* Normal FIFO mode */
              if (r_en && !empty) begin
                  data_out <= mem[b_rptr[PTR_WIDTH-1:0]];
                  rd_valid <= 1'b1;
              end else if (r_en && empty)
                  underflow <= 1'b1;
          end else begin
              /* FWFT mode */
              if (!empty)
                  rd_valid <= 1'b1;
  
              if (r_en && empty)
                  underflow <= 1'b1;
          end
      end
  end

endmodule
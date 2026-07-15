/*
  Configurable ASYNCHRONOUS FIFO IP

  Supported Modes:

  MODE = 0 : FWFT (First Word Fall Through)
             Data is available at the output without asserting read enable.

  MODE = 1 : Standard FIFO
             Data is available only after read enable is asserted.

  Reset:

  wr_rst_n and rd_rst_n are active-low resets (negedge).

  Configurable Parameters:

  DEPTH            : FIFO depth
  DATA_WIDTH       : Data width
  PROG_FULL_VALUE  : Programmable full threshold
  PROG_EMPTY_VALUE : Programmable empty threshold

  These parameters can be changed according to your application requirements.
*/

module async_top #(
  parameter DEPTH = 8, 
  parameter DATA_WIDTH = 8, 
  parameter PROG_FULL_VALUE = (DEPTH/2) - 1, 
  parameter PROG_EMPTY_VALUE = (DEPTH/2) + 1, 
  parameter MODE = 1
) (
   input                            wclk,
   input                            wr_rst_n,
   input                            rclk,
   input                            rd_rst_n,
   input                            w_en,
   input                            r_en,
   input  [DATA_WIDTH - 1 : 0]      data_in,

   output reg [DATA_WIDTH - 1 : 0]  data_out,
   output [PTR_WIDTH:0]             data_count,

   /* output flags */
   output                           full,
   output                           empty,
   output                           rst_busy,
   output                           half_empty,
   output                           half_full,
   output                           rd_valid,
   output                           underflow,
   output                           overflow,
   output                           prog_full,
   output                           prog_empty,
   output                           wr_ack,
   output                           almost_full,
   output                           almost_empty
  );
  
  parameter PTR_WIDTH = $clog2(DEPTH);
  
  reg [PTR_WIDTH:0] g_wptr_sync;
  reg [PTR_WIDTH:0] g_rptr_sync;
  reg [PTR_WIDTH:0] b_wptr;
  reg [PTR_WIDTH:0] b_rptr;
  reg [PTR_WIDTH:0] g_wptr; 
  reg [PTR_WIDTH:0] g_rptr;

  wire [PTR_WIDTH-1:0] waddr;
  wire [PTR_WIDTH-1:0] raddr;

  wire [$clog2(DEPTH+1)-1:0]read_data_count;
  wire [$clog2(DEPTH+1)-1:0]write_data_count;
  
  /* write pointer */
  sync #(
    .DATA_WIDTH(PTR_WIDTH)
  )
  sync_wptr (
    .clk(rclk), 
    .rst_n(rd_rst_n), 
    .data_in(g_wptr), 
    .data_out(g_wptr_sync)
  ); 

  /* read pointer */
  sync #(
    .DATA_WIDTH(PTR_WIDTH)
  ) 
  sync_rptr (
    .clk(wclk), 
    .rst_n(wr_rst_n), 
    .data_in(g_rptr), 
    .data_out(g_rptr_sync)
  ); 
  
  wptr_handler #(
    .PTR_WIDTH(PTR_WIDTH),
    .DEPTH(DEPTH)
  ) 
  wptr_h (
    .wclk(wclk),
    .wrst(wr_rst_n), 
    .w_en(w_en),
    .g_rptr_sync(g_rptr_sync),
    .prog_full_value(PROG_FULL_VALUE),
    .b_wptr(b_wptr),
    .g_wptr(g_wptr),
    .full(full),
    .half_full(half_full),
    .prog_full(prog_full),
    .almost_full(almost_full)
  );
  
  rptr_handler #(
    .PTR_WIDTH(PTR_WIDTH),
    .DEPTH(DEPTH)
  ) 
  rptr_h (
    .rclk(rclk), 
    .rrst(rd_rst_n), 
    .r_en(r_en),
    .g_wptr_sync(g_wptr_sync),
    .prog_empty_value(PROG_EMPTY_VALUE),
    .b_rptr(b_rptr),
    .g_rptr(g_rptr),
    .empty(empty),
    .half_empty(half_empty),
    .prog_empty(prog_empty),
    .almost_empty(almost_empty)
    );

  memory #(
    .DATA_WIDTH(DATA_WIDTH),
    .DEPTH(DEPTH),
    .PTR_WIDTH(PTR_WIDTH),
    .MODE(MODE)
  ) 
  mem (
    .rclk(rclk),
    .rrst(rd_rst_n),
    .wclk(wclk),
    .wrst(wr_rst_n), 
    .w_en(w_en),
    .r_en(r_en), 
    .full(full), 
    .empty(empty), 
    .b_wptr(b_wptr), 
    .b_rptr(b_rptr), 
    .data_in(data_in),
    .data_out(data_out),
    .rd_valid(rd_valid),
    .overflow(overflow),
    .underflow(underflow),
    .wr_ack(wr_ack),
    .data_count(data_count)
  );

  assign rst_busy = !rd_rst_n || !wr_rst_n;

endmodule
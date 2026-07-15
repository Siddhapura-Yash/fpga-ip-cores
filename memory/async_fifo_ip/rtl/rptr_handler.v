module rptr_handler #(
  parameter PTR_WIDTH = 3, 
  parameter DEPTH = 4
) (
  input                       rclk, 
  input                       rrst, 
  input                       r_en,
  input  [PTR_WIDTH:0]        g_wptr_sync,
  input  [PTR_WIDTH : 0]      prog_empty_value,

  output reg  [PTR_WIDTH:0]   b_rptr, 
  output reg  [PTR_WIDTH:0]   g_rptr,
  output reg                  empty,
  output reg                  half_empty,
  output reg                  prog_empty,
  output reg                  almost_empty
);

  reg [PTR_WIDTH:0] b_rptr_next;
  reg [PTR_WIDTH:0] g_rptr_next;

  reg [PTR_WIDTH:0] b_wptr_sync;   /* Gray to Binary converted */
  reg [$clog2(DEPTH+1)-1:0] data_count;

  wire rempty;

  integer i;
  always @(*) begin
    b_wptr_sync[PTR_WIDTH] = g_wptr_sync[PTR_WIDTH];

    for (i = PTR_WIDTH-1; i >= 0; i = i-1)
      b_wptr_sync[i] = b_wptr_sync[i+1] ^ g_wptr_sync[i];
  end

  assign b_rptr_next = b_rptr + (r_en & ~empty);
  assign g_rptr_next = (b_rptr_next >> 1) ^ b_rptr_next;

  assign rempty = (g_wptr_sync == g_rptr_next);

  always @(posedge rclk or negedge rrst) begin
    if (!rrst) begin
        b_rptr <= 0;
        g_rptr <= 0;
    end else begin
        b_rptr <= b_rptr_next;
        g_rptr <= g_rptr_next;
    end
  end

  always @(posedge rclk or negedge rrst) begin
    if (!rrst) begin
        empty <= 1'b1;
        almost_empty <= 1'b0;
    end else begin
      empty <= rempty;
      almost_empty <= 1'b0;

      if (data_count <= 1) begin
          almost_empty <= 1'b1;
      end
    end
  end

  always @(*) begin
    data_count = b_wptr_sync - b_rptr_next;
  end

  always @(posedge rclk or negedge rrst) begin
    if (!rrst)
        half_empty <= 1'b0;
    else
        half_empty <= (data_count <= ((DEPTH/2)));
  end

  always@(posedge rclk or negedge rrst) begin
    if (!rrst) begin
        prog_empty <= 1'b0;
    end else begin
      if (data_count <= (prog_empty_value)) begin
          prog_empty <= 1'b1;
      end else begin
          prog_empty <= 1'b0;
      end
    end
  end

endmodule

module wptr_handler #(
  parameter PTR_WIDTH = 3, 
  parameter DEPTH = 4
) (
  input                     wclk, 
  input                     wrst, 
  input                     w_en,
  input [PTR_WIDTH:0]       g_rptr_sync,
  input [PTR_WIDTH:0]       prog_full_value,

  output reg [PTR_WIDTH:0]  b_wptr, 
  output reg [PTR_WIDTH:0]  g_wptr,
  output reg                full,
  output reg                half_full,
  output reg                prog_full,
  output                    almost_full
);

  reg [PTR_WIDTH:0] b_wptr_next;
  reg [PTR_WIDTH:0] g_wptr_next;

  reg [PTR_WIDTH:0] b_rptr_sync;   /* gray to binary converted */
  reg [$clog2(DEPTH+1)-1:0] data_count;

  wire wfull;

  integer i;

/* convert gray to binary */ 
  always @(*) begin
    b_rptr_sync[PTR_WIDTH] = g_rptr_sync[PTR_WIDTH];

    for (i = PTR_WIDTH-1; i >= 0; i = i-1)
      b_rptr_sync[i] = b_rptr_sync[i+1] ^ g_rptr_sync[i];
  end

  assign b_wptr_next = b_wptr + (w_en & !full);
  assign g_wptr_next = (b_wptr_next >> 1) ^ b_wptr_next;

  assign wfull = (g_wptr_next == {~g_rptr_sync[PTR_WIDTH:PTR_WIDTH-1],g_rptr_sync[PTR_WIDTH-2:0]});

  always @(posedge wclk or negedge wrst) begin
    if (!wrst) begin
        b_wptr <= 0;
        g_wptr <= 0;
    end else begin
        b_wptr <= b_wptr_next;
        g_wptr <= g_wptr_next;
    end
  end

  always @(posedge wclk or negedge wrst) begin
    if (!wrst)  begin
        full <= 1'b0;
    end else begin
        full <= wfull;
    end
  end 

  always @(*) begin
    data_count = b_wptr - b_rptr_sync;
  end

  always @(posedge wclk or negedge wrst) begin
    if (!wrst)
        half_full <= 1'b0;
    else
        half_full <= (data_count >= (DEPTH/2));
  end

  always @(posedge wclk or negedge wrst) begin
    if (!wrst)begin
        prog_full <= 1'b0;
    end else begin
      if (data_count >= prog_full_value) begin
          prog_full <= 1'b1;
      end else begin
          prog_full <= 1'b0;
      end
    end
  end

assign write_data_count = data_count;
assign almost_full = (data_count >= (DEPTH-1));

endmodule

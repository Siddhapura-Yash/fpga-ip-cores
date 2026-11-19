module axi4_lite_wrapper #(
    parameter int unsigned ADDR_WIDTH               = 32,
    parameter int unsigned DATA_WIDTH               = 32,
    parameter int unsigned NO_OF_REG                = 32,
    parameter logic [ADDR_WIDTH-1:0] BASE_ADDRESS   = 32'h400F8000
) (
    input  logic                      ACLK_i,
    input  logic                      ARESETn_i,

    /* write address channel */
    input  logic [ADDR_WIDTH-1:0]     AWADDR_i,
    input  logic [2:0]                AWPROT_i,
    input  logic                      AWVALID_i,
    output logic                      AWREADY_o,

    /* write data channel */
    input  logic [DATA_WIDTH-1:0]     WDATA_i,
    input  logic [(DATA_WIDTH/8)-1:0] WSTRB_i,
    input  logic                      WVALID_i,
    output logic                      WREADY_o,

    /* write response channel */
    output logic [1:0]                BRESP_o,
    output logic                      BVALID_o,
    input  logic                      BREADY_i,

    /* read address channel */
    input  logic [ADDR_WIDTH-1:0]     ARADDR_i,
    input  logic [2:0]                ARPROT_i,
    input  logic                      ARVALID_i,
    output logic                      ARREADY_o,

    /* read data channel */
    output logic [DATA_WIDTH-1:0]     RDATA_o,
    output logic [1:0]                RRESP_o,
    output logic                      RVALID_o,
    input  logic                      RREADY_i
);

logic [DATA_WIDTH-1 : 0] register [0:NO_OF_REG-1];

logic write_addr;
logic write_data;
logic [4:0]adder;

logic aw_got;
logic w_got;
logic aw_ok;
logic w_ok;

/* to store data when channel data comes independently */
logic [ADDR_WIDTH-1:0]awaddr_q;
logic [DATA_WIDTH-1:0]wdata_q;
logic [(DATA_WIDTH/8)-1:0]wstrb_q;
logic [ADDR_WIDTH-1:0]waddr;
logic [DATA_WIDTH-1:0]wdata;
logic [4:0]temp_adder;
logic write_en;

logic start_pulse_o;
logic start_i_d;

logic [4:0] write_index;
logic write_addr_valid;
logic write_allowed;

logic [1:0] bresp_reg;
logic [1:0] rresp_reg;
logic [DATA_WIDTH/8-1:0] wstrb;

logic read_addr_valid;
logic write_error_bit;
logic read_error_bit;

/* write addresss chanel */
assign AWREADY_o  = (state == WRITE_CHANNEL) && !aw_got;

/* write data chanel */
assign WREADY_o   = (state == WRITE_CHANNEL) && !w_got;

/* write response chanel */
assign BVALID_o = (state == WRESP__CHANNEL) ? 1'b1 : 1'b0;
assign BRESP_o = bresp_reg;

/* read address channel */
assign ARREADY_o = (state == RADDR_CHANNEL);

/* read data channel */
assign RDATA_o = (state == RDATA__CHANNEL) ? register[adder] : {DATA_WIDTH{1'b0}};
assign RRESP_o = rresp_reg;
assign RVALID_o = (state == RDATA__CHANNEL) ? 1'b1 : 1'b0;

assign write_addr = AWVALID_i && AWREADY_o;
assign write_data = WREADY_o  && WVALID_i;

assign waddr = aw_got ? awaddr_q : AWADDR_i;
assign wdata = w_got  ? wdata_q  : WDATA_i;

assign temp_adder = waddr[6:2];
assign write_en = (state == WRITE_CHANNEL) && aw_ok && w_ok;

assign aw_ok = aw_got || write_addr;
assign w_ok = w_got  || write_data;

assign write_index = waddr[6:2];

assign wstrb = w_got ? wstrb_q : WSTRB_i;

always_ff @(posedge ACLK_i) begin
    if (!ARESETn_i) begin
        bresp_reg <= 2'b00;
    end
    else if (state == WRITE_CHANNEL && w_ok && aw_ok) begin
        if (!write_addr_valid)
            bresp_reg <= 2'b11;  // outside range
        else if (!write_allowed)
            bresp_reg <= 2'b10;  // writes on read only reg
        else
            bresp_reg <= 2'b00;  // okay
    end
end

assign write_addr_valid =
    (waddr[ADDR_WIDTH-1:7] == BASE_ADDRESS[ADDR_WIDTH-1:7]) &&
    (waddr[1:0] == 2'b00);

assign read_addr_valid =
    (ARADDR_i[ADDR_WIDTH-1:7] == BASE_ADDRESS[ADDR_WIDTH-1:7]) &&
    (ARADDR_i[1:0] == 2'b00) &&
    (ARADDR_i[6:2] <= 5'd26);

assign write_allowed =
    write_addr_valid &&
    ((write_index == 5'd0) ||
     (write_index == 5'd2) ||
     ((write_index >= 5'd3) && (write_index <= 5'd18)));

/* write to registers */
always_ff @(posedge ACLK_i) begin
    if (!ARESETn_i) begin
        adder <= 'b0;
    end
    else begin
        integer i;
        if(write_en && write_allowed) begin
            for (int i = 0; i < DATA_WIDTH/8; i++) begin
                if (wstrb[i]) begin
                    register[write_index][i*8 +: 8] <= wdata[i*8 +: 8];
                end
            end
    end
    end
end

always_ff @(posedge ACLK_i) begin
    if (!ARESETn_i) begin
        rresp_reg <= 2'b00;
    end
    else if (state == RADDR_CHANNEL && ARVALID_i && ARREADY_o) begin
        adder <= ARADDR_i[6:2];

        if ((ARADDR_i[ADDR_WIDTH-1:7] != BASE_ADDRESS[ADDR_WIDTH-1:7]) ||
            (ARADDR_i[1:0] != 2'b00)) begin
            rresp_reg <= 2'b11;  // outside range reading
        end
        else if (ARADDR_i[6:2] >= 5'd27) begin
            rresp_reg <= 2'b11;  // outside range reading
        end
        else begin
            rresp_reg <= 2'b00;  // okay
        end
    end
end

/* if data comes independetly store into local reg */
always_ff @(posedge ACLK_i) begin
    if (!ARESETn_i || state != WRITE_CHANNEL) begin
        aw_got <= 1'b0;
        w_got  <= 1'b0;
    end else begin
        if (write_addr) begin
            aw_got <= 1'b1;
        end
        if (write_data) begin
            w_got  <= 1'b1;
        end
    end
    if (write_addr) begin
        awaddr_q <= AWADDR_i;
    end
    if (write_data) begin
        wdata_q <= WDATA_i;
        wstrb_q <= WSTRB_i;
    end
end

/* high when restricted write take place, clears after next valid write */
always_ff @(posedge ACLK_i) begin
    if (!ARESETn_i) begin
        write_error_bit <= 1'b0;
    end
    else if ((state == WRITE_CHANNEL) && w_ok && aw_ok) begin
        write_error_bit <= !write_allowed;
    end
end

/* high when restricted read take place, clears after next valid read */
always_ff @(posedge ACLK_i) begin
    if (!ARESETn_i) begin
        read_error_bit <= 1'b0;
    end
    else if ((state == RADDR_CHANNEL) && ARVALID_i && ARREADY_o) begin
        read_error_bit <= !read_addr_valid;
    end
end

typedef enum logic [2:0] {
    IDLE,
    WRITE_CHANNEL,
    WRESP__CHANNEL,
    RADDR_CHANNEL,
    RDATA__CHANNEL
    } state_type_t;

state_type_t state , next_state;

always_ff@(posedge ACLK_i)begin
    if(!ARESETn_i)begin
        state <= IDLE;
    end
    else begin
        state <= next_state;
    end
end

always_comb begin
    case (state)
        IDLE : begin
            if (AWVALID_i || WVALID_i) begin
                next_state = WRITE_CHANNEL;
            end
            else if (ARVALID_i) begin
                next_state = RADDR_CHANNEL;
            end
            else begin
                next_state = IDLE;
            end
        end
        RADDR_CHANNEL:
            if (ARVALID_i && ARREADY_o) begin
                next_state = RDATA__CHANNEL;
            end
            else begin
                next_state = RADDR_CHANNEL;
            end
        RDATA__CHANNEL:
            if (RVALID_o  && RREADY_i) begin
                next_state = IDLE;
            end
            else begin
                next_state = RDATA__CHANNEL;
            end
        WRITE_CHANNEL:
            if (w_ok && aw_ok) begin
                next_state = WRESP__CHANNEL;
            end
            else begin
                next_state = WRITE_CHANNEL;
            end
        WRESP__CHANNEL:
            if (BVALID_o  && BREADY_i) begin
                next_state = IDLE;
            end
            else begin
                next_state = WRESP__CHANNEL;
            end

        default : next_state = state;
    endcase
end

endmodule

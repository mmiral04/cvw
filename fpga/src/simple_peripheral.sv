module simple_peripheral (
    // AXI signals
    input  logic clk,
    input  logic peripheral_aresetn,

    input  logic        S_AXI_AWVALID,
    output logic        S_AXI_AWREADY,
    input  logic [3:0]  S_AXI_AWADDR,

    input  logic [63:0] S_AXI_WDATA,
    input  logic [7:0]  S_AXI_WSTRB,
    input  logic        S_AXI_WVALID,
    output logic        S_AXI_WREADY,

    output logic        S_AXI_BVALID,
    input  logic        S_AXI_BREADY,
    output logic [1:0]  S_AXI_BRESP,

    input  logic        S_AXI_ARVALID,
    output logic        S_AXI_ARREADY,
    input  logic [3:0]  S_AXI_ARADDR,

    output logic        S_AXI_RVALID,
    input  logic        S_AXI_RREADY,
    output logic [63:0] S_AXI_RDATA,
    output logic [1:0]  S_AXI_RRESP,

    // led signals
    output logic        led1_state,
    output logic        led2_state,
    output logic        led3_state,
    output logic        led4_state);

    logic led1_register; // 0x0
    logic led2_register; // 0x4
    logic led3_register; // 0x8
    logic led4_register; // 0xC

    logic        awready;
    logic        arready;
    logic        bvalid;
    logic [3:0]  araddr;
    logic [3:0]  awaddr;
    logic        rvalid;
    logic [63:0] rdata;
    logic        read_ready;

    assign S_AXI_AWREADY = awready;
    assign S_AXI_WREADY = awready;
    assign S_AXI_ARREADY = arready;
    assign S_AXI_RVALID = rvalid;
    assign S_AXI_BVALID = bvalid;
    assign S_AXI_RDATA = rdata;
    assign S_AXI_RRESP = 2'b0;
    assign S_AXI_BRESP = 2'b0;
    assign araddr = S_AXI_ARADDR;
    assign awaddr = S_AXI_AWADDR;
    assign read_ready = (S_AXI_ARVALID && S_AXI_ARREADY);

    always_ff @(posedge clk) begin : aw_channel_handshake
        if (!peripheral_aresetn) awready <= 1'b0;
        else begin
            awready <= !awready
                        && (S_AXI_AWVALID && S_AXI_WVALID)
                        && (!S_AXI_BVALID || S_AXI_BREADY);
        end
    end

    always_ff @(posedge clk) begin : bvalid_ff
        if (!peripheral_aresetn) bvalid <= 1'b0;
        else if (awready)        bvalid <= 1'b1;
        else if (S_AXI_BREADY)   bvalid <= 1'b0;
    end

    assign arready = !S_AXI_RVALID;


    always_ff @(posedge clk) begin : rvalid_ff
        if (!peripheral_aresetn) rvalid <= 1'b0;
        else if (read_ready)     rvalid <= 1'b1;
        else if (S_AXI_RREADY)   rvalid <= 1'b0;
    end


    /*
    * register logic
    */
    always_ff @(posedge clk) begin : rdata_ff
        if (!peripheral_aresetn) rdata = 64'b0;
        else if (!S_AXI_RVALID || S_AXI_RREADY)
            case (araddr)
                4'h0:    rdata = led1_register;
                4'h4:    rdata = led2_register;
                4'h8:    rdata = led3_register;
                4'hC:    rdata = led4_register;
                default: rdata = rdata;
            endcase
    end

    logic wstrb_led1;
    logic wstrb_led2;
    logic wstrb_led3;
    logic wstrb_led4;
    assign wstrb_led1 = S_AXI_WSTRB[0] ? S_AXI_WDATA[0] : led1_register;
    assign wstrb_led2 = S_AXI_WSTRB[0] ? S_AXI_WDATA[0] : led2_register;
    assign wstrb_led3 = S_AXI_WSTRB[0] ? S_AXI_WDATA[0] : led3_register;
    assign wstrb_led4 = S_AXI_WSTRB[0] ? S_AXI_WDATA[0] : led4_register;

    always_ff @(posedge clk) begin : wdata_ff
        if (!peripheral_aresetn) begin
            led1_register = 1'b0;
            led2_register = 1'b0;
            led3_register = 1'b0;
            led4_register = 1'b0;
        end else if (awready) begin
            case(awaddr)
                4'h0: led1_register = wstrb_led1;
                4'h4: led2_register = wstrb_led2;
                4'h8: led3_register = wstrb_led3;
                4'hC: led4_register = wstrb_led4;
                default: begin
                    led1_register = led1_register;
                    led2_register = led2_register;
                    led3_register = led3_register;
                    led4_register = led4_register;
                end
            endcase
        end
    end

    // led output logic
    assign led1_state = led1_register;
    assign led2_state = led2_register;
    assign led3_state = led3_register;
    assign led4_state = led4_register;

endmodule

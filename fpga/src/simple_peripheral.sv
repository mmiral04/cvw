module simple_peripheral (
    // AXI signals
    input  logic clk,
    input  logic peripheral_aresetn,

    input  logic        S_AXI_AWVALID,
    output logic        S_AXI_AWREADY,
    input  logic [31:0] S_AXI_AWADDR,

    input  logic [63:0] S_AXI_WDATA,
    input  logic [7:0]  S_AXI_WSTRB,
    input  logic        S_AXI_WVALID,
    output logic        S_AXI_WREADY,

    output logic        S_AXI_BVALID,
    input  logic        S_AXI_BREADY,
    output logic [1:0]  S_AXI_BRESP,

    input  logic        S_AXI_ARVALID,
    output logic        S_AXI_ARREADY,
    input  logic [31:0] S_AXI_ARADDR,

    output logic        S_AXI_RVALID,
    input  logic        S_AXI_RREADY,
    output logic [63:0] S_AXI_RDATA,
    output logic [1:0]  S_AXI_RRESP,

    // led signals
    output logic        led1_state);

    // BASE_ADDR = 0x00001000
    logic [63:0] led1_register; // BASE_ADDR

    logic        awready;
    logic        arready;
    logic        bvalid;
    logic [31:0] araddr;
    logic [31:0] awaddr;
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
                32'h00001000: rdata = led1_register;
                default:      rdata = rdata;
            endcase
    end

    logic [63:0] wstrb_led1;
    assign wstrb_led1 = apply_wstrb(led1_register, S_AXI_WDATA, S_AXI_WSTRB);

    always_ff @(posedge clk) begin : wdata_ff
        if (!peripheral_aresetn) begin
            led1_register = 64'b0;
        end else if (awready) begin
            case(awaddr)
                32'h00001000: led1_register = wstrb_led1;
                default: begin
                    led1_register = led1_register;
                end
            endcase
        end
    end


    function [63:0] apply_wstrb;
        input [63:0] old_data;
        input [63:0] new_data;
        input [7:0]  wstrb;

        integer k;
        for(k=0; k<8; k=k+1) begin
            apply_wstrb[k*8 +: 8] = wstrb[k] ? new_data[k*8 +: 8] : old_data[k*8 +: 8];
        end
    endfunction

    // led output logic
    assign led1_state = led1_register != 0;

endmodule

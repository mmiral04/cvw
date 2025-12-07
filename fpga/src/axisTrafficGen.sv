module axis_traffic_gen #(parameter TDATA_WIDTH = 32,
    parameter TID_WIDTH = 1)(

    input logic                        ACLK,
    input logic                        ARESETn,

    // AXIS master intereface
    output logic [TDATA_WIDTH - 1:0]   tdata,
    output logic [TDATA_WIDTH/8 - 1:0] tkeep,
    output logic                       tlast,
    output logic                       tvalid,
    input logic                        tready);

    assign tkeep = '1;
    assign tvalid = 1;
    assign tlast = 1;

    always_ff@(posedge ACLK) begin
        if (ARESETn == 0) tdata <= '0;
        else if (tready) begin
            if (tdata == 8) tdata <= '0;
            else tdata <= tdata + 1;
        end
    end

endmodule

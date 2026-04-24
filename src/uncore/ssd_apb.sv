///////////////////////////////////////////
// 7seg_apb.sv
//
// Written: mariomiralles04@gmail.com 19 February 2026
// Modified:
//
// Purpose: Seven Segment Display peripheral
//   See FE310-G002-Manual-v19p05 for specifications
//
// Documentation: RISC-V System on Chip Design
//
// A component of the CORE-V-WALLY configurable RISC-V project.
// https://github.com/openhwgroup/cvw
//
// Copyright (C) 2021-23 Harvey Mudd College & Oklahoma State University
//
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
//
// Licensed under the Solderpad Hardware License v 2.1 (the “License”); you may not use this file
// except in compliance with the License, or, at your option, the Apache License version 2.0. You
// may obtain a copy of the License at
//
// https://solderpad.org/licenses/SHL-2.1/
//
// Unless required by applicable law or agreed to in writing, any work distributed under the
// License is distributed on an “AS IS” BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,
// either express or implied. See the License for the specific language governing permissions
// and limitations under the License.
////////////////////////////////////////////////////////////////////////////////////////////////

module ssd_apb import cvw::*; #(parameter cvw_t P) (
  input  logic                PCLK, PRESETn,
  input  logic                PSEL,
  input  logic [2:0]          PADDR,
  input  logic [P.XLEN-1:0]   PWDATA,
  input  logic [P.XLEN/8-1:0] PSTRB,
  input  logic                PWRITE,
  input  logic                PENABLE,
  output logic [P.XLEN-1:0]   PRDATA,
  output logic                PREADY,
  output logic [7:0]          ssd_signals
);

  // register map
  localparam LEFT_REGISTER = 3'h0;
  localparam RIGHT_REGISTER = 3'h4;

  logic       memwrite;
  logic [6:0] left_segments, right_segments;
  logic [2:0] entry;
  logic [31:0] Din, Dout;

  logic       toggle;

  // Clock speed is divided by half to get better results.
  logic [1:0] clkcounter;
  logic       clk10Mhz;

  always_ff @(posedge PCLK) begin: clock_counter
    if (~PRESETn) clkcounter <= 'b0;
    else if (clkcounter == {2{1'b1}}) clkcounter <= 'b0;
    else clkcounter <= clkcounter + 1;
  end

  always_ff @(posedge PCLK) begin: clock_divider
    if (~PRESETn) clk10Mhz <= 0;
    else if (clkcounter == {2{1'b1}}) clk10Mhz <= ~clk10Mhz;
  end

  assign entry = {PADDR[2], 2'b00};        // 32-bit word-aligned address
  assign memwrite = PWRITE & PENABLE & PSEL; // only write in access phase
  assign PREADY = 1'b1;                      // responses never take more than 1 cycle

  // account for subword read/write circuitry
  // -- Note SSD registers are 32 bits no matter what; access them with LW SW.
  assign Din = PWDATA[31:0];
  if (P.XLEN == 64) assign PRDATA = {Dout, Dout};
  else              assign PRDATA = Dout;

  // register access
  always_ff @(posedge PCLK) begin: read_register
    case(entry)
      LEFT_REGISTER:     Dout <= left_segments[6:0];
      RIGHT_REGISTER:    Dout <= right_segments[6:0];
    endcase
  end

  always_ff @(posedge PCLK) begin: write_register
    if (~PRESETn) begin
      left_segments = 'b0;
      right_segments = 'b0;
    end
    else if (memwrite)
      case(entry)
        LEFT_REGISTER:  left_segments <= Din[6:0];
        RIGHT_REGISTER: right_segments <= Din[6:0];
      endcase
  end

  // Seven Segment Display control logic
  // The driver switches the select signal of the SSD (7th bit) at a speed of 10Mhz
  // To turn both displays at the same time.
  assign ssd_signals[7] = toggle;

  always_ff @(posedge clk10Mhz) begin: segments_register
    if (~PRESETn) begin
      ssd_signals[6:0] = 'b0;
      toggle = 'b0;
    end else begin
      toggle <= ~toggle;
      case (toggle)
        1'b0: ssd_signals[6:0] <= left_segments[6:0];
        1'b1: ssd_signals[6:0] <= right_segments[6:0];
      endcase
    end
  end
endmodule

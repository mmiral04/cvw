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
  input  logic [4:0]          PADDR,
  input  logic [P.XLEN-1:0]   PWDATA,
  input  logic [P.XLEN/8-1:0] PSTRB,
  input  logic                PWRITE,
  input  logic                PENABLE,
  output logic [P.XLEN-1:0]   PRDATA,
  output logic                PREADY,
  output logic [7:0]          ssd_segments,
  output logic [7:0]          ssd_select
);

  // register map
  localparam REG0 = 5'h0;
  localparam REG1 = 5'h4;
  localparam REG2 = 5'h8;
  localparam REG3 = 5'hC;
  localparam REG4 = 5'h10;
  localparam REG5 = 5'h14;
  localparam REG6 = 5'h18;
  localparam REG7 = 5'h1C;

  logic       memwrite;
  logic [7:0][7:0] segments;
  logic [4:0] entry;
  logic [31:0] Din, Dout;

  logic [7:0] selected = 8'b11111110;

  // Clock speed is divided to 9KHz
  logic [13:0] clkcounter;
  logic       clk9KHz;

  always_ff @(posedge PCLK) begin: clock_counter
    if (~PRESETn) clkcounter <= 'b0;
    else if (clkcounter == {14{1'b1}}) clkcounter <= 'b0;
    else clkcounter <= clkcounter + 1;
  end

  always_ff @(posedge PCLK) begin: clock_divider
    if (~PRESETn) clk9KHz <= 0;
    else if (clkcounter == {14{1'b1}}) clk9KHz <= ~clk9KHz;
  end

  assign entry = {PADDR[4:2], 2'b00};        // 32-bit word-aligned address
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
      REG0: Dout <= ~segments[0][7:0];
      REG1: Dout <= ~segments[1][7:0];
      REG2: Dout <= ~segments[2][7:0];
      REG3: Dout <= ~segments[3][7:0];
      REG4: Dout <= ~segments[4][7:0];
      REG5: Dout <= ~segments[5][7:0];
      REG6: Dout <= ~segments[6][7:0];
      REG7: Dout <= ~segments[7][7:0];
    endcase
  end

  always_ff @(posedge PCLK) begin: write_register
    if (~PRESETn) begin
      segments[0] <= '1;
      segments[1] <= '1;
      segments[2] <= '1;
      segments[3] <= '1;
      segments[4] <= '1;
      segments[5] <= '1;
      segments[6] <= '1;
      segments[7] <= '1;
    end
    else if (memwrite)
      case(entry)
        REG0: segments[0][7:0] <= ~Din[7:0];
        REG1: segments[1][7:0] <= ~Din[7:0];
        REG2: segments[2][7:0] <= ~Din[7:0];
        REG3: segments[3][7:0] <= ~Din[7:0];
        REG4: segments[4][7:0] <= ~Din[7:0];
        REG5: segments[5][7:0] <= ~Din[7:0];
        REG6: segments[6][7:0] <= ~Din[7:0];
        REG7: segments[7][7:0] <= ~Din[7:0];
      endcase
  end

  // Seven Segment Display control logic
  always_ff @(posedge clk9KHz) begin: shift_select
    if (~PRESETn)
      selected <= 8'b11111110;
    else
      selected <= {selected[6:0], selected[7]};
  end

  assign ssd_select = selected;

  always_ff @(posedge clk9KHz) begin: segments_register
    if (~PRESETn)
      ssd_segments[7:0] = 'b1;
    else begin
      case (selected)
        8'b11111110: ssd_segments[7:0] <= segments[1][7:0];
        8'b11111101: ssd_segments[7:0] <= segments[2][7:0];
        8'b11111011: ssd_segments[7:0] <= segments[3][7:0];
        8'b11110111: ssd_segments[7:0] <= segments[4][7:0];
        8'b11101111: ssd_segments[7:0] <= segments[5][7:0];
        8'b11011111: ssd_segments[7:0] <= segments[6][7:0];
        8'b10111111: ssd_segments[7:0] <= segments[7][7:0];
        8'b01111111: ssd_segments[7:0] <= segments[0][7:0];
        default: ssd_segments = '1;
      endcase
    end
  end
endmodule

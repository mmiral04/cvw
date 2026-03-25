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
  input  logic [3:0]          PADDR,
  input  logic [P.XLEN-1:0]   PWDATA,
  input  logic [P.XLEN/8-1:0] PSTRB,
  input  logic                PWRITE,
  input  logic                PENABLE,
  output logic [P.XLEN-1:0]   PRDATA,
  output logic                PREADY,
  output logic [7:0]          ssd_signals
);

  // register map
  localparam SEGMENTS_REGISTER = 4'h4;
  localparam SELECT_REGISTER = 4'h0;

  logic       memwrite;
  logic [6:0] segments;
  logic       SEL0, SEL1;
  logic [2:0] entry;

  assign entry = {PADDR[3:2], 2'b00};        // 32-bit word-aligned address
  assign memwrite = PWRITE & PENABLE & PSEL; // only write in access phase
  assign PREADY = 1'b1;                      // responses never take more than 1 cycle

  // register access
  always_ff @(posedge PCLK) begin: read_register
    case(entry)
      SEGMENTS_REGISTER: PRDATA <= segments[6:0];
      SELECT_REGISTER:   PRDATA <= 2'd3;
      default: PRDATA <= 2'b10;
    endcase
  end

  always_ff @(posedge PCLK) begin: write_register
    if (~PRESETn) begin
      segments = 'b0;
      SEL0 = 'b0;
      SEL1 = 'b0;
    end
    else if (memwrite)
      case(entry)
        SEGMENTS_REGISTER: segments <= PWDATA[6:0];
        SELECT_REGISTER: begin
          SEL0 <= PWDATA[0];
          SEL1 <= PWDATA[1];
        end
      endcase
  end

  // Seven Segment Display control logic

  // If Display 0 is selected, C must be 0. If Display 1 is selected, C must be 1.
  // If both are selected, output a 0 but turn off all segments
  assign ssd_signals[7] = ~SEL0 & SEL1;
  assign ssd_signals[6:0] = (SEL0 ^ SEL1) ? segments[6:0] : 'b0;
endmodule

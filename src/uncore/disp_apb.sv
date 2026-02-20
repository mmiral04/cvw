///////////////////////////////////////////
// 7seg_apb.sv
//
// Written: mmiral04@ucm.es 19 February 2026
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

module display_apb import cvw::*; #(parameter cvw_t P) (
  input  logic                PCLK, PRESETn,
  input  logic                PSEL,
  input  logic [3:0]          PADDR,
  input  logic [P.XLEN-1:0]   PWDATA,
  input  logic [P.XLEN/8-1:0] PSTRB,
  input  logic                PWRITE,
  input  logic                PENABLE,
  output logic [P.XLEN-1:0]   PRDATA,
  output logic                PREADY,
  output logic [3:0]          leds
);

  // register map
  localparam LED_1 = 4'h0;
  localparam LED_2 = 4'h4;
  localparam LED_3 = 4'h8;
  localparam LED_4 = 4'hC;

  logic       memwrite;
  logic [3:0] led_registers;
  logic [3:0] entry;

  assign leds = led_registers;

  assign entry = {PADDR[3:2], 2'b00};        // 32-bit word-aligned address
  assign memwrite = PWRITE & PENABLE & PSEL; // only write in access phase
  assign PREADY = 1'b1;                      // responses never take more than 1 cycle

  // register access
  always_ff @(posedge PCLK) begin: read_register
    case(entry)
      LED_1: PRDATA <= led_registers[0];
      LED_2: PRDATA <= led_registers[1];
      LED_3: PRDATA <= led_registers[2];
      LED_4: PRDATA <= led_registers[3];
    endcase
  end

  always_ff @(posedge PCLK) begin: write_register
    if (~PRESETn) led_registers <= 4'b0000;
    else if (memwrite)
      case(entry)
        LED_1: led_registers[0] <= PWDATA[0];
        LED_2: led_registers[1] <= PWDATA[0];
        LED_3: led_registers[2] <= PWDATA[0];
        LED_4: led_registers[3] <= PWDATA[0];
      endcase
  end
endmodule

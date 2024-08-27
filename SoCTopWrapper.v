`timescale 1ns / 1ps
`default_nettype none
/***************************************************************************
*
* Module: SoCTop
*
* Author: Christopher Kitras
* Class:  ECEN 620, Section 1, Fall 2022
* Date: 2022-12-10
*
* Description: Verilog wrapper that allows the SoCTop to be used in the IP
*              integrator
*              
*
*
****************************************************************************/

module SoCTopWrapper(
        input wire S_AXIL_ACLK,                                                   // System clock frequency in Hertz
        input wire S_AXIL_ARESETn,
        input wire [31:0] S_AXIL_AWADDR,
        input wire S_AXIL_AWVALID,
        output wire S_AXIL_AWREADY,
        input wire S_AXIL_AWPROT,
        input wire S_AXIL_WVALID,
        output wire S_AXIL_WREADY,
        input wire [31:0] S_AXIL_WDATA,
        input wire [3:0] S_AXIL_WSTRB,
        output wire S_AXIL_BVALID,
        input wire S_AXIL_BREADY,
        output wire [1:0] S_AXIL_BRESP,
        input wire S_AXIL_ARVALID,
        output wire S_AXIL_ARREADY,
        input wire [31:0] S_AXIL_ARADDR,
        input wire S_AXIL_ARPROT,
        output wire S_AXIL_RVALID,
        input wire S_AXIL_RREADY,
        output wire [31:0] S_AXIL_RDATA,
        output wire [1:0] S_AXIL_RRESP,
        /***** BOARD HW *****/
        output wire [7:0] segment,                                             // Controls which segment will be turned on in value display
        output wire [7:0] anode                                                // Controls which digit is selected for write in value display
    );
    
    SoCTop custom_ip(
        .ACLK(S_AXIL_ACLK),                                                   // System clock frequency in Hertz
        .ARESETn(S_AXIL_ARESETn),
        .AWADDR(S_AXIL_AWADDR),
        .AWVALID(S_AXIL_AWVALID),
        .AWREADY(S_AXIL_AWREADY),
        .AWPROT(S_AXIL_AWPROT),
        .WVALID(S_AXIL_WVALID),
        .WREADY(S_AXIL_WREADY),
        .WDATA(S_AXIL_WDATA),
        .WSTRB(S_AXIL_WSTRB),
        .BVALID(S_AXIL_BVALID),
        .BREADY(S_AXIL_BREADY),
        .BRESP(S_AXIL_BRESP),
        .ARVALID(S_AXIL_ARVALID),
        .ARREADY(S_AXIL_ARREADY),
        .ARADDR(S_AXIL_ARADDR),
        .ARPROT(S_AXIL_ARPROT),
        .RVALID(S_AXIL_RVALID),
        .RREADY(S_AXIL_RREADY),
        .RDATA(S_AXIL_RDATA),
        .RRESP(S_AXIL_RRESP),
        /***** BOARD HW *****/
        .segment(segment),                                             // Controls which segment will be turned on in value display
        .anode(anode)                                                // Controls which digit is selected for write in value display
    );
    
endmodule

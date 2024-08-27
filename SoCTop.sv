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
* Description: AXI-Lite slave that handles data in data_to_draw and displays
*              it on the seven segment display.
*              
*
*
****************************************************************************/

module SoCTop
    (
        input wire logic ACLK,                                              // Global clock signal
        input wire logic ARESETn,                                           // Global reset signal, active LOW
        input wire logic [31:0] AWADDR,                                     // Write address
        input wire logic AWVALID,                                           // Write address is valid
        output logic AWREADY,                                               // Write address is ready
        input wire logic AWPROT,                                            // Value to be written is protected
        input wire logic WVALID,                                            // Valid write data is available
        output logic WREADY,                                                // Slave can accept the write data
        input wire logic [31:0] WDATA,                                      // Data to be read into slave
        input wire logic [3:0] WSTRB,                                       // Indicates which byte lanes hold valid data
        output logic BVALID,                                                // The write was valid
        input wire logic BREADY,                                            // Master can accept write response
        output logic [1:0] BRESP,                                           // Status of write transaction
        input wire logic ARVALID,                                           // Valid read address
        output logic ARREADY,                                               // Read address ready
        input wire logic [31:0] ARADDR,                                     // Read address
        input wire logic ARPROT,                                            // Read data is protected
        output logic RVALID,                                                // Signaling req read data
        input wire logic RREADY,                                            // master can accept read data
        output logic [31:0] RDATA,                                          // Data to be read    
        output logic [1:0] RRESP,                                           // Read response
        /***** BOARD HW *****/
        output logic [7:0] segment,                                         // Controls which segment will be turned on in value display
        output logic [7:0] anode                                            // Controls which digit is selected for write in value display
    );

	localparam RESP_OKAY   = 2'b00;

    /*********************** Seven Segment Controller **********************/
    // Draws values passed in on dataIn to the 8 seven segment digits on the
    // Nexys4DDR. digDisp is all 1s to enable all digits for drawing and
    // digPnt is all 0s to turn off all decimal points
    logic [31:0] data_to_draw;                                              // Binary data to be written to the seven segment display

    SevenSegmentController sev_seg (
        .clk(ACLK),
        .reset(~ARESETn),
        .dataIn(data_to_draw),
        .digDisp(8'b11011111),
        .digPnt(8'b00010100),
        .segment(segment),
        .anode(anode)
    );

    typedef enum logic [2:0] {IDLE, AR, R, AW, W, B} StateType;
    StateType nextState, currentState;    
    
    // The data that is to be displayed should either be all zeros if nothing
    // has been loaded, or it should be updated to the data being written
    // by the master when in the W (write) state
    always_ff @(posedge  ACLK) 
    begin
		if (!ARESETn)
			data_to_draw <= 0;
        else
			if (currentState == W) 
                data_to_draw <= WDATA;
	end
    
    /******************************** R/W FSM ******************************/
    // Follows conventions for the AXI4-Lite in reading and writing. Assures
    // all read and write operations are accompanied by the correct amount of
    // bytes sent.
                                       

    // Assigns the current state of the state machine to the next state as 
    // defined by the state machine. Will reset the state machine to the 
    // initial state when `ARESETn' is low
    always_ff @(posedge ACLK)
    begin
        if (!ARESETn)
            currentState <= IDLE;
        else
            currentState <= nextState;
    end
    
    logic awready;

    // States for the FSM of the receiver function as follows:
	// IDLE: State waits for either a read or write event on the AXI bus
	// AR: Read address state. This is when the address that will be read from by the 
    //     master is prepared 
	// R: Data is being read. It is in this state that the data to be read is loaded into
    //    the data_to_draw buffer
	// AW: Write address state. This is when the address that will be written to by the 
    //     master is prepared 
    // W:  Data is being written. It is in this state that the data to be written is loaded into
    //    the data_to_draw buffer
    // B: This state verifies that the write is successful 
    always_comb
    begin

        // FSM variables defaults
        nextState          = currentState;
        BRESP              = RESP_OKAY;
        RRESP              = RESP_OKAY;
        AWREADY            = 1'b0;
        WREADY             = 1'b0;
        BVALID             = 1'b0;
        ARREADY            = 1'b0;
        RDATA              = 0;
        RVALID             = 1'b0;
        case (currentState)
            IDLE:
            begin
                if (AWVALID)
                    nextState = AW;
                else if(ARVALID)
                    nextState = AR;
            end
            
            AR:
            begin
                ARREADY = 1'b1;
                if(ARVALID && ARREADY)
                    nextState = R;
            end
            
            R:
            begin
                RDATA = data_to_draw;
                RVALID  = 1'b1;
                if(RVALID && RREADY)
                    nextState = IDLE;
            end

            AW:
            begin
                AWREADY = 1'b1;
                if (AWVALID && AWREADY)
                    nextState = W;
            end

            W:
            begin
                WREADY = 1'b1;
                if (WVALID && WREADY)
                    nextState = B;
            end

            B:
            begin
                BVALID = 1'b1;
                if (BVALID && BREADY)
                    nextState = IDLE;
            end
        endcase
    end
    
endmodule
`default_nettype wire
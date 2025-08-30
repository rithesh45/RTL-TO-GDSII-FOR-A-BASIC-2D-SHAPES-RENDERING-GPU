// Module: controller
// Description: Finite State Machine (FSM) to control the drawing process in a GPU.
//              Receives a start signal from command_interface, generates a one-cycle
//              trigger pulse to the rasterizer, and sets busy until rasterizer signals
//              completion (r_done). Operates synchronously with clock and asynchronous reset.
// Inputs:
//   - clk: Clock signal for synchronous operation
//   - rst: Active-high asynchronous reset
//   - start: Input from command_interface to initiate drawing
//   - r_done: Input from rasterizer indicating drawing completion
// Outputs:
//   - trigger: One-cycle pulse to start the rasterizer
//   - busy: High when the controller is processing a command, low when idle
// FSM States:
//   - IDLE: Waits for start signal, outputs trigger=0, busy=0
//   - START: Generates one-cycle trigger pulse, sets busy=1
//   - WAIT_DONE: Waits for r_done, keeps busy=1 until done

module controller (
    input wire clk,         // Clock input
    input wire rst,         // Active-high asynchronous reset
    input wire start,       // Start signal from command_interface
    input wire r_done,      // Done signal from rasterizer
    output reg trigger,     // One-cycle pulse to rasterizer
    output reg busy         // Busy signal to indicate processing
);

    // State encoding
    localparam [1:0] IDLE = 2'b00,      // Idle state, waiting for start
                     START = 2'b01,     // Generate trigger pulse
                     WAIT_DONE = 2'b10; // Wait for rasterizer to finish

    reg [1:0] state; // Current FSM state

    // Sequential FSM logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            // Reset to initial state
            state <= IDLE;
            trigger <= 1'b0;
            busy <= 1'b0;
        end else begin
            case (state)
                IDLE: begin
                    if (start) begin
                        // Start received: transition to START, pulse trigger
                        state <= START;
                        trigger <= 1'b1;
                        busy <= 1'b1;
                    end else begin
                        // Stay in IDLE, keep outputs low
                        trigger <= 1'b0;
                        busy <= 1'b0;
                    end
                end
                START: begin
                    // Clear trigger after one cycle, move to WAIT_DONE
                    trigger <= 1'b0;
                    state <= WAIT_DONE;
                end
                WAIT_DONE: begin
                    if (r_done) begin
                        // Rasterizer done: return to IDLE, clear busy
                        state <= IDLE;
                        busy <= 1'b0;
                    end else begin
                        // Stay in WAIT_DONE, keep busy high
                        busy <= 1'b1;
                    end
                end
                default: begin
                    // Safety: return to IDLE (for unused state 2'b11)
                    state <= IDLE;
                    trigger <= 1'b0;
                    busy <= 1'b0;
                end
            endcase
        end
    end

endmodule

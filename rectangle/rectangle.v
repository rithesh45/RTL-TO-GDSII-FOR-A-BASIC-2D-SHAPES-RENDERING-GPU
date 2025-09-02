`timescale 1ns/1ps

module rectangle(
    input  wire        clk,           // Clock input
    input  wire        rst,           // Active-high reset
    input  wire        start,         // Start pulse
    input  wire [7:0]  x0, y0,       // Top-left coordinate
    input  wire [7:0]  x1, y1,       // Bottom-right coordinate
    input  wire        fill_enable,  // Enable filled rectangle
    input  wire [23:0] color,        // 24-bit RGB color
    output reg  [7:0]  px, py,       // Pixel coordinates
    output reg  [23:0] pixel_color,  // Pixel color
    output reg         pixel_valid,   // Pixel valid flag
    output reg         done          // Done signal
);

    reg [7:0] x, y;                  // Current pixel coordinates
    reg [1:0] state;                 // State machine
    localparam IDLE = 2'b00,         // Wait for start
               DRAW = 2'b01,         // Generate pixels
               FINISH = 2'b10;       // Signal completion

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            x <= 0;
            y <= 0;
            px <= 0;
            py <= 0;
            pixel_color <= 0;
            pixel_valid <= 0;
            done <= 0;
            state <= IDLE;
        end else begin
            case (state)
                IDLE: begin
                    px <= 0;
                    py <= 0;
                    pixel_color <= 0;
                    pixel_valid <= 0;
                    done <= 0;
                    if (start) begin
                        x <= x0;
                        y <= y0;
                        state <= DRAW;
                    end
                end
                DRAW: begin
                    // Output current pixel if valid
                    px <= x;
                    py <= y;
                    pixel_color <= color;
                   pixel_valid <= (fill_enable) ? 
               (x >= x0 && x <= x1 && y >= y0 && y <= y1) : 
               ((x == x0 || x == x1 || y == y0 || y == y1) && x >= x0 && x <= x1 && y >= y0 && y <= y1) ? 1 : 0;

                    // Increment for next pixel
                    if (x < x1) begin
                        x <= x + 1;
                    end else begin
                        x <= x0;
                        if (y < y1) begin
                            y <= y + 1;
                        end else begin
                            state <= FINISH;
                        end
                    end
                end
                FINISH: begin
                    px <= 0;
                    py <= 0;
                    pixel_color <= 0;
                    pixel_valid <= 0;
                    done <= 1;
                    state <= IDLE;
                end
                default: state <= IDLE;
            endcase
        end
    end

endmodule

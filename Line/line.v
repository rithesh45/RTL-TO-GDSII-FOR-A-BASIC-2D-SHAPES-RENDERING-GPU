`timescale 1ns/1ps

module line(
    input  wire        clk,
    input  wire        reset,
    input  wire        start,
    input  wire [7:0]  x0, y0,
    input  wire [7:0]  x1, y1,
    input  wire [23:0] color,
    output reg  [7:0]  px, py,
    output reg  [23:0] pixel_color,
    output reg         pixel_valid,
    output reg         done
);
    parameter [1:0] IDLE = 2'b00, INIT_0 = 2'b01, INIT_1 = 2'b10, DRAW = 2'b11;
    reg [1:0] state;

    // Bresenham variables
    reg signed [8:0] dx, dy, err;
    reg signed [8:0] sx, sy;
    reg [7:0] x_end, y_end;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= IDLE;
            pixel_valid <= 0;
            done <= 0;
            px <= 0;
            py <= 0;
            pixel_color <= 0;
            dx <= 0; dy <= 0; err <= 0;
            sx <= 0; sy <= 0;
            x_end <= 0; y_end <= 0;
        end else begin
            case (state)
                IDLE: begin
                    pixel_valid <= 0;
                    done <= 0;
                    if (start) begin
                        state <= INIT_0;
                    end
                end

                INIT_0: begin
                    // set start and end points
                    px <= x0;
                    py <= y0;
                    x_end <= x1;
                    y_end <= y1;
                    // absolute deltas
                    dx <= (x1 > x0) ? (x1 - x0) : (x0 - x1);
                    dy <= (y1 > y0) ? -(y1 - y0) : -(y0 - y1);
                    // step directions
                    sx <= (x0 < x1) ? 1 : -1;
                    sy <= (y0 < y1) ? 1 : -1;
                    state <= INIT_1;
                end

                INIT_1: begin
                    err <= dx + dy;  // initial error
                    pixel_color <= color;
                    pixel_valid <= 1;
                    state <= DRAW;
                end

                DRAW: begin
                    // output current pixel
                    pixel_color <= color;
                    pixel_valid <= 1;

                    if (px == x_end && py == y_end) begin
                        pixel_valid <= 0;
                        done <= 1;
                        state <= IDLE;
                    end else begin
                        // Bresenham step
                        if (2*err >= dy) begin
                            err <= err + dy;
                            px <= px + sx;
                        end
                        else if (2*err <= dx) begin
                            err <= err + dx;
                            py <= py + sy;
                        end
                    end
                end
            endcase
        end
    end
endmodule

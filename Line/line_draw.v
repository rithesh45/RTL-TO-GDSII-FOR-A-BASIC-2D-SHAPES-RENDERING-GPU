`timescale 1ns/1ps

module line_draw (
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
    reg swap;
    reg right;
    reg [7:0] xa, ya, xb, yb;
    reg [7:0] x_end, y_end;
    reg signed [8:0] dx, dy, err;

    wire movx = (2 * err >= dy);
    wire movy = (2 * err <= dx);

    always @(*) begin
        swap = (y0 > y1);
        xa = swap ? x1 : x0;
        xb = swap ? x0 : x1;
        ya = swap ? y1 : y0;
        yb = swap ? y0 : y1;
        right = (xa < xb);
    end

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= IDLE;
            pixel_valid <= 0;
            done <= 0;
            px <= 0;
            py <= 0;
            pixel_color <= 0;
            xa <= 0; ya <= 0;
            xb <= 0; yb <= 0;
            x_end <= 0; y_end <= 0;
            dx <= 0; dy <= 0; err <= 0;
            swap <= 0; right <= 0;
        end else begin
            case (state)
                IDLE: begin
                    pixel_valid <= 0;
                    done <= 0;
                    px <= x0;
                    py <= y0;
                    pixel_color <= 0;
                    if (start) begin
                        state <= INIT_0;
                    end
                end
                INIT_0: begin
                    dx <= right ? $signed(xb - xa) : $signed(xa - xb);
                    dy <= $signed(ya - yb);
                    state <= INIT_1;
                end
                INIT_1: begin
                    err <= dx + dy;
                    px <= xa;
                    py <= ya;
                    x_end <= xb;
                    y_end <= yb;
                    pixel_color <= color;
                    pixel_valid <= 1;
                    state <= DRAW;
                end
                DRAW: begin
                    if (px == x_end && py == y_end) begin
                        pixel_valid <= 0;
                        done <= 1;
                        px <= 0;
                        py <= 0;
                        pixel_color <= 0;
                        state <= IDLE;
                    end else begin
                        pixel_valid <= 1;
                        pixel_color <= color;
                        if (movx) begin
                            px <= right ? px + 1 : px - 1;
                            err <= err + dy;
                        end
                        if (movy) begin
                            py <= py + 1;
                            err <= err + dx;
                        end
                        if (movx && movy) begin
                            px <= right ? px + 1 : px - 1;
                            py <= py + 1;
                            err <= err + dy + dx;
                        end
                    end
                end
            endcase
        end
    end
endmodule


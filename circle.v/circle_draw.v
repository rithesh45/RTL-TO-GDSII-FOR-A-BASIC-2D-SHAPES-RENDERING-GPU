`timescale 1ns/1ps

module circle_draw (
    input wire        clk,
    input wire        rst,
    input wire        start,
    input wire [7:0]  xc, yc,
    input wire [7:0]  r,
    input wire        fill_enable,
    input wire [23:0] color,
    output reg        done,
    output reg        pixel_valid,
    output reg [7:0]  px, py,
    output reg [23:0] pixel_color
);
    localparam [1:0] IDLE = 2'b00, OUTLINE = 2'b01, FILLED = 2'b10, FINISH = 2'b11;
    reg [1:0] state;
    reg signed [8:0] x, y;
    reg signed [15:0] d;
    reg [2:0] octant;
    reg prev_start;
    reg [7:0] cx, cy, x_start, x_end;
    reg [15:0] r2;

    wire start_pulse = start && !prev_start;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            x <= 0; y <= 0; d <= 0; done <= 0; pixel_valid <= 0; octant <= 0;
            px <= 0; py <= 0; pixel_color <= 0; prev_start <= 0; cx <= 0; cy <= 0;
            x_start <= 0; x_end <= 0; r2 <= 0;
        end else begin
            prev_start <= start;
            case (state)
                IDLE: begin
                    pixel_valid <= 0; done <= 0; px <= 0; py <= 0; pixel_color <= 0;
                    x <= 0; y <= 0; d <= 0; octant <= 0; cx <= 0; cy <= 0; x_start <= 0; x_end <= 0; r2 <= 0;
                    if (start_pulse) begin
                        if (r == 0) begin
                            state <= FINISH;
                            done <= 1;
                        end else if (fill_enable) begin
                            state <= FILLED;
                            cy <= yc - r; cx <= xc - r; r2 <= r * r;
                        end else begin
                            state <= OUTLINE;
                            x <= 0; y <= r; d <= 3 - (r << 1);
                            octant <= 0;
                        end
                    end
                end
                OUTLINE: begin
                    pixel_color <= color;
                    pixel_valid <= 1;
                    case (octant)
                        3'd0: begin px <= xc + x[7:0]; py <= yc + y[7:0]; end
                        3'd1: begin px <= xc - x[7:0]; py <= yc + y[7:0]; end
                        3'd2: begin px <= xc + x[7:0]; py <= yc - y[7:0]; end
                        3'd3: begin px <= xc - x[7:0]; py <= yc - y[7:0]; end
                        3'd4: begin px <= xc + y[7:0]; py <= yc + x[7:0]; end
                        3'd5: begin px <= xc - y[7:0]; py <= yc + x[7:0]; end
                        3'd6: begin px <= xc + y[7:0]; py <= yc - x[7:0]; end
                        3'd7: begin px <= xc - y[7:0]; py <= yc - x[7:0]; end
                    endcase

                    if (octant < 7) begin
                        octant <= octant + 1;
                    end else begin
                        octant <= 0;
                        if (x < y) begin
                            x <= x + 1;
                            if (d <= 0) begin
                                d <= d + 4 * x + 6;
                            end else begin
                                y <= y - 1;
                                d <= d + 4 * (x - y) + 10;
                            end
                        end else begin
                            state <= FINISH;
                            done <= 1;
                            pixel_valid <= 0;
                            px <= 0; py <= 0; pixel_color <= 0;
                        end
                    end
                end
                FILLED: begin
                    // Calculate x range for current y
                    x_start <= xc - r;
                    x_end <= xc + r;
                    if (cy <= yc + r) begin
                        if (cx <= x_end) begin
                            if (($signed(cx) - $signed(xc)) * ($signed(cx) - $signed(xc)) + 
                                ($signed(cy) - $signed(yc)) * ($signed(cy) - $signed(yc)) <= $signed(r2)) begin
                                pixel_valid <= 1;
                                pixel_color <= color;
                            end else begin
                                pixel_valid <= 0;
                                pixel_color <= 0;
                            end
                            px <= cx;
                            py <= cy;
                            cx <= cx + 1;
                        end else begin
                            cx <= xc - r;
                            cy <= cy + 1;
                            pixel_valid <= 0;
                        end
                    end else begin
                        state <= FINISH;
                        pixel_valid <= 0;
                        px <= 0; py <= 0; pixel_color <= 0; done <= 1;
                    end
                end
                FINISH: begin
                    done <= 1; pixel_valid <= 0; px <= 0; py <= 0; pixel_color <= 0;
                    x <= 0; y <= 0; d <= 0; octant <= 0; cx <= 0; cy <= 0; x_start <= 0; x_end <= 0; r2 <= 0;
                    state <= IDLE;
                end
            endcase
        end
    end
endmodule

`timescale 1ns/1ps

module rect_draw (
    input wire        clk,
    input wire        rst,
    input wire        start,
    input wire [7:0]  x0, y0,
    input wire [7:0]  x1, y1,
    input wire        fill_enable,
    input wire [23:0] color,
    output reg        done,
    output reg        pixel_valid,
    output reg [7:0]  px, py,
    output reg [23:0] pixel_color
);
    reg [7:0] cx, cy;
    reg drawing;
    reg [1:0] border_state;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            drawing <= 0;
            done <= 0;
            pixel_valid <= 0;
            cx <= 0;
            cy <= 0;
            px <= 0;
            py <= 0;
            pixel_color <= 0;
            border_state <= 0;
        end else if (start && !drawing) begin
            if (x0 == x1 || y0 == y1) begin
                drawing <= 0;
                done <= 1;
                pixel_valid <= 0;
            end else begin
                cx <= x0;
                cy <= y0;
                drawing <= 1;
                done <= 0;
                border_state <= 0;
                pixel_valid <= 0;
            end
        end else if (drawing) begin
            if (fill_enable) begin
                // Filled rectangle (scanline)
                pixel_valid <= 1;
                px <= cx;
                py <= cy;
                pixel_color <= color;

                if (cx < x1) begin
                    cx <= cx + 1;
                end else if (cy < y1) begin
                    cx <= x0;
                    cy <= cy + 1;
                end else begin
                    drawing <= 0;
                    done <= 1;
                end
            end else begin
                // Outline rectangle (4 edges)
                case (border_state)
                    2'b00: begin // Top edge
                        pixel_valid <= 1;
                        px <= cx;
                        py <= cy;
                        pixel_color <= color;

                        if (cx < x1) begin
                            cx <= cx + 1;
                        end else begin
                            cx <= x0;
                            cy <= y1;
                            border_state <= 2'b01;
                        end
                    end
                    2'b01: begin // Bottom edge
                        pixel_valid <= 1;
                        px <= cx;
                        py <= cy;
                        pixel_color <= color;

                        if (cx < x1) begin
                            cx <= cx + 1;
                        end else if (y0 + 1 < y1) begin
                            cx <= x0;
                            cy <= y0 + 1;
                            border_state <= 2'b10;
                        end else begin
                            drawing <= 0;
                            done <= 1;
                        end
                    end
                    2'b10: begin // Left edge
                        pixel_valid <= 1;
                        px <= cx;
                        py <= cy;
                        pixel_color <= color;

                        if (cy < y1 - 1) begin
                            cy <= cy + 1;
                        end else begin
                            cx <= x1;
                            cy <= y0 + 1;
                            border_state <= 2'b11;
                        end
                    end
                    2'b11: begin // Right edge
                        pixel_valid <= 1;
                        px <= cx;
                        py <= cy;
                        pixel_color <= color;

                        if (cy < y1 - 1) begin
                            cy <= cy + 1;
                        end else begin
                            drawing <= 0;
                            done <= 1;
                        end
                    end
                endcase
            end
        end else begin
            pixel_valid <= 0;
            done <= 0;
        end
    end
endmodule

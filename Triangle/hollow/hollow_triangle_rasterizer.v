`timescale 1ns/1ps

module hollow_triangle_rasterizer (
    input wire clk,
    input wire rst,
    input wire start,
    input wire [7:0] x0, y0,
    input wire [7:0] x1, y1,
    input wire [7:0] x2, y2,
    input wire [23:0] color,
    output reg [7:0] px,
    output reg [7:0] py,
    output reg [23:0] pixel_color,
    output reg pixel_valid,
    output reg done
);

    reg [1:0] state; // 0,1,2=edge index; 3=done

    // Line drawing registers
    reg signed [8:0] dx, dy, sx, sy, err;
    reg signed [8:0] e2;
    reg [7:0] cur_x, cur_y;
    reg [7:0] x_start, y_start, x_end, y_end;

    wire [7:0] edge_x0 [2:0];
    wire [7:0] edge_y0 [2:0];
    wire [7:0] edge_x1 [2:0];
    wire [7:0] edge_y1 [2:0];

    assign edge_x0[0] = x0; assign edge_y0[0] = y0;
    assign edge_x1[0] = x1; assign edge_y1[0] = y1;

    assign edge_x0[1] = x1; assign edge_y0[1] = y1;
    assign edge_x1[1] = x2; assign edge_y1[1] = y2;

    assign edge_x0[2] = x2; assign edge_y0[2] = y2;
    assign edge_x1[2] = x0; assign edge_y1[2] = y0;

    reg init_line; // Signal to initialize new line
    reg started; // Line started flag

    // Line initialization logic, synchronous
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            dx <= 0; dy <= 0; sx <= 0; sy <= 0; err <= 0;
            cur_x <= 0; cur_y <= 0;
            x_start <= 0; y_start <= 0;
            x_end <= 0; y_end <= 0;
            init_line <= 0;
            started <= 0;
        end else if (init_line) begin
            x_start <= edge_x0[state];
            y_start <= edge_y0[state];
            x_end <= edge_x1[state];
            y_end <= edge_y1[state];
            dx <= (edge_x0[state] > edge_x1[state]) ? (edge_x0[state] - edge_x1[state]) : (edge_x1[state] - edge_x0[state]);
            dy <= (edge_y0[state] > edge_y1[state]) ? (edge_y0[state] - edge_y1[state]) : (edge_y1[state] - edge_y0[state]);
            sx <= (edge_x0[state] < edge_x1[state]) ? 1 : -1;
            sy <= (edge_y0[state] < edge_y1[state]) ? 1 : -1;
            err <= ((dx > dy) ? dx : -dy) >>> 1; // Signed shift for initial error
            cur_x <= edge_x0[state];
            cur_y <= edge_y0[state];
            started <= 1;
            init_line <= 0;
        end else begin
            started <= started; // Hold
        end
    end

    // Main FSM and pixel generation
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= 0;
            pixel_valid <= 0;
            done <= 0;
            init_line <= 1;
            started <= 0;
        end else begin
            if (start && !done) begin
                if (!started) begin
                    init_line <= 1; // Trigger initialization on new start or new edge
                    pixel_valid <= 0;
                end else begin
                    pixel_color <= color;
                    px <= cur_x;
                    py <= cur_y;
                    pixel_valid <= 1;

                    if ((cur_x == x_end) && (cur_y == y_end)) begin
                        // Current edge is done. Move to next edge or finish
                        pixel_valid <= 1;
                        state <= state + 1;
                        if (state == 2) begin
                            done <= 1;
                            pixel_valid <= 0;
                        end else begin
                            init_line <= 1;
                            started <= 0;
                        end
                    end else begin
                        // Bresenham stepping
                        e2 = err << 1;
                        if (e2 > -dy) begin
                            err <= err - dy;
                            cur_x <= cur_x + sx;
                        end
                        if (e2 < dx) begin
                            err <= err + dx;
                            cur_y <= cur_y + sy;
                        end
                    end
                end
            end else begin
                pixel_valid <= 0;
                done <= 0;
                state <= 0;
                init_line <= 1;
                started <= 0;
            end
        end
    end

endmodule

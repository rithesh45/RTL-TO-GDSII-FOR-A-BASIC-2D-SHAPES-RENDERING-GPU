`timescale 1ns/1ps

module triangle_draw #(
    parameter CORDW=8
) (
    input  wire                 clk,
    input  wire                 rst,
    input  wire                 start,
    input  wire [CORDW-1:0]     x0, y0,   // vertex 0
    input  wire [CORDW-1:0]     x1, y1,   // vertex 1
    input  wire [CORDW-1:0]     x2, y2,   // vertex 2
    input  wire                 fill_enable,
    input  wire [23:0]          color,
    output reg  [CORDW-1:0]     px,       // pixel x
    output reg  [CORDW-1:0]     py,       // pixel y
    output reg  [23:0]          pixel_color,
    output reg                  valid,
    output reg                  done
);

    // FSM states
    localparam IDLE  = 2'b00,
               DRAW  = 2'b01,
               DONE  = 2'b10;

    reg [1:0] state;

    // Bounding box
    reg [CORDW-1:0] xmin, xmax, ymin, ymax;
    reg [CORDW-1:0] cur_x, cur_y;

    // Edge function values
    wire signed [CORDW+CORDW:0] e0, e1, e2;

    assign e0 = (cur_x - x1) * (y2 - y1) - (cur_y - y1) * (x2 - x1);
    assign e1 = (cur_x - x2) * (y0 - y2) - (cur_y - y2) * (x0 - x2);
    assign e2 = (cur_x - x0) * (y1 - y0) - (cur_y - y0) * (x1 - x0);

    // FSM
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state       <= IDLE;
            done        <= 0;
            valid       <= 0;
            cur_x       <= 0;
            cur_y       <= 0;
            px          <= 0;
            py          <= 0;
            pixel_color <= 0;
        end else begin
            case (state)
                IDLE: begin
                    done  <= 0;
                    valid <= 0;
                    if (start) begin
                        // bounding box
                        xmin <= (x0 < x1) ? ((x0 < x2) ? x0 : x2) : ((x1 < x2) ? x1 : x2);
                        xmax <= (x0 > x1) ? ((x0 > x2) ? x0 : x2) : ((x1 > x2) ? x1 : x2);
                        ymin <= (y0 < y1) ? ((y0 < y2) ? y0 : y2) : ((y1 < y2) ? y1 : y2);
                        ymax <= (y0 > y1) ? ((y0 > y2) ? y0 : y2) : ((y1 > y2) ? y1 : y2);

                        cur_x <= (x0 < x1) ? ((x0 < x2) ? x0 : x2) : ((x1 < x2) ? x1 : x2);
                        cur_y <= (y0 < y1) ? ((y0 < y2) ? y0 : y2) : ((y1 < y2) ? y1 : y2);

                        state <= DRAW;
                    end
                end

                DRAW: begin
                    valid <= 0;

                    if (fill_enable) begin
                        // Fill: pixel is inside if all edges same sign
                        if ((e0 >= 0 && e1 >= 0 && e2 >= 0) ||
                            (e0 <= 0 && e1 <= 0 && e2 <= 0)) begin
                            px          <= cur_x;
                            py          <= cur_y;
                            pixel_color <= color;
                            valid       <= 1;
                        end
                    end else begin
                        // Outline: on any edge
                        if (e0 == 0 || e1 == 0 || e2 == 0) begin
                            px          <= cur_x;
                            py          <= cur_y;
                            pixel_color <= color;
                            valid       <= 1;
                        end
                    end

                    // Move to next pixel
                    if (cur_x < xmax) begin
                        cur_x <= cur_x + 1;
                    end else if (cur_y < ymax) begin
                        cur_x <= xmin;
                        cur_y <= cur_y + 1;
                    end else begin
                        state <= DONE;
                    end
                end

                DONE: begin
                    done <= 1;
                    valid <= 0;
                    if (!start) state <= IDLE;
                end
            endcase
        end
    end

endmodule


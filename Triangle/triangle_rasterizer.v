module triangle_rasterizer (
    input wire clk,
    input wire rst,
    input wire start,            // Trigger for new shape
    input wire [7:0] x0, y0,     // Vertex 0 coordinates
    input wire [7:0] x1, y1,     // Vertex 1 coordinates
    input wire [7:0] x2, y2,     // Vertex 2 coordinates
    input wire [23:0] color,     // Color to draw
    output reg [7:0] px, py,     // Pixel coordinates output
    output reg [23:0] pixel_color, // Pixel color output
    output reg pixel_valid,      // Pixel valid strobe
    output reg done              // Done signal
);

    // Compute triangle bounding box (can be pipelined if desired)
    reg [7:0] bbox_xmin, bbox_xmax, bbox_ymin, bbox_ymax;
    reg [7:0] cur_x, cur_y;
    reg active;

    // Edge function coefficients
    reg signed [16:0] edge0_a, edge0_b, edge0_c;
    reg signed [16:0] edge1_a, edge1_b, edge1_c;
    reg signed [16:0] edge2_a, edge2_b, edge2_c;
    reg signed [16:0] w0, w1, w2;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            px <= 0; py <= 0; pixel_valid <= 0;
            done <= 0;
            cur_x <= 0; cur_y <= 0; active <= 0;
        end else begin
            if (start && !active) begin
                // Calculate bounding box
                bbox_xmin <= min3(x0, x1, x2);
                bbox_xmax <= max3(x0, x1, x2);
                bbox_ymin <= min3(y0, y1, y2);
                bbox_ymax <= max3(y0, y1, y2);
                // Calculate edge coefficients
                edge0_a <= y1 - y2; edge0_b <= x2 - x1; edge0_c <= x1 * y2 - x2 * y1;
                edge1_a <= y2 - y0; edge1_b <= x0 - x2; edge1_c <= x2 * y0 - x0 * y2;
                edge2_a <= y0 - y1; edge2_b <= x1 - x0; edge2_c <= x0 * y1 - x1 * y0;
                cur_x <= min3(x0, x1, x2);
                cur_y <= min3(y0, y1, y2);
                active <= 1;
                done <= 0;
            end else if (active) begin
                if (cur_y <= bbox_ymax) begin
                    if (cur_x <= bbox_xmax) begin
                        // Edge function evaluations
                        w0 = edge0_a * cur_x + edge0_b * cur_y + edge0_c;
                        w1 = edge1_a * cur_x + edge1_b * cur_y + edge1_c;
                        w2 = edge2_a * cur_x + edge2_b * cur_y + edge2_c;
                        // Top-left rule ensures no edge misses
                        if (w0 >= 0 && w1 >= 0 && w2 >= 0) begin
                            px <= cur_x;
                            py <= cur_y;
                            pixel_color <= color;
                            pixel_valid <= 1;
                        end else begin
                            pixel_valid <= 0;
                        end
                        cur_x <= cur_x + 1;
                    end else begin
                        cur_x <= bbox_xmin;
                        cur_y <= cur_y + 1;
                    end
                end else begin
                    active <= 0;
                    done <= 1;
                end
            end else begin
                pixel_valid <= 0;
            end
        end
    end

    // Helper functions for min3/max3
    function [7:0] min3;
        input [7:0] a, b, c;
        begin
            min3 = (a < b) ? ((a < c) ? a : c) : ((b < c) ? b : c);
        end
    endfunction
    function [7:0] max3;
        input [7:0] a, b, c;
        begin
            max3 = (a > b) ? ((a > c) ? a : c) : ((b > c) ? b : c);
        end
    endfunction

endmodule
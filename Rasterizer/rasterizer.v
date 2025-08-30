`timescale 1ns/1ps

module rasterizer (
    input  wire        clk,           // Clock input
    input  wire        rst,           // Active-high reset
    input  wire        start,         // Start pulse
    input  wire [1:0]  shape_sel,    // Shape select: 0=line, 1=circle, 2=rect, 3=triangle
    input  wire [7:0]  x0, y0,       // Coordinate 0 (line start, circle center, rect top-left, triangle vertex 1)
    input  wire [7:0]  x1, y1,       // Coordinate 1 (line end, unused, rect bottom-right, triangle vertex 2)
    input  wire [7:0]  x2, y2,       // Coordinate 2 (unused, unused, unused, triangle vertex 3)
    input  wire [7:0]  r,            // Radius (circle only)
    input  wire        fill_enable,  // Fill mode for circle/rect
    input  wire [23:0] color,        // Color input
    output reg  [7:0]  px, py,       // Pixel coordinates
    output reg  [23:0] pixel_color,  // Pixel color
    output reg         pixel_valid,   // Pixel valid flag
    output reg         done          // Done signal
);
    // Shape module wires
    wire [7:0]  line_px, line_py, circle_px, circle_py, rect_px, rect_py, tri_px, tri_py;
    wire [23:0] line_pixel_color, circle_pixel_color, rect_pixel_color, tri_pixel_color;
    wire        line_pixel_valid, circle_pixel_valid, rect_pixel_valid, tri_pixel_valid;
    wire        line_done, circle_done, rect_done, tri_done;
    wire        line_start, circle_start, rect_start, tri_start;
    reg         prev_start;
    reg  [1:0]  state;

    // State machine parameters
    parameter [1:0] IDLE = 2'b00, DRAW = 2'b01, FINISH = 2'b10;

    // Start pulse detection
    wire start_pulse = start && !prev_start;

    // Instantiate shape modules
    line_draw line_inst (
        .clk(clk),
        .reset(rst),
        .start(line_start),
        .x0(x0), .y0(y0),
        .x1(x1), .y1(y1),
        .color(color),
        .px(line_px),
        .py(line_py),
        .pixel_color(line_pixel_color),
        .pixel_valid(line_pixel_valid),
        .done(line_done)
    );

    circle_draw circle_inst (
        .clk(clk),
        .rst(rst),
        .start(circle_start),
        .xc(x0), .yc(y0),
        .r(r),
        .fill_enable(fill_enable),
        .color(color),
        .px(circle_px),
        .py(circle_py),
        .pixel_color(circle_pixel_color),
        .pixel_valid(circle_pixel_valid),
        .done(circle_done)
    );

    rect_draw rect_inst (
        .clk(clk),
        .rst(rst),
        .start(rect_start),
        .x0(x0), .y0(y0),
        .x1(x1), .y1(y1),
        .fill_enable(fill_enable),
        .color(color),
        .px(rect_px),
        .py(rect_py),
        .pixel_color(rect_pixel_color),
        .pixel_valid(rect_pixel_valid),
        .done(rect_done)
    );

    triangle_draw tri_inst (
        .clk(clk),
        .rst(rst),
        .start(tri_start),
        .x0(x0), .y0(y0),
        .x1(x1), .y1(y1),
        .x2(x2), .y2(y2),
        .color(color),
        .pixel_x(tri_px),
        .pixel_y(tri_py),
        .pixel_color(tri_pixel_color),
        .pixel_valid(tri_pixel_valid),
        .done(tri_done)
    );

    // Start signals for each shape
    assign line_start   = (shape_sel == 2'd0) && start_pulse && (state == IDLE);
    assign circle_start = (shape_sel == 2'd1) && start_pulse && (state == IDLE);
    assign rect_start   = (shape_sel == 2'd2) && start_pulse && (state == IDLE);
    assign tri_start    = (shape_sel == 2'd3) && start_pulse && (state == IDLE);

    // State machine and output logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            px <= 0;
            py <= 0;
            pixel_color <= 0;
            pixel_valid <= 0;
            done <= 0;
            prev_start <= 0;
        end else begin
            prev_start <= start;
            case (state)
                IDLE: begin
                    px <= 0;
                    py <= 0;
                    pixel_color <= 0;
                    pixel_valid <= 0;
                    done <= 0;
                    if (start_pulse) begin
                        state <= DRAW;
                    end
                end
                DRAW: begin
                    case (shape_sel)
                        2'd0: begin // Line
                            px <= line_px;
                            py <= line_py;
                            pixel_color <= line_pixel_color;
                            pixel_valid <= line_pixel_valid;
                            done <= line_done;
                            if (line_done) state <= FINISH;
                        end
                        2'd1: begin // Circle
                            px <= circle_px;
                            py <= circle_py;
                            pixel_color <= circle_pixel_color;
                            pixel_valid <= circle_pixel_valid;
                            done <= circle_done;
                            if (circle_done) state <= FINISH;
                        end
                        2'd2: begin // Rectangle
                            px <= rect_px;
                            py <= rect_py;
                            pixel_color <= rect_pixel_color;
                            pixel_valid <= rect_pixel_valid;
                            done <= rect_done;
                            if (rect_done) state <= FINISH;
                        end
                        2'd3: begin // Triangle
                            px <= tri_px;
                            py <= tri_py;
                            pixel_color <= tri_pixel_color;
                            pixel_valid <= tri_pixel_valid;
                            done <= tri_done;
                            if (tri_done) state <= FINISH;
                        end
                    endcase
                end
                FINISH: begin
                    px <= 0;
                    py <= 0;
                    pixel_color <= 0;
                    pixel_valid <= 0;
                    done <= 0;
                    state <= IDLE;
                end
            endcase
        end
    end
endmodule

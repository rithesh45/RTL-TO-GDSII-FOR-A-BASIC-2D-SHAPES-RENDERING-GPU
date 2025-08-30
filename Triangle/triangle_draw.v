`timescale 1ns/1ps

//=====================================================================
// Module: triangle_draw
// Description:
//   This module draws a triangle using its three vertices (x0,y0), 
//   (x1,y1), and (x2,y2). It supports both edge-only drawing (wireframe) 
//   and filled-triangle rendering using scanline filling.
//
// Features:
//   - Accepts start signal to trigger drawing
//   - Outputs pixel coordinates (pixel_x, pixel_y) with pixel_valid flag
//   - Supports edge rendering (using line_draw submodule)
//   - Supports filled rendering (scanline method)
//   - Provides 'done' signal when triangle drawing completes
//
// Dependencies:
//   - Requires "line_draw" module for rasterizing edges
//
//=====================================================================
module triangle_draw (
    input  wire        clk,           // Clock input
    input  wire        rst,           // Active-high synchronous reset
    input  wire        start,         // Start pulse to trigger drawing
    input  wire [7:0]  x0, y0,        // Vertex 1
    input  wire [7:0]  x1, y1,        // Vertex 2
    input  wire [7:0]  x2, y2,        // Vertex 3
    input  wire        fill_enable,   // Enable fill mode (1=filled triangle, 0=wireframe)
    input  wire [23:0] color,         // Color for triangle edges and fill
    output reg         pixel_valid,   // Pixel valid flag (1=output pixel active)
    output reg  [7:0]  pixel_x,       // Pixel x-coordinate
    output reg  [7:0]  pixel_y,       // Pixel y-coordinate
    output reg  [23:0] pixel_color,   // Pixel color
    output reg         done           // Done signal when triangle drawing finishes
);

    //-----------------------------------------------------------------
    // State machine definitions
    //-----------------------------------------------------------------
    parameter IDLE   = 3'd0,   // Waiting for start signal
              EDGE1  = 3'd1,   // Draw edge between (x0,y0) and (x1,y1)
              EDGE2  = 3'd2,   // Draw edge between (x1,y1) and (x2,y2)
              EDGE3  = 3'd3,   // Draw edge between (x2,y2) and (x0,y0)
              FILL   = 3'd4,   // Scanline fill between edges
              FINISH = 3'd5;   // Drawing complete

    reg [2:0] state;           // Current FSM state

    //-----------------------------------------------------------------
    // Line-drawing control signals (for wireframe mode)
    //-----------------------------------------------------------------
    reg line_start;            // Start pulse for line_draw module
    reg [7:0] line_x0, line_y0;
    reg [7:0] line_x1, line_y1;
    wire line_pixel_valid;
    wire [7:0] line_px, line_py;
    wire [23:0] line_pixel_color;
    wire line_done;

    //-----------------------------------------------------------------
    // Scanline filling variables (for fill mode)
    //-----------------------------------------------------------------
    reg [7:0] scan_y, scan_x;          // Current scanline position
    reg [15:0] edge1_dx, edge2_dx;     // Edge slopes in fixed-point
    reg [15:0] edge1_x, edge2_x;       // Current edge x positions
    reg [7:0] min_y, max_y;            // Bounding box y-limits

    //-----------------------------------------------------------------
    // Edge detection for start signal (pulse generation)
    //-----------------------------------------------------------------
    reg prev_start;
    wire start_pulse = start & ~prev_start;

    //-----------------------------------------------------------------
    // Line drawing module instantiation
    //-----------------------------------------------------------------
    line_draw line_inst (
        .clk(clk),
        .reset(rst),
        .start(line_start),
        .x0(line_x0),
        .y0(line_y0),
        .x1(line_x1),
        .y1(line_y1),
        .color(color),
        .px(line_px),
        .py(line_py),
        .pixel_color(line_pixel_color),
        .pixel_valid(line_pixel_valid),
        .done(line_done)
    );

    //-----------------------------------------------------------------
    // Main FSM: Handles triangle drawing process
    //-----------------------------------------------------------------
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            // Reset all registers
            state        <= IDLE;
            pixel_valid  <= 0;
            pixel_x      <= 0;
            pixel_y      <= 0;
            pixel_color  <= 0;
            done         <= 0;
            line_start   <= 0;
            line_x0      <= 0; line_y0 <= 0;
            line_x1      <= 0; line_y1 <= 0;
            prev_start   <= 0;
            scan_y       <= 0; scan_x <= 0;
            edge1_dx     <= 0; edge2_dx <= 0;
            edge1_x      <= 0; edge2_x <= 0;
            min_y        <= 0; max_y   <= 0;

        end else begin
            prev_start <= start;   // Save previous start state
            line_start <= 0;       // Default line start low

            case (state)
                //-----------------------------------------------------
                // IDLE: Wait for start pulse and configure mode
                //-----------------------------------------------------
                IDLE: begin
                    pixel_valid <= 0;
                    pixel_x     <= 0;
                    pixel_y     <= 0;
                    pixel_color <= 0;
                    done        <= 0;

                    if (start_pulse) begin
                        // Check for degenerate triangles (two vertices same)
                        if ((x0 == x1 && y0 == y1) ||
                            (x1 == x2 && y1 == y2) ||
                            (x0 == x2 && y0 == y2)) begin
                            state <= FINISH;   // Nothing to draw
                        end else begin
                            // Compute bounding box for filling
                            min_y <= (y0 <= y1) ? ((y0 <= y2) ? y0 : y2) 
                                                : ((y1 <= y2) ? y1 : y2);
                            max_y <= (y0 >= y1) ? ((y0 >= y2) ? y0 : y2) 
                                                : ((y1 >= y2) ? y1 : y2);

                            if (fill_enable) begin
                                //-----------------------------------------------------
                                // Fill mode: initialize scanline filling
                                //-----------------------------------------------------
                                state   <= FILL;
                                scan_y  <= min_y;
                                edge1_x <= (y0 <= y1) ? x0 : x1;
                                edge2_x <= (y0 <= y2) ? x0 : x2;

                                // Slopes (fixed-point representation with <<8 shift)
                                edge1_dx <= ((y1 > y0) ? ((x1 - x0) << 8) / ((y1 > y0) ? (y1 - y0) : 1) : 0);
                                edge2_dx <= ((y2 > y0) ? ((x2 - x0) << 8) / ((y2 > y0) ? (y2 - y0) : 1) : 0);
                            end else begin
                                //-----------------------------------------------------
                                // Wireframe mode: draw edges sequentially
                                //-----------------------------------------------------
                                line_x0    <= x0;
                                line_y0    <= y0;
                                line_x1    <= x1;
                                line_y1    <= y1;
                                line_start <= 1;
                                state      <= EDGE1;
                            end
                        end
                    end
                end

                //-----------------------------------------------------
                // EDGE1: Draw line (x0,y0) -> (x1,y1)
                //-----------------------------------------------------
                EDGE1: begin
                    if (line_done) begin
                        // Move to next edge
                        line_x0    <= x1;
                        line_y0    <= y1;
                        line_x1    <= x2;
                        line_y1    <= y2;
                        line_start <= 1;
                        state      <= EDGE2;
                    end else begin
                        // Forward line pixels
                        pixel_valid <= line_pixel_valid;
                        pixel_x     <= line_px;
                        pixel_y     <= line_py;
                        pixel_color <= line_pixel_color;
                    end
                end

                //-----------------------------------------------------
                // EDGE2: Draw line (x1,y1) -> (x2,y2)
                //-----------------------------------------------------
                EDGE2: begin
                    if (line_done) begin
                        // Move to next edge
                        line_x0    <= x2;
                        line_y0    <= y2;
                        line_x1    <= x0;
                        line_y1    <= y0;
                        line_start <= 1;
                        state      <= EDGE3;
                    end else begin
                        pixel_valid <= line_pixel_valid;
                        pixel_x     <= line_px;
                        pixel_y     <= line_py;
                        pixel_color <= line_pixel_color;
                    end
                end

                //-----------------------------------------------------
                // EDGE3: Draw line (x2,y2) -> (x0,y0)
                //-----------------------------------------------------
                EDGE3: begin
                    if (line_done) begin
                        state <= FINISH;   // All edges complete
                    end else begin
                        pixel_valid <= line_pixel_valid;
                        pixel_x     <= line_px;
                        pixel_y     <= line_py;
                        pixel_color <= line_pixel_color;
                    end
                end

                //-----------------------------------------------------
                // FILL: Perform scanline filling between edges
                //-----------------------------------------------------
                FILL: begin
                    if (scan_y <= max_y) begin
                        // Fill between edge1_x and edge2_x
                        if (scan_x <= ((edge1_x > edge2_x) ? edge2_x : edge1_x) >> 9 &&
                            scan_x <= 255 && scan_x >= 0) begin
                            pixel_valid <= 1;
                            pixel_color <= color;
                            pixel_x     <= scan_x;
                            pixel_y     <= scan_y;
                            scan_x      <= scan_x + 1;
                        end else begin
                            // Move to next scanline
                            pixel_valid <= 0;
                            scan_x      <= (edge1_x < edge2_x) ? edge1_x : edge2_x >> 9;
                            scan_y      <= scan_y + 1;
                            edge1_x     <= edge1_x + edge1_dx;
                            edge2_x     <= edge2_x + edge2_dx;
                        end
                    end else begin
                        // All scanlines complete
                        state        <= FINISH;
                        pixel_valid  <= 0;
                        pixel_x      <= 0;
                        pixel_y      <= 0;
                        pixel_color  <= 0;
                    end
                end

                //-----------------------------------------------------
                // FINISH: Drawing complete, return to IDLE
                //-----------------------------------------------------
                FINISH: begin
                    pixel_valid <= 0;
                    pixel_x     <= 0;
                    pixel_y     <= 0;
                    pixel_color <= 0;
                    done        <= 1;     // Raise done flag
                    state       <= IDLE;  // Reset FSM
                end
            endcase
        end
    end
endmodule


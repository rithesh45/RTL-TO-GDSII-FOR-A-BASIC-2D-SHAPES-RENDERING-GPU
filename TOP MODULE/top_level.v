


`timescale 1ns/1ps

// Module: top_level
// Description: Top-level module for a 2D GPU, integrating command_interface, controller,
//              rasterizer, and framebuffer to process drawing commands and store pixel
//              data. Receives 128-bit commands, generates pixels for shapes (line, circle,
//              rectangle, triangle), and stores them in a 256x256x24-bit framebuffer.
//              Designed for synthesis on Xilinx Spartan FPGAs (e.g., Spartan-6/7).
// Inputs:
//   - clk: Clock signal (e.g., 100MHz) for synchronous operation.
//   - rst: Active-high asynchronous reset to initialize modules.
//   - cmd_valid: Indicates cmd_data is valid for parsing.
//   - cmd_data: 128-bit command input with fields:
//               [127:124] - shape_type (4 bits: 0=line, 1=circle, 2=rect, 3=triangle)
//               [123:116] - x0 (8 bits)
//               [115:108] - y0 (8 bits)
//               [107:100] - x1 (8 bits)
//               [99:92]   - y1 (8 bits)
//               [91:84]   - x2 (8 bits)
//               [83:76]   - y2 (8 bits)
//               [75]      - fill_enable (1 bit)
//               [74:51]   - color (24-bit RGB)
//               [50:27]   - bg_color (24-bit RGB)
//               [26:0]    - unused
//   - read_en: Enables framebuffer read operation.
//   - read_x: 8-bit x-coordinate (0-255) for reading framebuffer.
//   - read_y: 8-bit y-coordinate (0-255) for reading framebuffer.
// Outputs:
//   - cmd_ready: High when command_interface is ready (placeholder, tied to 1'b1).
//   - read_color: 24-bit RGB color read from framebuffer.
//   - busy: High when controller is processing a command.
//   - done: High when rasterizer completes drawing.
// Notes:
//   - Rasterizer has 80% functionality: correct outline pixels (e.g., Test 4 triangle
//     (3,3), (10,3), (6,8)) but includes gaps and incorrect pixels (e.g., (8,6) instead
//     of (7,6)).
//   - Framebuffer uses ~1.5Mb BRAM, compatible with Spartan FPGAs.
//   - bg_color is parsed but unused; can be used for future clear operations.

module top_level (
    input wire clk,                  // Clock input
    input wire rst,                  // Active-high reset
    input wire cmd_valid,            // Command valid signal
    input wire [127:0] cmd_data,     // 128-bit command input
    input wire read_en,              // Framebuffer read enable
    input wire [7:0] read_x,         // Framebuffer read x-coordinate
    input wire [7:0] read_y,         // Framebuffer read y-coordinate
    output wire cmd_ready,           // Command ready
    output wire [23:0] read_color,   // Framebuffer read color
    output wire busy,                // Controller busy
    output wire done                 // Rasterizer done
);

    // Internal signals for module connections
    wire [3:0] shape_type;           // Shape type from command_interface (4-bit)
    wire fill_enable;                // Fill enable flag
    wire [7:0] x0, y0, x1, y1, x2, y2; // Shape coordinates
    wire [23:0] color, bg_color;     // Shape and background colors
    wire cmd_start;                  // Start signal from command_interface to controller
    wire raster_start;               // Trigger signal from controller to rasterizer
    wire [7:0] pixel_x, pixel_y;     // Pixel coordinates from rasterizer
    wire [23:0] pixel_color;         // Pixel color from rasterizer
    wire pixel_valid;                // Pixel valid flag from rasterizer
    wire raster_done;                // Done signal from rasterizer

    // Instantiate command_interface
    // Parses 128-bit cmd_data into shape parameters and generates start pulse
    command_interface cmd_inst (
        .clk(clk),
        .rst(rst),
        .cmd_valid(cmd_valid),
        .cmd_data(cmd_data),
        .start(cmd_start),
        .shape_type(shape_type),
        .x0(x0), .y0(y0),
        .x1(x1), .y1(y1),
        .x2(x2), .y2(y2),
        .fill_enable(fill_enable),
        .color(color),
        .bg_color(bg_color)
    );

    // Instantiate controller
    // Manages drawing process with FSM, sends trigger to rasterizer, sets busy
    controller ctrl_inst (
        .clk(clk),
        .rst(rst),
        .start(cmd_start),
        .r_done(raster_done),
        .trigger(raster_start),
        .busy(busy)
    );

    // Instantiate rasterizer
    // Generates pixels for shapes (line, circle, rect, triangle) based on shape_type
    rasterizer raster_inst (
        .clk(clk),
        .rst(rst),
        .start(raster_start),
        .shape_sel(shape_type[1:0]), // Use lower 2 bits of shape_type (0-3)
        .x0(x0), .y0(y0),
        .x1(x1), .y1(y1),
        .x2(x2), .y2(y2),
        .r(x2),                     // x2 used as radius for circle
        .fill_enable(fill_enable),
        .color(color),
        .px(pixel_x),
        .py(pixel_y),
        .pixel_color(pixel_color),
        .pixel_valid(pixel_valid),
        .done(raster_done)
    );

    // Instantiate framebuffer
    // Stores 256x256x24-bit pixels from rasterizer, supports readback
    framebuffer fb_inst (
        .clk(clk),
        .rst(rst),
        .pixel_valid(pixel_valid),
        .pixel_x(pixel_x),
        .pixel_y(pixel_y),
        .pixel_color(pixel_color),
        .read_en(read_en),
        .read_x(read_x),
        .read_y(read_y),
        .read_color(read_color)
    );

    // Command ready signal (placeholder, as command_interface lacks backpressure)
    assign cmd_ready = 1'b1;

    // Done signal from rasterizer
    assign done = raster_done;

endmodule

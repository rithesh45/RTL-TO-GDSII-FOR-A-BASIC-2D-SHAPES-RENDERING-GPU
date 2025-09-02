`timescale 1ns/1ps

module gpu_top (
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
    controller ctrl_inst (
        .clk(clk),
        .rst(rst),
        .start(cmd_start),
        .r_done(raster_done),
        .trigger(raster_start),
        .busy(busy)
    );

    // Instantiate rasterizer
    rasterizer raster_inst (
        .clk(clk),
        .rst(rst),
        .start(raster_start),
        .shape_sel(shape_type[1:0]),
        .x0(x0), .y0(y0),
        .x1(x1), .y1(y1),
        .x2(x2), .y2(y2),
        .r(x2),
        .fill_enable(fill_enable),
        .color(color),
        .px(pixel_x),
        .py(pixel_y),
        .pixel_color(pixel_color),
        .pixel_valid(pixel_valid),
        .done(raster_done)
    );

    // Instantiate framebuffer
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

    assign cmd_ready = 1'b1;
    assign done = raster_done;

endmodule

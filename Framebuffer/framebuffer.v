`timescale 1ns/1ps

module framebuffer (
    input wire clk,                  // Clock input
    input wire rst,                  // Active-high reset
    input wire pixel_valid,          // Valid pixel signal
    input wire [7:0] pixel_x,       // X-coordinate (0-255)
    input wire [7:0] pixel_y,       // Y-coordinate (0-255)
    input wire [23:0] pixel_color,  // 24-bit RGB color
    input wire read_en,             // Read enable
    input wire [7:0] read_x,        // Read x-coordinate
    input wire [7:0] read_y,        // Read y-coordinate
    output reg [23:0] read_color    // Output color
);
    reg [23:0] mem [0:65535];       // 256x256 pixel memory
    reg [15:0] addr;                // Address for write
    integer i;

    always @(*) begin
        addr = {pixel_y, pixel_x};  // Write address
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            for (i = 0; i < 65536; i = i + 1) begin
                mem[i] <= 24'h000000;  // Clear to black
            end
            read_color <= 24'h000000;
        end else begin
            if (pixel_valid) begin
                mem[addr] <= pixel_color;  // Write pixel
            end
            read_color <= read_en ? mem[{read_y, read_x}] : 24'h000000;  // Read pixel
        end
    end
endmodule

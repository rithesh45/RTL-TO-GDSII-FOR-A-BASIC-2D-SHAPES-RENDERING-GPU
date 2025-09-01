command_interface.v
```verilog
module command_interface (
    input  wire        clk,          // Clock input
    input  wire        rst,          // Active-high reset
    input  wire        cmd_valid,    // Command valid signal
    input  wire [127:0] cmd_data,    // 128-bit command input
    output reg         start,        // Start signal to controller
    output reg [3:0]   shape_type,   // Shape type (e.g., 1=line, 2=rect)
    output reg [7:0]   x0, y0,       // Coordinates for vertex 0
    output reg [7:0]   x1, y1,       // Coordinates for vertex 1
    output reg [7:0]   x2, y2,       // Coordinates for vertex 2
    output reg         fill_enable,  // Enable filled shape drawing
    output reg [23:0]  color,        // Shape color (RGB)
    output reg [23:0]  bg_color      // Background color (RGB)
);

    // Sequential logic for command parsing
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            // Reset all outputs to default values
            start <= 1'b0;
            shape_type <= 4'b0;
            x0 <= 8'b0;
            y0 <= 8'b0;
            x1 <= 8'b0;
            y1 <= 8'b0;
            x2 <= 8'b0;
            y2 <= 8'b0;
            fill_enable <= 1'b0;
            color <= 24'b0;
            bg_color <= 24'b0;
        end else begin
            if (cmd_valid) begin
                // Parse cmd_data when cmd_valid is high
                start <= 1'b1;                    // Assert start for one cycle
                shape_type <= cmd_data[127:124];  // Extract shape type
                x0 <= cmd_data[123:116];          // Extract x0 coordinate
                y0 <= cmd_data[115:108];          // Extract y0 coordinate
                x1 <= cmd_data[107:100];          // Extract x1 coordinate
                y1 <= cmd_data[99:92];            // Extract y1 coordinate
                x2 <= cmd_data[91:84];            // Extract x2 coordinate
                y2 <= cmd_data[83:76];            // Extract y2 coordinate
                fill_enable <= cmd_data[75];      // Extract fill enable
                color <= cmd_data[74:51];         // Extract shape color
                bg_color <= cmd_data[50:27];      // Extract background color
            end else begin
                // Deassert start when no valid command
                start <= 1'b0;
            end
        end
    end

endmodule
```


controller.v
```verilog
// Module: controller
// Description: Finite State Machine (FSM) to control the drawing process in a GPU.
//              Receives a start signal from command_interface, generates a one-cycle
//              trigger pulse to the rasterizer, and sets busy until rasterizer signals
//              completion (r_done). Operates synchronously with clock and asynchronous reset.
// Inputs:
//   - clk: Clock signal for synchronous operation
//   - rst: Active-high asynchronous reset
//   - start: Input from command_interface to initiate drawing
//   - r_done: Input from rasterizer indicating drawing completion
// Outputs:
//   - trigger: One-cycle pulse to start the rasterizer
//   - busy: High when the controller is processing a command, low when idle
// FSM States:
//   - IDLE: Waits for start signal, outputs trigger=0, busy=0
//   - START: Generates one-cycle trigger pulse, sets busy=1
//   - WAIT_DONE: Waits for r_done, keeps busy=1 until done

module controller (
    input wire clk,         // Clock input
    input wire rst,         // Active-high asynchronous reset
    input wire start,       // Start signal from command_interface
    input wire r_done,      // Done signal from rasterizer
    output reg trigger,     // One-cycle pulse to rasterizer
    output reg busy         // Busy signal to indicate processing
);

    // State encoding
    localparam [1:0] IDLE = 2'b00,      // Idle state, waiting for start
                     START = 2'b01,     // Generate trigger pulse
                     WAIT_DONE = 2'b10; // Wait for rasterizer to finish

    reg [1:0] state; // Current FSM state

    // Sequential FSM logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            // Reset to initial state
            state <= IDLE;
            trigger <= 1'b0;
            busy <= 1'b0;
        end else begin
            case (state)
                IDLE: begin
                    if (start) begin
                        // Start received: transition to START, pulse trigger
                        state <= START;
                        trigger <= 1'b1;
                        busy <= 1'b1;
                    end else begin
                        // Stay in IDLE, keep outputs low
                        trigger <= 1'b0;
                        busy <= 1'b0;
                    end
                end
                START: begin
                    // Clear trigger after one cycle, move to WAIT_DONE
                    trigger <= 1'b0;
                    state <= WAIT_DONE;
                end
                WAIT_DONE: begin
                    if (r_done) begin
                        // Rasterizer done: return to IDLE, clear busy
                        state <= IDLE;
                        busy <= 1'b0;
                    end else begin
                        // Stay in WAIT_DONE, keep busy high
                        busy <= 1'b1;
                    end
                end
                default: begin
                    // Safety: return to IDLE (for unused state 2'b11)
                    state <= IDLE;
                    trigger <= 1'b0;
                    busy <= 1'b0;
                end
            endcase
        end
    end

endmodule

```
rasterizer.v
```verilog
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
    line line_inst (
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

    circle circle_inst (
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

    rectangle rect_inst (
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

    triangle tri_inst (
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
```
rectangle.v
```verilog
`timescale 1ns/1ps

module rectangle (
    input  wire        clk,           // Clock input
    input  wire        rst,           // Active-high reset
    input  wire        start,         // Start pulse
    input  wire [7:0]  x0, y0,       // Top-left coordinate
    input  wire [7:0]  x1, y1,       // Bottom-right coordinate
    input  wire        fill_enable,  // Enable filled rectangle
    input  wire [23:0] color,        // 24-bit RGB color
    output reg  [7:0]  px, py,       // Pixel coordinates
    output reg  [23:0] pixel_color,  // Pixel color
    output reg         pixel_valid,   // Pixel valid flag
    output reg         done          // Done signal
);

    reg [7:0] x, y;                  // Current pixel coordinates
    reg [1:0] state;                 // State machine
    localparam IDLE = 2'b00,         // Wait for start
               DRAW = 2'b01,         // Generate pixels
               FINISH = 2'b10;       // Signal completion

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            x <= 0;
            y <= 0;
            px <= 0;
            py <= 0;
            pixel_color <= 0;
            pixel_valid <= 0;
            done <= 0;
            state <= IDLE;
        end else begin
            case (state)
                IDLE: begin
                    px <= 0;
                    py <= 0;
                    pixel_color <= 0;
                    pixel_valid <= 0;
                    done <= 0;
                    if (start) begin
                        x <= x0;
                        y <= y0;
                        state <= DRAW;
                    end
                end
                DRAW: begin
                    // Output current pixel if valid
                    px <= x;
                    py <= y;
                    pixel_color <= color;
                   pixel_valid <= (fill_enable) ? 
               (x >= x0 && x <= x1 && y >= y0 && y <= y1) : 
               ((x == x0 || x == x1 || y == y0 || y == y1) && x >= x0 && x <= x1 && y >= y0 && y <= y1) ? 1 : 0;

                    // Increment for next pixel
                    if (x < x1) begin
                        x <= x + 1;
                    end else begin
                        x <= x0;
                        if (y < y1) begin
                            y <= y + 1;
                        end else begin
                            state <= FINISH;
                        end
                    end
                end
                FINISH: begin
                    px <= 0;
                    py <= 0;
                    pixel_color <= 0;
                    pixel_valid <= 0;
                    done <= 1;
                    state <= IDLE;
                end
                default: state <= IDLE;
            endcase
        end
    end

endmodule

```
framebuffer.v
```verilog
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
```

gpu_top.v
```verilog
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
```
tb_blink.v
```verilog
`timescale 1ns/1ps

module tb_blink;
    // Testbench signals
    reg clk;
    reg rst;
    reg cmd_valid;
    reg [127:0] cmd_data;
    reg read_en;
    reg [7:0] read_x;
    reg [7:0] read_y;
    wire cmd_ready;
    wire [23:0] read_color;
    wire busy;
    wire done;

    // Cycle counter for timing
    integer cycle_count;

    // Instantiate top_level
    gpu_top dut (
        .clk(clk),
        .rst(rst),
        .cmd_valid(cmd_valid),
        .cmd_data(cmd_data),
        .read_en(read_en),
        .read_x(read_x),
        .read_y(read_y),
        .cmd_ready(cmd_ready),
        .read_color(read_color),
        .busy(busy),
        .done(done)
    );

    // Clock generation (100MHz, 10ns period)
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Test procedure
    initial begin
        // Initialize signals
        cycle_count = 0;
        rst = 1;
        cmd_valid = 0;
        cmd_data = 128'b0;
        read_en = 0;
        read_x = 0;
        read_y = 0;

        // Reset pulse
        #20 rst = 0;

        // Wait a few cycles
        #20;

        // Command 1: Draw yellow face square (6x6 at (10,10) to (15,15))
        cmd_data = {4'd2, 8'd10, 8'd10, 8'd15, 8'd15, 8'd0, 8'd0, 1'b1, 24'hFFFF00, 24'h000000, 27'b0};
        cmd_valid = 1;
        #10 cmd_valid = 0;
        wait (done);
        #50; // Delay for animation visibility

        // Command 2: Draw left green eye pixel (at (12,11))
        cmd_data = {4'd2, 8'd12, 8'd11, 8'd12, 8'd11, 8'd0, 8'd0, 1'b1, 24'h00FF00, 24'h000000, 27'b0};
        cmd_valid = 1;
        #10 cmd_valid = 0;
        wait (done);
        #50;

        // Command 3: Draw right green eye pixel (at (14,11))
        cmd_data = {4'd2, 8'd14, 8'd11, 8'd14, 8'd11, 8'd0, 8'd0, 1'b1, 24'h00FF00, 24'h000000, 27'b0};
        cmd_valid = 1;
        #10 cmd_valid = 0;
        wait (done);
        #50;

        // Command 4: Draw green mouth rectangle (3x1 at (12,14) to (14,14))
        cmd_data = {4'd2, 8'd12, 8'd14, 8'd14, 8'd14, 8'd0, 8'd0, 1'b1, 24'h00FF00, 24'h000000, 27'b0};
        cmd_valid = 1;
        #10 cmd_valid = 0;
        wait (done);
        #50;

        // Command 5: Right eye blink to yellow (at (14,11))
        cmd_data = {4'd2, 8'd14, 8'd11, 8'd14, 8'd11, 8'd0, 8'd0, 1'b1, 24'hFFFF00, 24'h000000, 27'b0};
        cmd_valid = 1;
        #10 cmd_valid = 0;
        wait (done);
        #50;

        // Command 6: Right eye back to green (at (14,11))
        cmd_data = {4'd2, 8'd14, 8'd11, 8'd14, 8'd11, 8'd0, 8'd0, 1'b1, 24'h00FF00, 24'h000000, 27'b0};
        cmd_valid = 1;
        #10 cmd_valid = 0;
        wait (done);
        #50;

        // Read back a pixel to verify (e.g., left eye at (12,11))
        read_en = 1;
        read_x = 12;
        read_y = 11;
        #10;
        $display("Read at (%d,%d): color=%h", read_x, read_y, read_color);
        read_en = 0;

        // Finish simulation
        #100;
        $finish;
    end

    // Log pixel outputs with timestamp to console
    always @(posedge clk) begin
        cycle_count = cycle_count + 1;
        if (dut.raster_inst.pixel_valid) begin
            $display("%d,%d,%d,%d,%h", cycle_count, 
                     dut.raster_inst.px, dut.raster_inst.py, 
                     dut.raster_inst.pixel_valid, dut.raster_inst.pixel_color);
        end
    end

endmodule
```


there are two python scripts that show the image    
1 . <mark>display_gpu.py</mark> = shows directly the end image of the entire process    
2 . <mark>animate_gpu.py</mark> = shows the image being formed pixel by pixel     

display_gpy.py
```python
import numpy as np
import matplotlib.pyplot as plt
import matplotlib.ticker as ticker

# Read pixel data, skipping invalid lines
pixels = []
min_x, min_y, max_x, max_y = float('inf'), float('inf'), float('-inf'), float('-inf')
with open('sim_out.txt', 'r') as f:
    for line in f:
        line = line.strip()
        # Expect format: cycle,x,y,pixel_valid,color
        try:
            cycle, x, y, pixel_valid, color = line.split(',')
            x = int(x)
            y = int(y)
            pixel_valid = int(pixel_valid)
            color = int(color, 16)  # Convert hex color to integer
            if pixel_valid == 1:  # Only store valid pixels
                pixels.append((cycle, x, y, color))
                min_x = min(min_x, x)
                min_y = min(min_y, y)
                max_x = max(max_x, x)
                max_y = max(max_y, y)
        except ValueError:
            continue  # Skip non-numeric or malformed lines

# Create framebuffer with padding, initialized to grey (RGB [128,128,128])
pad = 3
fb_height = max_y - min_y + 1 + 2 * pad
fb_width = max_x - min_x + 1 + 2 * pad
fb = np.full((fb_height, fb_width, 3), 128, dtype=np.uint8)  # Medium grey background

# Apply all valid pixels to framebuffer
for cycle, x, y, color in pixels:
    r = (color >> 16) & 0xFF
    g = (color >> 8) & 0xFF
    b = color & 0xFF
    array_x = x - min_x + pad
    array_y = y - min_y + pad
    fb[array_y, array_x] = [r, g, b]

# Set up plot
fig, ax = plt.subplots()
img = ax.imshow(fb, extent=[min_x - pad, max_x + pad + 1, max_y + pad + 1, min_y - pad])

# Set static axes properties
ax.set_xlabel('X (Framebuffer Column)', fontsize=12, weight='bold', color='white')
ax.set_ylabel('Y (Framebuffer Row)', fontsize=12, weight='bold', color='white')
ax.set_title('GPU Final Shape (Graph Paper Grid)', fontsize=14, weight='bold', color='white')
ax.xaxis.set_major_locator(ticker.MultipleLocator(1))
ax.yaxis.set_major_locator(ticker.MultipleLocator(1))
ax.xaxis.set_minor_locator(ticker.MultipleLocator(0.5))
ax.yaxis.set_minor_locator(ticker.MultipleLocator(0.5))
ax.grid(True, which='major', linestyle='-', color='cyan', linewidth=1.5)  # Cyan major grid
ax.grid(True, which='minor', linestyle=':', color='white', linewidth=0.8)  # White minor grid
ax.set_aspect('equal')

# Draw x=0 and y=0 lines if within extent
if min_x - pad <= 0 <= max_x + pad:
    ax.axvline(x=0, color='yellow', linewidth=2.5, linestyle='--', alpha=0.9)
if min_y - pad <= 0 <= max_y + pad:
    ax.axhline(y=0, color='yellow', linewidth=2.5, linestyle='--', alpha=0.9)

# Customize tick labels
ax.tick_params(axis='both', which='major', labelsize=10, width=1.5, length=6, colors='white')
ax.tick_params(axis='both', which='minor', width=1, length=3, colors='white')

# Set background
fig.set_facecolor('darkgray')
ax.set_facecolor('grey')

plt.show()
```
animate_gpu.py
```python
import numpy as np
import matplotlib.pyplot as plt
import matplotlib.ticker as ticker
from matplotlib.animation import FuncAnimation

# Read pixel data with timestamps, skipping invalid lines
pixels = []
min_x, min_y, max_x, max_y = float('inf'), float('inf'), float('-inf'), float('-inf')
max_cycle = 0
with open('sim_out.txt', 'r') as f:
    for line in f:
        line = line.strip()
        # Expect format: cycle,x,y,pixel_valid,color
        try:
            cycle, x, y, pixel_valid, color = line.split(',')
            cycle = int(cycle)
            x = int(x)
            y = int(y)
            pixel_valid = int(pixel_valid)
            color = int(color, 16)  # Convert hex color to integer
            if pixel_valid == 1:  # Only store valid pixels
                pixels.append((cycle, x, y, color))
                min_x = min(min_x, x)
                min_y = min(min_y, y)
                max_x = max(max_x, x)
                max_y = max(max_y, y)
                max_cycle = max(max_cycle, cycle)
        except ValueError:
            continue  # Skip non-numeric or malformed lines

# Create framebuffer with padding, initialized to grey (RGB [128,128,128])
pad = 3
fb_height = max_y - min_y + 1 + 2 * pad
fb_width = max_x - min_x + 1 + 2 * pad
fb = np.full((fb_height, fb_width, 3), 128, dtype=np.uint8)  # Medium grey background

# Set up plot
fig, ax = plt.subplots()
img = ax.imshow(fb, extent=[min_x - pad, max_x + pad + 1, max_y + pad + 1, min_y - pad])

# Set static axes properties
ax.set_xlabel('X (Framebuffer Column)', fontsize=12, weight='bold', color='white')
ax.set_ylabel('Y (Framebuffer Row)', fontsize=12, weight='bold', color='white')
ax.set_title('GPU Drawing Animation (Graph Paper Grid)', fontsize=14, weight='bold', color='white')
ax.xaxis.set_major_locator(ticker.MultipleLocator(1))
ax.yaxis.set_major_locator(ticker.MultipleLocator(1))
ax.xaxis.set_minor_locator(ticker.MultipleLocator(0.5))
ax.yaxis.set_minor_locator(ticker.MultipleLocator(0.5))
ax.grid(True, which='major', linestyle='-', color='cyan', linewidth=1.5)  # Cyan major grid
ax.grid(True, which='minor', linestyle=':', color='white', linewidth=0.8)  # White minor grid
ax.set_aspect('equal')

# Draw x=0 and y=0 lines if within extent
if min_x - pad <= 0 <= max_x + pad:
    ax.axvline(x=0, color='yellow', linewidth=2.5, linestyle='--', alpha=0.9)
if min_y - pad <= 0 <= max_y + pad:
    ax.axhline(y=0, color='yellow', linewidth=2.5, linestyle='--', alpha=0.9)

# Customize tick labels
ax.tick_params(axis='both', which='major', labelsize=10, width=1.5, length=6, colors='white')
ax.tick_params(axis='both', which='minor', width=1, length=3, colors='white')

# Set background
fig.set_facecolor('darkgray')
ax.set_facecolor('grey')

# Animation update function
def update(cycle):
    # Reset framebuffer to grey
    fb.fill(128)
    # Add pixels up to current cycle
    for c, x, y, color in pixels:
        if c <= cycle:
            r = (color >> 16) & 0xFF
            g = (color >> 8) & 0xFF
            b = color & 0xFF
            array_x = x - min_x + pad
            array_y = y - min_y + pad
            fb[array_y, array_x] = [r, g, b]
    img.set_array(fb)
    print(f"Rendering frame for cycle {cycle}")  # Debug to confirm frame updates
    return [img, ax]  # Return axes to ensure grid/labels persist

# Create animation with blit=False to redraw everything
ani = FuncAnimation(fig, update, frames=range(max_cycle + 1), interval=100, blit=False)
plt.show()
```

`timescale 1ns/1ps

module triangle_raster_tb;

    reg clk;
    reg rst;
    reg start;
    reg [7:0] x0, y0, x1, y1, x2, y2;
    reg [23:0] color;
    wire [7:0] px, py;
    wire [23:0] pixel_color;
    wire pixel_valid;
    wire done;

    // Instantiate rasterizer
    triangle_rasterizer uut (
        .clk(clk),
        .rst(rst),
        .start(start),
        .x0(x0), .y0(y0),
        .x1(x1), .y1(y1),
        .x2(x2), .y2(y2),
        .color(color),
        .px(px),
        .py(py),
        .pixel_color(pixel_color),
        .pixel_valid(pixel_valid),
        .done(done)
    );

    // Clock generation: 10ns period = 100MHz
    initial clk = 0;
    always #5 clk = ~clk;

    initial begin
        // Dump waveform
        $dumpfile("triangle_raster.vcd");
        $dumpvars(0, triangle_raster_tb);

        // Initialize inputs
        rst = 1; start = 0;
        x0 = 0; y0 = 0; x1 = 0; y1 = 0; x2 = 0; y2 = 0; color = 24'hFF0000; // Red color

        // Reset release after 20ns
        #20 rst = 0;

        // Define triangle vertices after reset
        #10;
        x0 = 1; y0 = 7;
        x1 = 3; y1 = 7;
        x2 = 10; y2 = 9;
        start = 1; // Start rasterization

        #10;
        start = 0; // Deassert start after one clock

        // Wait for done signal or timeout
        wait(done);

        // Hold simulation for inspection
        #50;

        $finish;
    end

    // Optional: Monitor pixel outputs on console
    always @(posedge clk) begin
        if(pixel_valid) begin
            $display("Pixel drawn at (%d, %d) Color: %h", px, py, pixel_color);
        end
    end

endmodule

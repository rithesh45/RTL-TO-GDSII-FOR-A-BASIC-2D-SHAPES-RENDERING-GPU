// for two rectangles only
`timescale 1ns/1ps

module tb_rect_draw;

reg        clk;
reg        rst;
reg        start;
reg [7:0]  x0, y0;
reg [7:0]  x1, y1;
reg        fill_enable;
reg [23:0] color;
wire [7:0] px, py;
wire [23:0] pixel_color;
wire       pixel_valid;
wire       done;

// Instantiate the rect_draw module
rect_draw uut (
    .clk(clk),
    .rst(rst),
    .start(start),
    .x0(x0),
    .y0(y0),
    .x1(x1),
    .y1(y1),
    .fill_enable(fill_enable),
    .color(color),
    .px(px),
    .py(py),
    .pixel_color(pixel_color),
    .pixel_valid(pixel_valid),
    .done(done)
);

// Clock generation: 10 time units period
initial clk = 0;
always #5 clk = ~clk;

// Test stimulus
initial begin
    // Initialize VCD dumping
    $dumpfile("rect_draw.vcd");
    $dumpvars(0, tb_rect_draw);

    // Reset
    rst = 1;
    start = 0;
    x0 = 0;
    y0 = 0;
    x1 = 0;
    y1 = 0;
    fill_enable = 0;
    color = 0;
    #20;
    rst = 0;

    // First rectangle: Filled, top-left (10,10), bottom-right (14,12), blue color
    #10;
    x0 = 10;
    y0 = 10;
    x1 = 14;  // 10 + width 5 - 1
    y1 = 12;  // 10 + height 3 - 1
    fill_enable = 1;
    color = 24'h0000FF;  // Blue (RGB)
    start = 1;
    #10;
    start = 0;

    // Wait for first drawing to complete
    wait (done);
    #20;

    // Second rectangle: Filled, top-left (15,15), bottom-right (20,18), red color
    x0 = 15;
    y0 = 13;
    x1 = 19;  
    y1 = 15;  
    fill_enable = 1;
    color = 24'hFF0000;  // Red (RGB)
    start = 1;
    #10;
    start = 0;

    // Wait for second drawing to complete
    wait (done);
    #20;

    // Finish simulation
    $finish;
end

// Output pixel data when pixel_valid is high
always @(posedge clk) begin
    if (pixel_valid) begin
        $display("%d,%d,%b,%h", px, py, pixel_valid, pixel_color);
    end
end

endmodule


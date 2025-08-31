

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

    // First rectangle: Filled, top-left (10,20), bottom-right (14,22), blue color
    #10;
    x0 = 10;
    y0 = 20;
    x1 = 14;  // 10 + width 5 - 1
    y1 = 22;  // 20 + height 3 - 1
    fill_enable = 1;
    color = 24'h0000FF;  // Blue (RGB)
    start = 1;
    #10;
    start = 0;

    // Wait for first drawing to complete
    wait (done);
    #20;

    // Second rectangle: Filled, top-left (15,23), bottom-right (19,25), red color
    x0 = 15;
    y0 = 23;
    x1 = 19;  // 15 + width 5 - 1
    y1 = 25;  // 23 + height 3 - 1
    fill_enable = 1;
    color = 24'hFF0000;  // Red (RGB)
    start = 1;
    #10;
    start = 0;

    // Wait for second drawing to complete
    wait (done);
    #20;

    // Third rectangle: Filled, top-left (21,20), bottom-right (35,25), blue color
    #10;
    x0 = 21;
    y0 = 20;
    x1 = 35;  // 21 + width 15 - 1
    y1 = 25;  // 20 + height 6 - 1
    fill_enable = 1;
    color = 24'h0000FF;  // Blue (RGB)
    start = 1;
    #10;
    start = 0;

    // Wait for third drawing to complete
    wait (done);
    #20;

    // Fourth rectangle: Filled, top-left (21,16), bottom-right (23,18), red color
    #10;
    x0 = 21;
    y0 = 16;
    x1 = 23;  // 21 + width 3 - 1
    y1 = 18;  // 16 + height 3 - 1
    fill_enable = 1;
    color = 24'hFF0000;  // Red (RGB)
    start = 1;
    #10;
    start = 0;

    // Wait for fourth drawing to complete
    wait (done);
    #20;

    // Fifth rectangle: Filled, top-left (25,16), bottom-right (27,18), red color
    #10;
    x0 = 25;
    y0 = 16;
    x1 = 27;  // 25 + width 3 - 1
    y1 = 18;  // 16 + height 3 - 1
    fill_enable = 1;
    color = 24'hFF0000;  // Red (RGB)
    start = 1;
    #10;
    start = 0;

    // Wait for fifth drawing to complete
    wait (done);
    #20;

    // Sixth rectangle: Filled, top-left (29,16), bottom-right (31,18), red color
    #10;
    x0 = 29;
    y0 = 16;
    x1 = 31;  // 29 + width 3 - 1
    y1 = 18;  // 16 + height 3 - 1
    fill_enable = 1;
    color = 24'hFF0000;  // Red (RGB)
    start = 1;
    #10;
    start = 0;

    // Wait for sixth drawing to complete
    wait (done);
    #20;

    // Seventh rectangle: Filled, top-left (33,16), bottom-right (35,18), red color
    #10;
    x0 = 33;
    y0 = 16;
    x1 = 35;  // 33 + width 3 - 1
    y1 = 18;  // 16 + height 3 - 1
    fill_enable = 1;
    color = 24'hFF0000;  // Red (RGB)
    start = 1;
    #10;
    start = 0;

    // Wait for seventh drawing to complete
    wait (done);
    #20;

    // Eighth rectangle: Filled, top-left (21,13), bottom-right (23,14), red color
    #10;
    x0 = 21;
    y0 = 13;
    x1 = 23;  // 21 + width 3 - 1
    y1 = 14;  // 13 + height 2 - 1
    fill_enable = 1;
    color = 24'h0000FF;  // Red (RGB)
    start = 1;
    #10;
    start = 0;

    // Wait for eighth drawing to complete
    wait (done);
    #20;

    // Ninth rectangle: Filled, top-left (25,13), bottom-right (27,14), red color
    #10;
    x0 = 25;
    y0 = 13;
    x1 = 27;  // 25 + width 3 - 1
    y1 = 14;  // 13 + height 2 - 1
    fill_enable = 1;
    color = 24'h0000FF;  // Red (RGB)
    start = 1;
    #10;
    start = 0;

    // Wait for ninth drawing to complete
    wait (done);
    #20;

    // Tenth rectangle: Filled, top-left (29,13), bottom-right (31,14), red color
    #10;
    x0 = 29;
    y0 = 13;
    x1 = 31;  // 29 + width 3 - 1
    y1 = 14;  // 13 + height 2 - 1
    fill_enable = 1;
    color = 24'h0000FF;  // Red (RGB)
    start = 1;
    #10;
    start = 0;

    // Wait for tenth drawing to complete
    wait (done);
    #20;

    // Eleventh rectangle: Filled, top-left (33,13), bottom-right (35,14), red color
    #10;
    x0 = 33;
    y0 = 13;
    x1 = 35;  // 33 + width 3 - 1
    y1 = 14;  // 13 + height 2 - 1
    fill_enable = 1;
    color = 24'h0000FF;  // Red (RGB)
    start = 1;
    #10;
    start = 0;

    // Wait for eleventh drawing to complete
    wait (done);
    #20;
    
     // 12th rectangle: Filled, top-left (33,13), bottom-right (35,14), red color
    #10;
    x0 = 25;
    y0 = 7;
    x1 = 27;  // the og middle finger
    y1 = 11;  // 
    fill_enable = 1;
    color = 24'hFF0000;  // Red (RGB)
    start = 1;
    #10;
    start = 0;

    // Wait for eleventh drawing to complete
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

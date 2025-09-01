`timescale 1ns/1ps

module triangle_draw_tb;

    reg clk;
    reg rst;
    reg start;
    reg [7:0] x0, y0, x1, y1, x2, y2;
    reg fill_enable;
    reg [23:0] color;
    wire [7:0] px, py;
    wire [23:0] pixel_color;
    wire valid;
    wire done;

    // Instantiate DUT
    triangle_draw dut (
        .clk(clk),
        .rst(rst),
        .start(start),
        .x0(x0), .y0(y0),
        .x1(x1), .y1(y1),
        .x2(x2), .y2(y2),
        .fill_enable(fill_enable),
        .color(color),
        .px(px), .py(py),
        .pixel_color(pixel_color),
        .valid(valid),
        .done(done)
    );

    // Clock gen
    always #5 clk = ~clk;

    initial begin
        // Init
        clk = 0;
        rst = 1;
        start = 0;
        fill_enable = 1;  // 1 = filled, 0 = outline
        color = 24'h87CEEB; // Sky Blue
        #20 rst = 0;

        // Triangle vertices (simple right triangle for test)
        x0 = 128; y0 = 10;
        x1 = 20; y1 = 230;
        x2 = 236; y2 = 230;

        #10 start = 1;
        #10 start = 0;

        // Run until done
        wait(done);
        #20;
        $finish;
    end

    // Print pixels
    always @(posedge clk) begin
        if (valid) begin
            $display("px=%0d, py=%0d, color=%h", px, py, pixel_color);
        end
    end

endmodule


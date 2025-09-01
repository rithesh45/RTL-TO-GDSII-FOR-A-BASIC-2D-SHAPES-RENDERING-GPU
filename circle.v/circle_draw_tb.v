`timescale 1ns/1ps

module circle_draw_tb;

    parameter CLK_PERIOD = 10;
    parameter TIMEOUT_CYCLES = 7000; // Timeout limit

    reg        clk;
    reg        rst;
    reg        start;
    reg [7:0]  xc, yc;
    reg [7:0]  r;
    reg        fill_enable;
    reg [23:0] color;
    wire       done;
    wire       pixel_valid;
    wire [7:0] px, py;
    wire [23:0] pixel_color;
    integer cycle_count = 0;

    // Instantiate DUT (only one circle)
    circle_draw dut (
        .clk(clk),
        .rst(rst),
        .start(start),
        .xc(xc),
        .yc(yc),
        .r(r),
        .fill_enable(fill_enable),
        .color(color),
        .done(done),
        .pixel_valid(pixel_valid),
        .px(px),
        .py(py),
        .pixel_color(pixel_color)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end

    // Test stimulus
    initial begin
        $dumpfile("circle_draw_tb.vcd");
        $dumpvars(0, circle_draw_tb);

        // Initialize signals
        rst = 1;
        start = 0;
        xc = 0; yc = 0; r = 0;
        fill_enable = 0;
        color = 24'b0;
        #20;
        rst = 0;
        #10;
        $display("Starting Circle Draw Testbench");

        // Test: One filled circle (center 50,50, r=10, red)
        $display("\nTest: Filled Circle (center 50,50, r=10, red)");
        xc = 224; yc = 32; r = 15; color = 24'h00FF00;
        fill_enable = 1;
        start = 1;
        @(posedge clk);
        #1;
        start = 0;

        // Monitor outputs
        cycle_count = 0;
        while (!done && cycle_count < TIMEOUT_CYCLES) begin
            @(posedge clk);
            #1;
            if (pixel_valid) begin
                $display("Time=%0t: px=%0d, py=%0d, color=%h, valid=%b, done=%b",
                         $time, px, py, pixel_color, pixel_valid, done);
            end
            cycle_count = cycle_count + 1;
        end

        // Check test result
        if (done) begin
            $display("Time=%0t: Last Pixel -> px=%0d, py=%0d, color=%h, valid=%b, done=%b",
                     $time, px, py, pixel_color, pixel_valid, done);
            $display("Test complete!");
        end else begin
            $display("Test failed: Timeout after %0d cycles!", TIMEOUT_CYCLES);
            $finish;
        end
        rst = 1; #10; rst = 0;
        //testcondition-2
        $display("\nTest: Filled Circle (center 50,50, r=10, red)");
        xc = 40; yc = 40; r = 10; color = 24'hFF00FF;
        fill_enable = 1;
        start = 1;
        @(posedge clk);
        #1;
        start = 0;

        // Monitor outputs
        cycle_count = 0;
        while (!done && cycle_count < TIMEOUT_CYCLES) begin
            @(posedge clk);
            #1;
            if (pixel_valid) begin
                $display("Time=%0t: px=%0d, py=%0d, color=%h, valid=%b, done=%b",
                         $time, px, py, pixel_color, pixel_valid, done);
            end
            cycle_count = cycle_count + 1;
        end

        // Check test result
        if (done) begin
            $display("Time=%0t: Last Pixel -> px=%0d, py=%0d, color=%h, valid=%b, done=%b",
                     $time, px, py, pixel_color, pixel_valid, done);
            $display("Test complete!");
        end else begin
            $display("Test failed: Timeout after %0d cycles!", TIMEOUT_CYCLES);
            $finish;
        end
        rst = 1; #10; rst = 0;
        //testcase 3
        $display("\nTest: Filled Circle (center 50,50, r=10, red)");
        xc = 128; yc = 128; r = 40; color = 24'hF5DEB3;
        fill_enable = 1;
        start = 1;
        @(posedge clk);
        #1;
        start = 0;

        // Monitor outputs
        cycle_count = 0;
        while (!done && cycle_count < TIMEOUT_CYCLES) begin
            @(posedge clk);
            #1;
            if (pixel_valid) begin
                $display("Time=%0t: px=%0d, py=%0d, color=%h, valid=%b, done=%b",
                         $time, px, py, pixel_color, pixel_valid, done);
            end
            cycle_count = cycle_count + 1;
        end

        // Check test result
        if (done) begin
            $display("Time=%0t: Last Pixel -> px=%0d, py=%0d, color=%h, valid=%b, done=%b",
                     $time, px, py, pixel_color, pixel_valid, done);
            $display("Test complete!");
        end else begin
            $display("Test failed: Timeout after %0d cycles!", TIMEOUT_CYCLES);
            $finish;
        end
        

        // Finish simulation
        #20;
        $display("Testbench finished!");
        $finish;
    end
endmodule


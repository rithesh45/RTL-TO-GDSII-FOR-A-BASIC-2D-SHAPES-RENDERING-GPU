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

    // Test procedure (only one command)
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
        #20;

        
	// === R ===
// Stem
cmd_data = {4'd2, 8'd20, 8'd20, 8'd30, 8'd100, 8'd0, 8'd0, 1'b1, 24'hFF00FF, 24'h000000, 27'b0};
cmd_valid = 1; #10 cmd_valid = 0; wait(done); #50;
rst = 1; #20; rst = 0; #20;

// Curve (circle)
cmd_data = {4'd1, 8'd45, 8'd40, 8'd24, 8'd0, 8'd0, 8'd0, 1'b0, 24'hFF00FF, 24'h000000, 27'b0};
cmd_valid = 1; #10 cmd_valid = 0; wait(done); #50;
rst = 1; #20; rst = 0; #20;

// Diagonal leg
cmd_data = {4'd0, 8'd30, 8'd60, 8'd60, 8'd100, 8'd0, 8'd0, 1'b1, 24'hFF00FF, 24'h000000, 27'b0};
cmd_valid = 1; #10 cmd_valid = 0; wait(done); #50;
rst = 1; #20; rst = 0; #20;


// === V === (two slanted lines)
cmd_data = {4'd0, 8'd80, 8'd20, 8'd100, 8'd100, 8'd0, 8'd0, 1'b1, 24'hFFFF00, 24'h000000, 27'b0}; 
cmd_valid = 1; #10 cmd_valid = 0; wait(done); #50;

cmd_data = {4'd0, 8'd100, 8'd100, 8'd120, 8'd20, 8'd0, 8'd0, 1'b1, 24'hFFFF00, 24'h000000, 27'b0}; 
cmd_valid = 1; #10 cmd_valid = 0; wait(done); #50;
rst = 1; #20; rst = 0; #20;


// === 3 === (using only lines)
cmd_data = {4'd0, 8'd140, 8'd20, 8'd180, 8'd20, 8'd0, 8'd0, 1'b1, 24'hFFFFFF, 24'h000000, 27'b0}; // Top bar
cmd_valid = 1; #10 cmd_valid = 0; wait(done); #50;

cmd_data = {4'd0, 8'd140, 8'd60, 8'd180, 8'd60, 8'd0, 8'd0, 1'b1, 24'hFFFFFF, 24'h000000, 27'b0}; // Middle bar
cmd_valid = 1; #10 cmd_valid = 0; wait(done); #50;

cmd_data = {4'd0, 8'd140, 8'd100, 8'd180, 8'd100, 8'd0, 8'd0, 1'b1, 24'hFFFFFF, 24'h000000, 27'b0}; // Bottom bar
cmd_valid = 1; #10 cmd_valid = 0; wait(done); #50;

cmd_data = {4'd0, 8'd180, 8'd20, 8'd180, 8'd100, 8'd0, 8'd0, 1'b1, 24'hFFFFFF, 24'h000000, 27'b0}; // Right spine
cmd_valid = 1; #10 cmd_valid = 0; wait(done); #50;







        // Read back a pixel to verify (e.g., top-left of the square at (10,10))
        read_en = 1;
        read_x = 10;
        read_y = 10;
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

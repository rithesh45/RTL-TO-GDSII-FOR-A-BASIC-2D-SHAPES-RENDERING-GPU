`timescale 1ns/1ps

module circle(
    input wire        clk,
    input wire        rst,
    input wire        start,
    input wire [7:0]  xc, yc,
    input wire [7:0]  r,
    input wire        fill_enable,
    input wire [23:0] color,
    output reg        done,
    output reg        pixel_valid,
    output reg [7:0]  px, py,
    output reg [23:0] pixel_color
);
    localparam [1:0] IDLE = 2'b00, OUTLINE = 2'b01, FILLED = 2'b10, FINISH = 2'b11;
    reg [1:0] state;
    reg signed [8:0] x, y;
    reg signed [15:0] d;
    reg [2:0] octant;
    reg prev_start;
    reg [7:0] cy;
    reg [15:0] r2;
    reg [7:0] x_left, x_right;
    reg line_start;

    // Line draw module signals
    wire line_done;
    wire line_pixel_valid;
    wire [7:0] line_px, line_py;
    wire [23:0] line_pixel_color;

    // Instantiate line_draw module
    line line_draw_inst (
        .clk(clk),
        .reset(rst),
        .start(line_start),
        .x0(x_left),
        .y0(cy),
        .x1(x_right),
        .y1(cy),
        .color(color),
        .px(line_px),
        .py(line_py),
        .pixel_color(line_pixel_color),
        .pixel_valid(line_pixel_valid),
        .done(line_done)
    );

    wire start_pulse = start && !prev_start;

    // Function to approximate square root for x-coordinate calculation
    function [7:0] sqrt;
        input [15:0] value;
        reg [15:0] temp;
        reg [15:0] local_value;
        reg [7:0] result;
        integer i;
        begin
            result = 0;
            temp = 0;
            local_value = value; // Avoid modifying input
            for (i = 7; i >= 0; i = i - 1) begin
                temp = (result << (i + 1)) | (1 << (i * 2));
                if (temp <= local_value) begin
                    result = result | (1 << i);
                    local_value = local_value - temp;
                end
            end
            sqrt = result;
        end
    endfunction

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            x <= 0; y <= 0; d <= 0; done <= 0; pixel_valid <= 0; octant <= 0;
            px <= 0; py <= 0; pixel_color <= 0; prev_start <= 0; cy <= 0;
            r2 <= 0; x_left <= 0; x_right <= 0; line_start <= 0;
        end else begin
            prev_start <= start;
            case (state)
                IDLE: begin
                    pixel_valid <= 0; done <= 0; px <= 0; py <= 0; pixel_color <= 0;
                    x <= 0; y <= 0; d <= 0; octant <= 0; cy <= 0; r2 <= 0;
                    x_left <= 0; x_right <= 0; line_start <= 0;
                    if (start_pulse) begin
                        if (r == 0) begin
                            state <= FINISH;
                            done <= 1;
                        end else if (fill_enable) begin
                            state <= FILLED; // Fixed typo: stateTox to state
                            cy <= yc - r;
                            r2 <= r * r;
                        end else begin
                            state <= OUTLINE;
                            x <= 0; y <= r; d <= 3 - (r << 1);
                            octant <= 0;
                        end
                    end
                end
                OUTLINE: begin
                    pixel_color <= color;
                    pixel_valid <= 1;
                    case (octant)
                        3'd0: begin px <= xc + x[7:0]; py <= yc + y[7:0]; end
                        3'd1: begin px <= xc - x[7:0]; py <= yc + y[7:0]; end
                        3'd2: begin px <= xc + x[7:0]; py <= yc - y[7:0]; end
                        3'd3: begin px <= xc - x[7:0]; py <= yc - y[7:0]; end
                        3'd4: begin px <= xc + y[7:0]; py <= yc + x[7:0]; end
                        3'd5: begin px <= xc - y[7:0]; py <= yc + x[7:0]; end
                        3'd6: begin px <= xc + y[7:0]; py <= yc - x[7:0]; end
                        3'd7: begin px <= xc - y[7:0]; py <= yc - x[7:0]; end
                    endcase

                    if (octant < 7) begin
                        octant <= octant + 1;
                    end else begin
                        octant <= 0;
                        if (x < y) begin
                            x <= x + 1;
                            if (d <= 0) begin
                                d <= d + 4 * x + 6;
                            end else begin
                                y <= y - 1;
                                d <= d + 4 * (x - y) + 10;
                            end
                        end else begin
                            state <= FINISH;
                            done <= 1;
                            pixel_valid <= 0;
                            px <= 0; py <= 0; pixel_color <= 0;
                        end
                    end
                end
                FILLED: begin
                    if (cy <= yc + r) begin
                        if (!line_start && !line_pixel_valid && !line_done) begin
                            // Calculate x_left and x_right for current y
                            if (($signed(cy) - $signed(yc)) * ($signed(cy) - $signed(yc)) <= $signed(r2)) begin
                                x_left <= xc - sqrt(r2 - ($signed(cy) - $signed(yc)) * ($signed(cy) - $signed(yc)));
                                x_right <= xc + sqrt(r2 - ($signed(cy) - $signed(yc)) * ($signed(cy) - $signed(yc)));
                                line_start <= 1;
                            end else begin
                                cy <= cy + 1; // Skip if y is outside circle
                            end
                        end else if (line_start) begin
                            line_start <= 0; // Clear start signal after one cycle
                        end else if (line_pixel_valid) begin
                            px <= line_px;
                            py <= line_py;
                            pixel_color <= line_pixel_color;
                            pixel_valid <= 1;
                        end else if (line_done) begin
                            cy <= cy + 1;
                            pixel_valid <= 0;
                        end else begin
                            pixel_valid <= 0;
                        end
                    end else begin
                        state <= FINISH;
                        pixel_valid <= 0;
                        px <= 0; py <= 0; pixel_color <= 0; done <= 1;
                    end
                end
                FINISH: begin
                    done <= 1; pixel_valid <= 0; px <= 0; py <= 0; pixel_color <= 0;
                    x <= 0; y <= 0; d <= 0; octant <= 0; cy <= 0; r2 <= 0;
                    x_left <= 0; x_right <= 0; line_start <= 0;
                    state <= IDLE;
                end
            endcase
        end
    end
endmodule

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

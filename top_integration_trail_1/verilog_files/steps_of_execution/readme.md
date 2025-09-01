
to run the file 
1. step 1 : <mark> iverilog -o simfile command_interface.v controller.v rasterizer.v framebuffer.v gpu_top.v tb_blink.v line.v circle.v rectangle.v triangle.v </mark>
2. step 2 : <mark> vvp simfile > sim_out.txt </mark>
3. step 3 : <mark>python3 animate_gpu.py</mark>  or  <mark>python3 display_gpu.py</mark>

NOTE : make sure all files are in same directory python extensions are installed
  

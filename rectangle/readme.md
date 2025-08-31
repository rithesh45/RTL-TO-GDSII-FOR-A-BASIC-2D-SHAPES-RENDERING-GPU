follow the steps for simulation :

write the verilog and test bench files .  
then make sure you have followed the steps to step up python as mentioned   
then copy the python code    

then type the following commands for simulation   

```code
iverilog -o rectangle_sim rectangle.v tb_rectangle.v
```
this compiles the code and creates the executable file named : <mark>rectangle_sim</mark>   
next
```code
vvp rectangle_sim > sim_out.txt
```
this runs the executable file created , creates the vcd(value code dump) file and writes it into <mark>sim_out.txt</mark> which will be used by python script to generate image
next
```code
python3 visualize_from_out_txt.py
```
A Python script that reads simulation output (e.g., x,y,pixel_on values from sim_out.txt) and plots the results, such as a rectangle, using a library like Matplotlib.





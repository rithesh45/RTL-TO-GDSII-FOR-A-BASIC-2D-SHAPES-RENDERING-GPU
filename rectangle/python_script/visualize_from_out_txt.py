
import numpy as np
import matplotlib.pyplot as plt
import matplotlib.ticker as ticker

# Read pixel data from text file, skipping invalid lines
pixels = []
min_x, min_y, max_x, max_y = float('inf'), float('inf'), float('-inf'), float('-inf')
with open('sim_out.txt', 'r') as f:
    for line in f:
        line = line.strip()
        # Skip lines that don't match x,y,pixel_valid,color format
        try:
            x, y, pixel_valid, color = line.split(',')
            x = int(x)
            y = int(y)
            pixel_valid = int(pixel_valid)
            color = int(color, 16)  # Convert hex color to integer
            if pixel_valid == 1:  # Only plot valid pixels
                pixels.append((x, y, color))
                min_x = min(min_x, x)
                min_y = min(min_y, y)
                max_x = max(max_x, x)
                max_y = max(max_y, y)
        except ValueError:
            continue  # Skip non-numeric or malformed lines (e.g., VCD info)

# Mimic framebuffer: Create RGB array (crop to shape bounds + padding, background black)
pad = 3  # Padding around shape for visibility
fb_height = max_y - min_y + 1 + 2 * pad
fb_width = max_x - min_x + 1 + 2 * pad
fb = np.zeros((fb_height, fb_width, 3), dtype=np.uint8)  # Black background (like framebuffer reset)

for x, y, color in pixels:
    # Convert 24-bit RGB to [R, G, B]
    r = (color >> 16) & 0xFF
    g = (color >> 8) & 0xFF
    b = color & 0xFF
    # Map to array indices (origin top-left, y=0 at top)
    array_x = x - min_x + pad
    array_y = y - min_y + pad
    fb[array_y, array_x] = [r, g, b]

# Display as image with graph paper grid
fig, ax = plt.subplots()
ax.imshow(fb, extent=[min_x - pad, max_x + pad + 1, max_y + pad + 1, min_y - pad])  # Origin top-left, x horizontal, y vertical inverted
ax.set_xlabel('X (Framebuffer Column)')
ax.set_ylabel('Y (Framebuffer Row)')

# Graph paper: Integer ticks and grid
ax.xaxis.set_major_locator(ticker.MultipleLocator(1))
ax.yaxis.set_major_locator(ticker.MultipleLocator(1))
ax.xaxis.set_minor_locator(ticker.MultipleLocator(0.5))  # Finer grid
ax.yaxis.set_minor_locator(ticker.MultipleLocator(0.5))
ax.grid(True, which='major', linestyle='-', color='white', linewidth=0.8)  # Major grid white for contrast on black
ax.grid(True, which='minor', linestyle=':', color='gray', linewidth=0.4)   # Minor dotted gray
ax.set_aspect('equal')  # Square pixels
plt.title('Framebuffer-Like Visualization (Cropped View)')
plt.show()

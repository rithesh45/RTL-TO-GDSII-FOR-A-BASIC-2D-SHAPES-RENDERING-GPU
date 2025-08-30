import matplotlib.pyplot as plt
import re

# Paste your log into a file
filename = "tiv.txt"  # change to your log file

# Regex for parsing
pattern = re.compile(r"Pixel drawn at\s*\(\s*(\d+),\s*(\d+)\)\s*Color:\s*([0-9a-fA-F]+)")

x_coords = []
y_coords = []
colors = []

with open(filename, "r") as f:
    for line in f:
        match = pattern.search(line)
        if match:
            x, y, color = match.groups()
            x_coords.append(int(x))
            y_coords.append(int(y))
            colors.append("#" + color)

# Plot
plt.figure(figsize=(8, 8))
plt.scatter(x_coords, y_coords, c=colors, marker="s", s=50)  # square pixels
plt.gca().invert_yaxis()  # match screen coordinates
plt.gca().set_aspect("equal", adjustable="box")
plt.title("Pixel Shape from Log")
plt.xlabel("X")
plt.ylabel("Y")
plt.show()

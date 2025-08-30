import matplotlib.pyplot as plt
import re

# Input file
filename = "tri_sim.txt"

x_coords = []
y_coords = []

# Regex pattern for your triangle log (no color field here)
pattern = re.compile(r"px=(\d+), py=(\d+), valid=(\d)")

with open(filename, "r") as f:
    for line in f:
        match = pattern.search(line)
        if match:
            px, py, valid = match.groups()
            if valid == "1":  # only collect valid pixels
                x_coords.append(int(px))
                y_coords.append(int(py))

if not x_coords:
    print("⚠️ No valid pixels found in log file. Check the file format or valid flag.")
else:
    plt.figure(figsize=(6, 6))
    plt.scatter(x_coords, y_coords, c="white", edgecolors="black", s=100, marker="s")
    plt.gca().invert_yaxis()

    plt.grid(True, which="both", linestyle="--", linewidth=0.5)
    plt.xticks(range(0, max(x_coords) + 2))
    plt.yticks(range(0, max(y_coords) + 2))
    plt.xlim(0, max(x_coords) + 1)
    plt.ylim(0, max(y_coords) + 1)
    plt.gca().set_aspect("equal", adjustable="box")

    plt.title("Triangle Visualization (from tri_sim.txt)")
    plt.show()

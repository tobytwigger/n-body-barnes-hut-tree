import sys
import matplotlib.pyplot as plt
import mpl_toolkits.mplot3d.axes3d as p3
import matplotlib.animation as animation
from mpl_toolkits.mplot3d import axis3d
import random
import time
import numpy as np
import os
from mpi4py import MPI

import csv

def animation_update_positions(iteration_number, positions, points):
    print(points)
    points._offsets3d = (positions[iteration_number, :, 0], positions[iteration_number, :, 1], positions[iteration_number, :, 2])
    return points

def get_iteration_numbers(file):

    iter_numbers = np.zeros(2, dtype=np.intc)
    with open(file, 'r') as csvfile:
        reader = csv.reader(csvfile, delimiter=',', quotechar='|')
        for row in reader:
            iter_number = int(row[0])
            if iter_number > iter_numbers[0]:
                iter_numbers[0] = iter_number
            if iter_number == 0:
                iter_numbers[1] = iter_numbers[1] + 1
    # Add one to the iteration number to account for indexing starting at 0
    iter_numbers[0] = iter_numbers[0] + 1
    return iter_numbers

plt.ion()
autorun_number = sys.argv[1]
file = './images/auto_run_' + autorun_number + '.csv'

# Read filepause
iter_numbers = get_iteration_numbers(file)
iter_number = iter_numbers[0]
body_number = iter_numbers[1]
positions = np.zeros((iter_number, body_number, 3), dtype=np.float64)
body_ids = np.zeros(iter_number, dtype=np.intc)

with open(file, 'r') as csvfile:
    reader = csv.reader(csvfile, delimiter=',', quotechar='|')
    for row in reader:
        temp_iter_number = int(row[0])
        x_pos = float(row[1])
        y_pos = float(row[2])
        z_pos = float(row[3])
        positions[temp_iter_number][body_ids[temp_iter_number]][0] = x_pos
        positions[temp_iter_number][body_ids[temp_iter_number]][1] = y_pos
        positions[temp_iter_number][body_ids[temp_iter_number]][2] = z_pos
        body_ids[temp_iter_number] = body_ids[temp_iter_number] + 1


# Get Limits
lowerlimits = np.array([np.min(positions[:,:,0]),
np.min(positions[:,:,1]),
np.min(positions[:,:,2])],
dtype=np.float64)

upperlimits = np.array([
np.max(positions[:,:,0]),
np.max(positions[:,:,1]),
np.max(positions[:,:,2])],
dtype=np.float64)


limits = [[lowerlimits[0], upperlimits[0]], [lowerlimits[1], upperlimits[1]], [lowerlimits[2], upperlimits[2]]]

# Attaching 3D axis to the figure
fig = plt.figure()
ax = p3.Axes3D(fig)
points = ax.scatter(positions[0, :, 0], positions[0, :, 1], positions[0, :, 2], marker=".", c='white')

# Setting the axes properties
ax.set_xlim(limits[0])
ax.set_ylim(limits[1])
ax.set_zlim(limits[2])
ax.set_xlabel('X Axis')
ax.set_ylabel('Y Axis')
ax.set_zlabel('Z Axis')
ax.w_xaxis.set_pane_color((0,0,0,1))
ax.w_yaxis.set_pane_color((0,0,0,1))
ax.w_zaxis.set_pane_color((0,0,0,1))
ax.set_facecolor('black')
ax.grid(False)
ax.set_title('3D Test')

# Creating the Animation object
line_ani = animation.FuncAnimation(fig, animation_update_positions, len(positions), fargs=(positions, points),
                                   interval=50, blit=False)

plt.show()


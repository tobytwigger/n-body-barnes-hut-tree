import sys
from bhtree import BHTree
from area import Area
import matplotlib.pyplot as plt
from mpl_toolkits.mplot3d import Axes3D
import random
import time
import os

if int(len(sys.argv)) != 4:
    print("Usage: {} <ITERATIONS> <FOLDER> <dt>".format(sys.argv[0]))
    exit(1)
directory = 'images/{}'.format(sys.argv[2])
if not os.path.exists(directory):
    os.makedirs(directory)



def drawGrid(ax, node):
    for child in node.children:
        if child is not None:

            if not child.parent:
                ax = plotNodeArea(ax, child.area)
            else:
                ax = drawGrid(ax, child)
    return ax

def plotNodeArea(ax, area):
    color = random.choice(['b', 'g', 'r', 'c', 'm', 'y', 'k'])
    # Front Face
    ax.plot([area.min_x, area.max_x], [area.min_y, area.min_y], [area.min_z, area.min_z], color=color)
    ax.plot([area.max_x, area.max_x], [area.min_y, area.min_y], [area.min_z, area.max_z], color=color)
    ax.plot([area.min_x, area.max_x], [area.min_y, area.min_y], [area.max_z, area.max_z], color=color)
    ax.plot([area.min_x, area.min_x], [area.min_y, area.min_y], [area.max_z, area.min_z], color=color)

    #Right face
    ax.plot([area.max_x, area.max_x], [area.min_y, area.max_y], [area.max_z, area.max_z], color=color)
    ax.plot([area.max_x, area.max_x], [area.max_y, area.max_y], [area.min_z, area.max_z], color=color)
    ax.plot([area.max_x, area.max_x], [area.min_y, area.max_y], [area.min_z, area.min_z], color=color)

    #Left Face
    ax.plot([area.min_x, area.min_x], [area.min_y, area.max_y], [area.max_z, area.max_z], color=color)
    ax.plot([area.min_x, area.min_x], [area.max_y, area.max_y], [area.min_z, area.max_z], color=color)
    ax.plot([area.min_x, area.min_x], [area.min_y, area.max_y], [area.min_z, area.min_z], color=color)

    #Back Face
    ax.plot([area.min_x, area.max_x], [area.max_y, area.max_y], [area.max_z, area.max_z], color=color)
    ax.plot([area.min_x, area.max_x], [area.max_y, area.max_y], [area.min_z, area.min_z], color=color)
    return ax


def saveScatterPlot(fig, x, y, z, root_node=None):

    ax = fig.add_subplot(111, projection='3d')
    ax.scatter(x, y, z)
    # sc._offsets3d = (bhtree.bodies.positions[:, 0], bhtree.bodies.positions[:, 1], bhtree.bodies.positions[:, 2])
    if root_node is not None:
        ax = drawGrid(ax, bhtree.root_node)
    ax.set_xlim([min(x), max(x)])
    ax.set_ylim([min(y), max(y)])
    ax.set_zlim([min(z), max(z)])
    plt.savefig('{}/iteration_{}'.format(directory, iter_number), bbox_inches='tight')
    plt.cla()
    plt.clf()



# Create an area to calculate within
area = Area([0,0,0], [9*10**21, 9*10**21, 9*10**21])

# Create a Barnes Hut Tree
bhtree = BHTree()
# Generate all the relevant bodies
bhtree.generate_data(area, 500)

# Populate the tree with the bodies
bhtree.populate()

starttime = time.time()
iter_number = 0
# Iterate through time
fig = plt.figure()
for i in range(int(sys.argv[1])):
    print('Iteration {}'.format(i))
    saveScatterPlot(fig, bhtree.bodies.positions[:, 0], bhtree.bodies.positions[:, 1], bhtree.bodies.positions[:, 2]) # bhtree.root_node)
    iter_number += 1
    print('Complete')
    bhtree.iterate(0.1)

timetaken = time.time()-starttime
print('{} iterations took {}s, or {}s per iteration'.format(iter_number, timetaken, timetaken/iter_number))


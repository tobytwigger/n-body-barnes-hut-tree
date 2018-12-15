from bhtree import BHTree
from area import Area
from bodies import Bodies
import random

# Graphing Imports
import matplotlib.pyplot as plt
from mpl_toolkits.mplot3d import Axes3D


# Create an area to calculate within
area = Area([0,0,0], [9*10**8, 9*10**8, 9*10**8])

# Generate all the relevant bodies
Bodies.gen(area, 500)

# Create a Barnes Hut Tree
bhtree = BHTree()

# Populate the tree with the bodies
bhtree.populate()


fig = plt.figure()
ax = fig.add_subplot(111, projection='3d')
bhtree.iterate(100)

#ax = drawGrid(ax, bhtree.root_node)
vals = Bodies.positions
sc = ax.scatter(vals[:, 0], vals[:, 1], vals[:, 2])






plt.draw()
# exit()
# plt.show()
# bhtree.iterate(100)

# for i in range(Bodies.n):
#     pos = Bodies.get_position(i)
#     forces = Bodies.forces[i]
#     ax.quiver(pos[0], pos[1], pos[2], forces[0], forces[1], forces[2])
# plt.draw()
#
# exit()

for i in range(10):
    plt.pause(1)
    bhtree.iterate(100)
    vals = Bodies.positions

    sc._offsets3d = (vals[:, 0], vals[:, 1], vals[:, 2])
    plt.draw()













def drawGrid(ax, node):
    for child in node.children:
        if child is not None:
            if not child.parent:
                ax = plotNodeArea(ax, child.area)
            else:
                ax = drawGrid(ax, child)
    return ax

def plotNodeArea(ax, area):
    dimens = area.get_dimensions()
    #print(dimens)
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













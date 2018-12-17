
import sys
from bhtree import BHTree
from area cimport Area
import matplotlib.pyplot as plt
from mpl_toolkits.mplot3d import axes3d
import random
import time
import numpy as np





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

def drawForces(ax, bodies):
    x = bodies.positions[:, 0]
    y = bodies.positions[:, 1]
    z = bodies.positions[:, 2]
    u = bodies.forces[:, 0]
    v = bodies.forces[:, 1]
    w = bodies.forces[:, 2]
    arrow_len = bodies.area.get_dimensions()[0]/10
    for i in range(bodies.n):
        ax.quiver(x[i], y[i], z[i], u[i], v[i], w[i])#, length=arrow_len, normalize=True)
    return ax


def saveScatterPlot(fig, x, y, z, directory, iter_number, root_node=None, bodies=None):

    ax = fig.add_subplot(111, projection='3d')
    ax.scatter(x, y, z)
    # sc._offsets3d = (bhtree.bodies.positions[:, 0], bhtree.bodies.positions[:, 1], bhtree.bodies.positions[:, 2])
    if root_node is not None:
        ax = drawGrid(ax, root_node)
    if bodies is not None:
        ax = drawForces(ax, bodies)
    ax.set_xlim([min(x), max(x)])
    ax.set_ylim([min(y), max(y)])
    ax.set_zlim([min(z), max(z)])
    plt.savefig('images/{}/iteration_{}'.format(directory, iter_number), bbox_inches='tight')
    plt.cla()
    plt.clf()


cpdef void main(int iterations, str folder, float dt, float area_side, int num_bodies):

    cdef Area area

    # Create an area to calculate within
    area = Area(np.array([0,0,0], dtype=np.float64), np.array([area_side, area_side, area_side], dtype=np.float64))

    # Create a Barnes Hut Tree
    bhtree = BHTree()
    # Generate all the relevant bodies
    bhtree.generate_data(area, int(num_bodies))

    # Populate the tree with the bodies
    bhtree.populate()

    starttime = time.time()
    iter_number = 0
    # Iterate through time
    fig = plt.figure()
    for i in range(int(iterations)):
        print('Iteration {}'.format(i))
        saveScatterPlot(fig, bhtree.bodies.positions[:, 0], bhtree.bodies.positions[:, 1], bhtree.bodies.positions[:, 2], folder, iter_number)#, None, bhtree.bodies)#, bhtree.root_node)
        iter_number += 1
        print('Complete')
        bhtree.iterate(float(dt))

    timetaken = time.time()-starttime
    print('{} iterations took {}s, or {}s per iteration'.format(iter_number, timetaken, timetaken/iter_number))


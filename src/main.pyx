# cython: profile=True
# cython: linetrace=True

import sys
from src.bhtree import BHTree

from src.area import Area

import matplotlib.pyplot as plt
from mpl_toolkits.mplot3d import axes3d
import random
import time
import numpy as np
cimport numpy as np
import os
from mpi4py import MPI





def drawGrid(ax, node):
    for child in node.children:
        if child is not None:

            if child.parent is 0:
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


def saveScatterPlot(fig, x, y, z, directory, iter_number, rotation=False, root_node=None, bodies=None):
    # print('Saving...')
    comm = MPI.COMM_WORLD
    rank = comm.Get_rank()
    num_p = comm.Get_size()

    ax = fig.add_subplot(111, projection='3d')
    ax.scatter(x, y, z, marker=".", c='white')
    ax.w_xaxis.set_pane_color((0,0,0,1))
    ax.w_yaxis.set_pane_color((0,0,0,1))
    ax.w_zaxis.set_pane_color((0,0,0,1))


    if root_node is not None:
        ax = drawGrid(ax, root_node)
    if bodies is not None:
        ax = drawForces(ax, bodies)


    ax.set_xlim([min(x), max(x)])
    ax.set_ylim([min(y), max(y)])
    ax.set_zlim([min(z), max(z)])
    ax.set_xlabel('X Axis')
    ax.set_ylabel('Y Axis')
    ax.set_zlabel('Z Axis')

    # print('Setup graph')
    if rotation:
        rotations = []

        if rank == 0:
            for azimuth in [0, 120, 240, 360]:
                for elevation in [0, 120, 240, 360]:
                    rotations.append([azimuth, elevation])
            rotations = np.array_split(rotations, num_p)
        # print('Scattering')
        angles=comm.scatter(rotations,root=0)
        # print('Lets go')
        for angle in angles:
            azimuth = angle[0]
            elevation = angle[1]
            # print('Saving {}-{}: iteration {}'.format(azimuth, elevation, iter_number))
            if not os.path.exists('{}/{}-{}'.format(directory, azimuth, elevation)):
                os.mkdir('{}/{}-{}'.format(directory, azimuth, elevation))
            ax.view_init(elevation, azimuth)
            plt.savefig('{}/{}-{}/iteration_{}'.format(directory, azimuth, elevation, iter_number), bbox_inches='tight')
    else:
        if rank == 0:
            plt.savefig('{}/iteration_{}'.format(directory, iter_number), bbox_inches='tight')
    plt.cla()
    plt.clf()
    # print('finish')

def main(iterations, folder, dt, area_side, num_bodies, rotation):
    cdef:
        int i

    comm = MPI.COMM_WORLD
    rank = comm.Get_rank()
    num_p = comm.Get_size()
    # Create an area to calculate within
    area = Area(np.array([0,0,0], dtype=np.float64), np.array([area_side, area_side, area_side], dtype=np.float64))
    # Create a Barnes Hut Tree
    bhtree = BHTree()
    # Generate all the relevant bodies
    if rank == 0:
        bhtree.generate_data(area, int(num_bodies))
    starttime = time.time()

    fig = plt.figure()
    # print('Starting MPI tests:')

    for i in range(int(iterations)):
        bhtree = comm.bcast(bhtree, root=0)
        print('Rank {} broadcasted: {}'.format(rank, time.time()-starttime))
        if rank == 0:
            saveScatterPlot(fig, bhtree.bodies.positions[:, 0], bhtree.bodies.positions[:, 1], bhtree.bodies.positions[:, 2], folder, i, rotation)#, bhtree.root_node, bhtree.bodies)
        if rank == 0:
            iter_start_time = time.time()
            print('Iterating: {}'.format(time.time()-starttime))


        # print('Rank {}: About to iterate'.format(rank))

        bhtree.iterate(float(dt))

        if rank == 0:
            print('Rank {}: Iteration took {}s'.format(rank, time.time()-iter_start_time))
            periteration = ((time.time() - starttime)/(i if i != 0 else 1))
            if i % 25 == 0 and False:
                print('Rank {}: Computed iteration {}'.format(rank, i))
                print('Rank {0:}: ETA: {0:.2f}m ({1:.2f}m passed)'.format(rank, (((iterations - i) * periteration)/ 60 ), ((i * periteration)/ 60 )))
            print('restarting: {}'.format(time.time()-starttime))



    if rank == 0:
        time_taken = time.time()-starttime
        print('{} iterations took {}s per iteration with MPI'.format(iterations, time_taken/iterations))


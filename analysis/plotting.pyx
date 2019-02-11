# cython: profile=True
# cython: linetrace=True

import sys
from src.bhtree import BHTree
from src.bhtree cimport BHTree

from src.node import Node
from src.node cimport Node

import matplotlib.pyplot as plt
import mpl_toolkits.mplot3d.axes3d as p3
import matplotlib.animation as pltanimation
from mpl_toolkits.mplot3d import axis3d
import random
import time
import numpy as np
cimport numpy as np
import os
from mpi4py import MPI

from libc.math cimport floor
import csv


cdef showScatterPlot(fig, x, y, z):
    cdef int tolerance
    ax = fig.add_subplot(111, projection='3d')
    ax.scatter(x, y, z, marker=".", c='white')
    ax.w_xaxis.set_pane_color((0,0,0,1))
    ax.w_yaxis.set_pane_color((0,0,0,1))
    ax.w_zaxis.set_pane_color((0,0,0,1))

    tolerance = int(floor(len(x) * 0.04))
    if tolerance is not 0:
        ax.set_xlim([np.partition(x, tolerance)[tolerance] - 1, np.partition(x, -tolerance)[-tolerance] + 1])
        ax.set_ylim([np.partition(y, tolerance)[tolerance] - 1, np.partition(y, -tolerance)[-tolerance] + 1])
        ax.set_zlim([np.partition(z, tolerance)[tolerance] - 1, np.partition(z, -tolerance)[-tolerance] + 1])
    else:
        ax.set_xlim([min(x) - 1, max(x) + 1])
        ax.set_ylim([min(y) - 1, max(y) + 1])
        ax.set_zlim([min(z) - 1, max(z) + 1])
    ax.set_xlabel('X Axis')
    ax.set_ylabel('Y Axis')
    ax.set_zlabel('Z Axis')

    plt.show()
    plt.cla()
    plt.clf()

# Collect the max from x, y, z and set the x y z limits to these
cdef saveScatterPlot(fig, x, y, z, directory, iter_number, rotation=0, limits=0):
    if limits == 0:
        limits = [[0,1],[0,1][0,1]]
    cdef int tolerance
    ax = fig.add_subplot(111, projection='3d')
    ax.scatter(x, y, z, marker=".", c='white')
    ax.w_xaxis.set_pane_color((0,0,0,1))
    ax.w_yaxis.set_pane_color((0,0,0,1))
    ax.w_zaxis.set_pane_color((0,0,0,1))

    ax.tick_params(axis='x', colors='white')
    ax.tick_params(axis='y', colors='white')
    ax.tick_params(axis='z', colors='white')

    # tolerance = int(floor(len(x) * 0.04))
    # if tolerance is not 0:
    #     ax.set_xlim([np.partition(x, tolerance)[tolerance] - 1, np.partition(x, -tolerance)[-tolerance] + 1])
    #     ax.set_ylim([np.partition(y, tolerance)[tolerance] - 1, np.partition(y, -tolerance)[-tolerance] + 1])
    #     ax.set_zlim([np.partition(z, tolerance)[tolerance] - 1, np.partition(z, -tolerance)[-tolerance] + 1])
    # else:s
    #     ax.set_xlim([min(x) - 1, max(x) + 1])
    #     ax.set_ylim([min(y) - 1, max(y) + 1])
    #     ax.set_zlim([min(z) - 1, max(z) + 1])
    ax.set_xlim(limits[0])
    ax.set_ylim(limits[1])
    ax.set_zlim(limits[2])
    ax.set_xlabel('X Axis')
    ax.set_ylabel('Y Axis')
    ax.set_zlabel('Z Axis')

    ax.set_facecolor('black')

    ax.grid(False)

    # print('Setup graph')
    if rotation is 1:

        for azimuth in [0, 120, 240, 360]:
            for elevation in [0, 120, 240, 360]:
                if not os.path.exists('{}/{}-{}'.format(directory, azimuth, elevation)):
                    os.mkdir('{}/{}-{}'.format(directory, azimuth, elevation))
                ax.view_init(elevation, azimuth)
                plt.savefig('{}/{}-{}/iteration_{}'.format(directory, azimuth, elevation, iter_number), bbox_inches='tight')
    else:
        plt.savefig('{}/iteration_{}'.format(directory, iter_number), bbox_inches='tight')
    plt.cla()
    plt.clf()
    # print('finish')




def get_iteration_numbers(str file):
    cdef:
        int[:] iter_numbers
        int iter_number

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



def gen_all_images(str file, str image_directory, int rotation):
    cdef:
        double[:, :, :] positions
        double[:, :, :] all_positions
        int[:] body_ids
        int iter_number
        int body_number
        int[:] iter_numbers
        int temp_iter_number
        double x_pos, y_pos, z_pos

    comm = MPI.COMM_WORLD
    rank = comm.Get_rank()
    num_p = comm.Get_size()

    iter_numbers = get_iteration_numbers(file)
    iter_number = iter_numbers[0]
    body_number = iter_numbers[1]
    positions = np.zeros((iter_number, body_number, 3), dtype=np.float64)

    if rank == 0:
        rank_iterations = np.array_split(np.arange(iter_number), num_p)
    else:
        rank_iterations = None

    rank_iterations = comm.scatter(rank_iterations, root=0)

    body_ids = np.zeros(iter_number, dtype=np.intc)

    with open(file, 'r') as csvfile:
        reader = csv.reader(csvfile, delimiter=',', quotechar='|')
        for row in reader:
            if int(row[0]) in rank_iterations:
                temp_iter_number = int(row[0])
                x_pos = float(row[1])
                y_pos = float(row[2])
                z_pos = float(row[3])
                positions[temp_iter_number][body_ids[temp_iter_number]][0] = x_pos
                positions[temp_iter_number][body_ids[temp_iter_number]][1] = y_pos
                positions[temp_iter_number][body_ids[temp_iter_number]][2] = z_pos
                body_ids[temp_iter_number] = body_ids[temp_iter_number] + 1

    fig = plt.figure()

    nppositions = np.asarray(positions)

    mylowerlimits = np.array([np.min(nppositions[:,:,0]),
    np.min(nppositions[:,:,1]),
    np.min(nppositions[:,:,2])],
    dtype=np.float64)

    myupperlimits = np.array([
    np.max(nppositions[:,:,0]),
    np.max(nppositions[:,:,1]),
    np.max(nppositions[:,:,2])],
    dtype=np.float64)

    lowerlimits = np.zeros(3)
    upperlimits = np.zeros(3)
    comm.Allreduce(mylowerlimits, lowerlimits, op=MPI.MIN)
    comm.Allreduce(myupperlimits, upperlimits, op=MPI.MAX)

    limits = [[lowerlimits[0], upperlimits[0]], [lowerlimits[1], upperlimits[1]], [lowerlimits[2], upperlimits[2]]]

    for i in range(iter_number):
        if i in rank_iterations:
            # Pass the max from x, y, z here
            saveScatterPlot(fig, positions[i][:, 0], positions[i][:, 1], positions[i][:, 2], image_directory, i, rotation, limits)




def gen_single_axes(str file, int requested_iter_number):
    cdef:
        double[:, :, :] positions
        double[:, :, :] all_positions
        int[:] body_ids
        int iter_number
        int body_number
        int[:] iter_numbers
        int temp_iter_number
        double x_pos, y_pos, z_pos

    comm = MPI.COMM_WORLD
    rank = comm.Get_rank()
    num_p = comm.Get_size()

    iter_numbers = get_iteration_numbers(file)
    iter_number = iter_numbers[0]
    body_number = iter_numbers[1]
    positions = np.zeros((iter_number, body_number, 3), dtype=np.float64)

    if rank == 0:
        rank_iterations = np.array_split(np.arange(iter_number), num_p)
    else:
        rank_iterations = None

    rank_iterations = comm.scatter(rank_iterations, root=0)

    body_ids = np.zeros(iter_number, dtype=np.intc)

    with open(file, 'r') as csvfile:
        reader = csv.reader(csvfile, delimiter=',', quotechar='|')
        for row in reader:
            if int(row[0]) in rank_iterations:
                temp_iter_number = int(row[0])
                x_pos = float(row[1])
                y_pos = float(row[2])
                z_pos = float(row[3])
                positions[temp_iter_number][body_ids[temp_iter_number]][0] = x_pos
                positions[temp_iter_number][body_ids[temp_iter_number]][1] = y_pos
                positions[temp_iter_number][body_ids[temp_iter_number]][2] = z_pos
                body_ids[temp_iter_number] = body_ids[temp_iter_number] + 1

    if requested_iter_number in rank_iterations:
        fig = plt.figure()
        showScatterPlot(fig, positions[requested_iter_number][:, 0], positions[requested_iter_number][:, 1], positions[requested_iter_number][:, 2])

def animation(str file):
    plt.ion()
    comm = MPI.COMM_WORLD
    rank = comm.Get_rank()
    num_p = comm.Get_size()

    if rank == 0:

        # Read file
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
        line_ani = pltanimation.FuncAnimation(fig, animation_update_positions, 1000, fargs=(positions, points),
                                           interval=50, blit=True)

        plt.show()

def animation_update_positions(iteration_number, positions, points):
    print(points)
    points._offsets3d = (positions[iteration_number, :, 0], positions[iteration_number, :, 1], positions[iteration_number, :, 2])
    return points
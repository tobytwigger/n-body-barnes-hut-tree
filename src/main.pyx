# cython: profile=False
# cython: linetrace=False
# cython: cdivision=True
# cython: boundscheck=False
# cython: wraparound=False
# cython: initializedcheck=False

import sys
from src.bhtree import BHTree
from src.bhtree cimport BHTree

from src.galaxy import Galaxy
from src.galaxy cimport Galaxy

from src.node import Node
from src.node cimport Node

import time
import numpy as np
cimport numpy as np

from mpi4py import MPI

import matplotlib.pyplot as plt

import math

import csv


# Save a set of data to the CSV file
def saveCSV(x, y, z, file, iter_number):
    with open(file+'.csv', 'a') as csvfile:
        csvwriter = csv.writer(csvfile, delimiter=',', quotechar='|', quoting=csv.QUOTE_MINIMAL)
        for i in range(len(x)):
            csvwriter.writerow([iter_number, x[i], y[i], z[i]])

# Entrance to main program.
cpdef main(int iterations, str folder, float dt):
    cdef:
        int i
        int rank, num_bodies
        BHTree bhtree
        double[:, :] area
        double[:] star_mass
        double[:, :, :] stars
        Node node

    # Initialise MPI
    comm = MPI.COMM_WORLD
    rank = comm.Get_rank()
    num_p = comm.Get_size()


    # Create a galaxy.
    galaxy = Galaxy()

    # galaxy.spiral()
    galaxy.TomCode()
    # galaxy.four_bodies()

    # Get the data from a galaxy
    area = galaxy.area
    num_bodies = len(galaxy.star_mass)
    stars = galaxy.stars
    star_mass = galaxy.star_mass

    # Create a Barnes-Hut Tree, with a given area
    bhtree = BHTree(area)

    # Share the galaxy data between nodes
    comm.Bcast(stars, root=0)
    comm.Bcast(star_mass, root=0)
    bhtree.stars = stars
    bhtree.star_mass = star_mass
    bhtree.sf = np.max(bhtree.area[1]) * 0.58 * len(bhtree.stars) ** (-0.26)


    # Save the iteration times and the start time
    iteration_times = np.zeros((iterations, 3))
    # Iterate through each iteration requested
    for i in range(iterations):

        # Populate the Barnes Hut Tree
        if i % 2 == 0:
            bhtree.populate()
        # iteration_times[i][0] = time.time() - populate_time

        # Save the data in the CSV
        if rank == 0:
            saveCSV(bhtree.stars[:, 0, 0], bhtree.stars[:, 0, 1], bhtree.stars[:, 0, 2], folder, i)
        comm.Barrier()

        # Calculate the energy
        # E = 0
        # for j in range(len(bhtree.stars)):
        #     E += (0.5 * bhtree.star_mass[j] * math.sqrt(math.pow(bhtree.stars[j][1][0], 2.) + math.pow(bhtree.stars[j][1][1], 2.) + math.pow(bhtree.stars[j][1][2], 2.)))
        # print('Total energy: {}'.format(E))

        # Iterate the system in time
        # iteration_time = time.time()
        bhtree.iterate(dt)
        # iteration_times[i][2] = time.time() - iteration_time
        # if rank == 0:
        #     print('Iteration {} of {} complete'.format(i, iterations))
    # print('Rank {}: populating took {:.8f}s and iterating {:.8f}s'.format( rank, np.average(iteration_times[:, 0]), np.average(iteration_times[:, 2])))
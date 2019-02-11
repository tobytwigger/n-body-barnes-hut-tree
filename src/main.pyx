# cython: profile=True
# cython: linetrace=True

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

import csv


# Save a set of data to the CSV file
def saveCSV(x, y, z, file, iter_number):
    with open(file+'.csv', 'a') as csvfile:
        csvwriter = csv.writer(csvfile, delimiter=',', quotechar='|', quoting=csv.QUOTE_MINIMAL)
        for i in range(len(x)):
            csvwriter.writerow([iter_number, x[i], y[i], z[i]])

# Entrance to main program.
cpdef main(int iterations, str folder, float dt, int rotation):
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

    # Save the iteration times and the start time
    iteration_times = np.zeros((iterations, 3))

    # Iterate through each iteration requested
    for i in range(iterations):

        # Populate the Barnes Hut Tree
        populate_time = time.time()
        bhtree.populate()
        iteration_times[i][0] = time.time() - populate_time

        # Save the data in the CSV
        if rank == 0:
            save_time = time.time()
            saveCSV(bhtree.stars[:, 0, 0], bhtree.stars[:, 0, 1], bhtree.stars[:, 0, 2], folder, i)
            iteration_times[i][1] = time.time() - save_time
        comm.Barrier()

        # Iterate the system in time
        iteration_time = time.time()
        bhtree.iterate(dt)
        iteration_times[i][2] = time.time() - iteration_time
        print('Iteration {} of {} complete'.format(i, iterations))
    if rank == 0:
        print('Rank {}: populating took {:.4f}s, saving {:.4f}s and iterating {:.4f}s'.format( rank, np.average(iteration_times[:, 0]), np.average(iteration_times[:, 1]), np.average(iteration_times[:, 2])))
    #     fig = plt.figure()
    #     plt.plot(times[:, 0], label='Populating Time')
    #     plt.plot(times[:, 1], label='Iterating Time')
    #     plt.legend(loc='upper left')
    #
    #     plt.ylabel('Time for one iteration')
    #     plt.xlabel('Iteration Number')
    #     plt.show()
    #
    #     if rank == 0 and  i % 5 == 0:
    #         periteration = ((time.time() - process_start_time)/(i if i != 0 else 1))
    #         print('Computed iteration {}. ETA: {:.2f}m ({:.2f}m passed)'.format(i, ((iterations - i) * periteration), (i * periteration) ))
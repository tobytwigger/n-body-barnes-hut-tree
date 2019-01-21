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

import matplotlib.pyplot as plt

import csv


# Append the x, y, z, iter_number to the csv file, or create a csv file if not found
def saveCSV(x, y, z, file, iter_number):
    with open(file+'.csv', 'a') as csvfile:
        csvwriter = csv.writer(csvfile, delimiter=',', quotechar='|', quoting=csv.QUOTE_MINIMAL)
        for i in range(len(x)):
            csvwriter.writerow([iter_number, x[i], y[i], z[i]])

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


    # Create a galaxy. For now, all threads are creating a different galaxy. The other threads are overwritten at the start of the iteration
    galaxy = Galaxy()
    # galaxy.spiral()
    # galaxy.illustris()
    galaxy.TomCode()

    area = galaxy.area
    num_bodies = len(galaxy.star_mass)
    stars = galaxy.stars
    star_mass = galaxy.star_mass
    # Create a BHTree
    bhtree = BHTree(area)

    comm.Bcast(stars, root=0)
    comm.Bcast(star_mass, root=0)
    bhtree.stars = stars
    bhtree.star_mass = star_mass

    times = np.zeros((iterations, 2))
    process_start_time = time.time()
    for i in range(iterations):

        time1 = time.time()
        bhtree.populate()
        times[i][0] = time.time() - time1

        if rank == 0:
            saveCSV(bhtree.stars[:, 0, 0], bhtree.stars[:, 0, 1], bhtree.stars[:, 0, 2], folder, i)
        comm.Barrier()


        time1 = time.time()
        bhtree.iterate(dt)
        times[i][1] = time.time() - time1

        if rank == 0 and  i % 5 == 0:
            periteration = ((time.time() - process_start_time)/(i if i != 0 else 1))
            print('Computed iteration {}. ETA: {:.2f}m ({:.2f}m passed)'.format(i, (((iterations - i) * periteration)/ 60 ), ((i * periteration)/ 60 )))

    # if rank == 0:
    #     print('Rank {}: populating took {:.4f}s and iterating {:.4f}s'.format( rank, np.average(times[:, 0]), np.average(times[:, 1])))
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

    # if rank == 0:
    #     time_taken = time.time()-starttime
    #     print('{} iterations took {}s per iteration with MPI'.format(iterations, time_taken/iterations))
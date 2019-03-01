import src.main as galaxy
import os
from mpi4py import MPI
import time
import sys

# Set up MPI variables
comm = MPI.COMM_WORLD
rank = comm.Get_rank()
num_p = comm.Get_size()

# Set runtime variables
try:
    iterations = int(sys.argv[1])
    dt = float(sys.argv[2])
    n = int(sys.argv[3])
except:
    print('Usage: python run.py number_of_iterations timestep')

# Create a csv file to save data into
i = 0
csvfile = 'images/{}_{}'.format('run', i)

if rank == 0:
    # Find the next possible number to save data into
    while os.path.exists(csvfile+'.csv'):
        i += 1
        csvfile = 'images/{}_{}'.format('run', i)

csvfile=comm.bcast(csvfile, root=0)


if rank == 0:
    # Define when the code begins
    starttime = time.time()
    print('Calculating')

# Start the simulation
galaxy.main(iterations, csvfile, dt, n)

if rank == 0:
    print('Total runtime: {}s'.format(time.time() - starttime))


import src.main as universe
import os
from mpi4py import MPI
import time

# Set up MPI variables
comm = MPI.COMM_WORLD
rank = comm.Get_rank()
num_p = comm.Get_size()

# Set runtime variables
iterations = 20000
dt = 60.
# dt = 10.**3.3 # Use with four_bodies
# Create a csv file to save data into
i = 0
csvfile = 'images/{}_{}'.format('run', i)

if rank == 0:
    # Find the next possible number to save data into
    while os.path.exists(csvfile+'.csv'):
        i += 1
        csvfile = 'images/{}_{}'.format('run', i)

    # Let the user know which file contains their data
    print('Your galaxy ref. number with {} threads: {}'.format(num_p, i))

csvfile=comm.bcast(csvfile, root=0)


if rank == 0:
    # Define when the code begins
    starttime = time.time()

# Start the simulation
universe.main(iterations, csvfile, dt)

if rank == 0:
    print('Total runtime: {}s'.format(time.time() - starttime))

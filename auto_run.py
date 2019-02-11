import src.main as universe
import os
from mpi4py import MPI
import time

# Set up MPI variables
comm = MPI.COMM_WORLD
rank = comm.Get_rank()

# Set runtime variables
iterations = 200
dt = 10.
# dt = 10.**3.3 # Use with four_bodies
# Create a csv file to save data into
i = 0
csvfile = 'images/{}_{}'.format('auto_run', i)

if rank == 0:
    # Find the next possible number to save data into
    while os.path.exists(csvfile+'.csv'):
        i += 1
        csvfile = 'images/{}_{}'.format('auto_run', i)

    # Let the user know which file contains their data
    print('Your galaxy ref. number: {}'.format(i))

csvfile=comm.bcast(csvfile, root=0)


if rank == 0:
    # Define when the code begins
    starttime = time.time()
    print('Starting simulation')

# Start the simulation
universe.main(iterations, csvfile, dt, 0)

if rank == 0:
    print('Total runtime: {}s'.format(time.time() - starttime))

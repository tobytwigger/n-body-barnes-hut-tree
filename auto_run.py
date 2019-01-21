import src.main as universe
import os
from mpi4py import MPI
import time

comm = MPI.COMM_WORLD
rank = comm.Get_rank()
iterations = int(100)
starttime = time.time()

i = 0
directory = 'images/{}_{}'.format('auto_run', i)

if rank == 0:
    while os.path.exists(directory+'.csv'):
        i += 1
        directory = 'images/{}_{}'.format('auto_run', i)

    print('Your galaxy ref. number: {}'.format(i))
directory=comm.bcast(directory, root=0)

dt = float(10.**15)
if rank == 0:
    print('Starting simulation')
universe.main(iterations, directory, dt, 0)
if rank == 0:
    print('Total runtime: {}s'.format(time.time() - starttime))

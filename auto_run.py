import src.main as universe
import os
from mpi4py import MPI

comm = MPI.COMM_WORLD
rank = comm.Get_rank()
iterations = int(1000)

i = 0
directory = 'images/{}_{}'.format('auto_run', i)

if rank == 0:
    while os.path.exists(directory):
        i += 1
        directory = 'images/{}_{}'.format('auto_run', i)
    os.mkdir(directory)

directory=comm.bcast(directory, root=0)

dt = float(9000)
area_side = 9*10**8#0
num_bodies = 2
if rank == 0:
    print('Starting simulation')
universe.main(iterations, directory, dt, area_side, num_bodies, False)
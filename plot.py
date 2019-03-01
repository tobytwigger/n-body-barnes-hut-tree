import analysis.plotting as plot
import sys
import os
from mpi4py import MPI

comm = MPI.COMM_WORLD
rank = comm.Get_rank()
num_p = comm.Get_size()

autorun_number = sys.argv[1]

file = './images/run_'+autorun_number+'.csv'
directory = 'images/{}_{}'.format('run', autorun_number)



if sys.argv[2] == 'all':
    if rank == 0:
        if not os.path.exists(directory):
            os.mkdir(directory)

    plot.gen_all_images(file, directory, 0)

elif sys.argv[2] == 'single':
    plot.gen_single_axes(file, int(sys.argv[3]))
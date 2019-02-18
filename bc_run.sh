#!/bin/bash
# request resources:
#PBS -l nodes=1:ppn=16
#PBS -l walltime=12:00:00
# on compute node, change directory to 'submission directory':
# source activate comp-project
cd $PBS_O_WORKDIR
# run your program, timing it for good measure:
python setup.py build_ext -i
mpiexec -np 16 python run.py
# source deactivate
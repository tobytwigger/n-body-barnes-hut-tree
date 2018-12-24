#!/bin/sh

python setup.py build_ext -i

mpiexec -np 8 python auto_run.py

#for i in `seq 2 10`; do
#    echo "Computing with $i processes"
#    mpiexec -np $i python auto_run.py
#done

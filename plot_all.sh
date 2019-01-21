#!/bin/bash

python setup.py build_ext -i
mpiexec -np 8 python plot.py $1 $2 $3

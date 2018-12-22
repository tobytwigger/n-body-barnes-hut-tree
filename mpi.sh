#!/bin/sh

python setup.py build_ext -i
mpiexec -np 16 python auto_run.py

#!/bin/bash

number=0

while [ -f profiling/profile_$number.Prof ]
do
	number=$((number+1))
done
echo $number

python setup.py build_ext -i

mpiexec -tag-output -np 3 python -m cProfile -o profiling/profile_$number.Prof run.py
pyprof2calltree -k -i profiling/profile_$number.Prof

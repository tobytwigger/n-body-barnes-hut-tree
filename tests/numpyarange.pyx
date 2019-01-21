import numpy as np
cimport numpy as np

def numpy_arange():
    cdef double[:] array

    array = np.arange(50, 150, dtype=np.float64)
    print(array)

def normal():
    cdef:
        double[:] array
        int start, end

    start = 50
    end = 150
    for i in range(end-start):
        array[i] = start + i
    print(array)
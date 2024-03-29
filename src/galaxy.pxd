# cython: profile=False
# cython: linetrace=False
# cython: cdivision=True
# cython: boundscheck=False
# cython: wraparound=False
# cython: initializedcheck=False

cimport numpy as np
import numpy as np

cdef class Galaxy:

    cdef double[:, :, :] stars
    cdef double[:] star_mass
    cdef double[:, :] area

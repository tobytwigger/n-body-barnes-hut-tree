# cython: profile=False
# cython: linetrace=False
# cython: cdivision=True
# cython: boundscheck=False
# cython: wraparound=False
# cython: initializedcheck=False

import numpy as np
cimport numpy as np

cdef class Node:

    cdef int[:] bodies
    cdef int parent, depth, max_depth
    cdef double[:, :] area
    cdef double[:] com
    cdef double mass
    cdef Node[:] children
    cdef Node temp_node

    cdef void add_body(self, double[:, :, :] stars, double[:] star_mass, int body_id)
# cython: profile=True
# cython: linetrace=True

import numpy as np
cimport numpy as np


cdef class Node:

    cdef public object bodies
    cdef public int parent
    cdef public object area
    cdef public np.ndarray children
    cdef public int depth
    cdef public float mass
    cdef public np.ndarray com

    cpdef void addBody(self, all_bodies, Py_ssize_t body_id) except *
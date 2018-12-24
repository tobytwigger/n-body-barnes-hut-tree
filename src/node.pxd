# cython: profile=True
# cython: linetrace=True

import numpy as np
cimport numpy as np

from src.bodies import Bodies
from src.bodies cimport Bodies

from src.area import Area
from src.area cimport Area

cdef class Node:

    cdef np.ndarray bodies
    cdef int parent
    cdef Area area
    cdef np.ndarray children
    cdef int depth
    cdef float mass
    cdef np.ndarray com

    cpdef void addBody(self, Bodies all_bodies, Py_ssize_t body_id) except *
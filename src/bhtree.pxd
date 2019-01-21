# cython: profile=True
# cython: linetrace=True

from src.node import Node
from src.node cimport Node

import numpy as np
cimport numpy as np

cdef class BHTree:

    # bodies
    # theta
    # root_node
    cdef double[:, :, :] stars
    cdef double[:] star_mass
    cdef double[:, :] area

    cdef float theta
    cdef Node root_node

    cdef void populate(self) except *

    cdef void reset_children(self) except *

    cdef void iterate(self, float dt) except *

    cdef double[:] get_acceleration_of_body(self, Py_ssize_t body_id, Node node)

    cdef double[:] get_acceleration_due_to_body(self, Py_ssize_t body_id, Py_ssize_t gen_body_id)

    cdef double[:] get_acceleration_due_to_node(self, Py_ssize_t body_id, Node node)

    cdef double[:] calculate_acceleration(self, double[:] d, float m2)
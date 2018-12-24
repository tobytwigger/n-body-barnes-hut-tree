# cython: profile=True
# cython: linetrace=True

from src.node import Node
from src.node cimport Node

from src.area import Area
from src.area cimport Area

from src.bodies import Bodies
from src.bodies cimport Bodies

import numpy as np
cimport numpy as np

cdef class BHTree:

    # bodies
    # theta
    # root_node
    cdef public Bodies bodies
    cdef public float theta
    cdef public Node root_node

    cdef void _init(self)

    cdef void generate_data(self, Area area, int n)

    cdef void populate(self)

    cdef void reset_children(self)

    cdef void iterate(self, float dt)

    cdef np.ndarray get_force_on_body(self, Py_ssize_t body_id, Node node)

    cdef np.ndarray get_force_due_to_body(self, Py_ssize_t body_id, Py_ssize_t gen_body_id)

    cdef np.ndarray get_force_due_to_node(self, Py_ssize_t body_id, Node node)

    cdef np.ndarray calculate_force(self, float m, np.ndarray d, float m2)
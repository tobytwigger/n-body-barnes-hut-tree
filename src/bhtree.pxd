# cython: profile=True
# cython: linetrace=True

from src.node import Node
from src.node cimport Node

from src.bodies import Bodies

import math
import numpy as np
cimport numpy as np

from mpi4py import MPI

cdef class BHTree(object):

    # bodies
    # theta
    # root_node
    cdef public object bodies
    cdef public float theta
    cdef public object root_node
    cdef str _shutdown_threads
    cdef np.ndarray _data_send_request
    cdef int _data_send_request_tag

    cpdef void iterate(self, float dt) except *

    cdef np.ndarray get_force_on_body(self, Py_ssize_t body_id, Node node)

    cdef np.ndarray get_force_due_to_body(self, Py_ssize_t body_id, Py_ssize_t gen_body_id)

    cdef np.ndarray get_force_due_to_node(self, Py_ssize_t body_id, Node node)

    cdef np.ndarray calculate_force(self, float m, np.ndarray d, float m2)
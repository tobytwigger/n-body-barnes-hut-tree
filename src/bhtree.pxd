from src.node import Node
from src.node cimport Node

from src.node import Bodies
from src.bodies cimport Bodies

from src.area import Area
from src.area cimport Area

cdef class BHTree:

    cdef Bodies bodies
    cdef float theta
    cdef Node root_node

    cpdef void generate_data(self, Area area, int n) except *

    cpdef void populate(self) except *

    cpdef void reset_children(self) except *

    cpdef void iterate(self, float dt) except *

    cpdef double[:] get_force_on_body(self, int body_id, Node node) except *

    cpdef double[:] get_force_due_to_body(self, int body_id, int gen_body_id) except *

    cpdef double[:] get_force_due_to_node(self, int body_id, Node node) except *

    cpdef double[:] calculate_force(self, float m, double[:] d, float m2) except *
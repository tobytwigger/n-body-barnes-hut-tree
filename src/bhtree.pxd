from node import Node
from bodies import Bodies
from area cimport Area

cdef class BHTree:

    cdef Bodies bodies
    cdef float theta
    cdef Node root_node

    cpdef void generate_data(self, Area area, int n)

    cpdef void populate(self)

    cpdef void reset_children(self)

    cpdef void iterate(self, float dt)

    cpdef double[:] get_force_on_body(self, int body_id, Node node)

    cdef double[:] get_force_due_to_body(self, int body_id, int gen_body_id)

    cpdef double[:] get_force_due_to_node(self, int body_id, Node node)

    cpdef double[:] calculate_force(self, float m, double[:] d, float m2)
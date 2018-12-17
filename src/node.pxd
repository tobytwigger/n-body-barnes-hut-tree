from area import Area
from node import Node
from bodies import Bodies

cdef class Node:

    cdef int[:] bodies
    cdef bool parent
    cdef Area area
    cdef Node[:] children
    cdef int depth

    cpdef void addBody(self, Bodies all_bodies, int body_id)

    cpdef double[:] get_center_of_mass(self, Bodies bodies)

    cpdef float get_total_mass(self, Bodies bodies)
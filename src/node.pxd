from src.bodies import Bodies
from src.bodies cimport Bodies

from src.area import Area
from src.area cimport Area

from libcpp cimport bool
from cpython cimport bool

cdef class Node:

    cdef int[:] bodies
    cdef bool parent
    cdef Area area
    cdef object[:] children
    cdef int depth

    cpdef void addBody(self, Bodies all_bodies, int body_id) except *

    cpdef double[:] get_center_of_mass(self, Bodies bodies) except *

    cpdef float get_total_mass(self, Bodies bodies) except *
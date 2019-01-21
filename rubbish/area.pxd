# cython: profile=True
# cython: linetrace=True

import numpy as np
cimport numpy as np

cdef class Area:

    cdef:
        double min_x
        double min_y
        double min_z
        double max_x
        double max_y
        double max_z

    cdef void set_coordinates(self, double[:] min_coordinates, double[:] max_coordinates)

    cdef double[:] get_dimensions(self)

    cdef double[:] get_minimum_coordinates(self)

    cdef double[:] get_maximum_coordinates(self)

    cdef double[:] get_central_coordinates(self)

    cdef double get_center_x(self)

    cdef double get_center_y(self)

    cdef double get_center_z(self)

    cdef int get_node_index(self, double[:] positions) except *

    cdef Area get_node_index_area(self, int node_index)

    cdef void change_area_size(self, double[:] min_coordinates, double[:] max_coordinates)

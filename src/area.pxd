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

    cpdef np.ndarray get_dimensions(self)

    cpdef np.ndarray get_minimum_coordinates(self)

    cpdef np.ndarray get_maximum_coordinates(self)

    cpdef np.ndarray get_central_coordinates(self)

    cpdef double get_center_x(self)

    cpdef double get_center_y(self)

    cpdef double get_center_z(self)

    cpdef int get_node_index(self, np.ndarray positions)

    cpdef object get_node_index_area(self, int node_index)

    cpdef void change_area_size(self, np.ndarray min_coordinates, np.ndarray max_coordinates)
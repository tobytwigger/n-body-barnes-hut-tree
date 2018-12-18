cdef class Area(object):

    cdef double min_x, min_y, min_z, max_x, max_y, max_z

    cdef double[:] get_dimensions(self) except *

    cdef double[:] get_minimum_coordinates(self) except *

    cdef double[:] get_maximum_coordinates(self) except *

    cdef double[:] get_central_coordinates(self) except *

    cdef double get_center_x(self) except *

    cdef double get_center_y(self) except *

    cdef double get_center_z(self) except *

    cdef int get_node_index(self, double[:] positions) except *

    cdef Area get_node_index_area(self, int node_index)

    cdef void change_area_size(self, double[:] min_coordinates, double[:] max_coordinates) except *
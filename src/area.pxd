cdef class Area:

    cdef double min_x, min_y, min_z, max_x, max_y, max_z

    cpdef double[:] get_dimensions(self) except *

    cpdef double[:] get_minimum_coordinates(self) except *

    cpdef double[:] get_maximum_coordinates(self) except *

    cpdef double[:] get_central_coordinates(self) except *

    cpdef double get_center_x(self) except *

    cpdef double get_center_y(self) except *

    cpdef double get_center_z(self) except *

    cpdef int get_node_index(self, double[:] positions) except *

    cpdef Area get_node_index_area(self, int node_index)

    cpdef void change_area_size(self, double[:] min_coordinates, double[:] max_coordinates) except *
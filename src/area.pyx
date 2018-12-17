import numpy as np
cimport numpy as np

cdef class Area:

    def __init__(self, double[:] min_coordinates, double[:] max_coordinates):

        self.min_x = min_coordinates[0]
        self.min_y = min_coordinates[1]
        self.min_z = min_coordinates[2]
        self.max_x = max_coordinates[0]
        self.max_y = max_coordinates[1]
        self.max_z = max_coordinates[2]


    cpdef double[:] get_dimensions(self) except *:
        return np.array([self.max_x-self.min_x, self.max_y-self.min_y, self.max_z-self.min_z], dtype=np.float64)

    cpdef double[:] get_minimum_coordinates(self) except *:
        return np.array([self.min_x, self.min_y, self.min_z], dtype=np.float64)

    cpdef double[:] get_maximum_coordinates(self) except *:
        return np.array([self.max_x, self.max_y, self.max_z], dtype=np.float64)

    cpdef double[:] get_central_coordinates(self) except *:
        return np.array([self.get_center_x(), self.get_center_y(), self.get_center_z()], dtype=np.float64)

    cpdef double get_center_x(self) except *:
        return (self.max_x + self.min_x)/2

    cpdef double get_center_y(self) except *:
        return (self.max_y + self.min_y) / 2

    cpdef double get_center_z(self) except *:
        return (self.max_z + self.min_z) / 2

    cpdef int get_node_index(self, double[:] positions) except *:
        index = np.array([0,1,2,3,4,5,6,7], dtype=np.int)
        index = index[:4] if positions[0] <= self.get_center_x() else index[4:]
        index = index[:2] if positions[1] <= self.get_center_y() else index[2:]
        index = index[:1] if positions[2] <= self.get_center_z() else index[1:]
        return index[0]

    cpdef Area get_node_index_area(self, int node_index):
        if node_index == 0:
            return Area(np.array([self.min_x, self.min_y, self.min_z], dtype=np.float64), np.array([self.get_center_x(), self.get_center_y(), self.get_center_z()], dtype=np.float64))
        elif node_index == 1:
            return Area(np.array([self.min_x, self.min_y, self.get_center_z()], dtype=np.float64), np.array([self.get_center_x(), self.get_center_y(), self.max_z], dtype=np.float64))
        elif node_index == 2:
            return Area(np.array([self.min_x, self.get_center_y(), self.min_z], dtype=np.float64), np.array([self.get_center_x(), self.max_y, self.get_center_z()], dtype=np.float64))
        elif node_index == 3:
            return Area(np.array([self.min_x, self.get_center_y(), self.get_center_z()], dtype=np.float64), np.array([self.get_center_x(), self.max_y, self.max_z], dtype=np.float64))
        elif node_index == 4:
            return Area(np.array([self.get_center_x(), self.min_y, self.min_z], dtype=np.float64), np.array([self.max_x, self.get_center_y(), self.get_center_z()], dtype=np.float64))
        elif node_index == 5:
            return Area(np.array([self.get_center_x(), self.min_y, self.get_center_z()], dtype=np.float64), np.array([self.max_x, self.get_center_y(), self.max_z], dtype=np.float64))
        elif node_index == 6:
            return Area(np.array([self.get_center_x(), self.get_center_y(), self.min_z], dtype=np.float64), np.array([self.max_x, self.max_y, self.get_center_z()], dtype=np.float64))
        elif node_index == 7:
            return Area(np.array([self.get_center_x(), self.get_center_y(), self.get_center_z()], dtype=np.float64), np.array([self.max_x, self.max_y, self.max_z], dtype=np.float64))

    cpdef void change_area_size(self, double[:] min_coordinates, double[:] max_coordinates) except *:
        self.__init__(min_coordinates, max_coordinates)

    def __str__(self):
        return str([[self.min_x, self.max_x], [self.min_y, self.max_y], [self.min_z, self.max_z]])
import numpy as np

class Area:

    def __init__(self, min_coordinates, max_coordinates):

        self.min_x = min_coordinates[0]
        self.min_y = min_coordinates[1]
        self.min_z = min_coordinates[2]
        self.max_x = max_coordinates[0]
        self.max_y = max_coordinates[1]
        self.max_z = max_coordinates[2]

    def get_dimensions(self):
        return np.array([self.max_x-self.min_x, self.max_y-self.min_y, self.max_z-self.min_z])

    def get_minimum_coordinates(self):
        return [self.min_x, self.min_y, self.min_z]

    def get_maximum_coordinates(self):
        return [self.max_x, self.max_y, self.max_z]

    def get_center_x(self):
        return (self.max_x + self.min_x)/2

    def get_center_y(self):
        return (self.max_y + self.min_y) / 2

    def get_center_z(self):
        return (self.max_z + self.min_z) / 2

    def get_node_index(self, positions):
        index = [0,1,2,3,4,5,6,7]
        index = index[:4] if positions[0] <= self.get_center_x() else index[4:]
        index = index[:2] if positions[1] <= self.get_center_y() else index[2:]
        index = index[:1] if positions[2] <= self.get_center_z() else index[1:]
        return index[0]

    def get_node_index_area(self, node_index):
        if node_index == 0:
            return Area([self.min_x, self.min_y, self.min_z], [self.get_center_x(), self.get_center_y(), self.get_center_z()])
        elif node_index == 1:
            return Area([self.min_x, self.min_y, self.get_center_z()], [self.get_center_x(), self.get_center_y(), self.max_z])
        elif node_index == 2:
            return Area([self.min_x, self.get_center_y(), self.min_z], [self.get_center_x(), self.max_y, self.get_center_z()])
        elif node_index == 3:
            return Area([self.min_x, self.get_center_y(), self.get_center_z()], [self.get_center_x(), self.max_y, self.max_z])
        elif node_index == 4:
            return Area([self.get_center_x(), self.min_y, self.min_z], [self.max_x, self.get_center_y(), self.get_center_z()])
        elif node_index == 5:
            return Area([self.get_center_x(), self.min_y, self.get_center_z()], [self.max_x, self.get_center_y(), self.max_z])
        elif node_index == 6:
            return Area([self.get_center_x(), self.get_center_y(), self.min_z], [self.max_x, self.max_y, self.get_center_z()])
        elif node_index == 7:
            return Area([self.get_center_x(), self.get_center_y(), self.get_center_z()], [self.max_x, self.max_y, self.max_z])

    def __str__(self):
        return str([[self.min_x, self.max_x], [self.min_y, self.max_y], [self.min_z, self.max_z]])
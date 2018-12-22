# cython: profile=True
# cython: linetrace=True

import numpy as np
cimport numpy as np

class Bodies(object):



    def __init__(self):
        self.max_depth = 25
        self.area = None
        self.positions = None
        self.velocities = None
        self.accelerations = None
        self.masses = None
        self.forces = None
        self.n = 0

    def generate_3d_array(self, n, min, max):

        return_array = np.zeros((n, 3))
        iteration_number = 0
        for a in np.linspace(min, max, n):
            for i in [0, 1, 2]:
                return_array[iteration_number][i] = a
            iteration_number = iteration_number + 1
        return return_array

    def generate_data(self, area, n):
        self.set_area(area)
        self.positions = np.random.triangular(area.get_minimum_coordinates(), area.get_central_coordinates(), area.get_maximum_coordinates(), (n, 3))
        # self.masses = np.array([m * 1 * 10 ** 31 + 1 * 10 **30 for m in np.random.random_sample(n)], dtype=np.float)
        self.velocities = np.random.random_sample((n, 3)) * (2 * 10 ** 2)
        self.accelerations = np.random.random_sample((n, 3)) * 7 * 10 ** 0
        # self.positions = self.generate_3d_array(n, self.area.min_x, self.area.max_x)
        self.masses = np.full(n, 8*10**29)
        # self.velocities = self.generate_3d_array(n, 0, 1*10**4)
        # self.accelerations = np.zeros((n, 3))
        self.forces = np.zeros((n, 3))
        self.n = n

    def update_body(self, acceleration_dt, velocity_dt, position_dt, body_id):
        self.update_accelerations(acceleration_dt, body_id)
        self.update_velocities(velocity_dt, body_id)
        self.update_positions(position_dt, body_id)

    def update_accelerations(self, accelerations, body_id):
        updated_acceleration = np.array([a + b for a, b in zip(self.accelerations[body_id], accelerations)], dtype=np.double)
        self.accelerations[body_id] = updated_acceleration

    def update_velocities(self, velocities, body_id):
        updated_velocities = np.array([a + b for a, b in zip(self.velocities[body_id], velocities)], dtype=np.double)
        self.velocities[body_id] = updated_velocities

    def update_positions(self, positions, body_id):
        updated_positions = np.array([a + b for a, b in zip(self.positions[body_id], positions)], dtype=np.double)
        self.positions[body_id] = updated_positions


    def get_mass(self, body_id):
        return self.masses[body_id]

    def get_total_mass(self):
        return sum(self.masses)

    def get_position(self, int body_id):
        return self.positions[body_id]

    def maxb_x(self):
        return max(self.positions[:, 0])

    def maxb_y(self):
        return max(self.positions[:, 1])

    def maxb_z(self):
        return max(self.positions[:, 2])

    def minb_x(self):
        return min(self.positions[:, 0])

    def minb_y(self):
        return min(self.positions[:, 1])

    def minb_z(self):
        return min(self.positions[:, 2])

    def get_area(self):
        return self.area

    def set_area(self, area):
        self.area = area
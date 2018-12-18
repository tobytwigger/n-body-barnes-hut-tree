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

    def generate_data(self, area, n):
        self.set_area(area)
        self.positions = np.random.triangular(area.get_minimum_coordinates(), area.get_central_coordinates(), area.get_maximum_coordinates(), (n, 3))
        self.masses = np.array([m * 1 * 10 ** 31 + 1 * 10 **30 for m in np.random.random_sample(n)], dtype=np.float)
        self.velocities = np.random.random_sample((n, 3)) * (2 * 10 ** 8)
        self.accelerations = np.zeros((n, 3))#np.random.random_sample((n, 3)) * 7 * 10 ** 4
        self.forces = np.zeros((n, 3))
        self.n = n

    def accelerate(self, body_id, acceleration_dt, dt):

        velocity_dt = np.array([a * dt for a in acceleration_dt], dtype=np.float)
        position_dt = np.array([v * dt for v in velocity_dt], dtype=np.float)

        self.update_accelerations(acceleration_dt, body_id)
        self.update_velocities(position_dt, body_id)
        self.update_positions(velocity_dt, body_id)

    def update_accelerations(self, accelerations, body_id):
        updated_acceleration = np.array([a + b for a, b in zip(self.accelerations[body_id], accelerations)], dtype=float).view(dtype=float)
        self.accelerations[body_id] = updated_acceleration

    def update_velocities(self, velocities, body_id):
        updated_velocities = np.array([a + b for a, b in zip(self.velocities[body_id], velocities)], dtype=np.float).view(dtype=float)
        self.velocities[body_id] = updated_velocities

    def update_positions(self, positions, body_id):
        updated_positions = np.array([a + b for a, b in zip(self.positions[body_id], positions)], dtype=np.float).view(dtype=float)
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
# cython: profile=True
# cython: linetrace=True

import numpy as np
cimport numpy as np

cdef class Bodies:

    def __init__(self):
        self.max_depth = 25
        self.area = None
        self.positions = None
        self.velocities = None
        self.accelerations = None
        self.masses = None
        self.forces = None
        self.n = 0

    cdef np.ndarray generate_3d_array(self, int n, double min, double max):
        return_array = np.zeros((n, 3))
        iteration_number = 0
        for a in np.linspace(min, max, n):
            for i in [0, 1, 2]:
                return_array[iteration_number][i] = a
            iteration_number = iteration_number + 1
        return return_array

    cdef void generate_data(self, Area area, int n):
        self.area = area
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

    cdef void update_body(self, np.ndarray acceleration_dt, np.ndarray velocity_dt, np.ndarray position_dt, Py_ssize_t body_id):
        self.update_accelerations(acceleration_dt, body_id)
        self.update_velocities(velocity_dt, body_id)
        self.update_positions(position_dt, body_id)

    cdef void update_accelerations(self, np.ndarray accelerations, Py_ssize_t body_id):
        updated_acceleration = np.array([a + b for a, b in zip(self.accelerations[body_id], accelerations)], dtype=np.double)
        self.accelerations[body_id] = updated_acceleration

    cdef void update_velocities(self, np.ndarray velocities, Py_ssize_t body_id):
        updated_velocities = np.array([a + b for a, b in zip(self.velocities[body_id], velocities)], dtype=np.double)
        self.velocities[body_id] = updated_velocities

    cdef void update_positions(self, np.ndarray positions, Py_ssize_t body_id):
        updated_positions = np.array([a + b for a, b in zip(self.positions[body_id], positions)], dtype=np.double)
        self.positions[body_id] = updated_positions

    cdef double get_mass(self, Py_ssize_t body_id):
        return self.masses[body_id]

    cdef double get_total_mass(self):
        return sum(self.masses)

    cdef np.ndarray get_position(self, Py_ssize_t body_id):
        return self.positions[body_id]

    cdef double maxb_x(self):
        return max(self.positions[:, 0])

    cdef double maxb_y(self):
        return max(self.positions[:, 1])

    cdef double maxb_z(self):
        return max(self.positions[:, 2])

    cdef double minb_x(self):
        return min(self.positions[:, 0])

    cdef double minb_y(self):
        return min(self.positions[:, 1])

    cdef double minb_z(self):
        return min(self.positions[:, 2])

    cdef Area get_area(self):
        return self.area
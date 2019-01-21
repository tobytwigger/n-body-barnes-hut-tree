# cython: profile=True
# cython: linetrace=True

import numpy as np
cimport numpy as np
import random
import math

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
        print('BODIES HAS BEEN USED')

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

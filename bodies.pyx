import numpy as np
cimport numpy as np
from area import Area
from Cython.Includes.cpython import array


cdef class Bodies:

    cdef double [:] masses
    cdef double [:,:] positions
    cdef double [:,:] velocities
    cdef double [:,:] accelerations

    area = None
    cdef int n
    cdef int max_depth

    def __init__(self):
        self.max_depth = 15


    def accelerate(self, int body_id, double [:] acceleration, float dt):
        ''' Add to the acceleration/velocity '''

        cdef double [:,:] velocities = [aplural * dt for a in acceleration for aplural in a]
        cdef double [:,:] positions = [vplural * dt for v in velocities for vplural in v]
        self.accelerations[body_id] = self.accelerations[body_id] + acceleration
        self.velocities[body_id] = self.velocities[body_id] + velocities
        self.positions[body_id] = self.positions[body_id] + positions


    def get_mass(self, int body_id):
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
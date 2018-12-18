import numpy as np
cimport numpy as np

cdef class Bodies(object):

    def __cinit__(self):
        self.max_depth = 25
        self.area = None
        self.positions = None
        self.velocities = None
        self.accelerations = None
        self.masses = None
        self.forces = None
        self.n = 0

    cdef void generate_data(self, Area area, int n) except *:
        self.area = area
        self.positions = np.random.triangular(area.get_minimum_coordinates(), area.get_central_coordinates(), area.get_maximum_coordinates(), (n, 3))
        self.masses = np.array([(1 * 10 ** 31 * m) + 1 * 10**30 for m in np.random.random_sample(n)], dtype=float)
        self.velocities = np.random.random_sample((n, 3)) * (2 * 10 ** 8)
        self.accelerations = np.zeros((n, 3))#np.random.random_sample((n, 3)) * 7 * 10 ** 4
        self.forces = np.zeros((n, 3))
        self.n = n

    cdef void accelerate(self, int body_id, double [:] acceleration_dt, float dt) except *:
        cdef double [:] velocity_dt
        cdef double [:] position_dt

        velocity_dt = np.array([a * dt for a in acceleration_dt], dtype=np.float)
        position_dt = np.array([v * dt for v in velocity_dt], dtype=np.float)

        self.update_accelerations(acceleration_dt, body_id)
        self.update_velocities(position_dt, body_id)
        self.update_positions(velocity_dt, body_id)

    cdef void update_accelerations(self, double [:] accelerations, int body_id) except *:
        cdef double [:] updated_acceleration
        updated_acceleration = np.array([a + b for a, b in zip(self.accelerations[body_id], accelerations)], ).view(dtype=float)
        self.accelerations[body_id] = updated_acceleration

    cdef void update_velocities(self, double [:] velocities, int body_id) except *:
        cdef double [:] updated_velocities
        updated_velocities = np.array([a + b for a, b in zip(self.velocities[body_id], velocities)], ).view(dtype=float)
        self.velocities[body_id] = updated_velocities

    cdef void update_positions(self, double [:] positions, int body_id) except *:
        cdef double [:] updated_positions
        updated_positions = np.array([a + b for a, b in zip(self.positions[body_id], positions)], ).view(dtype=float)
        self.positions[body_id] = updated_positions

    cdef double get_mass(self, int body_id) except *:
        return self.masses[body_id]

    cdef double get_total_mass(self) except *:
        return sum(self.masses)

    cdef double[:] get_position(self, int body_id) except *:
        return self.positions[body_id]

    cdef double maxb_x(self) except *:
        return max(self.positions[:, 0])

    cdef double maxb_y(self) except *:
        return max(self.positions[:, 1])

    cdef double maxb_z(self) except *:
        return max(self.positions[:, 2])

    cdef double minb_x(self) except *:
        return min(self.positions[:, 0])

    cdef double minb_y(self) except *:
        return min(self.positions[:, 1])

    cdef double minb_z(self) except *:
        return min(self.positions[:, 2])
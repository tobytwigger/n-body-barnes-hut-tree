


cdef class Bodies:

    cpdef double [:] masses
    cpdef double [:,:] positions
    cpdef double [:,:] velocities
    cpdef double [:,:] accelerations

    cpdef object area
    cpdef int n
    cpdef int max_depth

    def __init__(self):
        self.max_depth = 15


    def accelerate(self, int body_id, double [:] acceleration, float dt):
        ''' Add to the acceleration/velocity '''

        cdef double [:] velocities = [a * dt for a in acceleration]
        cdef double [:] positions = [v * dt for v in velocities]
        self.accelerations[body_id] =  [current_acc + delta_acc for current_acc, delta_acc in zip(self.accelerations[body_id], acceleration)]
        self.velocities[body_id] = [current_vel + delta_vel for current_vel, delta_vel in zip(self.velocities[body_id], velocities)]
        self.positions[body_id] = [current_pos + delta_pos for current_pos, delta_pos in zip(self.positions[body_id], positions)]


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

    def get_area(self):
        return self.area

    def set_area(self, area):
        self.area = area
import numpy as np


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
        self.masses = np.random.random_sample(n) * 1 * 10 ** 31 + 1 * 10**30
        self.velocities = np.random.random_sample((n, 3)) * (2 * 10 ** 8)
        self.accelerations = np.zeros((n, 3))#np.random.random_sample((n, 3)) * 7 * 10 ** 4
        self.forces = np.zeros((n, 3))
        self.n = n

    def accelerate(self, int body_id, acceleration, float dt):
        ''' Add to the acceleration/velocity '''

        velocities = [a * dt for a in acceleration]
        positions = [v * dt for v in velocities]
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
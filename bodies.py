import numpy as np
from area import Area

def singleton(cls):
    return cls()

@singleton
class Bodies:

    positions = None
    masses = None
    velocities = None
    accelerations = None
    area = None
    n = 0
    max_depth = 15


    def __init__(self):
        pass

    def gen(self, area, n):
        self.area = area
        self.positions = area.get_minimum_coordinates() + np.random.normal([area.get_center_x(), area.get_center_y(), area.get_center_z()], 1.5, (n, 3))
        self.masses = np.random.random_sample(n)*1*10**31
        self.velocities = np.random.random_sample((n,3))*7*10**12
        self.accelerations = np.random.random_sample((n,3))*7*10**5
        self.n = n

    def accelerate(self, body_id, acceleration, dt):
        ''' Add to the acceleration/velocity '''

        self.accelerations[body_id] += acceleration
        self.velocities[body_id] += acceleration * dt
        self.positions[body_id] += self.velocities[body_id] * dt


    def get_mass(self, body_id):
        return self.masses[body_id]

    def get_position(self, body_id):
        return self.positions[body_id]
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


    def accelerate(self, body_id, acceleration, dt):
        ''' Add to the acceleration/velocity '''

        self.accelerations[body_id] += acceleration
        self.velocities[body_id] += acceleration * dt
        self.positions[body_id] = self.positions[body_id] + self.velocities[body_id] * dt


    def get_mass(self, body_id):
        return self.masses[body_id]

    def get_total_mass(self):
        return sum(self.masses)

    def get_position(self, body_id):
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

    def set_area(self, area):
        self.area = area

    def get_area(self):
        return self.area
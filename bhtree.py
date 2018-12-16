from node import Node
from bodies import Bodies
import math
import numpy as np

class BHTree:

    bodies = None
    theta = 0.5

    def __init__(self):
        self.bodies = Bodies()
        self.root_node = Node(self.bodies.area)

    def generate_data(self, area, n):
        self.bodies.area = area
        np.random.normal(
            [area.get_center_x(), area.get_center_y(), area.get_center_z()], 5, (n, 3))
        self.bodies.positions = np.random.triangular(area.get_minimum_coordinates(), area.get_central_coordinates(), area.get_maximum_coordinates(), (n, 3))
        self.bodies.masses = np.random.random_sample(n) * 1 * 10 ** 29
        self.bodies.velocities = np.random.random_sample((n, 3)) * 7 * 10 ** 20
        self.bodies.accelerations = np.random.random_sample((n, 3)) * 7 * 10 ** 20
        self.bodies.n = n

    def populate(self):
        # Reset the tree
        self.reset_children()
        # Iterate through each body
        for i in range(self.bodies.n):
            self.root_node.addBody(self.bodies, i)

    def reset_children(self):
        # Grow the area of the calulation space
        min_coordinates = [min(self.bodies.positions[:, 0]), min(self.bodies.positions[:, 1]), min(self.bodies.positions[:, 2])]
        max_coordinates = [max(self.bodies.positions[:, 0]), max(self.bodies.positions[:, 1]), max(self.bodies.positions[:, 2])]
        self.bodies.area.change_area_size(min_coordinates, max_coordinates)
        self.root_node = Node(self.bodies.area)

    def iterate(self, dt):
        # Calculate the new position, velocity and acceleration of each body in turn
        for i in range(self.bodies.n):
            # Find the updated force
            force = self.get_force_on_body(i, self.root_node)
            # Find acceleration
            acceleration = force/self.bodies.get_mass(i)
            self.bodies.accelerate(i, acceleration, dt)

        self.populate()

    def get_force_on_body(self, body_id, node):
        force = np.zeros(3)

        if not node.parent:
            for k in node.bodies:
                if k != body_id:  # Skip same body
                    force += self.get_force_due_to_body(body_id, k)
        else:
            s = max(node.area.get_dimensions())
            d = node.get_center_of_mass(self.bodies) - self.bodies.positions[body_id]
            r = math.sqrt(d.dot(d))
            if r > 0 and s / r < self.theta:
                force += self.get_force_due_to_node(body_id, node)
            else:
                # Iterate through child nodes
                for subnode in [child for child in node.children if child is not None]:
                    force += self.get_force_on_body(body_id, subnode)

        return force
            # s = max(node.bbox.sideLength)
            # d = node.center - POS[bodI]
            # # r = sqrt(d.dot(d))
            # if (True):#r > 0 and s / r < self.theta):


    def get_force_due_to_body(self, body_id, gen_body_id):
        distance = self.bodies.get_position(body_id) - self.bodies.get_position(gen_body_id)
        mass = self.bodies.get_mass(body_id)
        gen_mass = self.bodies.get_mass(gen_body_id)
        return self.calculate_force(mass, distance, gen_mass)
        # print(distance)
        # r = sqrt(d.dot(d)) + ETA
        # f = array(d * G * m1 * m2 / r ** 3)
        # return f

    def get_force_due_to_node(self, body_id, node):
        self.calculate_force(self.bodies.masses[body_id], node.get_center_of_mass(self.bodies), node.get_total_mass(self.bodies))
        distance = self.bodies.positions[body_id] - node.get_center_of_mass(self.bodies)
        mass = self.bodies.get_mass(body_id)
        gen_mass = node.get_total_mass(self.bodies)
        return self.calculate_force(mass, distance, gen_mass)

    def calculate_force(self, m, d, m2):
        ''' d should be an array of length 3 '''
        G = 6.61 * 10**(-11)
        r = math.sqrt(d.dot(d))
        return (G*m*m2*d)/(r**3)
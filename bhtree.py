from node import Node
from bodies import Bodies
import math
import numpy as np

class BHTree():

    def __init__(self):
        self.root_node = Node(Bodies.area)

    def populate(self):
        # Reset the tree
        self.reset_children()
        # Iterate through each body
        for i in range(Bodies.n):
            self.root_node.addBody(i)

    def reset_children(self):
        self.root_node = Node(Bodies.area)

    def iterate(self, dt):
        # Calculate the new position, velocity and acceleration of each body in turn
        for i in range(Bodies.n):
            # Find the updated force
            force = self.get_force_on_body(i, self.root_node)
            # Find acceleration
            acceleration = force/Bodies.get_mass(i)
            Bodies.accelerate(i, acceleration, dt)

        #self.populate()

    def get_force_on_body(self, body_id, node):
        force = np.zeros(3)

        if not node.parent:
            for k in node.bodies:
                if k != body_id:  # Skip same body
                    force += self.get_force_due_to_body(body_id, k)
        else:
            # Iterate through child nodes
            for subnode in [child for child in node.children if child is not None]:
                force += self.get_force_on_body(body_id, subnode)

        return force
            # s = max(node.bbox.sideLength)
            # d = node.center - POS[bodI]
            # # r = sqrt(d.dot(d))
            # if (True):#r > 0 and s / r < self.theta):
            #     # Far enough to do approximation
            #     Bodies.accelerate(self.get_force_on_body(body_id, k))
            #     acc += getForce(POS[bodI], 1.0, node.com, node.mass)
            # else:
            #     # Too close to approximate, recurse down tree
            #     for k in xrange(4):
            #         if node.children[k] != None:
            #             acc += self.calculateBodyAccelR(bodI, node.children[k])

    def get_force_due_to_body(self, body_id, gen_body_id):
        distance = Bodies.get_position(body_id) - Bodies.get_position(gen_body_id)
        mass = Bodies.get_mass(body_id)
        gen_mass = Bodies.get_mass(gen_body_id)
        return self.calculate_force(mass, distance, gen_mass)
        # print(distance)
        # r = sqrt(d.dot(d)) + ETA
        # f = array(d * G * m1 * m2 / r ** 3)
        # return f

    def get_acceleration_due_to_node(self):
        pass

    def calculate_force(self, m, d, m2):
        ''' d should be an array of length 3 '''
        G = 6.61 * 10**(-11)
        r = math.sqrt(d.dot(d))
        return (G*m*m2*d)/(r**3)
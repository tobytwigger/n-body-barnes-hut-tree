# cython: profile=True

import math

import numpy as np
cimport numpy as np

cdef class BHTree(object):

    def __cinit__(self):
        self.bodies = Bodies()
        self.theta = 0
        self.root_node = Node(self.bodies.area)

    cdef void generate_data(self, Area area, int n) except *:
        self.bodies.generate_data(area, n)

    cdef void populate(self) except *:
        cdef int i
        # Reset the tree
        self.reset_children()
        # Iterate through each body
        for i in range(self.bodies.n):
            self.root_node.addBody(self.bodies, i)

    cdef void reset_children(self) except *:
        cdef double[:] min_coordinates
        cdef double[:] max_coordinates
        # Grow the area of the calulation space
        min_coordinates = np.array([min(self.bodies.positions[:, 0]), min(self.bodies.positions[:, 1]), min(self.bodies.positions[:, 2])], dtype=np.float64)
        max_coordinates = np.array([max(self.bodies.positions[:, 0]), max(self.bodies.positions[:, 1]), max(self.bodies.positions[:, 2])], dtype=np.float64)
        self.bodies.area.change_area_size(min_coordinates, max_coordinates)
        self.root_node = Node(self.bodies.area)

    cdef void iterate(self, float dt) except *:
        cdef int i
        cdef double[:] force
        cdef double[:] acceleration
        cdef float mass

        # Calculate the new position, velocity and acceleration of each body in turn
        for i in range(self.bodies.n):
            # Find the updated force
            force = self.get_force_on_body(i, self.root_node)
            self.bodies.forces[i] = force
            # Find acceleration
            mass = self.bodies.get_mass(i)
            acceleration = np.array([f/mass for f in force], dtype=np.float)
            self.bodies.accelerate(i, acceleration, dt)

        self.populate()

    cdef double[:] get_force_on_body(self, int body_id, Node node) except *:
        cdef double[:] force = np.zeros(3)
        cdef double[:] d
        cdef int k
        cdef float s, r
        cdef Node sub_node

        if not node.parent:
            for k in node.bodies:
                if k != body_id:  # Skip same body
                    force = np.array([f + new_f for f, new_f in zip(force, self.get_force_due_to_body(body_id, k))], dtype=np.float)

        else:
            s = max(node.area.get_dimensions())
            d = np.array([pos - com for pos, com in zip(self.bodies.positions[body_id], node.get_center_of_mass(self.bodies))], dtype=np.float)
            r = math.sqrt(np.dot(d, d))
            if r > 0 and s / r < self.theta:
                print('Using node not body!')
                force = np.array([f + new_f for f, new_f in zip(force, self.get_force_due_to_node(body_id, node))], dtype=np.float)

            else:
                # Iterate through child nodes
                for sub_node in [child for child in node.children if child is not None]:
                    force = np.array([f + new_f for f, new_f in zip(force, self.get_force_on_body(body_id, sub_node))], dtype=np.float)

        return force

    cdef double[:] get_force_due_to_body(self, int body_id, int gen_body_id) except *:
        cdef double[:] distance
        cdef double mass
        cdef double gen_mass

        distance = np.array([pos - gen_pos for pos, gen_pos in zip(self.bodies.get_position(body_id), self.bodies.get_position(gen_body_id))], dtype=np.float)
        mass = self.bodies.get_mass(body_id)
        gen_mass = self.bodies.get_mass(gen_body_id)
        return self.calculate_force(mass, distance, gen_mass)
        # print(distance)
        # r = sqrt(d.dot(d)) + ETA
        # f = array(d * G * m1 * m2 / r ** 3)
        # return f

    cdef double[:] get_force_due_to_node(self, int body_id, Node node) except *:
        cdef double[:] distance
        cdef double mass
        cdef double gen_mass

        distance = [pos - com for pos, com in zip(self.bodies.positions[body_id], node.get_center_of_mass(self.bodies))]
        mass = self.bodies.get_mass(body_id)
        gen_mass = node.get_total_mass(self.bodies)
        return self.calculate_force(mass, distance, gen_mass)

    cdef double[:] calculate_force(self, float m, double[:] d, float m2) except *:
        cdef double G
        cdef double r
        ''' d should be an array of length 3 '''
        G = 6.61 * 10**(1)
        r = math.sqrt(np.dot(d, d))
        return np.array([dist * -((G*m*m2)/(r**3)) for dist in d], dtype=np.float)

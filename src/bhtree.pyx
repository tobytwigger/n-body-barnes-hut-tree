# cython: profile=True
# cython: linetrace=True

from src.node import Node
from src.node cimport Node

from src.area import Area
from src.area cimport Area

from src.bodies import Bodies
from src.bodies cimport Bodies

import math
import numpy as np
cimport numpy as np

from mpi4py import MPI

import time

cdef class BHTree:

    def __init__(self):
        self._init()


    cdef void _init(self):
        self.bodies = Bodies()
        self.theta = 0
        self.root_node = Node(self.bodies.get_area())

    cdef void generate_data(self, Area area, int n):
        self.bodies.generate_data(area, n)
        self.populate()

    cdef void populate(self):
        cdef int i
        cdef int n

        n = self.bodies.n
        # print('populating')
        # Reset the tree
        self.reset_children()
        # Iterate through each body
        for i in range(n):
            self.root_node.addBody(self.bodies, i)

    cdef void reset_children(self):
        # Grow the area of the calulation space
        min_coordinates = np.array([min(self.bodies.positions[:, 0]), min(self.bodies.positions[:, 1]), min(self.bodies.positions[:, 2])], dtype=np.float64)
        max_coordinates = np.array([max(self.bodies.positions[:, 0]), max(self.bodies.positions[:, 1]), max(self.bodies.positions[:, 2])], dtype=np.float64)
        self.bodies.get_area().change_area_size(min_coordinates, max_coordinates)
        self.root_node = Node(self.bodies.get_area())

    cdef void iterate(self, float dt):
        cdef:
            Py_ssize_t body_id
            list bodies
            int body_number
            np.ndarray body_totals

        comm = MPI.COMM_WORLD
        rank = comm.Get_rank()
        num_p = comm.Get_size()
        status = MPI.Status()
        # print('About to process {} bodies'.format(len(bodies)))
        if rank == 0:
            bodies = np.array_split(range(self.bodies.n), num_p)
            body_number = 0
        else:
            bodies = None
        body_totals = np.zeros((self.bodies.n, 3, 3))
        my_bodies = comm.scatter(bodies, root=0)

        body_calculations = np.zeros((self.bodies.n, 3, 3))

        # print('Rank {} has to process {}'.format(rank, my_bodies))

        for body in my_bodies:
            force = self.get_force_on_body(body, self.root_node)
            acceleration_dt = force/self.bodies.get_mass(body)
            velocity_dt = np.array([a * dt for a in acceleration_dt], dtype=np.float64)
            position_dt = np.array([v * dt for v in velocity_dt], dtype=np.float64)
            body_calculations[body] = np.array([
                acceleration_dt, velocity_dt, position_dt
            ])
            # print('Rank {} put body {}\'s calculation as {}'.format(rank, body, body_calculations[body]))

        body_calculations = comm.Reduce(
            [body_calculations, MPI.DOUBLE],
            [body_totals, MPI.DOUBLE],
            op = MPI.SUM,
            root = 0
        )

        body_positions = np.zeros((self.bodies.n, 3))
        if rank == 0:
            # print('Rank {} has body_totals as {}'.format(rank, body_totals))
            body_id = 0
            for body_derivatives in body_totals:
                self.bodies.update_body(body_derivatives[0], body_derivatives[1], body_derivatives[2], body_id)
                body_positions[body_id] = body_derivatives[2]
                body_id = body_id + 1

        self.populate()

    def slow_iterate(self, dt):
        # Calculate the new position, velocity and acceleration of each body in turn
        for i in range(self.bodies.n):
            # Find the updated force
            force = self.get_force_on_body(i, self.root_node)
            self.bodies.forces[i] = force
            # Find acceleration
            acceleration = force/self.bodies.get_mass(i)
            self.bodies.accelerate(i, acceleration, dt)

        self.populate()

    cdef np.ndarray get_force_on_body(self, Py_ssize_t body_id, Node node):
        cdef:
            np.ndarray force
            int k
            float s
            np.ndarray d
            float r
            object child
            object subnode

        force = np.zeros(3)

        if node.parent is 0:
            for k in node.bodies:
                if k != body_id:  # Skip same body
                    force += self.get_force_due_to_body(body_id, k)
        else:
            s = max(node.area.get_dimensions())

            d = node.com - self.bodies.positions[body_id]
            r = math.sqrt(np.dot(d, d))
            if r > 0 and s / r < self.theta:
                force += self.get_force_due_to_node(body_id, node)
            else:
                # Iterate through child nodes
                for subnode in [child for child in node.children if child is not None]:
                    force += self.get_force_on_body(body_id, subnode)

        return force

    cdef np.ndarray get_force_due_to_body(self, Py_ssize_t body_id, Py_ssize_t gen_body_id):
        cdef:
            np.ndarray distance
            float mass
            float gen_mass

        distance = np.array([a+b for a, b in zip(self.bodies.get_position(body_id), self.bodies.get_position(gen_body_id))])
        mass = self.bodies.get_mass(body_id)
        gen_mass = self.bodies.get_mass(gen_body_id)
        return self.calculate_force(mass, distance, gen_mass)

    cdef np.ndarray get_force_due_to_node(self, Py_ssize_t body_id, Node node):
        cdef:
            np.ndarray distance
            float mass, gen_mass, a, b

        distance = np.array([a+b for a, b in zip(self.bodies.get_position(body_id), node.com)])
        mass = self.bodies.get_mass(body_id)
        gen_mass = node.mass
        return self.calculate_force(mass, distance, gen_mass)

    cdef np.ndarray calculate_force(self, float m, np.ndarray d, float m2):
        cdef:
            double G, r

        G = 6.67 * math.pow(10, -11)
        r = math.sqrt(np.dot(d, d))
        constant = -((G*m*m2)/(r**3))
        if math.isinf(constant):
            print('R is too large to calculate!')
        force = np.array([dist * constant for dist in d], dtype=np.float64)
        # print('Using G={:20.20f}, r={:20f}, m1={:10f}, m2={:10f}, constant={}, force={}'.format(G, r**3, m, m2, constant, force))

        return force
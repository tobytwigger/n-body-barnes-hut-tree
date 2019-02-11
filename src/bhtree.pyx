# cython: profile=True
# cython: linetrace=True

from src.node import Node
from src.node cimport Node

from libc cimport math


import numpy as np
cimport numpy as np
import numpy.ma as ma

import random
from mpi4py import MPI

cimport cython

cdef class BHTree:

    def __init__(self, double[:, :] area):
        self.area = area
        self.theta = 0
        self.root_node = Node(self.area)

    cdef void populate(self) except *:
        """
        Populates the barnes hut tree
        
        Calling this will populate the Barnes Hut Tree. 
        
        :return: 
        """

        cdef int i, n

        n = len(self.stars)
        # Reset the tree
        self.reset_children()
        # Iterate through each body
        for i in range(n):
            self.root_node.add_body(self.stars, self.star_mass, i)

    cdef void reset_children(self) except *:
        """
        Reset the root node
        
        Resizes the calculation area and depopulates the tree
        
        :return: 
        """
        # Grow the area of the calulation space
        self.area = np.array([
            [np.min(self.stars[:, 0, :]), np.min(self.stars[:, 1, :]), np.min(self.stars[:, 2, :])],
            [np.max(self.stars[:, 0, :]), np.max(self.stars[:, 1, :]), np.max(self.stars[:, 2, :])]
        ], dtype=np.float64)

        self.root_node = Node(self.area)

    # @cython.boundscheck(False)
    # @cython.wraparound(False)
    # @cython.cdivision(True)
    cdef void iterate(self, float dt) except *:
        """
        Iterates the system forward by a time dt.
        
        The data can be retrieved from the immutable property
        BHTree.stars.
        
        :param dt: Timestep in s to iterate the system by
         
        :return: 
        """
        cdef:
            Py_ssize_t i, body_id
            int[:] bodies
            double[:] force
            double[:, :, :] body_totals, stars
            double body_mass
            int l, m, n, rank, num_p, num_of_bodies

        comm = MPI.COMM_WORLD
        rank = comm.Get_rank()
        num_p = comm.Get_size()

        # Split up the stars between the processes.
        n = <int>len(self.stars)
        l = <int>(n / num_p)
        m = n % num_p
        if n < num_p:
            if rank == 0:
                num_of_bodies = n
                bodies = np.arange(n, dtype=np.intc)
            else:
                num_of_bodies = 0
        else:
            if m > rank:
                num_of_bodies = l+1
                bodies = np.arange(rank*l, ((rank+1)*l)+1, dtype=np.intc)
                bodies[num_of_bodies-1] = n-rank-1
            else:
                num_of_bodies = l
                bodies = np.arange(rank*l, (rank+1)*l, dtype=np.intc)

        stars = self.stars
        area_length = np.max([self.area[1][0] - self.area[0][0], self.area[1][1] - self.area[0][1], self.area[1][2] - self.area[0][2]])
        central_coordinates = np.array([(self.area[1][0] + self.area[0][0])/2, (self.area[1][1] + self.area[0][1])/2, (self.area[1][2] + self.area[0][2])/2], dtype=np.float64)

        # Each rank iterates through their own bodies, saving the data to 'stars'
        i = 0
        while i < num_of_bodies:

            body_id = bodies[i]

            # Get the acceleration
            acceleration = self.get_acceleration_of_body(body_id, self.root_node)

            # Set an empty array for the halfway points of v
            v_half = np.zeros(3, dtype=np.float64)

            # Update star data
            for j in range(3):
                # v(1/2) += 1/2 * a(0) * dt
                v_half[j] += 0.5 * stars[body_id][2][j] * dt

                # r(1) += v(1/2) * dt
                stars[body_id][0][j] += v_half[j] * dt

                # a(1) += a(new)
                stars[body_id][2][j] += acceleration[j]

                # v(1) += v(1/2) + 1/2 * dt * a(1)
                stars[body_id][1][j] += v_half[j] + 1/2 * dt * stars[body_id][2][j]

            i = i + 1

        # Share the updated star information
        body_totals = np.zeros((n, 3, 3), dtype=np.float64)
        comm.Allreduce(
            stars,
            body_totals,
            op = MPI.SUM
        )

        self.stars = body_totals

    cdef double[:] get_acceleration_of_body(self, Py_ssize_t body_id, Node node):
        """
        Gets the change in acceleration of the body given due to the node given
        
        :param body_id: The body to calculate the acceleration for
        :param node: The node to calculate the acceleration within
        
        :return: array len 3, with the three components of acceleration due to node node
        """
        cdef:
            double[:] force, additional_force
            int k
            float s
            double[:] d = np.zeros(3)
            float r
            Node child, subnode
        force = np.zeros(3)

        # Node isn't a parent, so we can calculate acceleration directly
        if node.parent is 0:
            for k in node.bodies:
                if k != body_id:
                    # Get the acceleration due to a particular body
                    additional_force = self.get_acceleration_due_to_body(body_id, k)
                    for i in range(3):
                        force[i] = force[i] + additional_force[i]

        # Node is a parent, iterate through the nodes
        else:
            # Find values for node condition
            s = np.max([node.area[1][0] - node.area[0][0], node.area[1][1] - node.area[0][1], node.area[1][2] - node.area[0][2]])
            for i in range(3):
                d[i] = node.com[i] - self.stars[body_id][0][i]
            r = math.sqrt(np.dot(d, d))

            # Condition is met, we can just use the node not the bodies
            if r > 0 and s / r < self.theta:
                additional_force = self.get_acceleration_due_to_node(body_id, node)
                for i in range(len(additional_force)):
                    force[i] = force[i] + additional_force[i]

            # Need to dive further into the nodes
            else:
                for subnode in [child for child in node.children if child is not None]:
                    additional_force = self.get_acceleration_of_body(body_id, subnode)
                    for i in range(len(additional_force)):
                        force[i] = force[i] + additional_force[i]
        return force


    cdef double[:] get_acceleration_due_to_body(self, Py_ssize_t body_id, Py_ssize_t gen_body_id):
        cdef:
            double[:] distance = np.zeros(3)
            float mass
            float gen_mass

        distance[0] = self.stars[body_id][0][0] - self.stars[gen_body_id][0][0]
        distance[1] = self.stars[body_id][0][1] - self.stars[gen_body_id][0][1]
        distance[2] = self.stars[body_id][0][2] - self.stars[gen_body_id][0][2]
        gen_mass = self.star_mass[gen_body_id]

        return self.calculate_acceleration(distance, gen_mass)

    cdef double[:] get_acceleration_due_to_node(self, Py_ssize_t body_id, Node node):
        cdef:
            double[:] distance = np.zeros(3)
            float mass, gen_mass, a, b

        distance[0] = self.stars[body_id][0][0] - node.com[0]
        distance[1] = self.stars[body_id][0][1] - node.com[1]
        distance[2] = self.stars[body_id][0][2] - node.com[2]
        gen_mass = node.mass

        return self.calculate_acceleration(distance, gen_mass)

    cdef double[:] calculate_acceleration(self, double[:] d, float m):
        """
        Calculate the acceleration on a body, given the distance and mass
        of an object relative to the body
        
        :param d: Distance of the body generating the force (array of len 3)
        :param m: Mass of the body generating the force
        
        :return: Acceleration - array of length 3 for each acceleration
        """
        cdef:
            double G, r
            double[:] acceleration = np.zeros(3)
            double constant

        # Find the gravitational constant and the distances
        # G = 6.67 * pow(10., -11.)
        G = 6.67 * pow(10., -1.)
        r = math.sqrt(
            math.pow(d[0], 2.)
            + math.pow(d[1], 2.)
            + math.pow(d[2], 2.)
        )
        if r == 0.:
            print('r is 0!')
            exit(1)

        # Constant in gravitational eq, with a softening factor
        sf = np.max(self.area[1]) * 0.58 * len(self.stars) ** (-0.26)
        constant = -((G*m)/(pow(r, 3) + sf))


        if np.isnan(sf):
            print(np.asarray(self.area))
            print('SF is nan: {} {}'.format(np.max(self.area[1]), len(self.stars)))
            exit(1)
        if np.isnan(constant):
            print('D is ({}, {}, {})'.format(d[0], d[1], d[2]))
            print('Constant is nan. {} * {} / {}^3 ({}) + sf {}'.format(G, m, r, pow(r, 3), sf))
            exit(1)
        if math.isinf(constant):
            print('R is too large to calculate!')
            exit(1)


        # Multiply by the directional vector to decompose
        acceleration[0] = constant * d[0]
        acceleration[1] = constant * d[1]
        acceleration[2] = constant * d[2]
        return acceleration
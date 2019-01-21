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
        cdef int i, n

        n = len(self.stars)
        # Reset the tree
        self.reset_children()
        # Iterate through each body
        for i in range(n):
            self.root_node.add_body(self.stars, self.star_mass, i)

    cdef void reset_children(self) except *:
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
        cdef:
            Py_ssize_t i
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

        # print('Rank {} got bodies {}'.format(rank, np.asarray(bodies)))
        # Set up variables ready for saving star data in, and deleting bodies that're too far away
        stars = np.zeros((n, 3, 3), dtype=np.float64)
        deleted_bodies = np.zeros(n, dtype=np.intc)
        area_length = np.max([self.area[1][0] - self.area[0][0], self.area[1][1] - self.area[0][1], self.area[1][2] - self.area[0][2]])
        central_coordinates = np.array([(self.area[1][0] + self.area[0][0])/2, (self.area[1][1] + self.area[0][1])/2, (self.area[1][2] + self.area[0][2])/2], dtype=np.float64)

        # Each rank iterates through their own bodies, saving the data to 'stars' and deleted_bodies
        i = 0
        while i < num_of_bodies:
            # Update positions
            stars[bodies[i]][0][0] = stars[bodies[i]][1][0] * dt/2
            stars[bodies[i]][0][1] = stars[bodies[i]][1][1] * dt/2
            stars[bodies[i]][0][2] = stars[bodies[i]][1][2] * dt/2

            acceleration = self.get_acceleration_of_body(bodies[i], self.root_node)
            stars[bodies[i]][2][0] = acceleration[0]
            stars[bodies[i]][2][1] = acceleration[1]
            stars[bodies[i]][2][2] = acceleration[2]
            stars[bodies[i]][1][0] = stars[bodies[i]][1][0] + stars[bodies[i]][2][0] * dt
            stars[bodies[i]][1][1] = stars[bodies[i]][1][1] + stars[bodies[i]][2][1] * dt
            stars[bodies[i]][1][2] = stars[bodies[i]][1][2] + stars[bodies[i]][2][2] * dt
            stars[bodies[i]][0][0] = stars[bodies[i]][0][0] + stars[bodies[i]][1][0] * dt/2
            stars[bodies[i]][0][1] = stars[bodies[i]][0][1] + stars[bodies[i]][1][1] * dt/2
            stars[bodies[i]][0][2] = stars[bodies[i]][0][2] + stars[bodies[i]][1][2] * dt/2

            # print(np.asarray(self.stars[bodies[i]]))
            # print('Max change in body {} is {}'.format(bodies[i], max(self.stars[bodies[i]][0][0],self.stars[ bodies[i]][0][0], self.stars[bodies[i]][0][0]) ))
            # d = math.sqrt(
            #     math.pow((central_coordinates[0] - stars[bodies[i]][0][0]), 2)
            #     + math.pow((central_coordinates[1] - stars[bodies[i]][0][1]), 2)
            #     + math.pow((central_coordinates[2] - stars[bodies[i]][0][2]), 2)
            # )
            # print('Body is {}m away and the total length is {}'.format(d, area_length))
            # if 2 * area_length < d:
            #     deleted_bodies[bodies[i]] = 1

            i = i + 1
        # Share the updated positions
        body_totals = np.zeros((n, 3, 3), dtype=np.float64)
        comm.Allreduce(
            stars,
            body_totals,
            op = MPI.SUM
        )

        # Deleting
        # raw_mask = np.zeros(n, dtype=np.intc)
        #
        # comm.Allreduce(
        #     deleted_bodies,
        #     raw_mask,
        #     op=MPI.SUM
        # )
        # mask = []
        # for i in range(len(raw_mask)):
        #     if raw_mask[i] == 1:
        #         mask.append(i)
        #
        # if len(mask) > 0:
        #     self.stars = np.delete(self.stars, raw_mask, axis=0)
        #     self.star_mass = np.delete(self.star_mass, raw_mask, axis=0)

        i=0
        # while i < (len(raw_mask) - sum(raw_mask)):
        while i < n:

            self.stars[i][0][0] = self.stars[i][0][0] + body_totals[i][0][0] + (self.stars[i][1][0] * dt)
            self.stars[i][0][1] = self.stars[i][0][1] + body_totals[i][0][1] + (self.stars[i][1][1] * dt)
            self.stars[i][0][2] = self.stars[i][0][2] + body_totals[i][0][2] + (self.stars[i][1][2] * dt)
            self.stars[i][1][0] = self.stars[i][1][0] + body_totals[i][1][0] + (self.stars[i][2][0] * dt)
            self.stars[i][1][1] = self.stars[i][1][1] + body_totals[i][1][1] + (self.stars[i][2][1] * dt)
            self.stars[i][1][2] = self.stars[i][1][2] + body_totals[i][1][2] + (self.stars[i][2][2] * dt)
            self.stars[i][2][0] = self.stars[i][2][0] + body_totals[i][2][0]
            self.stars[i][2][1] = self.stars[i][2][1] + body_totals[i][2][1]
            self.stars[i][2][2] = self.stars[i][2][2] + body_totals[i][2][2]

            i = i + 1

    cdef double[:] get_acceleration_of_body(self, Py_ssize_t body_id, Node node):
        cdef:
            double[:] force, additional_force
            int k
            float s
            double[:] d = np.zeros(3)
            float r
            Node child, subnode
        force = np.zeros(3)
        if node.parent is 0:
            for k in node.bodies:
                if k != body_id:
                    additional_force = self.get_acceleration_due_to_body(body_id, k)
                    force[0] = force[0] + additional_force[0]
                    force[1] = force[1] + additional_force[1]
                    force[2] = force[2] + additional_force[2]
        else:
            s = np.max([node.area[1][0] - node.area[0][0], node.area[1][1] - node.area[0][1], node.area[1][2] - node.area[0][2]])
            d[0] = node.com[0] - self.stars[body_id][0][0]
            d[1] = node.com[1] - self.stars[body_id][0][1]
            d[2] = node.com[2] - self.stars[body_id][0][2]
            r = math.sqrt(np.dot(d, d))
            if r > 0 and s / r < self.theta:
                additional_force = self.get_acceleration_due_to_node(body_id, node)
                for i in range(len(additional_force)):
                    force[i] = force[i] + additional_force[i]
            else:
                # Iterate through child nodes
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
        if np.isnan(distance[0]):
            print(np.asarray(self.stars));
            print('Body x is: {}    Body against is {}'.format(self.stars[body_id][0][0], self.stars[gen_body_id][0][0]))
        distance[1] = self.stars[body_id][0][1] - self.stars[gen_body_id][0][1]
        distance[2] = self.stars[body_id][0][2] - self.stars[gen_body_id][0][2]
        gen_mass = self.star_mass[gen_body_id]

        comm = MPI.COMM_WORLD
        rank = comm.Get_rank()
        return self.calculate_acceleration(distance, gen_mass)

    cdef double[:] get_acceleration_due_to_node(self, Py_ssize_t body_id, Node node):
        cdef:
            double[:] distance
            float mass, gen_mass, a, b
        distance = np.array([a-b for a, b in zip(self.stars[body_id][0], node.com)])

        gen_mass = node.mass
        comm = MPI.COMM_WORLD
        rank = comm.Get_rank()
        return self.calculate_acceleration(distance, gen_mass)

    cdef double[:] calculate_acceleration(self, double[:] d, float m):
        cdef:
            double G, r
            double[:] force = np.zeros(3)
            double constant
        comm = MPI.COMM_WORLD
        rank = comm.Get_rank()
        G = 6.67 * pow(10.0, -11)
        r = math.sqrt(
            math.pow(d[0], 2)
            + math.pow(d[1], 2)
            + math.pow(d[2], 2)
        )
        if r == 0.:
            print('r is 0!')
            exit(1)
        constant = -((G*m)/(pow(r, 3) + 1))
        if np.isnan(constant):
            print('D is ({}, {}, {})'.format(d[0], d[1], d[2]))
            print('R is nan. {} * {} / {}^3 ({})'.format(G, m, r, pow(r, 3)))
            exit(1)
        if math.isinf(constant):
            print('R is too large to calculate!')
            exit(1)
        force[0] = constant * d[0]
        force[1] = constant * d[1]
        force[2] = constant * d[2]
        return force
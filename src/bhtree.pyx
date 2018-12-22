# cython: profile=True
# cython: linetrace=True

from src.node import Node
from src.node cimport Node

from src.bodies import Bodies

import math
import numpy as np
cimport numpy as np

from mpi4py import MPI

import time

cdef class BHTree(object):

    def __init__(self):
        self.bodies = Bodies()
        self.theta = 0.5
        self.root_node = Node(self.bodies.get_area())
        self._shutdown_threads = 'random_string'
        self._data_send_request = np.full((3, 3), 0., dtype=np.float64)
        self._data_send_request_tag = 0

    def generate_data(self, area, n):
        self.bodies.generate_data(area, n)
        self._data_send_request_tag = self.bodies.n + 1
        self.populate()

    def populate(self):
        # print('populating')
        # Reset the tree
        self.reset_children()
        # Iterate through each body
        for i in range(self.bodies.n):
            self.root_node.addBody(self.bodies, i)

    def reset_children(self):
        # Grow the area of the calulation space
        min_coordinates = np.array([min(self.bodies.positions[:, 0]), min(self.bodies.positions[:, 1]), min(self.bodies.positions[:, 2])], dtype=np.float64)
        max_coordinates = np.array([max(self.bodies.positions[:, 0]), max(self.bodies.positions[:, 1]), max(self.bodies.positions[:, 2])], dtype=np.float64)
        self.bodies.get_area().change_area_size(min_coordinates, max_coordinates)
        self.root_node = Node(self.bodies.get_area())

    cpdef void iterate(self, float dt) except *:
        cdef Py_ssize_t body_id

        comm = MPI.COMM_WORLD
        rank = comm.Get_rank()
        num_p = comm.Get_size()
        status = MPI.Status()
        active_processors = np.array([], dtype=np.int32)
        bodies = np.arange(self.bodies.n, dtype=np.int32)
        # print('About to process {} bodies'.format(len(bodies)))
        if rank == 0:
            starttime = time.time()
            body_number = 0

            while body_number < self.bodies.n:
                # Check if a new processor is now available
                # If so, send it a body

                # Get a new response
                details = np.empty((3, 3), dtype=np.float64)
                comm.Recv(details, source=MPI.ANY_SOURCE, tag=MPI.ANY_TAG, status=status)
                process_id = status.source
                body_id = status.tag
                # print('Rank {}, got a response from rank {}: {} - {}'.format(rank, process_id, body_id, details))
                 # Send a new body to the process
                # print('Sending body {} to process {}'.format(bodies[body_number], process_id))
                comm.send(None, dest=process_id, tag=bodies[body_number])
                # print('Finished body {}, sending body {} to process {}'.format(body_id, bodies[body_number], process_id))

                # Check to see if this was a response to being sent a body, or a request to get a body
                if body_id is not self._data_send_request_tag:
                    # print('Rank {}, rank {} successfully processed body {}'.format(rank, process_id, body_id))
                    # Add the response to the bodies class
                    # print('Positions was {}'.format(self.bodies.positions[body_id]))
                    # print('Received from process {} the results to body {}: {}'.format(process_id, body_id, details))
                    # print('Updating position by {}'.format(details[2]))
                    self.bodies.update_body(details[0], details[1], details[2], body_id)
                    # print('New position is {}'.format(self.bodies.get_position(body_id)))
                else:
                    # print('Initialised rank {}'.format(process_id))
                    active_processors = np.append(active_processors, process_id)

                # if body_number % 50 == 0:
                    # print('Finished body number {}'.format(body_number))
                body_number = body_number + 1

            # print('We now need to shut down these processors: {}'.format(active_processors))
            requests = []
            for p in active_processors:
                # print('Shutting down process {}'.format(p))
                requests.append(comm.isend(self._shutdown_threads, dest=p, tag=0))
            MPI.Request.waitall(requests)

        else:
            # Send a request for a bit of data
            # print('Rank {}: Sending a request for data: {} - {}'.format(rank, self._data_send_request_tag, self._data_send_request))
            comm.Send(self._data_send_request, dest=0, tag=self._data_send_request_tag)
            while True:
                force = np.zeros(3)
                acceleration = np.zeros(3)
                shutdown = comm.recv(source=0, tag=MPI.ANY_TAG, status=status)
                body_id = status.tag
                # print('Rank {} processing body {}, shutdown command {}'.format(rank, body_id, shutdown))

                # print('I\'m rank {} and ̣I\'ve just received {}'.format(rank, body_id))
                if shutdown == self._shutdown_threads:
                    print('Rank {}, out.'.format(rank))
                    break
                else:
                    # Find the updated force
                    force = self.get_force_on_body(body_id, self.root_node)
                    acceleration_dt = force/self.bodies.get_mass(body_id)
                    velocity_dt = np.array([a * dt for a in acceleration_dt], dtype=np.float64)
                    position_dt = np.array([v * dt for v in velocity_dt], dtype=np.float64)
                    # print('I\'m rank {}, and have just processed body {}. This has a return statement of {}'.format(rank, body_id, np.array([acceleration_dt, velocity_dt, position_dt])))
                    comm.Send(np.array([acceleration_dt, velocity_dt, position_dt], dtype=np.float64), dest=0, tag=body_id)

        self.bodies = comm.bcast(self.bodies, root=0)
        self.populate()
        if rank == 0:
            print('Processed in {}s'.format(time.time() - starttime))

            # bodies = np.arange(self.bodies.n, dtype=np.int32)
            # comm.Scatter(bodies, recvbuf, root=0)

            # Find the updated force
            # self.bodies.forces[body_id] = self.get_force_on_body(body_id, self.root_node)
            # # Find acceleration
            # self.bodies.accelerate(body_id, self.bodies.forces[body_id]/self.bodies.get_mass(body_id), dt)



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
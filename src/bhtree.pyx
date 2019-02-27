# cython: profile=False
# cython: linetrace=False
# cython: cdivision=True
# cython: boundscheck=False
# cython: wraparound=False
# cython: initializedcheck=False


from src.node import Node
from src.node cimport Node

from libc cimport math



import numpy as np
cimport numpy as np

from mpi4py import MPI

cimport cython

cdef class BHTree:

    def __init__(self, double[:, :] area):
        self.area = area
        self.theta = 0.7
        self.root_node = Node(self.area)

    cdef void populate(self):
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

    cdef void reset_children(self):
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

    cdef void iterate(self, float dt):
        """
        Iterates the system forward by a time dt.
        
        The data can be retrieved from the immutable property
        BHTree.stars.
        
        :param dt: Timestep in s to iterate the system by
         
        :return: 
        """
        cdef int n = len(self.stars)
        body_totals = np.zeros((n, 3, 3), dtype=np.float64)
        stars = np.zeros((n, 3, 3), dtype=np.float64)

        cdef:
            Py_ssize_t i, j, body_id
            int[:] bodies
            int l, m, rank, num_p, num_of_bodies
            double[:, :, :] body_totals_view = body_totals
            double[:, :, :] stars_view = stars
            double[:] acceleration = np.zeros(3)

        num_of_bodies = n
        bodies = np.arange(n, dtype=np.intc)

        # Each rank iterates through their own bodies, saving the data to 'stars'
        i = 0

        while i < num_of_bodies:

            body_id = bodies[i]

            # Get the acceleration
            acceleration = self.get_acceleration_of_body(body_id, self.root_node)
            
            # Update star data
            for j in range(3):

                # r(1) += v(0)*dt + 1/2 * a(0) * dt
                stars_view[body_id][0][j] = self.stars[body_id][0][j] + self.stars[body_id][1][j] * dt + 0.5 * self.stars[body_id][2][j] * dt

                # v(1) += (a(0)  + 1/2 * newacc) * dt
                stars_view[body_id][1][j] = self.stars[body_id][1][j] + (self.stars[body_id][2][j] + 1/2 * acceleration[j]) * dt

                # a(1) += a(new)
                stars_view[body_id][2][j] += acceleration[j]

            i = i + 1


        self.stars = stars_view

    cdef double[:] get_acceleration_of_body(self, Py_ssize_t body_id, Node node):
        """
        Gets the change in acceleration of the body given due to the node given
        
        :param body_id: The body to calculate the acceleration for
        :param node: The node to calculate the acceleration within
        
        :return: array len 3, with the three components of acceleration due to node node
        """
        cdef:
            double[:] acceleration = np.zeros(3)
            double[:] additional_acceleration = np.zeros(3)
            int k
            float s, r
            double[:] d
            Node child, subnode
            
        acceleration = np.zeros(3)
        d = np.zeros(3)
        # Node isn't a parent, so we can calculate acceleration directly
        if node.parent is 0:
            for k in node.bodies:
                if k != body_id:
                    # Get the acceleration due to a particular body
                    additional_acceleration = self.get_acceleration_due_to_body(body_id, k)
                    for i in range(3):
                        acceleration[i] = acceleration[i] + additional_acceleration[i]

        # Node is a parent, iterate through the nodes
        else:
            # Find values for node condition
            s = np.max([node.area[1][0] - node.area[0][0], node.area[1][1] - node.area[0][1], node.area[1][2] - node.area[0][2]])
            for i in range(3):
                d[i] = node.com[i] - self.stars[body_id][0][i]
            r = math.sqrt(np.dot(d, d))

            # Condition is met, we can just use the node not the bodies
            if r > 0 and s / r < self.theta:
                additional_acceleration = self.get_acceleration_due_to_node(body_id, node)
                for i in range(3):
                    acceleration[i] = acceleration[i] + additional_acceleration[i]

            # Need to dive further into the nodes
            else:
                for subnode in [child for child in node.children if child is not None]:
                    additional_acceleration = self.get_acceleration_of_body(body_id, subnode)
                    for i in range(3):
                        acceleration[i] = acceleration[i] + additional_acceleration[i]

        return acceleration

    cdef double[:] get_acceleration_due_to_body(self, Py_ssize_t body_id, Py_ssize_t gen_body_id):
        """
        Get the acceleration on a body due to another body
        
        :param body_id: Body to calculate the acceleration of
        :param gen_body_id: Body to calculate the acceleration due to
        :return: 
        """
        cdef:
            double[:] distance = np.zeros(3)

        for j in range(3):
            distance[j] = self.stars[body_id][0][j] - self.stars[gen_body_id][0][j]

        return self.calculate_acceleration(distance, self.star_mass[gen_body_id])

    cdef double[:] get_acceleration_due_to_node(self, Py_ssize_t body_id, Node node):
        """
        Get the acceleration of a body due to a node (i.e. multiple bodies)
        
        :param body_id: Body to calculate the acceleration of
        :param node: Node which contains the bodies providing a force
        
        :return: 
        """
        cdef:
            double[:] distance = np.zeros(3)

        for j in range(3):
            distance[j] = self.stars[body_id][0][j] - node.com[j]

        return self.calculate_acceleration(distance, node.mass)

    cdef double[:] calculate_acceleration(self, double[:] d, float m):
        """
        Calculate the acceleration on a body, given the distance and mass
        of an object relative to the body
        
        :param d: Distance of the body generating the acceleration (array of len 3)
        :param m: Mass of the body generating the acceleration
        
        :return: Acceleration - array of length 3 for each acceleration
        """
        cdef:
            double[:] acceleration = np.zeros(3)
            double constant
            Py_ssize_t j

        # Find the gravitational constant and the distances

        # Constant in gravitational eq, with a softening factor
        constant = -(( 6.67 * math.pow(10., -12.) * m)   /   (math.pow( np.dot(d, d) , 3) + self.sf))

        # Multiply by the directional vector to decompose
        for j in range(3):
            acceleration[j] = constant * d[j]

        return acceleration
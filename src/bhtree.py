from src.node import Node




import numpy as np
import math
from mpi4py import MPI


class BHTree:

    def __init__(self, area):
        self.area = area
        self.theta = 0.7
        self.root_node = Node(self.area)

    def populate(self):
        """
        Populates the barnes hut tree
        
        Calling this will populate the Barnes Hut Tree. 
        
        :return: 
        """
        n = len(self.stars)
        # Reset the tree
        self.reset_children()
        # Iterate through each body
        for i in range(n):
            self.root_node.add_body(self.stars, self.star_mass, i)

    def reset_children(self):
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

    def iterate(self, dt):
        """
        Iterates the system forward by a time dt.
        
        The data can be retrieved from the immutable property
        BHTree.stars.
        
        :param dt: Timestep in s to iterate the system by
         
        :return: 
        """
        n = len(self.stars)
        body_totals = np.zeros((n, 3, 3), dtype=np.float64)
        stars = np.zeros((n, 3, 3), dtype=np.float64)

        comm = MPI.COMM_WORLD
        rank = comm.Get_rank()
        num_p = comm.Get_size()

        # Split up the stars between the processes.
        l = (n / num_p)
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

        # Each rank iterates through their own bodies, saving the data to 'stars'
        i = 0

        while i < num_of_bodies:

            body_id = bodies[i]

            # Get the acceleration
            acceleration = self.get_acceleration_of_body(body_id, self.root_node)
            
            # Update star data
            for j in range(3):

                # r(1) += v(0)*dt + 1/2 * a(0) * dt
                stars[body_id][0][j] = self.stars[body_id][0][j] + self.stars[body_id][1][j] * dt + 0.5 * self.stars[body_id][2][j] * dt

                # v(1) += (a(0)  + 1/2 * newacc) * dt
                stars[body_id][1][j] = self.stars[body_id][1][j] + (self.stars[body_id][2][j] + 1/2 * acceleration[j]) * dt

                # a(1) += a(new)
                stars[body_id][2][j] += acceleration[j]

            i = i + 1

        comm.Allreduce(
            stars,
            body_totals,
            op = MPI.SUM
        )
        self.stars = body_totals

    def get_acceleration_of_body(self, body_id, node):
        """
        Gets the change in acceleration of the body given due to the node given
        
        :param body_id: The body to calculate the acceleration for
        :param node: The node to calculate the acceleration within
        
        :return: array len 3, with the three components of acceleration due to node node
        """
            
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

    def get_acceleration_due_to_body(self, body_id, gen_body_id):
        """
        Get the acceleration on a body due to another body
        
        :param body_id: Body to calculate the acceleration of
        :param gen_body_id: Body to calculate the acceleration due to
        :return: 
        """
        distance = np.zeros(3)

        for j in range(3):
            distance[j] = self.stars[body_id][0][j] - self.stars[gen_body_id][0][j]

        return self.calculate_acceleration(distance, self.star_mass[gen_body_id])

    def get_acceleration_due_to_node(self, body_id, node):
        """
        Get the acceleration of a body due to a node (i.e. multiple bodies)
        
        :param body_id: Body to calculate the acceleration of
        :param node: Node which contains the bodies providing a force
        
        :return: 
        """
        distance = np.zeros(3)

        for j in range(3):
            distance[j] = self.stars[body_id][0][j] - node.com[j]

        return self.calculate_acceleration(distance, node.mass)

    def calculate_acceleration(self, d, m):
        """
        Calculate the acceleration on a body, given the distance and mass
        of an object relative to the body
        
        :param d: Distance of the body generating the acceleration (array of len 3)
        :param m: Mass of the body generating the acceleration
        
        :return: Acceleration - array of length 3 for each acceleration
        """
        acceleration = np.zeros(3)

        # Find the gravitational constant and the distances

        # Constant in gravitational eq, with a softening factor
        constant = -(( 6.67 * math.pow(10., -12.) * m)   /   (math.pow( np.dot(d, d) , 3) + self.sf))

        # Multiply by the directional vector to decompose
        for j in range(3):
            acceleration[j] = constant * d[j]

        return acceleration
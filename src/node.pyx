# cython: profile=True
# cython: linetrace=True

import numpy as np
cimport numpy as np

cdef class Node:

    def __init__(self, double[:, :] area, int depth=0):
        self.parent = 0
        self.area = area
        self.children = np.array([None,None,None,None,None,None,None,None], dtype=Node)
        self.depth = depth
        self.mass = 0
        self.com = np.array([0,0,0], dtype=np.float64)
        self.max_depth = 25
        self.bodies = np.zeros(0, dtype=np.intc)

    cdef void add_body(self, double[:, :, :] stars, double[:] star_mass, int body_id) except *:
        """
        Add a body in a node or chile node
        
        :param stars: Positions, velocities and accelerations of the bodies
        :param star_mass: Masses of the stars
        :param body_id: ID of the body being added
        
        :return: 
        """
        cdef Py_ssize_t body, node_id

        # Change the centre of mass and the mass of the node
        # Even if a body is saved in a child node, we still alter the CoM and mass.
        old_mass = self.mass
        self.mass = self.mass + star_mass[body_id]
        for j in range(3):
            self.com[j] = ((self.com[j] * old_mass) + (stars[body_id][0][j] * star_mass[body_id]))/self.mass

        # This node is either a parent, or has bodies present already
        if (len(self.bodies) > 0 or self.parent is 1) and self.depth <= self.max_depth:

            # Build up an array of all bodies to be added
            detached_bodies = [body_id]
            if len(self.bodies) > 0:
                detached_bodies = np.append(detached_bodies, self.bodies)
                self.bodies = np.array([], dtype=np.intc)

            # Iterate through each body to add to a child
            for body in detached_bodies:

                # Get the index of the node to add the body to
                index = np.array([0,1,2,3,4,5,6,7], dtype=np.intc)
                index = index[:4] if stars[body][0][0] <= np.sum(self.area[:, 0])/2 else index[4:]
                index = index[:2] if stars[body][0][1] <= np.sum(self.area[:, 1])/2 else index[2:]
                index = index[:1] if stars[body][0][2] <= np.sum(self.area[:, 2])/2 else index[1:]
                node_id = int(index[0])

                # Create a new node for a child if needed
                if self.children[node_id] is None:
                    new_area = np.zeros((2, 3), dtype=np.float64)
                    if node_id == 0:
                        new_area = np.array([[self.area[0][0], self.area[0][1], self.area[0][2]], [np.sum(self.area[:, 0])/2, np.sum(self.area[:, 1])/2, np.sum(self.area[:, 2])/2]], dtype=np.float64)
                    elif node_id == 1:
                        new_area = np.array([[self.area[0][0], self.area[0][1], np.sum(self.area[:, 2])/2], [np.sum(self.area[:, 0])/2, np.sum(self.area[:, 1])/2, self.area[1][2]]], dtype=np.float64)
                    elif node_id == 2:
                        new_area = np.array([[self.area[0][0], np.sum(self.area[:, 1])/2, self.area[0][2]], [np.sum(self.area[:, 0])/2, self.area[1][1], np.sum(self.area[:, 2])/2]], dtype=np.float64)
                    elif node_id == 3:
                        new_area = np.array([[self.area[0][0], np.sum(self.area[:, 1])/2, np.sum(self.area[:, 2])/2], [np.sum(self.area[:, 0])/2, self.area[1][1], self.area[1][2]]], dtype=np.float64)
                    elif node_id == 4:
                        new_area = np.array([[np.sum(self.area[:, 0])/2, self.area[0][1], self.area[0][2]], [self.area[1][0], np.sum(self.area[:, 1])/2, np.sum(self.area[:, 2])/2]], dtype=np.float64)
                    elif node_id == 5:
                        new_area = np.array([[np.sum(self.area[:, 0])/2, self.area[0][1], np.sum(self.area[:, 2])/2], [self.area[1][0], np.sum(self.area[:, 1])/2, self.area[1][2]]], dtype=np.float64)
                    elif node_id == 6:
                        new_area = np.array([[np.sum(self.area[:, 0])/2, np.sum(self.area[:, 1])/2, self.area[0][2]], [self.area[1][0], self.area[1][1], np.sum(self.area[:, 2])/2]], dtype=np.float64)
                    elif node_id == 7:
                        new_area = np.array([[np.sum(self.area[:, 0])/2, np.sum(self.area[:, 1])/2, np.sum(self.area[:, 2])/2], [self.area[1][0], self.area[1][1], self.area[1][2]]], dtype=np.float64)

                    child_node = Node(new_area, self.depth+1)
                    self.children[node_id] = child_node

                # Add the body to the new child node
                (<Node>self.children[node_id]).add_body(stars, star_mass, body)

            self.parent = 1

        # This node is empty, so we can just add the body straight away.
        else:
            self.bodies = np.append(self.bodies, np.array(body_id, dtype=np.intc))
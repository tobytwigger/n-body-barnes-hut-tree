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
        cdef Py_ssize_t body, node_id

        mass_ratio = star_mass[body_id] / (self.mass + star_mass[body_id])
        self.com[0] = (self.com[0] * self.mass) + (stars[body_id][0][0] * mass_ratio)
        self.com[1] = (self.com[1] * self.mass) + (stars[body_id][0][1] * mass_ratio)
        self.com[2] = (self.com[2] * self.mass) + (stars[body_id][0][2] * mass_ratio)
        self.mass = self.mass + star_mass[body_id]
        # If we have bodies already present or this is a parent
        if (len(self.bodies) > 0 or self.parent is 1) and self.depth <= self.max_depth:
            detached_bodies = [body_id]  # bodies to add to children
            if len(self.bodies) > 0:
                # if node has children, move own body down to child
                detached_bodies = np.append(detached_bodies, self.bodies)
                self.bodies = np.array([], dtype=np.intc)

            for body in detached_bodies:
                # Find the node ID
                index = np.array([0,1,2,3,4,5,6,7], dtype=np.intc)
                index = index[:4] if stars[body][0][0] <= np.sum(self.area[:, 0])/2 else index[4:]
                index = index[:2] if stars[body][0][1] <= np.sum(self.area[:, 1])/2 else index[2:]
                index = index[:1] if stars[body][0][2] <= np.sum(self.area[:, 2])/2 else index[1:]
                node_id = int(index[0])

                if not self.children[node_id]:
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

                self.temp_node = self.children[node_id]
                self.temp_node.add_body(stars, star_mass, body)


            self.parent = 1


        else:
            new_bodies = np.append(self.bodies, np.array(body_id, dtype=np.intc))
            self.bodies = new_bodies
            self.mass = self.mass + star_mass[body_id]
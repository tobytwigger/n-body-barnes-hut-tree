# cython: profile=True
# cython: linetrace=True

import numpy as np
cimport numpy as np

class Node:

    def __init__(self, area, depth=0):
        self.bodies = np.array([], dtype=np.int64)
        self.parent = False
        self.area = area
        self.children = np.full(8, None)
        self.depth = depth
        self.mass = 0
        self.com = np.array(3, dtype=float)

    def addBody(self, all_bodies, body_id):
        self.com = ((self.com * self.mass) + (all_bodies.get_position(body_id) * all_bodies.masses[body_id]))/(self.mass + all_bodies.masses[body_id])
        self.mass += all_bodies.masses[body_id]
        # If we have bodies already present or this is a parent
        if (len(self.bodies) > 0 or self.parent) and self.depth <= all_bodies.max_depth:
            detached_bodies = [body_id]  # bodies to add to children
            if len(self.bodies) > 0:
                # if node has children, move own body down to child
                detached_bodies = np.append(detached_bodies, self.bodies)
                self.bodies = np.array([], dtype=np.int64)

            for body in detached_bodies:
                node_id = int(self.area.get_node_index(all_bodies.get_position(body)))

                if not self.children[node_id]:
                    child_area = self.area.get_node_index_area(node_id)
                    self.children[node_id] = Node(child_area, self.depth+1)

                self.children[node_id].addBody(all_bodies, body)


            self.parent = True


        else:
            self.bodies = np.append(np.array(self.bodies, dtype=np.int64), body_id)
            self.mass += all_bodies.masses[body_id]

    def get_center_of_mass(self, bodies):
        return self.com

    def get_total_mass(self, bodies):
        return self.mass
import numpy as np
cimport numpy as np

cdef class Node:

    def __cinit__(self, area, depth=0):
        self.bodies = np.empty(0, dtype=np.int32)
        self.parent = False
        self.area = area
        self.children = np.empty(8, dtype=object)
        self.depth = depth

    cpdef void addBody(self, Bodies all_bodies, int body_id) except *:
        cdef int[:] detached_bodies = np.empty(0, dtype=np.int32)

        # If we have bodies already present or this is a parent
        if (len(self.bodies) > 0 or self.parent) and self.depth <= all_bodies.max_depth:
            detached_bodies = np.append(detached_bodies, np.array([body_id], dtype=np.int32)) # bodies to add to children
            if len(self.bodies) > 0:
                # if node has children, move own body down to child

                detached_bodies = np.append(detached_bodies, self.bodies) # bodies to add to children
                self.bodies = np.empty(0, dtype=np.int32)


            for each_body in detached_bodies:
                node_id = self.area.get_node_index(all_bodies.get_position(each_body))

                if self.children[node_id] is None:
                    child_area = self.area.get_node_index_area(node_id)
                    child_depth = self.depth + 1
                    self.children[node_id] = Node(child_area, child_depth)



                self.children[node_id].addBody(all_bodies, each_body)


            self.parent = True


        else:
            self.bodies = np.append(self.bodies, np.array([body_id], dtype=np.int32))

    cpdef double[:] get_center_of_mass(self, Bodies bodies) except *:
        com = np.zeros(3)
        if self.parent:
            for child_node in self.children:
                if child_node is not None:
                    com += child_node.get_center_of_mass(bodies)
        else:
            for body_id in self.bodies:
                com += [p * bodies.masses[body_id] for p in bodies.get_position(body_id)]
        return com

    cpdef float get_total_mass(self, Bodies bodies) except *:
        total_mass = 0
        if self.parent:
            for child_node in self.children:
                if child_node is not None:
                    total_mass += child_node.get_total_mass(bodies)
        else:
            for body_id in self.bodies:
                total_mass += bodies.masses[body_id]
        return total_mass
import numpy as np

class Node():

    def __init__(self, area, depth=0):
        self.bodies = []
        self.parent = False
        self.area = area
        self.children = [None] * 8
        self.depth = depth

    def addBody(self, all_bodies, body_id):
        # If we have bodies already present or this is a parent
        if (len(self.bodies) > 0 or self.parent) and self.depth <= all_bodies.max_depth:
            detached_bodies = [body_id]  # bodies to add to children
            if len(self.bodies) > 0:
                # if node has children, move own body down to child
                detached_bodies.extend(self.bodies)
                self.bodies = []

            for body in detached_bodies:
                node_id = int(self.area.get_node_index(all_bodies.get_position(body)))

                if not self.children[node_id]:
                    child_area = self.area.get_node_index_area(node_id)
                    self.children[node_id] = Node(child_area, self.depth+1)

                self.children[node_id].addBody(all_bodies, body)


            self.parent = True


        else:
            self.bodies.append(body_id)

    def get_center_of_mass(self, bodies):
        com = np.zeros(3)
        if self.parent:
            for child_node in self.children:
                if child_node is not None:
                    com += child_node.get_center_of_mass(bodies)
        else:
            for body_id in self.bodies:
                com += (bodies.get_position(body_id) * bodies.masses[body_id])
        return com

    def get_total_mass(self, bodies):
        total_mass = 0
        if self.parent:
            for child_node in self.children:
                if child_node is not None:
                    total_mass += child_node.get_total_mass(bodies)
        else:
            for body_id in self.bodies:
                total_mass += bodies.masses[body_id]
        return total_mass
from bodies import Bodies
from area import Area

class Node():

    def __init__(self, area, depth=0):
        self.bodies = []
        self.parent = False
        self.area = area
        self.children = [None] * 8
        self.depth = depth
        pass

    def addBody(self, body_id):
        # If we have bodies already present or this is a parent
        if (len(self.bodies) > 0 or self.parent) and self.depth <= Bodies.max_depth:
            detached_bodies = [body_id]  # bodies to add to children
            if len(self.bodies) > 0:
                # if node has children, move own body down to child
                detached_bodies.extend(self.bodies)
                self.bodies = []

            for body in detached_bodies:
                node_id = int(self.area.get_node_index(Bodies.get_position(body)))

                if not self.children[node_id]:
                    child_area = self.area.get_node_index_area(node_id)
                    self.children[node_id] = Node(child_area, self.depth+1)

                self.children[node_id].addBody(body)


            self.parent = True


        else:
            self.bodies.append(body_id)


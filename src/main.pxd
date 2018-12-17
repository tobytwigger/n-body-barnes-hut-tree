from node import Node
from bodies import Bodies
from area cimport Area






cpdef drawGrid(ax, Node node)

cpdef plotNodeArea(ax, Area area)

cpdef drawForces(ax, Bodies bodies)

cpdef void saveScatterPlot(fig, double[:,:] x, double[:,:] y, double[:,:] z, str directory, int iter_number, Node root_node=None, Bodies bodies=None)

cpdef void main(int iterations, str folder, float dt, float area_side, int num_bodies)


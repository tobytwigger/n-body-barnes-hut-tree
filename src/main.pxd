from src.node import Node
from src.node cimport Node

from src.bodies import Bodies
from src.bodies cimport Bodies

from src.area import Area
from src.area cimport Area

from src.bhtree import BHTree
from src.bhtree cimport BHTree

cdef drawGrid(ax, Node node)

cdef plotNodeArea(ax, Area area)

cdef drawForces(ax, Bodies bodies)

cdef void saveScatterPlot(fig, double[:] x, double[:] y, double[:] z, str directory, int iter_number, Node root_node, Bodies bodies)

cpdef void main(int iterations, str folder, float dt, float area_side, int num_bodies) except *


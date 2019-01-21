# cython: profile=True
# cython: linetrace=True

import numpy as np
cimport numpy as np

cdef class Galaxy:

    cdef double[:, :, :] stars
    cdef double[:] star_mass
    cdef double[:, :] area

    cdef void spiral(self) except *

    cdef void four_bodies(self) except *
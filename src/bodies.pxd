# cython: profile=True
# cython: linetrace=True

import numpy as np
cimport numpy as np

from src.area import Area
from src.area cimport Area

cdef class Bodies:

    cdef int max_depth
    cdef Area area
    cdef np.ndarray positions
    cdef np.ndarray velocities
    cdef np.ndarray accelerations
    cdef np.ndarray masses
    cdef np.ndarray forces
    cdef int n

    cdef np.ndarray generate_3d_array(self, int n, double min, double max)

    cdef void generate_data(self, Area area, int n)

    cdef void update_body(self, np.ndarray acceleration_dt, np.ndarray velocity_dt, np.ndarray position_dt, Py_ssize_t body_id)

    cdef void update_accelerations(self, np.ndarray accelerations, Py_ssize_t body_id)

    cdef void update_velocities(self, np.ndarray velocities, Py_ssize_t body_id)

    cdef void update_positions(self, np.ndarray positions, Py_ssize_t body_id)

    cdef double get_mass(self, Py_ssize_t body_id)

    cdef double get_total_mass(self)

    cdef np.ndarray get_position(self, Py_ssize_t body_id)

    cdef double maxb_x(self)

    cdef double maxb_y(self)

    cdef double maxb_z(self)

    cdef double minb_x(self)

    cdef double minb_y(self)

    cdef double minb_z(self)

    cdef Area get_area(self)
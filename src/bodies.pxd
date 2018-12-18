from src.area import Area
from src.area cimport Area

cdef class Bodies(object):

    cdef int max_depth
    cdef Area area
    cdef double[:, :] positions
    cdef double[:, :] velocities
    cdef double[:, :] accelerations
    cdef double[:] masses
    cdef double[:, :] forces
    cdef int n

    cdef void generate_data(self, Area area, int n) except *

    cdef void accelerate(self, int body_id, double [:] acceleration_dt, float dt) except *

    cdef void update_accelerations(self, double [:] accelerations, int body_id) except *

    cdef void update_velocities(self, double [:] velocities, int body_id) except *

    cdef void update_positions(self, double [:] positions, int body_id) except *

    cdef double get_mass(self, int body_id) except *

    cdef double get_total_mass(self) except *

    cdef double[:] get_position(self, int body_id) except *

    cdef double maxb_x(self) except *

    cdef double  maxb_y(self) except *

    cdef double  maxb_z(self) except *

    cdef double  minb_x(self) except *

    cdef double  minb_y(self) except *

    cdef double  minb_z(self) except *
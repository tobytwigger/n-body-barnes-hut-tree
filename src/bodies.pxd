from src.area import Area
from src.area cimport Area

cdef class Bodies:

    cdef int max_depth
    cdef Area area
    cdef double[:, :] positions
    cdef double[:, :] velocities
    cdef double[:, :] accelerations
    cdef double[:] masses
    cdef double[:, :] forces
    cdef int n

    cpdef void generate_data(self, Area area, int n) except *

    cpdef void accelerate(self, int body_id, double [:] acceleration_dt, float dt) except *

    cpdef void update_accelerations(self, double [:] accelerations, int body_id) except *

    cpdef void update_velocities(self, double [:] velocities, int body_id) except *

    cpdef void update_positions(self, double [:] positions, int body_id) except *

    cpdef double get_mass(self, int body_id) except *

    cpdef double get_total_mass(self) except *

    cpdef double[:] get_position(self, int body_id) except *

    cpdef double maxb_x(self) except *

    cpdef double  maxb_y(self) except *

    cpdef double  maxb_z(self) except *

    cpdef double  minb_x(self) except *

    cpdef double  minb_y(self) except *

    cpdef double  minb_z(self) except *
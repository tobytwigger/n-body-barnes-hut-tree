from area cimport Area

cdef class Bodies(object):

    cdef int max_depth
    cdef Area area
    cdef double[:, :] positions
    cdef double[:, :] velocities
    cdef double[:, :] accelerations
    cdef double[:] masses
    cdef double[:, ] forces
    cdef int n

    cpdef void generate_data(self, Area area, int n)

    cpdef void accelerate(self, int body_id, acceleration, float dt)

    cpdef double get_mass(self, int body_id)

    cpdef double get_total_mass(self)

    cpdef double[:] get_position(self, int body_id)

    cpdef double maxb_x(self)

    cpdef double  maxb_y(self)

    cpdef double  maxb_z(self)

    cpdef double  minb_x(self)

    cpdef double  minb_y(self)

    cpdef double  minb_z(self)

    cpdef Area  get_area(self)

    cpdef void set_area(self, Area area)
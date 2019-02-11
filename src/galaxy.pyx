# cython: profile=True
# cython: linetrace=True

import numpy as np
cimport numpy as np
import random
import math
# import illustrisAPI.iApi as ill
import sys

cdef class Galaxy:

    cdef void spiral(self) except *:
        n = 500
        area_side = 5*10**15
        area = np.array( [ [0, 0, 0], [area_side, area_side, area_side] ] , dtype=np.float64)
        self.stars = np.zeros((n, 3, 3), dtype=np.float64)

        galaxy_radius = max([area[1][0]-area[0][0], area[1][1]-area[0][1], area[1][2]-area[0][2]])
        number_of_arms = 3
        number_of_disk_stars = int(n * 0.35)
        radius_of_core = galaxy_radius * 0.6
        radius_of_disk = galaxy_radius - radius_of_core
        tightness_of_arms = 0.5
        width_of_arm = 65 #degrees
        noise_factor = 0.01
        depth_of_arms = int((area[1][0] - area[0][0])/7)
        depth_of_core = int((area[1][0] - area[0][0])/4)

        maximum_star_velocity = 1800.
        minimum_star_velocity = 2400.

        # omega is the separation (in degrees) between each arm
        # Prevent div by zero error:
        if number_of_arms:
            omega = 360.0 / number_of_arms
        else:
            omega = 0.0
        i = 0
        while i < number_of_disk_stars:

            # Choose a random distance from center
            fake_distance = radius_of_core + random.random() * radius_of_disk
            distance = fake_distance + random.uniform(0,radius_of_disk * 0.1)

            # This is the 'clever' bit, that puts a star at a given distance
            # into an arm: First, it wraps the star round by the number of
            # rotations specified.  By multiplying the distance by the number of
            # rotations the rotation is proportional to the distance from the
            # center, to give curvature
            theta = ((360.0 * tightness_of_arms * (distance / radius_of_disk))

                     # Then move the point further around by a random factor up to
                     # ARMWIDTH
                     + random.random() * width_of_arm

                     # Then multiply the angle by a factor of omega, putting the
                     # point into one of the arms
                     # + (omega * random.random() * number_of_arms )
                     + omega * random.randrange(0, number_of_arms)

                     # Then add a further random factor, 'fuzzin' the edge of the arms
                     + random.random() * noise_factor * max([area[1][0]-area[0][0], area[1][1]-area[0][1], area[1][2]-area[0][2]])
                     # + random.randrange( -noise_factor, noise_factor )
                     )

            # Convert to cartesian
            x = math.cos(theta * math.pi / 180.0) * distance
            y = math.sin(theta * math.pi / 180.0) * distance
            z = random.random() * depth_of_arms * 2.0 - depth_of_arms

            # Add star to the self.stars array
            self.stars[i][0][0] = x
            self.stars[i][0][1] = y
            self.stars[i][0][2] = z

            # Process next star
            i = i + 1

        scale = depth_of_core / (radius_of_core * radius_of_core)

        while i < n:

            # Choose a random distance from center
            dist = random.random() * radius_of_core
            distance = dist + random.uniform(0,radius_of_core * 0.1)

            # Any rotation (points are not on arms)
            theta = random.random() * 360

            # Convert to cartesian
            x = math.cos(theta * math.pi / 180.0) * distance
            y = math.sin(theta * math.pi / 180.0) * distance
            z = (random.random() * 2 - 1) * (depth_of_core - scale * distance * distance)

            # Add star to the self.stars array
            self.stars[i][0][0] = x
            self.stars[i][0][1] = y
            self.stars[i][0][2] = z

            # Process next star
            i = i + 1

        for i in range(n):
            velocity = minimum_star_velocity + (random.random())/4 * maximum_star_velocity
            # velocities = np.zeros(3)
            #
            # velocities[0] = (
            # # Velocity of a star at a distance
            # # R from the center of a galaxy
            # (math.pi * math.sqrt(self.positions[i][0]**2 + self.positions[i][1]**2))
            # # Random noise
            # + (np.random.normal(0, (math.pi * math.sqrt(self.positions[i][0]**2 + self.positions[i][1]**2)) * 0.05))
            # )
            # velocities[1] = (
            # (math.pi * math.sqrt(self.positions[i][0]**2 + self.positions[i][1]**2))
            # + (np.random.normal(0, (math.pi * math.sqrt(self.positions[i][0]**2 + self.positions[i][1]**2)) * 0.05))
            # )
            # velocities[2] = 0

            # Direction
            self.stars[i][1][0] = velocity * math.sin(theta)
            self.stars[i][1][1] = velocity * math.cos(theta)
            self.stars[i][1][2] = random.random() * minimum_star_velocity / 10

        i = 0
        while i < n:
            self.stars[i][2][0] = random.random() * 100
            self.stars[i][2][1] = random.random() * 100
            self.stars[i][2][2] = random.random() * 100
            i = i + 1

        self.star_mass = np.full(n, 8*10**19, dtype=np.float64)
        self.area = area

    cdef void four_bodies(self) except *:
        self.star_mass = np.full(4, 1, dtype=np.float64)
        # self.star_mass[3] = 1000000000
        self.area = np.array( [ [0., 0., 0.], [10., 10., 10.] ] )
        # self.stars = np.array([
        # [
        #     [1., 1., 0.],
        #     [0.1, 0.3, 0.1],
        #     [0.1, 0.1, 0.]
        # ], [
        #     [9., 9., 0.],
        #     [-0.1, -0.3, 0.],
        #     [-0.1, -0.1, 0.4]
        # ], [
        #     [4., 4., 0.],
        #     [0.1, 0.3, 0.],
        #     [0.1, 0.1, 0.5]
        # ], [
        #     [3., 9., 1.0],
        #     [-0.1, -0.3, 0.2],
        #     [-0.1, -0.1, 0.1]
        # ]], dtype=np.float64)
        self.stars = np.array([
        [
            [1., 1., 1.],
            [0., 0., 0.],
            [0., 0., 0.]
        ], [
            [9., 2., 5.4],
            [0., 0., 0.],
            [0., 0., 0.],
        ], [
            [4., 6., 1.],
            [0., 0., 0.],
            [0., 0., 0.],
        ], [
            [3., 10., 10.],
            [0., 0., 0.],
            [0., 0., 0.],
        ]], dtype=np.float64)
    #
    # def illustris(self):
    #     fields = [
    #         [4,'Masses'], # star mass (N_star values)
    #         [4,'Coordinates'], # star position (N_star x 3 values)
    #         [4,'Velocities'], # star velocity (N_star x 3 values)
    #     ]
    #     galaxyData = ill.getGalaxy(100, fields, simulation='Illustris-3', snapshot=85)
    #     mStar=galaxyData[0][:]
    #     rStar=galaxyData[1][:,:] #don't forget this is a 2d array
    #     vStar=galaxyData[2][:,:]
    #     print(mStar)
    #     print(rStar)
    #     print(vStar)
    #     self.star_mass = mStar
    #     # self.stars = np.array([])

    def TomCode(self):
        # Define parameters
        n = 1000
        area_side = 1
        area = np.array( [ [0, 0, 0], [area_side, area_side, area_side] ] , dtype=np.float64)

        # Generate Galaxy
        masses, velocities, points = self._DefInitial(n, area_side)

        self.star_mass = masses
        stars = np.zeros((n, 3, 3))
        stars[:, 0, :] = points
        stars[:, 1, :] = velocities
        # print(stars)
        self.area = area
        self.stars = stars

        # print(np.asarray(self.stars))
        # print(np.asarray(self.star_mass))


    def _DefInitial(self, n, size):
        '''
        Generates a spiral galaxy
        '''
        # Generate holders
        masses = abs(np.random.normal(0.5, 0.05, n))
        velocities = np.zeros((n, 3))
        points = np.zeros((n, 3))

        # Generate Positions
        points = self._DefPoints(size, points)

        internal_COMs = np.zeros((n, 3))
        internal_masses = np.zeros(n)
        distances = np.linalg.norm(points[:, 0:2], axis = 1)

        for i in range(n):
            COM_points = points[distances < distances[i]]
            COM_masses = masses[distances < distances[i]]

            internal_masses[i] = np.sum(COM_masses)
            if internal_masses[i] != 0:
                internal_COMs[i] = np.tensordot(COM_points, COM_masses, axes = (0, 0)) / internal_masses[i]
            else:
                internal_COMs[i] = [0.0, 0.0, 0.0]

        relative_points = points - internal_COMs

        # Generate Velocities
        velocities = self._DefVelocities(size, relative_points, internal_masses, velocities)
        return masses, velocities, points

    def _DefPoints(self, size, points):
        '''
        Initialises galaxy points
        '''
        n = len(points)
        galaxy_spread = size / 5

        points_r = np.random.exponential(size, n)
        points_p = np.random.rand(n) * 2 * np.pi

        points_x = points_r * np.cos(points_p)
        points_y = points_r * np.sin(points_p)

        points[:, 0] = np.random.normal(0, galaxy_spread, n) + points_x
        points[:, 1] = np.random.normal(0, galaxy_spread, n) + points_y
        points[:, 2] = np.random.normal(0, galaxy_spread, n)

        return points

    def _DefVelocities(self, size, relative_points, internal_masses, velocities):
        '''
        Initialises point velocities
        '''

        relative_distances = np.linalg.norm(relative_points, axis = 1)
        speeds = np.sqrt((internal_masses * 10.0**-11) / (relative_distances))

        radial_vectors = relative_points[:, 0:2]
        vertical_vectors = np.random.normal(0, speeds / 1000, len(velocities))

        vectors = np.zeros((len(velocities), 3))
        vectors[:, 0] = - radial_vectors[:, 1]
        vectors[:, 1] = radial_vectors[:, 0]
        vectors[:, 2] = vertical_vectors

        normalisation = np.linalg.norm(vectors, axis = 1)
        velocities[:, 0] = speeds * (vectors[:, 0] / normalisation)
        velocities[:, 1] = speeds * (vectors[:, 1] / normalisation)
        velocities[:, 2] = speeds * (vectors[:, 2] / normalisation)
        return velocities

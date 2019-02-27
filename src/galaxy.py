# cython: profile=False
# cython: linetrace=False
# cython: cdivision=True
# cython: boundscheck=False
# cython: wraparound=False
# cython: initializedcheck=False
import numpy as np
import random
import math
# import illustrisAPI.iApi as ill
import sys

class Galaxy:

    def TomCode(self):
        # Define parameters
        n = 100
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
        masses = abs(np.random.normal(1, 0.5, n))
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
        vertical_vectors = np.random.normal(0, speeds / 10, len(velocities))

        vectors = np.zeros((len(velocities), 3))
        vectors[:, 0] = - radial_vectors[:, 1]
        vectors[:, 1] = radial_vectors[:, 0]
        vectors[:, 2] = vertical_vectors

        normalisation = np.linalg.norm(vectors, axis = 1)
        velocities[:, 0] = speeds * (vectors[:, 0] / normalisation)
        velocities[:, 1] = speeds * (vectors[:, 1] / normalisation)
        velocities[:, 2] = speeds * (vectors[:, 2] / normalisation)
        return velocities

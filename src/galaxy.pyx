# cython: profile=False
# cython: linetrace=False
# cython: cdivision=True
# cython: boundscheck=False
# cython: wraparound=False
# cython: initializedcheck=False
import numpy as np
cimport numpy as np
import random
import math
# import illustrisAPI.iApi as ill
import sys

cdef class Galaxy:

    def SpiralGalaxy(self, n):
        '''

        Generate a spiral galaxy with position, mass and velocity

        :param n:
        :return:
        '''
        # Define galaxy area
        area_side = 1
        area = np.array( [ [0, 0, 0], [area_side, area_side, area_side] ] , dtype=np.float64)

        # Generate data about the galaxy
        masses, velocities, positions = self.getInitialConfiguration(n, area_side)

        # Create a stars array
        stars = np.zeros((n, 3, 3))
        stars[:, 0, :] = positions
        stars[:, 1, :] = velocities

        # Set the variables to be retrieved
        self.star_mass = masses
        self.area = area
        self.stars = stars

    def getInitialConfiguration(self, n, area_side):
        '''

        Generate the masses, velocities and positions of a spiral galaxy

        :param n:
        :param area_side:
        :return:
        '''

        # Generate Masses
        masses = abs(np.random.normal(1, 0.5, n)) # Gaussian for masses

        # Generate Positions
        position = self.getInitialPosition(n, area_side)

        # Build up some information about the galaxy so we can use density curves etc

        # Contains the centre of mass enclosed in a circle with a radius from the star to the centre of the galaxy
        enclosed_COMs = np.zeros((n, 3))

        # Contains the sum of masses enclosed in a circle with a radius from the star to the centre of the galaxy
        enclosed_masses = np.zeros(n)

        # Radius length for each star
        distances = np.linalg.norm(position[:, 0:2], axis = 1)

        # Populate
        for i in range(n):
            # Get the total CoM and Mass within star i
            COM_position = position[distances < distances[i]]
            COM_masses = masses[distances < distances[i]]

            # Save the masses and COMs
            enclosed_masses[i] = np.sum(COM_masses)
            if enclosed_masses[i] != 0:
                enclosed_COMs[i] = np.tensordot(COM_position, COM_masses, axes = (0, 0)) / enclosed_masses[i]
            else:
                enclosed_COMs[i] = [0.0, 0.0, 0.0]

        # Position relative to each stars CoM, used for velocity calculation
        position_from_com = position - enclosed_COMs

        # Generate Velocities
        velocities = self.getInitialVelocity(area_side, position_from_com, enclosed_masses, n)
        return masses, velocities, position

    def getInitialPosition(self, n, area_side):
        '''
        Create a random distribution of positional vectors

        :param n:
        :param area_side:
        :return:
        '''
        galaxy_sd = area_side / 5 # How large is the central bit of the galaxy

        # Generate in polar coordinates
        position_radial = np.random.exponential(area_side, n)
        position_angular = np.random.rand(n) * 2 * np.pi

        # Convert to cartesian
        position_x = position_radial * np.cos(position_angular)
        position_y = position_radial * np.sin(position_angular)

        position = np.zeros((n, 3))
        position[:, 0] = np.random.normal(0, galaxy_sd, n) + position_x
        position[:, 1] = np.random.normal(0, galaxy_sd, n) + position_y
        position[:, 2] = np.random.normal(0, galaxy_sd, n)

        return position

    def getInitialVelocity(self, area_side, position_from_com, enclosed_masses, n):
        '''
        Create a random distribution of velocities

        :param area_side:
        :param position_from_com:
        :param enclosed_masses:
        :param n:
        :return:
        '''

        # Relative distances of each body
        relative_distances = np.linalg.norm(position_from_com, axis = 1)

        # Magnitude of the velocity at which the body should be travelling
        magnitude = np.sqrt((enclosed_masses * 10.0**-11) / relative_distances)

        # Calculate the angle of velocity
        radial_vectors = position_from_com[:, 0:2]
        vertical_vectors = np.random.normal(0, magnitude / 10, n)

        vectors = np.zeros((n, 3))
        vectors[:, 0] = - radial_vectors[:, 1]
        vectors[:, 1] = radial_vectors[:, 0]
        vectors[:, 2] = vertical_vectors

        normalisation = np.linalg.norm(vectors, axis = 1)
        velocities = np.zeros((n, 3))
        velocities[:, 0] = magnitude * (vectors[:, 0] / normalisation)
        velocities[:, 1] = magnitude * (vectors[:, 1] / normalisation)
        velocities[:, 2] = magnitude * (vectors[:, 2] / normalisation)

        return velocities

import src.main as universe
import os
import sys


directory = 'images/profileTest'
if not os.path.exists(directory):
    os.makedirs(directory)
area_side = 1*10**5
num_bodies = 400
universe.main(10, directory, 0.01, area_side, num_bodies)
import src.main as universe
import os
import sys

if int(len(sys.argv)) != 4 and False:
    print("Usage: {} <ITERATIONS> <FOLDER> <dt>".format(sys.argv[0]))
else:
    iterations = int(sys.argv[1])

    directory = 'images/{}'.format(sys.argv[2])
    if not os.path.exists(directory):
        os.makedirs(directory)

    dt = float(sys.argv[3])
    dt = dt * 10 ** -20
    area_side = 1*10**5
    num_bodies = 400
    universe.main(iterations, directory, dt, area_side, num_bodies)
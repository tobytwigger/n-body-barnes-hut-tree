import src.main as universe
import os
import sys

if int(len(sys.argv)) != 4:
    print("Usage: {} <ITERATIONS> <FOLDER> <dt>".format(sys.argv[0]))
else:
    directory = 'images/{}'.format(sys.argv[2])
    if not os.path.exists(directory):
        os.makedirs(directory)
    area_side = 1*10**5
    num_bodies = 400
    universe.main(sys.argv[1], sys.argv[2], sys.argv[3],area_side, num_bodies)
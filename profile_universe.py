import pstats, cProfile

import src.main as universe
import os

directory = 'images/profiling'
if not os.path.exists(directory):
    os.makedirs(directory)

# Parameters
iterations = int(1)
dt = float(0.01)
area_side = 1 * 10 ** 5
num_bodies = 3
universe.main(iterations, directory, dt, area_side, num_bodies)

cProfile.runctx("universe.main(1, 'images/profiling', 0.01, 1 * 10 ** 5, 3)", globals(), locals(), "Profile.prof")

s = pstats.Stats("Profile.prof")
s.strip_dirs().print_stats()
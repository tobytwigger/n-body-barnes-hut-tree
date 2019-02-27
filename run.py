import src.main as universe
import os
from mpi4py import MPI
import time

# Set runtime variables
iterations = 20
dt = 60.
# dt = 10.**3.3 # Use with four_bodies
# Create a csv file to save data into
i = 0
csvfile = 'images/{}_{}'.format('run', i)

# Find the next possible number to save data into
while os.path.exists(csvfile+'.csv'):
    i += 1
    csvfile = 'images/{}_{}'.format('run', i)

# Let the user know which file contains their data
print('Your galaxy ref. number with {} threads: {}'.format(1, i))



# Define when the code begins
starttime = time.time()

# Start the simulation
universe.main(iterations, csvfile, dt)

print('Total runtime: {}s'.format(time.time() - starttime))


import os
os.environ["MKL_NUM_THREADS"] = "1"
os.environ["NUMEXPR_NUM_THREADS"] = "1"
os.environ["OMP_NUM_THREADS"] = "1"

from barnes_hut import FindAccelerations
from octree import Octree
from mpi4py import MPI

import numpy as np
import time
import csv

comm = MPI.COMM_WORLD
rank = comm.Get_rank()
numtasks = comm.Get_size()
mpi_status = MPI.Status()

def DefInitial(n, size, G):
    '''
    Generates a spiral galaxy
    '''
    masses = abs(np.random.normal(0.5, 0.05, n))
    velocities = np.zeros((n, 3))
    points = np.zeros((n, 3))
    
    DefPoints(size, points)
    
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
    DefVelocities(size, relative_points, internal_masses, velocities, G)
    return masses, velocities, points

def DefPoints(size, points):
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

def DefVelocities(size, relative_points, internal_masses, velocities, G):
    '''
    Initialises point velocities
    '''
    radial_vectors = relative_points[:, 0:2]
    vertical_vectors = np.random.normal(0, size / 100, len(velocities))
    
    vectors = np.zeros((len(velocities), 3))
    vectors[:, 0] = - radial_vectors[:, 1]
    vectors[:, 1] = radial_vectors[:, 0]
    vectors[:, 2] = vertical_vectors

    normalisation = np.linalg.norm(vectors, axis = 1)
    relative_distances = np.linalg.norm(relative_points, axis = 1)
    speeds = np.sqrt((internal_masses * G) / (relative_distances))
    
    velocities[:, 0] = speeds * (vectors[:, 0] / normalisation)
    velocities[:, 1] = speeds * (vectors[:, 1] / normalisation)
    velocities[:, 2] = speeds * (vectors[:, 2] / normalisation)

def LeapFrog(octree, points, velocities, accelerations, theta, G, dt, sf):
    '''
    Finds accelerations etc. for next time step
    '''
    if accelerations is None:
        accelerations = FindAccelerations(octree, points, points, theta, G, sf)
    
    new_points = points + velocities * dt + 0.5 * accelerations * dt ** 2
    new_accelerations = FindAccelerations(octree, new_points, points, theta, G, sf)
    new_velocities = velocities + 0.5 * (accelerations + new_accelerations) * dt

    return new_velocities, new_points, new_accelerations


def Master(item):
    '''
    Master Task
    Has two lists - queue and nodes
    Sends queue items to Workers
    Receives nodes, queue items from Workers
    '''
    processors = np.full(numtasks, True)
    processors[0] = False
    
    queue = [item]
    queue_counter = 1
    nodes = []
    nodes_counter = 0
    while queue_counter > nodes_counter:
        while len(queue) > 0 and True in processors:
            dest_rank = np.argwhere(processors == True)[0]
            comm.send(queue[0], dest = dest_rank, tag = 0)
            processors[dest_rank] = False
            del(queue[0])
    
        while comm.iprobe(source = MPI.ANY_SOURCE, tag = 1, status = mpi_status):
            mpi_source = mpi_status.Get_source()
            node = comm.recv(source = mpi_source, tag = 1)
            
            for item in node.items:
                queue.append(item)
                queue_counter += 1

            processors[mpi_source] = True
            nodes.append(node)
            nodes_counter += 1

            if queue_counter == nodes_counter:
                break
        
        nodes_index = 1
        while len(nodes) > nodes_index:
            if nodes[0].id != []:
                for i in range(1, len(nodes)):
                    if nodes[i].id == []:
                        nodes[0], nodes[i] = nodes[i], nodes[0]
                        break
        
            if nodes[0].id == []:
                octree, node = nodes[0], nodes[nodes_index]
                insert_index = 0
                for j in range(len(node.id) - 1):
                    for child in octree.children:
                        if node.id[j] == child.id[j]:
                            octree = child
                            break
                    else:
                        break
            
                if octree.id == node.id[:-1]:
                    for child in octree.children:
                        if child.id[-1] < node.id[-1]:
                            insert_index += 1
                    octree.children.insert(insert_index, node)
                    del(nodes[nodes_index])
                else:
                    nodes_index += 1
            else:
                break

    for dest_rank in range(1, numtasks):
        comm.send([None, None, None, None, None, None], dest = dest_rank, tag = 0)
    return nodes[0]

def Worker():
    '''
    Receives node information
    Generates node
    Sends node to Master
    '''
    while True:
        position, size, masses, points, n, id = comm.recv(source = 0, tag = 0)
        if id != None:
            node = Octree(position, size, masses, points, n, id)
            comm.send(node, dest = 0, tag = 1)
            continue
        break

def Main(dt = 0.1, run_time = 100, n = 5000, size = 0.1, theta = 1, G = 10.0 ** -7):
    '''
    Main Function
    '''
    masses, masses_chunks = None, None
    velocities, velocities_chunks = None, None
    points, points_chunks = None, None
    
    # Task 0 generates random spiral galaxy
    if rank == 0:
        masses, velocities, points = DefInitial(n, size, G)
        velocities = np.random.normal(0, 0, (n, 3))
        points = np.random.normal(0, size, (n, 3))
        masses_chunks = np.array_split(masses, numtasks, axis = 0)
        velocities_chunks = np.array_split(velocities, numtasks, axis = 0)
        points_chunks = np.array_split(points, numtasks, axis = 0)
    
    # sf - softening factor for gravity calculations
    sf = size * 0.58 * n ** (-0.26)
    time_n = int(run_time / dt)
    position = np.zeros(3)
    points_record = []

    # Uses MPI to send points to different tasks
    scatter_masses = comm.scatter(masses_chunks, root = 0)
    scatter_velocities = comm.scatter(velocities_chunks, root = 0)
    scatter_points = comm.scatter(points_chunks, root = 0)

    scatter_accelerations = None
    octree = None
    
    # Main loop - timed
    timer, tree_timer, gravity_timer = 0, 0, 0
    for time_i in range(time_n):
        start = time.time()
        points = comm.gather(scatter_points, root = 0)
        
        # Task 0 collects information
        if rank == 0:
            points = np.concatenate(points)
            points_record.append(points.reshape(n * 3))
            size = np.amax(abs(points)) * 2.1
            
            # Task 0 is Master for parallel tree generation
            tree_start = time.time()
            octree = Master((position, size, masses, points, n, []))
            tree_end = time.time()
        
        # Other tasks are Workers
        else:
            Worker()
        
        # Sends tree to all Tasks
        octree = comm.bcast(octree, root = 0)

        # Parallel gravity calculation
        gravity_start = time.time()
        outputs = LeapFrog(octree, scatter_points, scatter_velocities, scatter_accelerations, theta, G, dt, sf)
        scatter_velocities, scatter_points, scatter_accelerations = outputs
        gravity_end = time.time()
        end = time.time()
        
        # Timer information for each step
        if rank == 0:
            '''
            print(' ')
            print('Step:', time_i)
            print('NumTasks:', numtasks)
            print('Total:', end - start)
            print('Tree:', tree_end - tree_start)
            print('Gravity:', gravity_end - gravity_start)
            print((end - start) / (n * np.log(n)))
            '''
            
            timer += end - start
            tree_timer += tree_end - tree_start
            gravity_timer += gravity_end - gravity_start

    # Upon completion prints timer information
    if rank == 0:
        print('Total number of processes: %s' %numtasks)
        print('Total time to run: %.2f seconds' %timer)
        print('Total time for tree generation: %.2f seconds' %tree_timer)
        print('Total time for gravity calculations: %.2f seconds' %gravity_timer)

        # Writes all points to CSV file
        with open('points_record.csv', 'w') as csv_file:
            writer = csv.writer(csv_file)
            writer.writerows(points_record)

# Runs Main
Main()

# Many Body Galaxy Simulation

Toby Twigger ([tt15951@bristol.ac.uk](mailto:tt15951@bristol.ac.uk)) 

## Installation

Compatible with Python 3

Extract the code into a directory.

Several make commands have been exposed to allow simple compilation of the software.

- ```make create-environment``` will create a virtual environment using python
- ```make install``` will install the pip requirements in the current environment
- ```make build``` will compile the code.

For a complete install using the above commands, run the following

```bash
chmod u+x install.sh
source ./install.sh
```

## Running the Simulation

To run the simulation, simply call the run.py file and pass it the:

- Number of iterations to complete
- Timestep to use
- Number of bodies to use

```bash
mpiexec -np 8 python run.py 10 60 500
```

A CSV file will be produced, which contains positional data for the bodies over a range of timestep increments.

## Plotting

You may create a static plot, set of plots or an animation.

The CSV file will be called something like run_1.csv. Take note of the number, since this is the ID of the galaxy to plot.

### Static Plot

The following command will produce a single 3D plot of a galaxy at a snapshot in time.

- Galaxy ID: The number of the CSV file
- The text 'single' tells the plot you only want a snapshot in time
- IterationNumber: The iteration number to plot.

```bash
mpiexec -np 8 python plot.py GalaxyID single IterationNumber
```

### Range of plots

You may also plot a galaxy at every step in time, saved as images in a directory. If you have many iterations, this step may take a while.

- Galaxy ID: The number of the CSV file
- The text 'all' tells the plot you want all iterations

```bash
mpiexec -np 8 python plot.py GalaxyID all
```

Find the images in the 'images' folder

### Animation

To produce an animation of a galaxy, invoke the animation.py file

- Galaxy ID: The number of the CSV file

```bash
python -i animation.py GalaxyID
```

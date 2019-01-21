import math
import matplotlib.pyplot as plt
import numpy as np
import time


def DeterminePart():
    MyInput = "0"
    plt.close("all")
    while True:  # Loop until a choice is chosen
        print("Enter a choice, \'a\', \'b\' or \'q\' to quit")  # Give the user options of what to enter.
        MyInput = input("> ")  # Ask the user what option they want to use
        if MyInput == "a":
            beginSimulation(1)
            break
        elif MyInput == "b":
            beginSimulation(2)
            break
        elif MyInput == "q":
            print("You have chosen to quit. Goodbye.")
            break
        else:
            print("This is not a valid choice.")  # Backup incase the user doesn't enter a valid input


def beginSimulation(body):
    x, y, vx, vy = InitialConditions()  # Get the inital conditions from the user
    x, y, vx, vy, shortestdist = RungeKutta(x, y, vx, vy,
                                            body)  # Find the path the orbit takes and save it in the arrays x, y, vx and vy
    kin, pot, tot, time = Energy(x, y, vx, vy, body)  # Find the energies (kinetic, total and potential)
    xearth, yearth, xmoon, ymoon = PlotPlanets()  # Get x and y arrays to plot to represent the Earth and the Moon
    plot(time, pot, kin, tot, x, y, xearth, yearth, xmoon, ymoon, body,
         shortestdist)  # Send the data (planet positions and the path) to be plotted


def InitialConditions():
    while True:
        try:
            method = float(input(
                "Do you want to enter initial conditions in cartesian coordinates (enter 1) or polar coordinates (enter 2): "))
            if method == 1 or method == 2:
                break
            else:
                print("Please enter 1 or 2")
        except:
            print("Please enter 1 or 2")

    if method == 1:
        while True:
            try:
                x = [float(input("Enter the initial x position: "))]
                break
            except:
                print("Please enter a number.")

        while True:
            try:
                y = [float(input("Enter the initial y position: "))]
                break
            except:
                print("Please enter a number.")

        while True:
            try:
                vx = [float(input("Enter the initial x velocity: "))]
                break
            except:
                print("Please enter a number.")
        while True:
            try:
                vy = [float(input("Enter the initial y velocity: "))]
                break
            except:
                print("Please enter a number.")

    elif method == 2:
        while True:
            try:
                rstart = float(input(
                    "Enter the radius of the orbit of the rocket in m above the earth: ")) + 6371000  # 6371000 is the radius of the earth
                break
            except:
                print("Please enter a number.")
        while True:
            try:
                rangle = float(input(
                    "Enter the angle around the Earth (North Pole = 0 radians) at which the rocket should begin its orbit, in multiples of pi: ")) * math.pi
                break
            except:
                print("Please enter a number.")

        while True:
            try:
                vstart = float(input("Enter the velocity of the rocket in m/s: "))
                break
            except:
                print("Please enter a number.")

        while True:
            try:
                vangle = float(input("Enter the angle of the velocity vector, in multiples of pi: ")) * math.pi
                break
            except:
                print("Please enter a number.")

        x = [rstart * math.sin(rangle)]  # Decompose the vectors into cartesian coordinates, to get x, y, vx and vy
        y = [rstart * math.cos(rangle)]
        vx = [vstart * math.sin(vangle)]
        vy = [vstart * math.cos(vangle)]

    return x, y, vx, vy  # send these back


def Constants():
    h = 50  # step size
    G = 6.67 * 10 ** (-11)  # Gravitational constant
    Me = 5 * 10 ** (24)  # Mass of earth
    m = 28817  # mass of body
    Mm = 7 * 10 ** (22)  # mass of moon
    Em = 384400000  # distance between earth and moon
    return h, G, Me, m, Mm, Em


def RungeKutta(x, y, vx, vy, body):
    sectors = [0, 0, 0, 0]  # each section in the array turns to 1 when the body passes through it
    closeness = [0, 0, 0]  # [started close to the earth, passed the moon, came back to earth]
    h, G, Me, m, Mm, Em = Constants()  # get the constants
    i = 0
    starttime = time.time()  # get the current time
    disttomoon = []
    while ((x[i] ** 2 + y[i] ** 2) ** (
    0.5)) <= 3 * Em:  # loop until the distance from the earth to the body is 3 times the distance from the earth to the moon
        k1, k2, k3, k4 = calculatek(vx[i], vy[i], x[i], y[i], G, Me, Mm, Em, h, body)  # find k1, k2, k3 and k4
        x.append(
            x[i] + (h / 6) * (k1[0] + 2 * k2[0] + 2 * k3[0] + k4[0]))  # add the next path position using the k values
        y.append(y[i] + (h / 6) * (k1[1] + 2 * k2[1] + 2 * k3[1] + k4[1]))
        vx.append(vx[i] + (h / 6) * (k1[2] + 2 * k2[2] + 2 * k3[2] + k4[2]))
        vy.append(vy[i] + (h / 6) * (k1[3] + 2 * k2[3] + 2 * k3[3] + k4[3]))
        i += 1
        sectors, closeness = assignSector(x[i], y[i], sectors,
                                          closeness)  # look at the current position to work out if the simulation should be stopped
        disttomoon.append(math.sqrt((x[i] - Em) ** 2 + y[
            i] ** 2) - 1737000)  # how far to the moon, to find the closest to the moon the body got
        if CheckContinue(starttime, x, y, Em, body, i, sectors,
                         closeness) == 0:  # if the simulation should be terminated
            break  # terminate the simulation
    return x, y, vx, vy, np.min(disttomoon)


def CheckContinue(starttime, x, y, Em, body, i, sectors, closeness):  # should the simulation be terminated?
    continuevar = 1  # 1 means keep the simulatoin going, 0 means stop the simulation
    if time.time() - starttime > 10:  # if the simulaton has been running for 10 seconds, stop it
        continuevar = 0
        print("The simulation timed out.")
    if CheckPos(x[i], y[i], Em, body) == 1:  # if the simulation collides with the earth or the moon, stop it
        print("The body crashed!")
        continuevar = 0
    if body == 1:  # if the moon isn't involved in the simulation
        if np.sum(sectors) == 4:  # Been to all four sectors, so has made an orbit
            if x[i] * x[0] >= 0 and y[i] * y[0] >= 0:  # If it's back in the same sector it started in
                if abs(y[0] - y[i]) <= 300000 and abs(
                        x[0] - x[i]) <= 300000:  # if the x and y values are close to where they started
                    continuevar = 0  # stop the simulation
    elif body == 2:  # if the moon is involved too
        if np.sum(
                closeness) == 3:  # only occurs after the body has started close to earth, passed close to the moon then got back close to earth
            continuevar = 0  # stop simulation
    return continuevar


def assignSector(x, y, sectors, closeness):
    h, G, Me, m, Mm, Em = Constants()
    #############Determine the sector the rocket is in (top left, top right, bottom left, bottom right) and change the array sectors[] accordingly
    if x > 0 and y > 0:
        sectors[0] = 1
    elif x > 0 and y < 0:
        sectors[1] = 1
    elif x < 0 and y < 0:
        sectors[2] = 1
    elif x < 0 and y > 0:
        sectors[3] = 1

    if math.sqrt(x ** 2 + y ** 2) <= 20000000 and sum(
            closeness) == 0:  # if the body is close to earth and hasn't been to the moon yet
        closeness[0] = 1
    elif math.sqrt((x - Em) ** 2 + y ** 2) <= 20000000 and sum(
            closeness) == 1:  # if the body is close to the moon and started close to earth
        closeness[1] = 1
    elif math.sqrt(x ** 2 + y ** 2) <= 20000000 and sum(
            closeness) == 2:  # if the body has been close to earth and the moon, and is now close to earth again
        closeness[2] = 1
    return sectors, closeness


def CheckPos(x, y, Em, body):
    collision = 0
    rearth = 6371000  # radius of earth in m
    rmoon = 1737000  # radius of moon in m
    rbodyearth = ((x ** 2 + y ** 2) ** (0.5))  # distance from body to earth
    rbodymoon = (((x - Em) ** 2 + y ** 2) ** (0.5))  # distance from body to moon
    if rbodyearth <= rearth:  # if collided with earth
        collision = 1  # collision occured
    if body == 2:  # only if moon involved in simulation
        if rbodymoon <= rmoon:  # if collided with moon
            collision = 1  # collision occured
    return collision


def calculatek(vx, vy, x, y, G, Me, Mm, Em, h, body):  # Calculate k values
    # Define variables
    # [kx,ky,kvx,kvy]
    k1 = [0, 0, 0, 0]
    k2 = [0, 0, 0, 0]
    k3 = [0, 0, 0, 0]
    k4 = [0, 0, 0, 0]
    k1 = [vx, vy, f3(G, Me, Mm, Em, x, y, body), f4(G, Me, Mm, Em, x, y, body)]
    k2 = [vx + (h * k1[2] / 2), vy + (h * k1[3] / 2), f3(G, Me, Mm, Em, x + (h * k1[0] / 2), y + (h * k1[1] / 2), body),
          f4(G, Me, Mm, Em, x + (h * k1[0] / 2), y + (h * k1[1] / 2), body)]
    k3 = [vx + (h * k2[2] / 2), vy + (h * k2[3] / 2), f3(G, Me, Mm, Em, x + (h * k2[0] / 2), y + (h * k2[1] / 2), body),
          f4(G, Me, Mm, Em, x + (h * k2[0] / 2), y + (h * k2[1] / 2), body)]
    k4 = [vx + (h * k3[2]), vy + (h * k3[3]), f3(G, Me, Mm, Em, x + (h * k3[0]), y + (h * k3[1]), body),
          f4(G, Me, Mm, Em, x + (h * k3[0]), y + (h * k3[1]), body)]
    return k1, k2, k3, k4


def f3(G, Me, Mm, Em, x, y, body):
    if body == 1:  # only the earth
        num = -G * Me * x
        den = (x ** 2 + y ** 2) ** (3 / 2)
        total = num / den
    elif body == 2:  # Differential equation for the earth and the moon
        num1 = -G * Me * x
        dem1 = (x ** 2 + y ** 2) ** (3 / 2)
        num2 = -G * Mm * (x - Em)
        dem2 = ((x - Em) ** 2 + y ** 2) ** (3 / 2)
        total = num1 / dem1 + num2 / dem2
    return total


def f4(G, Me, Mm, Em, x, y, body):
    if body == 1:
        num = -G * Me * y
        dem = (x ** 2 + y ** 2) ** (3 / 2)
        total = num / dem
    elif body == 2:
        num1 = -G * Me * y
        dem1 = (x ** 2 + y ** 2) ** (3 / 2)
        num2 = -G * Mm * y
        dem2 = ((x - Em) ** 2 + y ** 2) ** (3 / 2)
        total = num1 / dem1 + num2 / dem2
    return total


def Energy(x, y, vx, vy, body):
    h, G, Me, m, Mm, Em = Constants()
    vel = []  # velocity vector
    kin = []  # kinetic energy vector
    pot = []  # potential energy vector
    tot = []  # total energy vector
    time = [0]
    rbodytomoon = 0
    rbodytoearth = 0
    for i in range(len(x)):  # loop for as many times as there are values in the x vector
        vel.append((vx[i] ** 2 + vy[i] ** 2) ** (0.5))  # find the current velocity
        kin.append(0.5 * m * vel[i] ** 2)  # find the kinetic energy with E=0.5 m v^2
        rbodytomoon = (((x[i] - Em) ** 2 + y[i] ** 2) ** (1 / 2))  # distance from body to moon
        rbodytoearth = ((x[i] ** 2 + y[i] ** 2) ** (1 / 2))  # distance from body to earth
        earthpot = ((-G * Me * m) / (rbodytoearth))  # potential due to the earth
        moonpot = ((-G * Mm * m) / (rbodytomoon))  # potential due to the moon
        if body == 1:  # if only earth
            pot.append(earthpot)
        elif body == 2:  # if both earth and moon involved
            pot.append(earthpot + moonpot)
        time.append(time[i] + h)  # next time step
        tot.append(kin[i] + pot[i])  # add the energies together
    return kin, pot, tot, time[:-1]  # time[:-1] removes the last element of the time array as it's too long


def PlotPlanets():
    h, G, Me, m, Mm, Em = Constants()
    xearth = []
    yearth = []
    xmoon = []
    ymoon = []
    rearth = 6371000
    rmoon = 1737000
    theta = 0
    rad = 0
    # this finds an array for x and y values for the moon and the earth
    # it uses polar coordinates to find the values, then converts to cartesian to send back
    while rad <= rearth:  # loops until the variable rad is equal to the radius of the earth
        theta = 0
        while theta <= math.pi * 2:  # loops until the variable theta is = 2pi
            xearth.append(rad * math.sin(theta))  # find the x and y values
            yearth.append(rad * math.cos(theta))
            theta += 0.1  # increase the angle
        rad += 5000  # increase the radius
    rad = 0
    while rad <= rmoon:  # do the same for the moon
        theta = 0
        while theta <= math.pi * 2:
            xmoon.append(rad * math.sin(theta) + Em)
            ymoon.append(rad * math.cos(theta))
            theta += 0.1
        rad += 500

    return xearth, yearth, xmoon, ymoon


def plot(time, pot, kin, tot, x, y, xearth, yearth, xmoon, ymoon, body, shortestdist):
    plt.plot(time, pot, label="Potential Energy")  # plot potential energy
    plt.plot(time, kin, label="Kinetic Energy")  # plot kinetic energy
    plt.plot(time, tot, label="Total Energy")  # plot total energy
    plt.xlabel("Time (s)")  # labels for the axis
    plt.ylabel("Energy (J)")
    plt.legend(loc="upper right")  # legend in the upper right
    plt.show()  # show the graph
    plt.figure()  # new figure

    plt.plot(x, y)  # plot the path
    plt.plot(xearth, yearth)  # plot the earth
    if body == 2:
        plt.plot(xmoon, ymoon)  # if the moon is involved, plot the moon
    plt.xlabel("x (m)")  # axis labels
    plt.ylabel("y (m)")
    plt.gca().set_aspect('equal', adjustable='box')  # makes the scales the same so the graph isn't distorted
    plt.show()  # show

    std = np.std(tot)  # find standard deviation of the total energy
    mean = np.mean(tot)  # find mean of the total energy
    maxim = np.amax(tot)  # find maximum of the total energy

    print("The standard deviation of the total energy is " + str(
        round(np.mean(std), 6)))  # round the standard deviation to 6 characters
    print("This corresponds to a confidence that energy is conserved of " + str(
        round((abs(np.mean(maxim) - np.mean(mean)) / np.mean(std)),
              3)) + " sigma.")  # use Z = |mean - value|/standard deviatoin to find confidence level
    print("The closest distance to the moon was " + str(
        round(shortestdist, 0) / 1000) + "km.")  # shortest distance to moon
    print("The orbit took a total of " + str(round(time[-1], 0)) + "s to complete.")  # how long the orbit took


DeterminePart()
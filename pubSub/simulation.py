import sys
import time
from TOSSIM import *

t = Tossim([])

topofile = "topology.txt"
modelfile = "meyer-heavy.txt"

radio = t.radio()

#simulation_outfile = "simulation.txt"
#simulation_out = open(simulation_outfile, "w")
#out = open(simulation_outfile, "w")
out = sys.stdout

t.addChannel("SimpleMessage", out)
t.addChannel("client", out)
t.addChannel("broker", out)
t.addChannel("radio", out)
t.addChannel("ResendPub", out)

print "Creating node 1..."
node1 = t.getNode(1)
time1 = 0 * t.ticksPerSecond()
node1.bootAtTime(time1)
print ">>>Will boot at time", time1 / t.ticksPerSecond(), "[sec]"

print "Creating node 2..."
node2 = t.getNode(2)
time2 = 1 * t.ticksPerSecond()
node2.bootAtTime(time2)
print ">>>Will boot at time", time2 / t.ticksPerSecond(), "[sec]"

print "Creating node 3..."
node3 = t.getNode(3)
time3 = 2 * t.ticksPerSecond()
node3.bootAtTime(time2)
print ">>>Will boot at time", time2 / t.ticksPerSecond(), "[sec]"

print "Creating radio channels..."
f = open(topofile, "r")
lines = f.readlines()
for line in lines:
    s = line.split()
    if (len(s) > 0):
        print ">>>Setting radio channel from node ", s[0], " to node ", s[1], " with gain ", s[2], " dBm"
        radio.add(int(s[0]), int(s[1]), float(s[2]))

print "Initializing Closest Pattern Matching (CPM)...";
noise = open(modelfile, "r")
lines = noise.readlines()
compl = 0;
mid_compl = 0;

print "Reading noise model data file:", modelfile;
print "Loading:",
for line in lines:
    str = line.strip()
    if (str != "") and ( compl < 10000 ):
        val = int(str)
        mid_compl = mid_compl + 1;
        if ( mid_compl > 5000 ):
            compl = compl + mid_compl;
            mid_compl = 0;
            sys.stdout.write ("#")
            sys.stdout.flush()
        for i in range(1, 4):
            t.getNode(i).addNoiseTraceReading(val)
print "Done!";

for i in range(1, 4):
    print ">>>Creating noise model for node:", i;
    t.getNode(i).createNoiseModel()



print "Start simulation with TOSSIM! \n\n\n"

for i in range(0,5000):
    t.runNextEvent()
    
print "\n\n\nSimulation finished!"

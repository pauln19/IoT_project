import sys
import time
from TOSSIM import *

t = Tossim([])

sf = SerialForwarder(9001)
throttle = Throttle(t, 10)
sf_process = True
sf_throttle = True

topofile = "topology.txt"
modelfile = "meyer-heavy.txt"

mac = t.mac()
radio = t.radio()
t.init()
#simulation_outfile = "simulation.txt"
#simulation_out = open(simulation_outfile, "w")
#out = open(simulation_outfile, "w")
out = sys.stdout

t.addChannel("SimpleMessage", out)
t.addChannel("client", out)
t.addChannel("broker", out)

node1 = t.getNode(1)
time1 = 0 * t.ticksPerSecond()
node1.bootAtTime(time1)

node2 = t.getNode(2)
time2 = 1*t.ticksPerSecond()
node2.bootAtTime(time2)
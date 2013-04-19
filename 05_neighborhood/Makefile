## Makefile - ASSIGNMENT05
##
## 1) TODO
## $ make telosb
## $ motelist
## $ make telosb install,1 bsl,/dev/ttyUSB0
##
## and 2) TODO mote sending requests
## $ make telosb
## $ motelist
## $ make telosb install,2 bsl,/dev/ttyUSB0
##
##
## debugging:
## $ java net.tinyos.tools.Listen -comm serial@/dev/ttyUSB0:telosb
##
## printf:
## $ java net.tinyos.tools.PrintfClient -comm serial@/dev/ttyUSB0:telosb
##
## @author: Lothar Rubusch

COMPONENT=NeighborhoodAppC
include $(MAKERULES)

## CC2420 radio settings (up to 31 possible)
CFLAGS += -DCC2420_DEF_RFPOWER=3            

## printf
CFLAGS += -I$(TOSDIR)/lib/printf

# printf - change default buffer (only 250)
CFLAGS += -DPRINTF_BUFFER_SIZE=2048

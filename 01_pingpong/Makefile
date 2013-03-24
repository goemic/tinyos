## Makefile
##
## @author: Lothar Rubusch

COMPONENT=PingPongAppC
include $(MAKERULES)

## CC2420 radio settings (up to 31 possible)
CFLAGS += -DCC2420_DEF_RFPOWER=3

## printf
CFLAGS += -I$(TOSDIR)/lib/printf

# default buffer is only 250
#CFLAGS += -DPRINTF_BUFFER_SIZE=XXX


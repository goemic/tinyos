/**
 * NeighborhoodAppC.nc
 *
 * wiring app file
 *
 * @author: Lothar Rubusch
 **/
#include <Timer.h>
#include "Neighborhood.h"
#include "printf.h" // debug

configuration NeighborhoodAppC
{
}
implementation
{
        components MainC;
        components LedsC;

        // this app
        component NeighborhoodC as App;

        // clock
        component new TimerMilliC() as Timer;
// TODO
}

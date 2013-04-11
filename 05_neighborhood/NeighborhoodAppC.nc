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
        components NeighborhoodC as App;

        // clock
        components new TimerMilliC() as Timer;

        // serial
        components SerialActiveMessageC;
        components new SerialAMSenderC( AM_SERIAL );

// TODO


        App.Boot -> MainC;
        App.leds -> LedsC;

        App.RequestTimer -> RequestTimer; //   


        // serial sending
        App.SerialPacket -> SerialAMSenderC;
        App.SerialAMPacket -> SerialAMSenderC;
        App.SerialAMSend -> SerialAMSenderC;
        App.SerialAMControl -> SerialActiveMessageC;


}

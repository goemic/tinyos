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

configuration NeighborhoodAppC{}
implementation
{
        components MainC;
        components LedsC;

        // this app
        components NeighborhoodC as App;

        // serial
        components SerialActiveMessageC;
        components new SerialAMSenderC( AM_SERIAL );

        // wifi sending
        components ActiveMessageC;
        components new AMSenderC( AM_PROTO );



        // LINKAGE

        App.Boot -> MainC;
        App.Leds -> LedsC;

        // serial wiring
        App.SerialPacket -> SerialAMSenderC;
        App.SerialAMPacket -> SerialAMSenderC;
        App.SerialAMSend -> SerialAMSenderC;
        App.SerialAMControl -> SerialActiveMessageC;

        // wifi wiring
        App.Packet -> AMSenderC;
        App.AMPacket -> AMSenderC;
        App.AMSend -> AMSenderC;
        App.AMControl -> ActiveMessageC;
}

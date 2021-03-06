/**
 * NeighborhoodAppC.nc
 *
 * wiring app file
 *
 * @author: Lothar Rubusch
 * @email: L.Rubusch@gmx.ch
 * @license: GPL v.3
 **/
#include "Neighborhood.h"

#include <Timer.h>
#include <printf.h> // debug

configuration NeighborhoodAppC{}
implementation
{
        // app
        components NeighborhoodC as App;
        components MainC;
        App.Boot -> MainC;
        components LedsC;
        App.Leds -> LedsC;

        // clock
        components new TimerMilliC() as Timer_Request;
        App.Timer_Request -> Timer_Request;
        components new TimerMilliC() as Timer_Resend;
        App.Timer_Resend -> Timer_Resend;

        // serial sending
        components SerialActiveMessageC;
        components new SerialAMSenderC( AM_SERIAL );
        App.SerialPacket -> SerialAMSenderC;
        App.SerialAMPacket -> SerialAMSenderC;
        App.SerialAMSend -> SerialAMSenderC;
        App.SerialAMControl -> SerialActiveMessageC;

        // wifi sending
        components ActiveMessageC;
        components new AMSenderC( AM_PROTO );
        App.Packet -> AMSenderC;
        App.AMPacket -> AMSenderC;
        App.AMSend -> AMSenderC;
        App.AMControl -> ActiveMessageC;

        // wifi receiving
        components new AMReceiverC( AM_PROTO );
        App.Receive -> AMReceiverC;

        components UserButtonC;
        App.Get -> UserButtonC;
        App.Notify -> UserButtonC;

        components new QueueC( Neighborhood_t*, sizeof( Neighborhood_t* ) );
        App.Neighborhood_list -> QueueC;

        // signal strength
// TODO
//        components CC2420ActiveMessageC;
//        App.CC2420Packet -> CC2420ActiveMessageC.CC2420Packet;

        // battery power
// TODO send remaining battery power with ACK

        // debugging
        components PrintfC;
        components SerialStartC;
}

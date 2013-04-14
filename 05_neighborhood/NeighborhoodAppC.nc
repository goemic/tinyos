/**
 * NeighborhoodAppC.nc
 *
 * wiring app file
 *
 * @author: Lothar Rubusch
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

        // debugging
        components PrintfC;
        components SerialStartC;
}

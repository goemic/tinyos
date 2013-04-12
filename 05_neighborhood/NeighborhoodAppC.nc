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
        components MainC;
        components LedsC;

        // clock
        components new TimerMilliC() as Timer_Request;
        components new TimerMilliC() as Timer_Resend;

        // this app
        components NeighborhoodC as App;

        // serial sending
        components SerialActiveMessageC;
        components new SerialAMSenderC( AM_SERIAL );

        // wifi sending
        components ActiveMessageC;
        components new AMSenderC( AM_PROTO );

        // wifi receiving
        components new AMReceiverC( AM_PROTO );

        // debugging
        components PrintfC;
        components SerialStartC;
        
        // WIRING
        
        App.Boot -> MainC;
        App.Leds -> LedsC;

        // clock
        App.Timer_Request -> Timer_Request;
        App.Timer_Resend -> Timer_Resend;

        // serial sending
        App.SerialPacket -> SerialAMSenderC;
        App.SerialAMPacket -> SerialAMSenderC;
        App.SerialAMSend -> SerialAMSenderC;
        App.SerialAMControl -> SerialActiveMessageC;

        // wifi sending
        App.Packet -> AMSenderC;
        App.AMPacket -> AMSenderC;
        App.AMSend -> AMSenderC;
        App.AMControl -> ActiveMessageC;

        // wifi receiving
        App.Receive -> AMReceiverC;
}

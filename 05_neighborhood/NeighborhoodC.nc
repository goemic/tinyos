/**
 * NeighborhoodC.nc
 *
 * TODO
 *
 * @author: Lothar Rubusch
 **/
#include <Timer.h>
#include "printf.h"
#include "Neighborhood.h"

module NeighborhoodC
{
        uses interface Boot;
        uses interface Leds;

        uses interface Timer<TMilli> as SomeTimer;

        uses interface Packet as SerialPacket;
        uses interface AMPacket as SerialAMPacket;
        uses interface AMSend as SerialAMSend;
        uses interface SplitControl as SerialAMControl;

}
implementation
{
        // TODO

        message_t pkt;
        message_t serial_pkt;

        event void Boot.booted()
        {
                call AMControl.start();
                call SerialAMControl.start();
        }

        event void SerialAMControl.startDone( error_t err) {}
        event void AMControl.stopDone( error_t err ){}
        event void SerialAMControl.stopDone( error_t err ){}


        event void RequestTimer.fired()
//                SensingMsg_t* io_payload = NULL;
                SerialMsg_t* serial_payload = Null;

        // ...
        serial_payload = (SerialMsg_t*) (call Packet.getPayload( &serial_pkt, sizeof( SerialMsg_t ) ) );


        // ...
        call SerialAMSend.send( AM_BROADCAST_ADDR, (message_t*) &serial_pkt, sizeof( SerialMsg_t ) );
}

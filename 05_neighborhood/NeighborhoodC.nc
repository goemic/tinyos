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

        // clock
        uses interface Timer<TMilli> as Timer_Request;

        // serial send
        uses interface Packet as SerialPacket;
        uses interface AMPacket as SerialAMPacket;
        uses interface AMSend as SerialAMSend;
        uses interface SplitControl as SerialAMControl;

        // wifi send
        uses interface Packet;
        uses interface AMPacket;
        uses interface AMSend;
        uses interface SplitControl as AMControl;

        // wifi receive
        uses interface Receive;
}
implementation
{
        // wifi sending
        bool busy = FALSE;

        // wifi packet
        message_t pkt;

        // serial packet
        message_t serial_pkt;



        event void Boot.booted()
        {
                call AMControl.start();
                call SerialAMControl.start();
        }

        // serial io
        event void SerialAMControl.startDone( error_t err) {}
        event void SerialAMControl.stopDone( error_t err ){}
	event void SerialAMSend.sendDone( message_t* msg, error_t error ){}


        // wifi io
        event void AMControl.startDone( error_t err )
        {
// TODO in case start timers here
                if( SUCCESS != err ){
                        call AMControl.start();
                        call SerialAMControl.start();
                }else{
                        call Timer_Request.startPeriodic( PERIOD_REQUEST );
                }
        }

        event void AMControl.stopDone( error_t err ){}

        event void AMSend.sendDone( message_t* msg, error_t err ){
                /* check to ensure the message buffer that was signaled is the
                   same as the local message buffer */
                if( &pkt == msg ){
                        busy = FALSE;
                        // TODO clean message
                }
        }

        event message_t* Receive.receive( message_t* msg, void* payload, uint8_t len){
                ProtoMsg_t* io_payload = NULL;
                io_payload = (ProtoMsg_t*) payload;
                // TODO
        }

//        event void SomeTimer.fired()
//                SensingMsg_t* io_payload = NULL;
//                SerialMsg_t* serial_payload = Null;

        // ...
//        serial_payload = (SerialMsg_t*) (call Packet.getPayload( &serial_pkt, sizeof( SerialMsg_t ) ) );


        // ...
//        call SerialAMSend.send( AM_BROADCAST_ADDR, (message_t*) &serial_pkt, sizeof( SerialMsg_t ) );

        // timer
        event void Timer_Request.fired()
        {
                ProtoMsg_t* io_payload = NULL;
                SerialMsg_t* serial_payload = NULL;
                if( !busy ){
                        call Leds.led0Toggle();

                        io_payload = (ProtoMsg_t*) (call Packet.getPayload( &pkt, sizeof( ProtoMsg_t )));
                        serial_payload = (ProtoMsg_t*) (call Packet.getPayload( &pkt, sizeof( ProtoMsg_t )));
                        
                        // TODO fill packet
                        // TODO fill serial packet
                        
                        if( SUCCESS == (call AMSend.send( AM_BROADCAST_ADDR, (message_t*) &pkt, sizeof( ProtoMsg_t )))){
                                call SerialAMSend.send( AM_BROADCAST_ADDR, (message_t*) &serial_pkt, sizeof( ProtoMsg_t ));
                                busy = TRUE;
                        }
                }

        }
}

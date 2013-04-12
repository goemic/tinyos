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


        /*
          FUNCTIONS
         */
        event void Boot.booted()
        {
                if( 1 == TOS_NODE_ID ){
                        
// TURN OFF
                        return;
                }
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
                uint16_t node_id;   
                if( len != sizeof( ProtoMsg_t ) ){
                        DB_BEGIN "ERROR: received wrong packet length" DB_END;
                        // ERROR somegthing's wrong with the length
                        return NULL;
                }
                io_payload = (ProtoMsg_t*) payload;

                // TODO read out values
                if( TOS_NODE_ID == io_payload->node_id ){
                        // ERROR our node id
                        DB_BEGIN "ERROR: received own node_id" DB_END;
                        return NULL;
                }


                // 

                // TODO init ACK message to return
                io_payload->node_id = TOS_NODE_ID;

                io_payload->seri

                if( SUCCESS == (call AMSend.send( AM_BROADCAST_ADDR, msg, sizeof( ProtoMsg_t ))) ){
                        // TODO print out serial
                        busy = TRUE;
                }

                return msg;
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
                        call Leds.led2Toggle();

                        io_payload = (ProtoMsg_t*) (call Packet.getPayload( &pkt, sizeof( ProtoMsg_t )));
                        serial_payload = (SerialMsg_t*) (call Packet.getPayload( &pkt, sizeof( SerialMsg_t )));
                        
// TODO put in create_packet( node_id, node_quality, sequence_number)
                        io_payload->node_id = TOS_NODE_ID;
                        serial_payload->node_id = io_payload->node_id;

                        io_payload->node_quality = -1;
                        serial_payload->node_quality = io_payload->node_quality;
// TODO serial number
                        io_payload->sequence_number = 11; // TODO random number
                        serial_payload->sequence_number = io_payload->sequence_number;
// TODO timeout
// TODO resend
// TODO confirmation/ack
                        
                        if( SUCCESS == (call AMSend.send( AM_BROADCAST_ADDR, (message_t*) &pkt, sizeof( ProtoMsg_t )))){
                                call SerialAMSend.send( AM_BROADCAST_ADDR, (message_t*) &serial_pkt, sizeof( ProtoMsg_t ));
                                busy = TRUE;
                        }
                }

        }
}

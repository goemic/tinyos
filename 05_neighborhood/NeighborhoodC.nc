/**
 * NeighborhoodC.nc
 *
 * TODO
 *
 * @author: Lothar Rubusch
 **/
#include "Neighborhood.h"

#include <Timer.h>
#include <printf.h>
#include <UserButton.h>

module NeighborhoodC
{
        uses interface Boot;
        uses interface Leds;

        // clock
        uses interface Timer<TMilli> as Timer_Request;
        uses interface Timer<TMilli> as Timer_Resend;
        uses interface Timer<TMilli> as Timer_Button;  

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

        // button
        uses interface Get<button_state_t>;
        uses interface Notify<button_state_t>;
}
implementation
{
        // wifi sending
        bool is_busy = FALSE;

        // wifi packet
        message_t pkt;

        // serial packet
        message_t serial_pkt;

        // resend
        bool is_already_resent_once = FALSE;


        /*
          FUNCTIONS
        */
/*
        // measure link quality to a specified node
        //
        // this means
        // - send time
        // - response time
        // - send failure (resends) or unreachable (timeout)
        void APPLICATION_link_quality( uint16_t node_id )
        {
                // send like three pings
                // TODO
                // measure send time
                // measure return time
                // measure resends
                // measure failures
                ;
        }

        void prepare_payload( ProtoMsg_t* io_payload
                              , SerialMsg_t* serial_payload
                              , uint16_t sequence_number
                              , uint8_t tos )
        {
                io_payload->node_id = TOS_NODE_ID;
                serial_payload->node_id = io_payload->node_id;

                io_payload->node_quality = 0;
                serial_payload->node_quality = io_payload->node_quality;
// TODO serial number
                io_payload->sequence_number = sequence_number; // TODO random number
                serial_payload->sequence_number = io_payload->sequence_number;

                io_payload->tos = tos; // TODO
                serial_payload->tos = io_payload->tos;
        }
//b*/

        /*
          BOOT
         */
        event void Boot.booted()
        {
//                APPLICATION_link_quality( 2 );
                call AMControl.start();
                call SerialAMControl.start();
                call Timer_Button.startPeriodic( 4096 );  
        }


        /*
          SERIAL IO
        */
        event void SerialAMControl.startDone( error_t err) {}
        event void SerialAMControl.stopDone( error_t err ){}
	event void SerialAMSend.sendDone( message_t* msg, error_t error ){}


        /*
          WIFI IO
        */
        event void AMControl.startDone( error_t err )
        {
// TODO in case start timers here
                if( SUCCESS != err ){
                        call AMControl.start();
                        call SerialAMControl.start();
                }
/* TODO 
                else{
//                        call Timer_Request.startOneShot( PERIOD_RESEND_TIMEOUT );
                        
                        if( 1 == TOS_NODE_ID ){
                                call Timer_Request.startPeriodic( PERIOD_REQUEST );
                        }else{
                                // all others
                                ;
                        }
                }
//*/
        }

        event void AMControl.stopDone( error_t err ){}

        event void AMSend.sendDone( message_t* msg, error_t err ){
                /* check to ensure the message buffer that was signaled is the
                   same as the local message buffer */
                if( &pkt == msg ){
                        is_busy = FALSE;
                        if( !is_already_resent_once ){
                                call Timer_Resend.startOneShot( PERIOD_RESEND_TIMEOUT );
                        }
// TODO clean message
                }
        }

        event message_t* Receive.receive( message_t* msg, void* payload, uint8_t len){
                ProtoMsg_t* io_payload = NULL;
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

                if( TOS_ACK == io_payload->tos ){
                        // received ACK
                        DB_BEGIN "IiTzOk: ACK received" DB_END;
                        call Leds.led0Off();  
//                        call Leds.led1Toggle();
// TODO check sequence number
                        call Timer_Resend.stop();
                        return msg;

                }else if( TOS_REQ == io_payload->tos ){
                        // received REQ
                        DB_BEGIN "IiTzOk: REQ received" DB_END;
                        call Leds.led0On();  

                        // init ACK message to return
                        io_payload->node_id = TOS_NODE_ID;

                        io_payload->sequence_number++;

                        io_payload->tos = TOS_ACK;

                        if( SUCCESS == (call AMSend.send( AM_BROADCAST_ADDR, msg, sizeof( ProtoMsg_t ))) ){
// TODO print out serial
                                DB_BEGIN "\tconfirmed with ACK\n" DB_END;
                                is_busy = TRUE;
                        }
                }else{
                        // error
                        DB_BEGIN "ERROR: wrong message type" DB_END
                }

                return msg;
        }

        /*
          BUTTONS
        */

        event void Notify.notify( button_state_t state )
        {
                if( BUTTON_PRESSED == state ){
                        call Leds.led1On();
                }else if( BUTTON_RELEASED == state ){
                        call Leds.led1Off();
                }
        }


        /*
          TIMER
        */
        event void Timer_Request.fired()
        {
                ProtoMsg_t* io_payload = NULL;
                SerialMsg_t* serial_payload = NULL;

                if( is_busy ) return;

                io_payload = (ProtoMsg_t*) (call Packet.getPayload( &pkt, sizeof( ProtoMsg_t )));
                serial_payload = (SerialMsg_t*) (call Packet.getPayload( &pkt, sizeof( SerialMsg_t )));

                        
// TODO put in create_packet( node_id, node_quality, sequence_number)
                io_payload->node_id = TOS_NODE_ID;
                serial_payload->node_id = io_payload->node_id;

                io_payload->node_quality = 0;  
                serial_payload->node_quality = io_payload->node_quality;  
// TODO serial number
                io_payload->sequence_number = 11; // TODO random number
                serial_payload->sequence_number = io_payload->sequence_number;

                io_payload->tos = TOS_REQ; // TODO
                serial_payload->tos = io_payload->tos;

                // performance measuring (first approach)
// TODO check
                io_payload->timestamp_initial = (call Timer_Resend.getNow() );  
                serial_payload->timestamp_initial = io_payload->timestamp_initial;  

                if( SUCCESS == (call AMSend.send( AM_BROADCAST_ADDR, (message_t*) &pkt, sizeof( ProtoMsg_t )))){
                        call SerialAMSend.send( AM_BROADCAST_ADDR, (message_t*) &serial_pkt, sizeof( ProtoMsg_t ));
                        call Leds.led2Toggle();
                        is_busy = TRUE;
                }
        }

        event void Timer_Resend.fired()
        {
// TODO resend packet
// TODO store packet
// TODO incase is_busy flag, waiting list for other packets, etc
                if( is_busy ){
                        // ERROR
                        DB_BEGIN "ERROR: busy sending a packet, while awaiting an ACK of another packet... o_O" DB_END;
                        return;
                }
                if( SUCCESS == (call AMSend.send( AM_BROADCAST_ADDR, (message_t*) &pkt, sizeof( ProtoMsg_t )))){
                        call SerialAMSend.send( AM_BROADCAST_ADDR, (message_t*) &serial_pkt, sizeof( ProtoMsg_t ));
                        is_already_resent_once = TRUE;
                        is_busy = TRUE;
                }
        }

       event void Timer_Button.fired(){
               button_state_t bs;
               bs = call Get.get();
               if( bs == BUTTON_PRESSED ){
                       call Leds.led1On();
               }else if( bs == BUTTON_RELEASED ){
                       call Leds.led1Off();
               }
       }
}

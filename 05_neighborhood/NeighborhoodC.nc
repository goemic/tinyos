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

        // sequence_number
        uint16_t sequence_number = 0;


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

//*/

//*
        // setup packets
        void setup_payload( ProtoMsg_t* io_payload
                            , SerialMsg_t* serial_payload
                            , uint8_t tos )
        {
                io_payload->node_id = TOS_NODE_ID;
                serial_payload->node_id = io_payload->node_id;

// TODO do we need this?
                io_payload->node_quality = 0;
                serial_payload->node_quality = io_payload->node_quality;

                io_payload->sequence_number = sequence_number;
                serial_payload->sequence_number = io_payload->sequence_number;

                io_payload->tos = tos;
                serial_payload->tos = io_payload->tos;

// TODO evaluate timestamp and time measuring
                io_payload->timestamp_initial = (call Timer_Request.getNow() );  
                serial_payload->timestamp_initial = io_payload->timestamp_initial;  
        }
//*/

        void send_packet()
        {
                if( SUCCESS == (call AMSend.send( AM_BROADCAST_ADDR, (message_t*) &pkt, sizeof( ProtoMsg_t )))){
                        call SerialAMSend.send( AM_BROADCAST_ADDR, (message_t*) &serial_pkt, sizeof( ProtoMsg_t ));
                        DB_BEGIN "send request" DB_END;
                        is_busy = TRUE;
                }
        }


        /*
          BOOT
         */

        event void Boot.booted()
        {
//                APPLICATION_link_quality( 2 );
                call AMControl.start();
                call SerialAMControl.start();
                call Notify.enable();
        }


        /*
          BUTTONS
        */

        event void Notify.notify( button_state_t state )
        {
                if( BUTTON_PRESSED == state ){
                        call Leds.led1On();
                        call Timer_Request.startOneShot( PERIOD_REQUEST );
                }
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
                        // restart services when failed
                        call AMControl.start();
                        call SerialAMControl.start();
                }
        }

        event void AMControl.stopDone( error_t err ){}

        event void AMSend.sendDone( message_t* msg, error_t err ){
                /* check to ensure the message buffer that was signaled is the
                   same as the local message buffer */
                if( &pkt == msg ){
                        is_busy = FALSE;
                        if( !is_already_resent_once ){
                                call Timer_Resend.startOneShot( PERIOD_RESEND_TIMEOUT );
                        }else{
// TODO implement dropping
                                DB_BEGIN "dropped" DB_END;
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

                if( TOS_NODE_ID == io_payload->node_id ){
                        // ERROR our node id
                        DB_BEGIN "ERROR: received own node_id" DB_END;
                        return NULL;
                }

                if( TOS_ACK == io_payload->tos ){
                        // received ACK
                        DB_BEGIN "IiTzOk: ACK received" DB_END;
                        call Leds.led1Off();  
                        if( (sequence_number+1) != io_payload->sequence_number ){
                                DB_BEGIN "ERROR: ACK with wrong sequence number received, dropped" DB_END;
                                return NULL;
                        }
                        DB_BEGIN "\tsequence number ok" DB_END;
                        call Timer_Resend.stop();
                        call Leds.led2Toggle();

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
                                call Leds.led0Off();  
                                is_busy = TRUE;
                        }
                }else{
                        // error
                        DB_BEGIN "ERROR: wrong message type" DB_END
                }

                return msg;
        }


        /*
          TIMER
        */

        // send request
        event void Timer_Request.fired()
        {
                ProtoMsg_t* io_payload = NULL;
                SerialMsg_t* serial_payload = NULL;

                if( is_busy ) return;

                io_payload = (ProtoMsg_t*) (call Packet.getPayload( &pkt, sizeof( ProtoMsg_t )));
                serial_payload = (SerialMsg_t*) (call Packet.getPayload( &pkt, sizeof( SerialMsg_t )));

                
                setup_payload( io_payload, serial_payload, TOS_REQ ); // TODO test   
// XXX
                
/*
// TODO put in create_packet( node_id, node_quality, sequence_number)
                io_payload->node_id = TOS_NODE_ID;
                serial_payload->node_id = io_payload->node_id;

                io_payload->node_quality = 0;  
                serial_payload->node_quality = io_payload->node_quality;  
// TODO serial number
                io_payload->sequence_number = sequence_number; // TODO random number
                serial_payload->sequence_number = io_payload->sequence_number;

                io_payload->tos = TOS_REQ; // TODO
                serial_payload->tos = io_payload->tos;

                // performance measuring (first approach)
// TODO check
                io_payload->timestamp_initial = (call Timer_Request.getNow() );  
                serial_payload->timestamp_initial = io_payload->timestamp_initial;  
//*/

                send_packet(); // TODO test
/*
                if( SUCCESS == (call AMSend.send( AM_BROADCAST_ADDR, (message_t*) &pkt, sizeof( ProtoMsg_t )))){
                        call SerialAMSend.send( AM_BROADCAST_ADDR, (message_t*) &serial_pkt, sizeof( ProtoMsg_t ));
                        DB_BEGIN "send request" DB_END;
                        is_busy = TRUE;
                }
//*/
        }

        event void Timer_Resend.fired()
        {
// TODO store packet
// TODO incase is_busy flag, waiting list for other packets, etc
// TODO check and indicate 'dropped packets'
                if( is_busy ){
                        // ERROR
                        DB_BEGIN "ERROR: busy sending a packet, while awaiting an ACK of another packet... o_O" DB_END;
                        return;
                }
                DB_BEGIN "resending packet" DB_END;
                if( SUCCESS == (call AMSend.send( AM_BROADCAST_ADDR, (message_t*) &pkt, sizeof( ProtoMsg_t )))){
                        call SerialAMSend.send( AM_BROADCAST_ADDR, (message_t*) &serial_pkt, sizeof( ProtoMsg_t ));
                        is_already_resent_once = TRUE;
                        is_busy = TRUE;
                }
        }
}

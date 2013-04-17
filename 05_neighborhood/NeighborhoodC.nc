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
        uint8_t number_of_resend = 0;

        // sequence_number
        uint16_t sequence_number = 0;

        /*
          LIST
         */

// TODO convert into macrolist
        // neighborhood protocol
        Neighborhood_p nl_first = NULL;
        Neighborhood_p nl_last = NULL;
        uint16_t nl_size = 0;

        Neighborhood_p neighborlist_find( uint8_t node_id )
        {
                uint8_t idx;
                Neighborhood_p elem = nl_first;
                for(idx=0; idx < nl_size; ++idx){
                        if(node_id == elem->node_id){
                                return elem;
                        }
                }
                return NULL;
        }

        void neighborlist_add( Neighborhood_p entry )
        {
                if( !entry ){
                        DB_BEGIN "ERROR: entry was NULL" DB_END;
                        return;
                }

                nl_last = entry;
                nl_size++;
                if( !nl_first ){
                        nl_first = nl_last;
                }
        }

        void neighborlist_del( uint8_t node_id )
        {
                Neighborhood_p elem;
                Neighborhood_p before;
                Neighborhood_p after;
                elem = neighborlist_find( node_id );
                before = elem->prev;
                after = elem->next;
                before->next = after;
                after->prev = before;
                
                // in case free element here
        }

        uint16_t neighborlist_size()
        {
                return nl_size;
        }

        void neighborlist_show()
        {
                DB_BEGIN "TODO print the list information" DB_END;
        }


        /*
          FUNCTIONS
        */
//*
        // measure link quality to a specified node
        //
        // this means
        // - send time
        // - response time
        // - send failure (resends) or unreachable (timeout)
        void APPLICATION_link_quality()
        {
                DB_BEGIN "APPLICATION_link_quality()" DB_END;  
                call Timer_Request.startOneShot( PERIOD_REQUEST );
/*
                call Timer_Request.startOneShot( PERIOD_REQUEST );
                call Timer_Request.startOneShot( PERIOD_REQUEST );
                call Timer_Request.startOneShot( PERIOD_REQUEST );
                call Timer_Request.startOneShot( PERIOD_REQUEST );
//*/
                // send like three pings
                // TODO
                // measure send time
                // measure return time
                // measure resends
                // measure failures
// TODO
        }
//*/

//*
        // setup packets
        void setup_payload( ProtoMsg_t* io_payload
                            , SerialMsg_t* serial_payload
                            , uint8_t dst_node_id
                            , uint8_t tos )

        {
                io_payload->src_node_id = TOS_NODE_ID;
                serial_payload->src_node_id = io_payload->src_node_id;

                io_payload->dst_node_id = dst_node_id;
                serial_payload->dst_node_id = io_payload->dst_node_id;

                io_payload->sequence_number = ++sequence_number;
                serial_payload->sequence_number = io_payload->sequence_number;

                io_payload->tos = tos;
                serial_payload->tos = io_payload->tos;

// TODO evaluate timestamp and time measuring
                io_payload->timestamp_initial = (call Timer_Request.getNow() );  
                serial_payload->timestamp_initial = io_payload->timestamp_initial;  
        }
//*/

        void send_packet( message_t* message )
        {
//                if( SUCCESS == (call AMSend.send( AM_BROADCAST_ADDR, (message_t*) &pkt, sizeof( ProtoMsg_t )))){  
                if( SUCCESS == (call AMSend.send( AM_BROADCAST_ADDR, message, sizeof( ProtoMsg_t )))){
                        call SerialAMSend.send( AM_BROADCAST_ADDR, (message_t*) &serial_pkt, sizeof( SerialMsg_t ));
                        DB_BEGIN "send packet" DB_END;
                        is_busy = TRUE;
                }
        }


        /*
          BOOT
         */

        event void Boot.booted()
        {
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
                        DB_BEGIN "button pressed" DB_END;
                        call Leds.led1On();
                        APPLICATION_link_quality();
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
//                        is_busy = FALSE;   
                        if( 0 < number_of_resend ){
                                DB_BEGIN "resend %u", number_of_resend DB_END;
                                call Timer_Resend.startOneShot( PERIOD_RESEND_TIMEOUT );
                        }else{
// TODO implement dropping
                                DB_BEGIN "dropped" DB_END;
                        }
                        is_busy = FALSE;
                }
        }

        event message_t* Receive.receive( message_t* msg, void* payload, uint8_t len){
                uint8_t dst_node_id;
                ProtoMsg_t* io_payload = NULL;
                SerialMsg_t* serial_payload = NULL;
                if( len != sizeof( ProtoMsg_t ) ){
                        DB_BEGIN "ERROR: received wrong packet length" DB_END;
                        // ERROR somegthing's wrong with the length
                        return NULL;
                }

                // obtain payload
                io_payload = (ProtoMsg_t*) payload;
//*/
                serial_payload = (SerialMsg_t*) (call Packet.getPayload( &serial_pkt, sizeof( SerialMsg_t )));
//*                
                DB_BEGIN "received:" DB_END;
                DB_BEGIN "src_node_id\t\t%u", io_payload->src_node_id DB_END;
                DB_BEGIN "dst_node_id\t\t%u", io_payload->dst_node_id DB_END;
                DB_BEGIN "sequence_number\t\t%u", io_payload->sequence_number DB_END;
                DB_BEGIN "tos\t\t\t%u", io_payload->tos DB_END;
                DB_BEGIN "timestamp_initial\t%u", io_payload->timestamp_initial DB_END;
                DB_BEGIN " " DB_END;
                
//*/

/*
                if( TOS_NODE_ID != io_payload->dst_node_id ){
                        DB_BEGIN "TODO: not for me" DB_END;
// TODO handle forward
                        return NULL;
                }
//*/

                if( TOS_NODE_ID == io_payload->src_node_id ){
                        // ERROR our node id
                        DB_BEGIN "ERROR: received own src_node_id" DB_END;
                        return NULL;
                }

// XXX
// FIXME: why becomes this tos 0?
//                DB_BEGIN "tos = %u", io_payload->tos DB_END;  

                if( TOS_ACK == io_payload->tos ){
                        // received ACK
                        DB_BEGIN "ACK received" DB_END;
                        number_of_resend = 0;
                        if( (sequence_number+1) != io_payload->sequence_number ){
                                DB_BEGIN "ERROR: ACK with wrong sequence number received, dropped" DB_END;
                                return NULL;
                        }
                        DB_BEGIN "\tsequence number ok" DB_END;
                        sequence_number = io_payload->sequence_number;

                        

                        call Timer_Resend.stop();
                        call Leds.led1Off();

                }else if( TOS_REQ == io_payload->tos ){
                        // received REQ - send ACK
                        DB_BEGIN "REQ received" DB_END;

                        sequence_number = io_payload->sequence_number;
                        dst_node_id = io_payload->src_node_id;
// TODO append node_id to neighbor node id list - snooping
// TODO create neighbor node id list
                        setup_payload( io_payload, serial_payload, dst_node_id, TOS_ACK );
                        number_of_resend = 0;

                        DB_BEGIN "\tconfirm with ACK\n" DB_END;
                        send_packet( msg );

                        call Leds.led2Toggle();

                }else{
                        // error
                        DB_BEGIN "ERROR: wrong message type" DB_END
                        call Timer_Resend.stop();
                        call Leds.led1Off();
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
                uint8_t dst_node_id = 2;

                if( is_busy ){
                        DB_BEGIN "WARNING: is busy" DB_END;  
                        return;
                }

                io_payload = (ProtoMsg_t*) (call Packet.getPayload( &pkt, sizeof( ProtoMsg_t )));
                serial_payload = (SerialMsg_t*) (call Packet.getPayload( &serial_pkt, sizeof( SerialMsg_t )));
                setup_payload( io_payload, serial_payload, dst_node_id, TOS_REQ );
                number_of_resend = NUMBER_OF_RESEND;
                send_packet((message_t*) &pkt);
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
                number_of_resend--;  
                send_packet((message_t*) &pkt); // TODO test
        }
}

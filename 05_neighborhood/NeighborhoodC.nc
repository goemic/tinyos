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

        // queue
// TODO
//        uses interface Queue<Neighborhood_t> as Neighbor_list;
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

        void neighborlist_add( Neighborhood_t *entry )
        {
                DB_BEGIN "neighborlist_add()" DB_END;   
                if( !entry ){
                        DB_BEGIN "ERROR: entry was NULL" DB_END;
                        return;
                }

                DB_BEGIN "before" DB_END;  
/*
                DB_BEGIN "\tnl_last->node_id\t%u", (uint16_t) nl_last->node_id DB_END;  
                DB_BEGIN "\t&nl_last\t\t%u", (uint16_t) &nl_last DB_END;  
                DB_BEGIN "\tnl_last\t\t\t%u", (uint16_t) nl_last DB_END;  
                DB_BEGIN "\tentry->node_id\t\t%u", (uint16_t) entry->node_id DB_END;  
                DB_BEGIN "\t&entry\t\t\t%u", (uint16_t) &entry DB_END;  
                DB_BEGIN "\tentry\t\t\t%u", (uint16_t) entry DB_END;  
//*/
                DB_BEGIN "\tentry->next\t%u", (uint16_t) entry->next DB_END;  
                DB_BEGIN "\tnl_last->next\t%u", (uint16_t) nl_last->next DB_END;  

                DB_BEGIN "assignment" DB_END;
//                if( !nl_last ){ // TODO check both
                if( 0 == nl_size ){
                        // list was empty
                        *nl_first = *entry;
                }else{
                        // already contains elements
                        nl_last->next = entry;
                        DB_BEGIN "\tnl_last->next\t\t%u", (uint16_t) nl_last->next DB_END;  

                        entry->prev = nl_last;
                        DB_BEGIN "\tentry->prev\t\t%u", (uint16_t) entry->prev DB_END;  
                }
                // set nl_last
                nl_last = entry;

                // just make sure...
                nl_last->next = NULL;
                nl_first->prev = NULL;
/*
                DB_BEGIN "after" DB_END;  
                DB_BEGIN "\tnl_last->node_id\t%u", (uint16_t) nl_last->node_id DB_END;  
                DB_BEGIN "\t&nl_last\t\t%u", (uint16_t) &nl_last DB_END;  
                DB_BEGIN "\tnl_last\t\t\t%u", (uint16_t) nl_last DB_END;  
                DB_BEGIN "\tentry->node_id\t\t%u", (uint16_t) entry->node_id DB_END;  
                DB_BEGIN "\t&entry\t\t\t%u", (uint16_t) &entry DB_END;  
                DB_BEGIN "\tentry\t\t\t%u", (uint16_t) entry DB_END;  
//*/
                DB_BEGIN "\tentry->next\t%u", (uint16_t) entry->next DB_END;  
                DB_BEGIN "\tentry->prev\t%u", (uint16_t) entry->prev DB_END;  

                DB_BEGIN "\tnl_last->next\t%u", (uint16_t) nl_last->next DB_END;  
                DB_BEGIN "\tnl_last->prev\t%u", (uint16_t) nl_last->prev DB_END;  

                DB_BEGIN "\tnl_first->next\t%u", (uint16_t) nl_first->next DB_END;  
                DB_BEGIN "\tnl_first->prev\t%u", (uint16_t) nl_first->prev DB_END;  

                nl_size++;
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
                Neighborhood_p ptr = NULL;
                uint16_t idx = 0;   
                DB_BEGIN "neighborlist_show()" DB_END;  
                DB_BEGIN "nl_size '%d'", nl_size DB_END;
//*
                if( !nl_first ) return;
                // init
                DB_BEGIN "INIT" DB_END;
                ptr = nl_first;

                for(idx=0; idx<1+nl_size; ++idx){

                DB_BEGIN "\tnode_id:\t%u", ptr->node_id DB_END;

                if( NULL == ptr->next ){
                        // stop
                        DB_BEGIN "STOP" DB_END;
                        DB_BEGIN "\tptr->next was NULL" DB_END;
                        return;
                }else{
                        // iterate
                        DB_BEGIN "ITERATE" DB_END;
                        ptr = ptr->next;
                }

                }
/*/
                if( !nl_first ) return;
                for( ptr = nl_first; ptr->next != NULL; ptr = ptr->next ){
                        DB_BEGIN "\tnode_id:\t%u", ptr->node_id DB_END;
//                        DB_BEGIN "\tnode_quality:\t%u", ptr->node_quality DB_END;
                        DB_BEGIN " " DB_END;
                }
//*/
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

                io_payload->timestamp_initial = (call Timer_Request.getNow() );
                serial_payload->timestamp_initial = io_payload->timestamp_initial;
        }

        void send_packet()
        {
                if( SUCCESS == (call AMSend.send( AM_BROADCAST_ADDR, (message_t*) &pkt, sizeof( ProtoMsg_t )))){
                        is_busy = TRUE;
                        DB_BEGIN "send packet" DB_END;
                        call SerialAMSend.send( AM_BROADCAST_ADDR, (message_t*) &serial_pkt, sizeof( SerialMsg_t ));
                }
        }


        /*
          BOOT
         */

        event void Boot.booted()
        {
                nl_first = NULL;
                nl_last = NULL;
                nl_size = 0;

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
                        is_busy = FALSE;
                        if( 0 < number_of_resend ){
                                DB_BEGIN "resend %u", number_of_resend DB_END;
                                call Timer_Resend.startOneShot( PERIOD_RESEND_TIMEOUT );
                        }else{
                                DB_BEGIN "dropped" DB_END;
                        }
                }
        }

        event message_t* Receive.receive( message_t* msg, void* payload, uint8_t len){
                uint8_t dst_node_id;
                ProtoMsg_t* io_payload = NULL;
                SerialMsg_t* serial_payload = NULL;
                Neighborhood_t item;
                if( len != sizeof( ProtoMsg_t ) ){
                        DB_BEGIN "ERROR: received wrong packet length" DB_END;
                        // ERROR somegthing's wrong with the length
                        return NULL;
                }

                // obtain payload
                io_payload = (ProtoMsg_t*) (call Packet.getPayload( &pkt, sizeof( ProtoMsg_t )));
                serial_payload = (SerialMsg_t*) (call Packet.getPayload( &serial_pkt, sizeof( SerialMsg_t )));
/*
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

                if( TOS_NODE_ID == ((ProtoMsg_t*) payload)->src_node_id ){
                        // ERROR our node id
                        DB_BEGIN "ERROR: received own src_node_id" DB_END;
                        return NULL;
                }

                if( TOS_ACK == ((ProtoMsg_t*) payload)->tos ){
                        // received ACK
                        DB_BEGIN "ACK received" DB_END;
                        number_of_resend = 0;
                        if( (sequence_number+1) != ((ProtoMsg_t*) payload)->sequence_number ){
                                DB_BEGIN "ERROR: ACK with wrong sequence number received, dropped" DB_END;
                                return NULL;
                        }
                        DB_BEGIN "\tsequence number ok" DB_END;
                        sequence_number = ((ProtoMsg_t*) payload)->sequence_number;

                        
                        item.node_id = ((ProtoMsg_t*) payload)->src_node_id;
                        item.next = NULL;
                        DB_BEGIN "XXX item.next\t%u", (uint16_t) item.next DB_END;   
                        item.prev = NULL;
                        neighborlist_add( &item );
                        
                        neighborlist_show();  
                        
// TODO create neighbor node id list
// TODO append node_id to neighbor node id list - snooping
                        call Timer_Resend.stop();
                        call Leds.led1Off();

                }else if( TOS_REQ == ((ProtoMsg_t*) payload)->tos ){
                        // received REQ - send ACK
                        DB_BEGIN "REQ received" DB_END;
                        sequence_number = ((ProtoMsg_t*) payload)->sequence_number;
                        dst_node_id = ((ProtoMsg_t*) payload)->src_node_id;
                        setup_payload( io_payload, serial_payload, dst_node_id, TOS_ACK );
                        number_of_resend = 0;

                        DB_BEGIN "\tconfirm with ACK\n" DB_END;
                        send_packet();

                        call Leds.led2Toggle();
                        return &pkt;

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
                // explicitly send request to node 2
                uint8_t dst_node_id = 2;           

                if( is_busy ) return;
                io_payload = (ProtoMsg_t*) (call Packet.getPayload( &pkt, sizeof( ProtoMsg_t )));
                serial_payload = (SerialMsg_t*) (call Packet.getPayload( &serial_pkt, sizeof( SerialMsg_t )));
                setup_payload( io_payload, serial_payload, dst_node_id, TOS_REQ );
                number_of_resend = NUMBER_OF_RESEND;
                send_packet();
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
                send_packet(); // TODO test
        }
}

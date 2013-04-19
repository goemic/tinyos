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
        uses interface Queue<Neighborhood_t*> as Neighborhood_list;
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

        Neighborhood_p neighborlist_find( uint8_t node_id )
        {
                uint8_t idx = 0;
                Neighborhood_p elem = NULL;
                uint8_t size = 0;

                size = (call Neighborhood_list.size());
                for( idx=0; idx<size; ++idx ){
                        elem = (call Neighborhood_list.element( idx ));
                        if( node_id == elem->node_id ){
                                return elem;
                        }
                }
                return NULL;
        }

        void neighborlist_add( Neighborhood_t *entry )
        {
                Neighborhood_p ptr=NULL;
                uint16_t rtt = 0;
                uint16_t mean_rtt = 0;

//                DB_BEGIN "neighborlist_add( Neighborhood_t *entry )" DB_END;
                if( NULL == (ptr = neighborlist_find( entry->node_id )) ){
                        DB_BEGIN "\tnew neighbor found" DB_END;

                        // check size
                        if( (call Neighborhood_list.maxSize()) <= (call Neighborhood_list.size()) ){
                                DB_BEGIN "ERROR: list is full" DB_END;
                                return;
                        }

                        // append
                        if( SUCCESS != (call Neighborhood_list.enqueue(entry))){
                                DB_BEGIN "ERROR: could not queue element" DB_END;
                                return;
                        }
                }else{
                        DB_BEGIN "WARNING: element already in list, dropped" DB_END;
                        rtt = entry->node_quality;
                        mean_rtt = ptr->node_quality;
/*
                        // take measurements directly
                        ptr->node_quality = rtt;
/*/
                        // mean filter, to average measurements
                        ptr->node_quality = mean_rtt + (10/5) * (rtt - mean_rtt) / 10;
//*/
                        rtt = 0;
                }
        }

        void neighborlist_show()
        {
                Neighborhood_p elem = NULL;
                uint16_t idx = 0;
                uint8_t size = 0;

                size = (uint8_t) (call Neighborhood_list.size());
                for( idx=0; idx<size; ++idx ){
                        elem = (call Neighborhood_list.element( idx ));
                        DB_BEGIN "node_id\t\t%u", elem->node_id DB_END;
                        DB_BEGIN "node_quality\t%u", elem->node_quality DB_END;
                }
        }


        /*
          FUNCTIONS
        */

        // measure link quality to a specified node by button
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
                            , uint8_t tos
                            , uint16_t timestamp_initial )

        {
                io_payload->src_node_id = TOS_NODE_ID;
                serial_payload->src_node_id = io_payload->src_node_id;

                io_payload->dst_node_id = dst_node_id;
                serial_payload->dst_node_id = io_payload->dst_node_id;

                io_payload->sequence_number = ++sequence_number;
                serial_payload->sequence_number = io_payload->sequence_number;

                io_payload->tos = tos;
                serial_payload->tos = io_payload->tos;

                io_payload->timestamp_initial = timestamp_initial;
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
                                DB_BEGIN "done" DB_END;
                        }
                }
        }

        event message_t* Receive.receive( message_t* msg, void* payload, uint8_t len){
                uint8_t dst_node_id;
                ProtoMsg_t* io_payload = NULL;
                SerialMsg_t* serial_payload = NULL;
                Neighborhood_t item;
                uint8_t node_id;

                // check length
                if( len != sizeof( ProtoMsg_t ) ){
                        DB_BEGIN "ERROR: received wrong packet length" DB_END;
                        return NULL;
                }

                // obtain payload
                io_payload = (ProtoMsg_t*) (call Packet.getPayload( &pkt, sizeof( ProtoMsg_t )));
                serial_payload = (SerialMsg_t*) (call Packet.getPayload( &serial_pkt, sizeof( SerialMsg_t )));


                // dst id correct?
                node_id = ((ProtoMsg_t*) payload)->dst_node_id;
                if( (TOS_NODE_ID != node_id) && (255 != node_id) ){
                        DB_BEGIN "WARNING: packet not for me, dropped" DB_END;
                        return NULL;
                }

                // type of service received?
                if( TOS_ACK == ((ProtoMsg_t*) payload)->tos ){
                        // received ACK
                        DB_BEGIN "ACK received" DB_END;
                        number_of_resend = 0;

                        // check sequence number, no handling for higher / different sequences implemented
                        if( (sequence_number+1) != ((ProtoMsg_t*) payload)->sequence_number ){
                                DB_BEGIN "ERROR: ACK with wrong sequence number received, dropped" DB_END;
                                return NULL;
                        }
                        DB_BEGIN "\tsequence number ok" DB_END;
                        sequence_number = ((ProtoMsg_t*) payload)->sequence_number;
                        
                        item.node_id = ((ProtoMsg_t*) payload)->src_node_id;
                        item.node_quality = (uint16_t) (call Timer_Request.getNow() ) - (uint16_t) ((ProtoMsg_t*) payload)->timestamp_initial;
                        neighborlist_add( &item );
                        neighborlist_show();
                        
                        call Timer_Resend.stop();
                        call Leds.led1Off();

                }else if( TOS_REQ == ((ProtoMsg_t*) payload)->tos ){
                        // received REQ - send ACK
                        DB_BEGIN "REQ received" DB_END;
                        sequence_number = ((ProtoMsg_t*) payload)->sequence_number;
                        dst_node_id = ((ProtoMsg_t*) payload)->src_node_id;
                        setup_payload( io_payload, serial_payload, dst_node_id, TOS_ACK, ((ProtoMsg_t*) payload)->timestamp_initial );
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
                uint8_t dst_node_id = 255;           

                if( is_busy ) return;
                io_payload = (ProtoMsg_t*) (call Packet.getPayload( &pkt, sizeof( ProtoMsg_t )));
                serial_payload = (SerialMsg_t*) (call Packet.getPayload( &serial_pkt, sizeof( SerialMsg_t )));
                setup_payload( io_payload, serial_payload, dst_node_id, TOS_REQ, (call Timer_Request.getNow() ) );
                number_of_resend = NUMBER_OF_RESEND;
                send_packet();
        }

        event void Timer_Resend.fired()
        {
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

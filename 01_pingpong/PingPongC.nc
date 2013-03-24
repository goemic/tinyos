/**
 * PingPongC.nc
 *
 * send a message over the radio
 *
 * @author: Lothar Rubusch
 **/

#include <Timer.h>
#include "printf.h"
#include "PingPong.h"

module PingPongC{
	uses interface Boot;
	uses interface Leds;
	uses interface Timer<TMilli> as Timer0;
	uses interface Packet;
	uses interface AMPacket;
	uses interface AMSend;
	uses interface SplitControl as AMControl;
        uses interface Receive;
}
implementation{
	uint16_t counter = 0;
	bool busy = FALSE;
	message_t pkt;

	event void Boot.booted(){
		// node 2 is only responding
		call AMControl.start();
	}

	event void AMControl.startDone( error_t err ){
		if( err == SUCCESS ){
			call Timer0.startPeriodic( TIMER_PERIOD_MILLI );
		}else{
			// radio restarted
			call AMControl.start();
		}
	}

	event void AMControl.stopDone( error_t err ){}

	event void Timer0.fired(){
		PingPongMsg_t* pp_pkt = NULL;
		if( !busy ){
			// other nodes return right away
			if( TOS_NODE_ID != 1 ){ return; }

			pp_pkt = (PingPongMsg_t*) (call Packet.getPayload( &pkt, sizeof( PingPongMsg_t )));

			pp_pkt->Sender_NodeID = TOS_NODE_ID;
			counter++;
			pp_pkt->Packet_sequence_number = (uint16_t) counter;
			pp_pkt->Timestamp = ( call Timer0.getNow() );

			if( call AMSend.send( AM_BROADCAST_ADDR, &pkt, sizeof( PingPongMsg_t )) == SUCCESS ){
				if( TOS_NODE_ID == 1 ){
					// output for sender, id==1
					printf("client sent packet %u\n", counter);
					printfflush();
				}

				busy = TRUE;
			}
		}
	}

	event void AMSend.sendDone( message_t* msg, error_t error ){
		/* check to ensure the message buffer that was signaled is the
		   same as the local message buffer */
		if( &pkt == msg ){
			busy = FALSE;
		}
	}

        event message_t* Receive.receive( message_t* msg, void* payload, uint8_t len ){
		PingPongMsg_t* pp_pkt = NULL;
		if( len == sizeof( PingPongMsg_t )){

                        // simply blink
			call Leds.led2Toggle();


			pp_pkt = (PingPongMsg_t*) payload;

			if( 2 == TOS_NODE_ID ){
				// we are ping-pong-server
				printf("ping-pong-server received packet %u, sent at %u, from %u\n", pp_pkt->Packet_sequence_number, pp_pkt->Timestamp, pp_pkt->Sender_NodeID);
				printfflush();

				// overwriting with current TOS_NODE_ID
				pp_pkt->Sender_NodeID = TOS_NODE_ID;

				// setting new timestamp
				pp_pkt->Timestamp = ( call Timer0.getNow() );

				if( call AMSend.send( AM_BROADCAST_ADDR, msg, sizeof( PingPongMsg_t )) == SUCCESS ){
					busy = TRUE;
				}
			}else{
				// we are sender
				printf("client received packet %u, sent at %u, from %u\n", pp_pkt->Packet_sequence_number, pp_pkt->Timestamp, pp_pkt->Sender_NodeID );
				printfflush();
			}
		}
		return msg;
        }
}

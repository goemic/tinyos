/**
 * SensingC.nc
 *
 * send a message over the radio
 *
 * @author: Lothar Rubusch
 **/

#include <Timer.h>
#include "printf.h"
#include "Sensing.h"


module SensingC{
	uses interface Boot;
	uses interface Leds;

	// clock
	uses interface Timer<TMilli> as Timer;

	// send/receive
	uses interface Packet;
	uses interface AMPacket;
	uses interface AMSend;
	uses interface SplitControl as AMControl;
	uses interface Receive;

	// sensing
	uses interface Read<uint16_t> as ReadTemperature;
	uses interface Read<uint16_t> as ReadHumidity;
}
implementation{
	// sensing
	uint16_t humidity = 0;
	uint16_t temperature = 0;
	uint16_t mote2_next_request = 1;

	// sending
	bool busy = FALSE;

        // packet
	message_t pkt;

	event void Boot.booted()
	{
		// init
		call AMControl.start();
	}

	event void AMControl.startDone( error_t err )
	{
		if( SUCCESS == err ){
			call Timer.startPeriodic( TIMER_PERIOD );
		}else{
			// restart radio
			call AMControl.start();
		}
	}

	// on stopDone
	event void AMControl.stopDone( error_t err ){}

	event void Timer.fired()
	{
		SensingMsg_t* pp_pkt = NULL;

                // signal, that timer is running
                call Leds.led0Toggle();

		if( TOS_NODE_ID == 1 ){
			// mote1

                        // reads both sensors
			call ReadTemperature.read();
			call ReadHumidity.read();
		}else{
                        // mote2

                        // signal 2 leds for timer (debugging)
                        call Leds.led1Toggle();
                }

		if( !busy && TOS_NODE_ID == 2){
			// mote2 and NOT busy

                        // prepare package
			pp_pkt = (SensingMsg_t*) (call Packet.getPayload( &pkt, sizeof( SensingMsg_t ) ) );

			// pkt, node id
			pp_pkt->mote_id = TOS_NODE_ID;
			DB_BEGIN "sending request\n" DB_END;

			// pkt, timestamp
			pp_pkt->timestamp = (call Timer.getNow());

			// pkt, request sensor
			if( TEMPERATURE == mote2_next_request ){
				pp_pkt->request_sensor = TEMPERATURE;
			}else if( HUMIDITY == mote2_next_request ){
				pp_pkt->request_sensor = HUMIDITY;
			}

                        // send
			if( SUCCESS == (call AMSend.send( AM_BROADCAST_ADDR, &pkt, sizeof( SensingMsg_t ) ) ) ){
				busy = TRUE;
			}
		}
	}

	event void ReadTemperature.readDone(error_t result, uint16_t data)
	{
		if( result == SUCCESS){
			temperature = data;
			DB_BEGIN "measure raw temperature\t%u", temperature DB_END;
		}
	}

	event void ReadHumidity.readDone(error_t result, uint16_t data)
	{
		if( result == SUCCESS){
                        humidity = data;
			DB_BEGIN "measure raw humidity\t%u", humidity DB_END;
		}
	}

	event void AMSend.sendDone( message_t* msg, error_t error ){
		/* check to ensure the message buffer that was signaled is the
		   same as the local message buffer */
		if( &pkt == msg ){
			busy = FALSE;
		}
	}

	event message_t* Receive.receive( message_t* msg, void* payload, uint8_t len) {
		SensingMsg_t* pp_pkt = NULL;
		if( len == sizeof( SensingMsg_t )){

			// simply blink
			call Leds.led2Toggle();

			pp_pkt = (SensingMsg_t*) payload;

                        DB_BEGIN "received:" DB_END;
                        DB_BEGIN "'''" DB_END;
                        DB_BEGIN "from mote_id\t%d", (uint16_t) pp_pkt->mote_id DB_END;
                        DB_BEGIN "at timestamp\t%u", (uint16_t) pp_pkt->timestamp DB_END;

			if( 1 == TOS_NODE_ID ){
				// mote1, answering with temp data

				// pkg mote id
				pp_pkt->mote_id = TOS_NODE_ID;

				// pkg timestamp
				pp_pkt->timestamp = ( call Timer.getNow() );

				// get sensor data
				if( TEMPERATURE == pp_pkt->request_sensor ){
                                        DB_BEGIN "request for temperature data" DB_END;
					pp_pkt->request_sensor = temperature;
				}else if( HUMIDITY == pp_pkt->request_sensor){
                                        DB_BEGIN "request for humidity data" DB_END;
					pp_pkt->request_sensor = humidity;
				}else{
					// error
					DB_BEGIN "ERROR: request_sensor data invalid" DB_END;
				}

				if( SUCCESS == (call AMSend.send( AM_BROADCAST_ADDR, msg, sizeof( SensingMsg_t ))) ){
					busy = TRUE;
				}
			}else{
				// mote2

				// set sensor data
				if( TEMPERATURE == mote2_next_request ){
                                        // (val - 3955) / 100
// TODO check conversion
					temperature = ((float) pp_pkt->request_sensor - 3955.0) / 100.0;
                                        DB_BEGIN "temperature\t%u", (uint16_t) temperature DB_END;
                                        mote2_next_request = HUMIDITY;
				}else if( HUMIDITY == mote2_next_request ){
// TODO conversion formula
					humidity = pp_pkt->request_sensor;
                                        DB_BEGIN "humidity\t%u", (uint16_t) humidity DB_END;
                                        mote2_next_request = TEMPERATURE;
				}
			}
                        DB_BEGIN "\"\"\"\n" DB_END;
		}

                // simply blink
                call Leds.led2Toggle();

		return msg;
	}

}


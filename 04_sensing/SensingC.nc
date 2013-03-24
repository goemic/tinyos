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
                // payload
		SensingMsg_t* pp_pkt = NULL;

                // intermediate result
                uint16_t measure = 0;

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
                                        // convert to centi units
                                        // D1 = -40.1       -> -4010 / 100 for 5V
                                        // D1 = -39.8       -> -3980 / 100 for 4V
                                        // D1 = -39.7       -> -3970 / 100 for 3.5V *
                                        // D1 = -39.6       -> -3960 / 100 for 3V
                                        // D1 = -39.4       -> -3940 / 100 for 2.5V
                                        //
                                        // D2 = 0.01        ->     1 / 100 for 14 bit *
                                        // D2 = 0.04        ->     4 / 100 for 12 bit
                                        // temperature = D2 * pp_pkt->request_sensor + D1
                                        temperature    = 1 * pp_pkt->request_sensor - 3970;

                                        // convert to milli units  1 / 1000
					pp_pkt->request_sensor = 10 * temperature;

				}else if( HUMIDITY == pp_pkt->request_sensor){
                                        DB_BEGIN "request for humidity data" DB_END;
                                        /*
                                          calculation of humidity (milli)

                                          linear
                                          humidity = C1 + C2 * pp_pkt->request_sensor + C3 * (pp_pkt->request_sensor)^2
                                          temperature compensation
                                          humidity = (temperature - 25) * (T1 + T2 * pp_pkt->request_sensor) + RH_linear
                                        */
//*
                                        // 8 bit
                                        measure = pp_pkt->request_sensor;

                                        // C1 = -2.0468     ->  -2047 / 1000
                                        // C2 = 0.5872      ->    587 / 1000
                                        // C3 = -0.00040845 ->      0 / 1000
                                        // humidity = C1     + C2 * measure + C3 * measure^2
                                        humidity    = -2047 + 587 * measure + 0;

                                        // T1 = 0.01        ->      10 / 1000
                                        // T2 = 0.00128     ->       1 / 1000
                                        // humidity = (temperature - 25)    * (T1 + T2 * measure) + humidity
                                        humidity    = (temperature - 25000) * (10 + 1  * measure) + humidity;
/*/
                                        // 12 bit
                                        measure = pp_pkt->request_sensor;

                                        // C1 = -2.0468     ->  -2047 / 1000
                                        // C2 = 0.5872      ->     37 / 1000
                                        // C3 = -0.00008    ->      0 / 1000
                                        // humidity = C1     + C2 * measure + C3 * measure^2
                                        humidity    = -2047  + 37 * measure + 0;

                                        // T1 = 0.01        ->      10 / 1000
                                        // T2 = 0.00008     ->       0 / 1000
                                        // humidity = (temperature - 25)    * (T1 + T2 * measure) + humidity
                                        humidity    = (temperature - 25000) * (10 + 0 )           + humidity;
//*/
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
                                        // temperature / 1000
                                        temperature = pp_pkt->request_sensor;
                                        DB_BEGIN "temperature\t%u C", (temperature / 1000) DB_END;
                                        mote2_next_request = HUMIDITY;

				}else if( HUMIDITY == mote2_next_request ){
                                        // humidity / 1000
                                        humidity = pp_pkt->request_sensor;
                                        DB_BEGIN "humidity\t%u \%", (humidity/1000) DB_END;
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
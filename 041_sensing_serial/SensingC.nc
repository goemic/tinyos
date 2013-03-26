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
	uses interface Timer<TMilli> as RequestTimer;
        uses interface Timer<TMilli> as MeasurementTimer;

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
        uint16_t cnt_measure = 0;
	uint16_t humidity = 0;
        uint16_t arr_humidity[NMEASURE];
	uint16_t temperature = 0;
        uint16_t arr_temperature[NMEASURE];
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
                        if( TOS_NODE_ID == 2 ){
                                call RequestTimer.startPeriodic( REQUEST_PERIOD );
                        }else if(TOS_NODE_ID == 1){
                                call MeasurementTimer.startPeriodic( MEASUREMENT_PERIOD );
                        }
		}else{
			// restart radio
			call AMControl.start();
		}
	}

	// on stopDone
	event void AMControl.stopDone( error_t err ){}

	event void RequestTimer.fired()
	{
		SensingMsg_t* pp_pkt = NULL;
		if( !busy && TOS_NODE_ID == 2){
			// mote2 and NOT busy

                        // 2 leds for mote2
                        call Leds.led0Toggle();
                        call Leds.led1Toggle();

                        // prepare package
			pp_pkt = (SensingMsg_t*) (call Packet.getPayload( &pkt, sizeof( SensingMsg_t ) ) );

			// pkt, node id
			pp_pkt->mote_id = TOS_NODE_ID;
			DB_BEGIN "sending request\n" DB_END;

			// pkt, timestamp
			pp_pkt->timestamp = (call RequestTimer.getNow());

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

	event void MeasurementTimer.fired()
        {
		if( TOS_NODE_ID == 1 ){
                        ++cnt_measure;

			// mote1
                        call Leds.led0Toggle();

                        // reads both sensors
			call ReadTemperature.read();
			call ReadHumidity.read();
		}else{
                        // mote2
                        ;
                }
        }

	event void ReadTemperature.readDone(error_t result, uint16_t data)
	{
		if( result == SUCCESS){
                        // TEMPERATURE CALCULATION
                        //
                        // convert to centi units
                        // D1 = -40.1       -> -4010 / 100 for 5V
                        // D1 = -39.8       -> -3980 / 100 for 4V
                        // D1 = -39.7       -> -3970 / 100 for 3.5V *
                        // D1 = -39.6       -> -3960 / 100 for 3V
                        // D1 = -39.4       -> -3940 / 100 for 2.5V
                        //
                        // D2 = 0.01        ->     1 / 100 for 14 bit *
                        // D2 = 0.04        ->     4 / 100 for 12 bit
                        // temperature                          = D2 * data + D1
                        arr_temperature[cnt_measure % NMEASURE] = 1  * data - 3970;
		}
	}

	event void ReadHumidity.readDone(error_t result, uint16_t data)
	{
                uint16_t measure = 0;
		if( result == SUCCESS){
                        // HUMIDITY CALCULATION
                        //
/* // turned off the 8 bit version, due to very high measurements and data sheet

                        // 8 bit
                        measure = data;

                        // C1 = -2.0468     ->   -205 / 100
                        // C2 = 0.5872      ->     59 / 100
                        // C3 = -0.00040845 ->      0 / 100
                        // humidity = C1     + C2 * measure + C3 * measure^2
                        humidity      = 59  * measure + 0 - 205;

                        // T1 = 0.01        ->      1 / 100
                        // T2 = 0.00128     ->      0 / 100
                        // humidity                          = (temperature - 25)   * (T1 + T2 * measure) + humidity
                        arr_humidity[cnt_measure % NMEASURE] = (temperature - 2500) * (1  + 0)            + humidity;
/*/
                        // 12 bit
                        measure = data;

                        // C1 = -2.0468     ->   -205 / 100
                        // C2 = 0.5872      ->      4 / 100
                        // C3 = -0.00008    ->      0 / 100
                        // humidity = C2 * measure + C3 * measure^2 + C1
                        humidity    = 4  * measure + 0              - 205;

                        // T1 = 0.01        ->       1 / 100
                        // T2 = 0.00008     ->       0 / 100
                        // humidity                          = (temperature - 25)   * (T1 + T2 * measure) + humidity
                        arr_humidity[cnt_measure % NMEASURE] = (temperature - 2500) * (1  + 0 )           + humidity;
//*/

                        // sht11 humidity sensor may provide measurements >100,
                        // this needs to be corrected
                        if( 10000 <= arr_humidity[cnt_measure % NMEASURE] ){
                                arr_humidity[cnt_measure % NMEASURE] = 10000;
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

	event message_t* Receive.receive( message_t* msg, void* payload, uint8_t len) {
                // payload
		SensingMsg_t* pp_pkt = NULL;

		if( len == sizeof( SensingMsg_t )){
                        uint16_t idx=0;

			// simply blink
			call Leds.led2Toggle();

			pp_pkt = (SensingMsg_t*) payload;

                        DB_BEGIN "received:" DB_END;
                        DB_BEGIN "'''" DB_END;
                        DB_BEGIN "from mote_id\t\t%d", (uint16_t) pp_pkt->mote_id DB_END;
                        DB_BEGIN "at timestamp\t\t%u", (uint16_t) pp_pkt->timestamp DB_END;

			if( 1 == TOS_NODE_ID ){
				// mote1, answering with temp data

				// pkg mote id
				pp_pkt->mote_id = TOS_NODE_ID;

				// pkg timestamp
				pp_pkt->timestamp = ( call RequestTimer.getNow() );

				// get sensor data
				if( TEMPERATURE == pp_pkt->request_sensor ){
                                        DB_BEGIN "request for temperature data" DB_END;

                                        // last NMEASURE values
                                        temperature = 0;
                                        for( idx=0; idx<NMEASURE; ++idx ){
                                                temperature += arr_temperature[idx];
                                        }
                                        temperature = temperature / NMEASURE;
                                        DB_BEGIN "measured temperature\t%u C ", (temperature/100) DB_END;
					pp_pkt->request_sensor = temperature;

				}else if( HUMIDITY == pp_pkt->request_sensor){
                                        DB_BEGIN "request for humidity data" DB_END;

                                        // last NMEASURE values
                                        humidity = 0;
                                        for( idx=0; idx<NMEASURE; ++idx ){
                                                humidity += arr_humidity[idx];
                                        }
                                        humidity = humidity / NMEASURE;
                                        DB_BEGIN "measured humidity\t%u percent ", (humidity/100) DB_END;
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
                                        // temperature / 100
                                        temperature = pp_pkt->request_sensor;
                                        DB_BEGIN "temperature\t\t%u C", (temperature / 100) DB_END;
                                        mote2_next_request = HUMIDITY;

				}else if( HUMIDITY == mote2_next_request ){
                                        // humidity / 100
                                        humidity = pp_pkt->request_sensor;
                                        DB_BEGIN "humidity\t\t%u percent", (humidity/100) DB_END;
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

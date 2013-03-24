/**
 * Sensing.h
 *
 * @author: Lothar Rubusch
 **/

#ifndef SENSING_H_
#define SENSING_H_

enum{
	AM_SENSING = 123,

        // sensor request
        TEMPERATURE = 1,
        HUMIDITY = 2,
        NMEASURE = 5,

// TODO check, one timer for sending/receiving and sensor reading
/*
	REQUEST_PERIOD = 30000
/*/
	// TODO just for debugging
	REQUEST_PERIOD = 5000,
//*/
        MEASUREMENT_PERIOD = 50
};

// the message type / payload
typedef nx_struct SensingMsg{
	nx_uint16_t request_sensor;
	nx_uint16_t mote_id;
	nx_uint16_t timestamp;
} SensingMsg_t;


#define NEW_PRINTF_SEMANTICS 1



#define MOTE1 "MOTE 1"
#define MOTE2 "MOTE 2"

#define DB_BEGIN                                \
  printf( "MOTE %d: ", TOS_NODE_ID );           \
  printf(

#define DB_END                                  \
  );                                            \
  printf( "\n" );                               \
  printfflush();

#endif // SENSING_H_

/**
 * Sensing.h
 *
 * @author: Lothar Rubusch
 **/

#ifndef SENSING_H_
#define SENSING_H_

enum{
	AM_SENSING = 11,
        AM_SERIALMSG = 22,

        // sensor request
        TEMPERATURE = 1,
        HUMIDITY = 2,
        NMEASURE = 5,
/*
	REQUEST_PERIOD = 300000,
/*/ //  debugging:
	REQUEST_PERIOD = 5000,
//*/
        MEASUREMENT_PERIOD = 100
};

// the message type / payload
typedef nx_struct SensingMsg{
	nx_uint16_t mote_id;
	nx_uint16_t request_sensor;
	nx_uint16_t timestamp;
} SensingMsg_t;

// serial
typedef nx_struct SerialMsg{
        nx_uint16_t nodeid;
        nx_uint16_t request_sensor;
        nx_uint16_t timestamp;
} SerialMsg_t;

// printf warning turned off
#define NEW_PRINTF_SEMANTICS 1

// debugging output
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

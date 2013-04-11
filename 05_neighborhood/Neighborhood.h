/**
 *
 * @author: Lothar Rubusch
 **/

#ifndef NEIGHBORHOOD_H_
#define NEIGHBORHOOD_H_

enum{
        AM_PROTO = 11,
        AM_SERIAL = 22,

        TIMER_PERIOD = 500
};

// io message payload
typedef nx_struct ProtoMsg{
        nx_uint16_t node_id;
        nx_uint16_t node_quality;
} ProtoMsg_t;

// serial message payload
typedef nx_struct SerialMsg{
        nx_uint16_t node_id;
        nx_uint16_t node_quality;
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


#endif

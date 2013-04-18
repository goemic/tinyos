/**
 *
 * @author: Lothar Rubusch
 **/

#ifndef NEIGHBORHOOD_H_
#define NEIGHBORHOOD_H_

enum{
        AM_PROTO = 11,
        AM_SERIAL = 22,

        // timer
        PERIOD_REQUEST = 0,
        PERIOD_RESEND_TIMEOUT = 3000,
        NUMBER_OF_RESEND = 3,

        // type of service
// TODO, TCP codes and TOSes
        TOS_ACK = 8,
        TOS_REQ = 9
};

// TODO think about TTL field in payload

// io message payload
typedef nx_struct ProtoMsg{
        nx_uint8_t src_node_id;
        nx_uint8_t dst_node_id;
        nx_uint16_t sequence_number;
        nx_uint8_t tos;
        nx_uint16_t timestamp_initial;  
} ProtoMsg_t;

// serial message payload
typedef nx_struct SerialMsg{
        nx_uint8_t src_node_id;
        nx_uint8_t dst_node_id;
        nx_uint16_t sequence_number;
        nx_uint8_t tos;
        nx_uint16_t timestamp_initial;  
} SerialMsg_t;



// Neighborhood table
typedef struct Neighborhood_s{
        uint8_t node_id;
        uint8_t node_quality;
        // TODO
} Neighborhood_t;
typedef Neighborhood_t* Neighborhood_p;


// DEBUGGING

// printf warning turned off
#define NEW_PRINTF_SEMANTICS 1

// debugging output
#define DB_BEGIN                                \
  printf( "MOTE %d: ", TOS_NODE_ID );           \
  printf(

#define DB_END                                  \
  );                                            \
  printf( "\n" );                               \
  printfflush();

#endif

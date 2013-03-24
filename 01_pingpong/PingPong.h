/**
 * PingPong.h
 *
 * @author: Lothar Rubusch
 **/

#ifndef PINGPONG_H_
#define PINGPONG_H_

enum{
	AM_PINGPONG = 123,
	TIMER_PERIOD_MILLI = 500
};


// the message type / payload
typedef nx_struct PingPongMsg{
	nx_uint16_t Sender_NodeID;
	nx_uint16_t Packet_sequence_number;
	nx_uint16_t Timestamp;
} PingPongMsg_t;

#define NEW_PRINTF_SEMANTICS 1

#endif PINGPONG

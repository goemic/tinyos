/**
 * PingPongAppC.nc
 *
 * wiring app file
 *
 * $ make telosb
 * $ motelist
 * $ make telosb install,1 bsl,/dev/ttyUSB0
 *
 * and
 * $ make telosb
 * $ motelist
 * $ make telosb install,2 bsl,/dev/ttyUSB0
 *
 * @author: Lothar Rubusch
 **/

#include <Timer.h>
#include "PingPong.h"
#include "printf.h"

configuration PingPongAppC{
}
implementation{
	components MainC;
	components LedsC;
	components PingPongC as App;
	components new TimerMilliC() as Timer0;
	components ActiveMessageC;
	components new AMSenderC( AM_PINGPONG );
	components new AMReceiverC( AM_PINGPONG );

	// printf
	components PrintfC;
	components SerialStartC;

	App.Boot -> MainC;
	App.Leds -> LedsC;
	App.Timer0 -> Timer0;
	App.Packet -> AMSenderC;
	App.AMPacket -> AMSenderC;
	App.AMSend -> AMSenderC;
	App.AMControl -> ActiveMessageC;
	App.Receive -> AMReceiverC;
}

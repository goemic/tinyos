/**
 * SensingAppC.nc
 *
 * wiring app file
 *
 * @author: Lothar Rubusch
 **/
#include <Timer.h>
#include "Sensing.h"
#include "printf.h"


configuration SensingAppC
{
}
implementation
{
        components MainC;
        components LedsC;

	// this app
        components SensingC as App;

	// clock
        components new TimerMilliC() as RequestTimer;
        components new TimerMilliC() as MeasurementTimer;

        
        // serial communication
        components SerialActiveMessageC;
        components new SerialAMSenderC(AM_SERIALMSG);
        

	// sending / receiving
        components ActiveMessageC;
        components new AMSenderC( AM_SENSING );
        components new AMReceiverC( AM_SENSING );

        // printf / debugging
        components PrintfC;
        components SerialStartC;

	// sensor
// another available sensor for temperature would be the following
//        components new Msp430InternalTemperatureC() as TempSensor;
	components new SensirionSht11C() as HumidSensor;

        App.Boot             -> MainC;
        App.Leds             -> LedsC;

	// clock
        App.RequestTimer     -> RequestTimer;
        App.MeasurementTimer -> MeasurementTimer;

        // serial sending
        App.SerialPacket -> SerialAMSenderC;
        App.SerialAMPacket -> SerialAMSenderC;
        App.SerialAMSend -> SerialAMSenderC;
        App.SerialAMControl -> SerialActiveMessageC;

	// wifi sending
        App.Packet           -> AMSenderC;
        App.AMPacket         -> AMSenderC;
        App.AMSend           -> AMSenderC;
        App.AMControl        -> ActiveMessageC;
        // wifi receive
        App.Receive          -> AMReceiverC;

	// sensor
//	App.ReadTemperature  -> TempSensor; // ignored
	App.ReadTemperature  -> HumidSensor.Temperature;
	App.ReadHumidity     -> HumidSensor.Humidity;
}

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
        components new TimerMilliC() as Timer;

	// sending / receiving
        components ActiveMessageC;
        components new AMSenderC( AM_SENSING );
        components new AMReceiverC( AM_SENSING );

        // printf / debugging
        components PrintfC;
        components SerialStartC;

	// sensor
// TODO check name DemoSensorC
//	components new DemoSensorC() as Sensor;   
	
        components new Msp430InternalTemperatureC() as TempSensor;
//	components new Sht21RawHumidityC() as HumidSensor;
	components new SensirionSht11C() as HumidSensor;
	

        App.Boot        -> MainC;
        App.Leds        -> LedsC;

	// clock
        App.Timer       -> Timer;

	// sending / receiving
        App.Packet      -> AMSenderC;
        App.AMPacket    -> AMSenderC;
        App.AMSend      -> AMSenderC;
        App.AMControl   -> ActiveMessageC;
        App.Receive     -> AMReceiverC;

	// sensor
//	App.ReadTemperature -> TempSensor;
	App.ReadTemperature -> HumidSensor.Temperature;
	App.ReadHumidity    -> HumidSensor.Humidity;

}
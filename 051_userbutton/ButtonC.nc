#include <Timer.h>
#include <UserButton.h>

module ButtonC {
        uses interface Boot;
        uses interface Get<button_state_t>;
        uses interface Notify<button_state_t>;
        uses interface Leds;
//        uses interface Timer<TMilli>;
}
implementation {
        event void Boot.booted()
        {
                call Notify.enable();
//                call Timer.startPeriodic( 4096 );
        }

        event void Notify.notify( button_state_t state )
        {
                if ( state == BUTTON_PRESSED ) {
                        call Leds.led2On();
                } else if ( state == BUTTON_RELEASED ) {
                        call Leds.led2Off();
                }
        }

/*
        event void Timer.fired()
        {
                button_state_t bs;
                bs = call Get.get();
                if ( bs == BUTTON_PRESSED ) {
                        call Leds.led1On();
                } else if ( bs == BUTTON_RELEASED ) {
                        call Leds.led1Off();
                }
        }
//*/
}

configuration ButtonAppC{}
implementation{
        components ButtonC as App;
        components MainC;
        App.Boot -> MainC;
        components LedsC;
        App.Leds -> LedsC;

        // timer
        components new TimerMilliC();
//        App.Timer -> TimerMilliC;

        // button
        components UserButtonC;
        App.Get -> UserButtonC;
        App.Notify -> UserButtonC;
}

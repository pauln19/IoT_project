#include "messages.h"

configuration pubSubAppC {}

implementation {

    components MainC;
    components RandomC;
    components pubSubC as App;
    components ActiveMessageC;

    components new AMSenderC(AM_CONNECT_MSG) as SendSimple;
    components new AMReceiverC(AM_CONNECT_MSG) as RecSimple;

    components new AMSenderC(AM_PUBLISH_MSG) as SendPub;
    components new AMReceiverC(AM_PUBLISH_MSG) as RecPub;

    components new AMSenderC(AM_SUBSCRIBE_MSG) as SendSub;
    components new AMReceiverC(AM_SUBSCRIBE_MSG) as RecSub;

    components new TimerMilliC() as TimerPub;
    components new TimerMilliC() as TimerAckConnect;
    components new TimerMilliC() as TimerAckSub;

    components new TimerMilliC() as Timer0;
/*    components new TimerMilliC() as Timer1;
    components new TimerMilliC() as Timer2;
    components new TimerMilliC() as Timer3;
    components new TimerMilliC() as Timer4;
    components new TimerMilliC() as Timer5;
    components new TimerMilliC() as Timer6;
    components new TimerMilliC() as Timer7;
    components new TimerMilliC() as Timer8;
    components new TimerMilliC() as Timer9;
    components new TimerMilliC() as Timer10;*/
    
    App.Boot -> MainC.Boot;
    App.SplitControl -> ActiveMessageC;

    App.Read -> RandomC;
    RandomC <- MainC.SoftwareInit;

    App.SendSimple -> SendSimple;
    App.ReceiveSimple -> RecSimple;

    App.SendPub -> SendPub;
    App.ReceivePub -> RecPub;

    App.SendSub -> SendSub;
    App.ReceiveSub -> RecSub;

    App.AMPacket -> SendPub;
    App.Packet -> SendPub;

    App.TimerPub -> TimerPub;
    App.TimerAckConnect -> TimerAckConnect;
    App.TimerAckSub -> TimerAckSub;
    
    App.TimerAckPub -> Timer0;
    /*App.TimerAckPub[1] -> Timer1;
    App.TimerAckPub[2] -> Timer2;
    App.TimerAckPub[3] -> Timer3;
    App.TimerAckPub[4] -> Timer4;
    App.TimerAckPub[5] -> Timer5;
    App.TimerAckPub[6] -> Timer6;
    App.TimerAckPub[7] -> Timer7;
    App.TimerAckPub[8] -> Timer8;
    App.TimerAckPub[9] -> Timer9;
    App.TimerAckPub[10] -> Timer10;*/



}
#include "messages.h"

configuration pubSubAppC {}

implementation {

    components MainC;
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
    components new TimerMilliC() as TimerAckPub;

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
    App.TimerAckPub -> TimerAckPub;
}
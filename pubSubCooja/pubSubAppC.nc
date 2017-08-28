#include "messages.h"
#include "printf.h"

configuration pubSubAppC {}

implementation {

    components MainC;
    components RandomC;
    components pubSubC as App;
    components ActiveMessageC;

    components new AMSenderC(AM_SIMPLE_MSG) as SendSimple;
    components new AMReceiverC(AM_SIMPLE_MSG) as RecSimple;

    components new AMSenderC(AM_PUBLISH_MSG) as SendPub;
    components new AMReceiverC(AM_PUBLISH_MSG) as ReceivePub;

    components new AMSenderC(AM_SUBSCRIBE_MSG) as SendSub;
    components new AMReceiverC(AM_SUBSCRIBE_MSG) as RecSub;

    components new TimerMilliC() as TimerPub;
    components new TimerMilliC() as TimerAckConnect;
    components new TimerMilliC() as TimerSub;


    components SerialPrintfC;
    components SerialStartC;
    
    App.Boot -> MainC.Boot;
    App.SplitControl -> ActiveMessageC;

    App.Read -> RandomC;
    RandomC <- MainC.SoftwareInit;

    App.SendSimple -> SendSimple;
    App.ReceiveSimple -> RecSimple;

    App.SendPub -> SendPub;
    App.ReceivePub -> ReceivePub;

    App.SendSub -> SendSub;
    App.ReceiveSub -> RecSub;

    App.AMPacket -> SendPub;
    App.Packet -> SendPub;
    App.PacketAcknowledgements -> ActiveMessageC;

    App.TimerPub -> TimerPub;
    App.TimerAckConnect -> TimerAckConnect;
    App.TimerSub -> TimerSub;
}
#include "messages.h"

configuration clientAppC {}

implementation {

    components MainC;
    components clientC;
    components ActiveMessageC;
    components PrintfC;
    components SerialStartC;
    
    components new AMSenderC(AM_SIMPLE_MSG) as SendSimpleMsg;
    components new AMReceiverC(AM_SIMPLE_MSG) as RecSimpleMsg;
    
    components new AMSenderC(AM_PUBLISH_MSG) as SendPub;
    components new AMReceiverC(AM_PUBLISH_MSG) as RecPub;
    
    components new AMSenderC(AM_SUBSCRIBE_MSG) as SendSub;

    components new TimerMilliC() as Timer;

    clientC.Boot -> MainC.Boot;
    clientC.SplitControl -> ActiveMessageC;

    clientC.SendSimpleMsg -> SendSimpleMsg;
    clientC.ReceiveSimpleMsg -> RecSimpleMsg;

    clientC.SendPub -> SendPub;
    clientC.ReceivePub -> RecPub;

    clientC.SendSub -> SendSub;

    clientC.Packet -> SendSimpleMsg;

    clientC.Timer -> Timer;
}
#include "messages.h"

configuration brokerAppC {}

implementation {

    components MainC;
    components brokerC;
    components ActiveMessageC;
    components PrintfC;
    components SerialStartC;
    
    components new AMSenderC(AM_SIMPLE_MSG) as SendSimpleMsg;
    components new AMReceiverC(AM_SIMPLE_MSG) as RecSimpleMsg;
    
    components new AMSenderC(AM_PUBLISH_MSG) as SendPub;
    components new AMReceiverC(AM_PUBLISH_MSG) as RecPub;
    
    components new AMReceiverC(AM_SUBSCRIBE_MSG) as RecSub;

    brokerC.Boot -> MainC.Boot;
    brokerC.SplitControl -> ActiveMessageC;

    brokerC.SendSimpleMsg -> SendSimpleMsg;
    brokerC.ReceiveSimpleMsg -> RecSimpleMsg;

    brokerC.SendPub -> SendPub;
    brokerC.ReceivePub -> RecPub;

    brokerC.ReceiveSub -> RecSub;

    brokerC.Packet -> SendSimpleMsg;

}
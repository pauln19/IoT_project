#include "messages.h"

configuration clientAppC {}

implementation {

    components MainC;
    components clientC;
    components RandomC;
    components ActiveMessageC;
    components PrintfC;
    components SerialStartC;
    
    components new AMSenderC(AM_CONNECT_MSG) as SendConnectMsg;
    components new AMReceiverC(AM_CONNECT_MSG) as RecConnAck;
    
    components new AMSenderC(AM_PUBLISH_MSG) as SendPub;
    components new AMReceiverC(AM_PUBLISH_MSG) as RecPub;
    
    components new AMSenderC(AM_SUBSCRIBE_MSG) as SendSub;

    components new TimerMilliC() as TimerPub;

    clientC.Boot -> MainC.Boot;
    clientC.SplitControl -> ActiveMessageC;

    clientC.Read -> RandomC;
    RandomC <- MainC.SoftwareInit;

    clientC.SendConnectMsg -> SendConnectMsg;
    clientC.ReceiveConnAck -> RecConnAck;

    clientC.SendPub -> SendPub;
    clientC.ReceivePub -> RecPub;

    clientC.SendSub -> SendSub;

    clientC.PacketAcknowledgements -> ActiveMessageC;
    clientC.AMPacket -> SendPub;
    clientC.Packet -> SendPub;

    clientC.TimerPub -> TimerPub;
}

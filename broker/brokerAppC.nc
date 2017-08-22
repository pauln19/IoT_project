#include "messages.h"

configuration brokerAppC {}

implementation {

    components MainC;
    components brokerC;
    components ActiveMessageC;
    components PrintfC;
    components SerialStartC;

  //  components new AMSenderC(AM_CONNECT_MSG) as SendConnectMsg;
    components new AMReceiverC(AM_CONNECT_MSG) as RecConnectMsg;

    components new AMSenderC(AM_PUBLISH_MSG) as SendPub;
    components new AMReceiverC(AM_PUBLISH_MSG) as RecPub;

    components new AMReceiverC(AM_SUBSCRIBE_MSG) as RecSub;

    brokerC.Boot -> MainC.Boot;
    brokerC.SplitControl -> ActiveMessageC;

  //  brokerC.SendConnectMsg -> SendConnectMsg;
    brokerC.ReceiveConnectMsg -> RecConnectMsg;

    brokerC.SendPub -> SendPub;
    brokerC.ReceivePub -> RecPub;

    brokerC.ReceiveSub -> RecSub;

    brokerC.PacketAcknowledgments -> ActiveMessageC;
    brokerC.AMPacket -> SendConnectMsg;
    brokerC.Packet -> SendConnectMsg;

}

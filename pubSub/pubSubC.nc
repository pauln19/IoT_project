#include "messages.h"

module pubSubC {
  uses{

    interface Boot;
    interface SplitControl;
    interface Random as Read;

    interface AMSend as SendSimple;
    interface Receive as ReceiveSimple;
    
    interface AMSend as SendPub;
    interface Receive as ReceivePub;
    
    interface AMSend as SendSub;
    interface Receive as ReceiveSub;
    
    interface AMPacket;
    interface Packet;
    
    interface Timer<TMilli> as TimerPub;
    interface Timer<TMilli> as TimerAckConnect;
    interface Timer<TMilli> as TimerAckSub;
    interface Timer<TMilli> as TimerAckPub;

  }
}

implementation {

    uint16_t counter = 0;
    uint16_t brokerAddress;

    my_sub_t tempSub[256];
    uint8_t numTempSub = 0;
    my_sub_t humSub[256];
    uint8_t numHumSub = 0;
    my_sub_t lumSub[256];
    uint8_t numLumSub = 0;

    uint16_t clients[256];
    uint8_t nClients = 0;


    event void Boot.booted()
    {
        call SplitControl.start();
    }

    event void SplitControl.startDone(error_t err)
    {
        if (err == SUCCESS) {
            dbg("radio", "%d - Radio on!", TOS_NODE_ID);

            if (TOS_NODE_ID == BROKER) {

            } else {

            }
        } else 
            call SplitControl.start();
    }
    
    event void SplitControl.stopDone(error_t err) {}

    event message_t* ReceiveSimple.receive(message_t* packet, void* payload, uint8_t len) { 
        if (call AMPacket.isForMe(packet))
        {
            if (TOS_NODE_ID == BROKER) {

            }

        }
    }

    event message_t* ReceivePub.receive(message_t* packet, void* payload, uint8_t len) {
        if (call AMPacket.isForMe(packet))
        {
            

            if (TOS_NODE_ID == BROKER) {

            }
        }
    }

    event message_t* ReceiveSub.receive(message_t* packet, void* payload, uint8_t len) {
        if (call AMPacket.isForMe(packet))
        {
            if (TOS_NODE_ID == BROKER) {

            }
        }
    }

    event void SendSimple.sendDone(message_t* msg, error_t err)
    {

    }

    event void SendPub.sendDone(message_t* msg, error_t err)
    {
        
    }

    event void SendSub.sendDone(message_t* msg, error_t err)
    {
        
    }

    event void TimerPub.fired() {

    }

    event void TimerAckConnect.fired() {

    }

    event void TimerAckSub.fired() {

    }

    event void TimerAckPub.fired() {

    }
}
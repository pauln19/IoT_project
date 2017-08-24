#include "messages.h"
//#include "printf.h"
#include "Timer.h"

module clientC {
    uses{
        
        interface Boot;
        interface SplitControl;
        
        interface Receive as ReceivePub;
        interface Receive as ReceiveConnAck;

        interface AMSend as SendConnectMsg;
        interface AMSend as SendPub;
        interface AMSend as SendSub;

        interface PacketAcknowledgements;
        interface AMPacket;
        interface Packet;
        interface Random as Read;        
        
        interface Timer<TMilli> as TimerPub;
    }
}

implementation {
  
  uint16_t counter = 0;
  uint16_t brokerAddress = 1;

  event void Boot.booted()
  {
    call SplitControl.start();
  }

  void sendConnect() 
  {
    message_t packet;

    connect_msg_t* msg = (connect_msg_t*) (call Packet.getPayload(&packet, sizeof(connect_msg_t)));
    msg->id = counter++;
    msg->address = TOS_NODE_ID;
    msg->connect_msg_type = CONNECT;
    //call PacketAcknowledgements.requestAck(&packet);
    if(call SendConnectMsg.send(AM_BROADCAST_ADDR, &packet, sizeof(connect_msg_t)) == SUCCESS){
      //printf("client_%d: Send CONNECT\n", TOS_NODE_ID);
      //printfflush();
    }
  }

  task void sendSubscribe() 
  {
    message_t packet;
    uint32_t subCounter = 0;
    int tmpId = TOS_NODE_ID;
    
    subscribe_msg_t* msg = (subscribe_msg_t*) (call Packet.getPayload(&packet, sizeof(subscribe_msg_t)));
    msg->id = counter++;
    msg->address = TOS_NODE_ID;
    

    // Pseudo random choice of subscription and qos
    while(tmpId >= 0 && subCounter < 3) {
      sub_item_t item;

      switch (TOS_NODE_ID%3) {
        case 0:
          item.topic = TEMPERATURE;
        case 1:
          item.topic = HUMIDITY;
        case 2:
          item.topic = LUMINOSITY;
      }

      if ((call Read.rand16()) % 2 == 0)
      {
        item.qos = 0;  
      } else {
        item.qos = 1;
      } 
      msg->subscriptions[subCounter] = item;
      subCounter ++;
      tmpId -= 2;
    }
    msg->numOfSubs = subCounter;
    
    //call PacketAcknowledgements.requestAck(&packet);
    if(call SendConnectMsg.send(brokerAddress, &packet, sizeof(subscribe_msg_t)) == SUCCESS){
      //printf("client_%d: Send SUBSCRIBE - msg_id: %d\n", TOS_NODE_ID, msg->id);
      //printfflush();
    }
  }


  event void SplitControl.startDone(error_t err)
  {
    if (err == SUCCESS) {
      //printf("client_%d: Radio on!\n", TOS_NODE_ID);
      //printfflush();

      sendConnect();
    }
    else {
      call SplitControl.start();
    }
  }
  
  event void SplitControl.stopDone(error_t err) {}

  event message_t* ReceivePub.receive(message_t* packet, void* payload, uint8_t len){
    publish_msg_t* msg = (publish_msg_t*) payload;


    uint16_t sourceAddr = msg->address;
    //printf("client_%d: Received forwarded PUB from: %d\n", TOS_NODE_ID, sourceAddr);
    //printf("client_%d: -- id %d", TOS_NODE_ID, msg->id);
    //printf("client_%d: -- topic %d", TOS_NODE_ID, msg->topic);
    //printf("client_%d: -- payload %d", TOS_NODE_ID, msg->payload);

    //printfflush();
    return packet;
  }

  event message_t* ReceiveConnAck.receive(message_t* packet, void* payload, uint8_t len){
    connect_msg_t* msg = (connect_msg_t*) payload;
    
    if (msg->connect_msg_type == CONNACK) {
      brokerAddress = msg->address;
      //printf("client_%d: Received CONNACK\n", TOS_NODE_ID);
      //printfflush();

      post sendSubscribe();

      call TimerPub.startPeriodic(3000); //start sendig PUBLISH
    }
    return packet;
  }

  event void SendConnectMsg.sendDone(message_t* msg, error_t err)
  {
    //if(!(call PacketAcknowledgements.wasAcked(msg))){
    //  call SendConnectMsg.send(AM_BROADCAST_ADDR, msg, sizeof(connect_msg_t));
      //printf("client_%d: Resend CONNECT\n", TOS_NODE_ID);
      //printfflush();
    //}
    // else {
    //   //printf("client_%d: Received CONNACK\n", TOS_NODE_ID);
    //   //printfflush();

    //   post sendSubscribe();

    //   call TimerPub.startPeriodic(3000); //start sendig PUBLISH
    // }
  }

  event void SendSub.sendDone(message_t* msg, error_t err)
  {
    //if(!(call PacketAcknowledgements.wasAcked(msg))){
    //  call SendSub.send(brokerAddress, msg, sizeof(subscribe_msg_t));
      //printf("client_%d: Resend SUBSCRIBE\n", TOS_NODE_ID);
      //printfflush();
    //} else {
      //printf("client_%d: SUBACK received\n", TOS_NODE_ID);
      //printfflush();
    //}
  }

  event void SendPub.sendDone(message_t* msg, error_t err)
  {
    publish_msg_t* publishMsg = (publish_msg_t*) msg;

    //if(publishMsg->qos && !(call PacketAcknowledgements.wasAcked(msg))){
    //  call SendPub.send(brokerAddress, msg, sizeof(publish_msg_t));
      //printf("client_%d: Resend PUBLISH\n", TOS_NODE_ID);
      //printfflush();
    //} else if(publishMsg->qos){
      //printf("client_%d: PUBACK of msg %d received\n", TOS_NODE_ID, publishMsg->id);
      //printfflush();
    //}
  }

  event void TimerPub.fired() {
    message_t packet;

    publish_msg_t* msg = (publish_msg_t*) (call Packet.getPayload(&packet, sizeof(publish_msg_t)));
    msg->id = counter++;
    msg->address = TOS_NODE_ID;

    //statically choose the topic for publish
    switch (TOS_NODE_ID%3) {
      case 0:
        msg->topic = TEMPERATURE;
      case 1:
        msg->topic = HUMIDITY;
      case 2:
        msg->topic = LUMINOSITY;
    }

    //randomize the qos
    if ((call Read.rand16()) % 2 == 0)
    {
      msg->qos = 0;  
    } else {
      msg->qos = 1;
      //call PacketAcknowledgements.requestAck(&packet);
    } 

    msg->payload = call Read.rand16();

    if(call SendPub.send(brokerAddress, &packet, sizeof(publish_msg_t)) == SUCCESS){
      //printf("client_%d: Send PUBLISH - msg_id: %d\n", TOS_NODE_ID, msg->id);
      //printf("client_%d: -- topic %d", TOS_NODE_ID, msg->topic);
      //printf("client_%d: -- payload %d", TOS_NODE_ID, msg->payload);
      //printf("client_%d: -- qos %d", TOS_NODE_ID, msg->qos);
      //printfflush();
    }
  }
}

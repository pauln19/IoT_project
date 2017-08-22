#include "messages.h"
#include "printf.h"

module brokerC {
  uses{

    interface Boot;
    interface SplitControl;

    interface Receive as ReceiveSub;
    interface Receive as ReceivePub;
    interface Receive as ReceiveConnectMsg;

    //interface AMSend as SendConnectMsg;
    interface AMSend; //as SendPub;

    interface PacketAcknowledgments;
    interface AMPacket;
    interface Packet;

  }
}

implementation{

  //This part is done in order to keep track of the subscriptions and to loop on them

  my_sub_t tempSub[256];
  uint8_t numTempSub = 0;
  my_sub_t humSub[256];
  uint8_t numHumSub = 0;
  my_sub_t lumSub[256];
  uint8_t numLumSub = 0;
  /*
  void sendACK(uint16_t id, uint16_t address, uint8_t ackType){

  message_t packetAck;

  simple_msg_t* ack = (simple_msg_t*) (call Packet.getPayload(&packetAck, sizeof(simple_msg_t)));
  ack->id = id;
  ack->simple_msg_type = ackType;
  ack->address = TOS_NODE_ID;

  if(call SendSimpleMsg.send(address, &packetAck, sizeof(simple_msg_t)) == SUCCESS){
  printf("broker: Send %d to %d\n", ackType, sourceAddr);
  printfflush();
}
}
*/
void forwardPublish(my_sub_t subscribers[256], uint8_t numOfSubs, message_t* msg){
  uint8_t i;
  publish_msg_t* publishMsg = (publish_msg_t*) msg;

  for(i=0; i<numOfSubs; i++){

    publishMsg->qos = subscribers[i].qos;

    if(publishMsg->qos)
    call PacketAcknowledgments.requestAck(&msg);

    if(call AMSend.send(subscribers[i].address_id, msg, sizeof(publish_msg_t)) == SUCCESS){
      printf("broker: forwardPublish %d to %d\n", publishMsg->id, subscribers[i].address_id);
      printfflush();
    }

    // trovare modo per "salvare" il messaggio che eventualmente potrebbe essere rimandato


  }
}

event message_t* ReceiveSub.receive(message_t* packet, void* payload, uint8_t len){
  uint8_t i;
  subscribe_msg_t* msg = (subscribe_msg_t*) payload;

  uint16_t sourceAddr = msg->address;
  printf("broker: Received SUB - id: %d _ from: %d\n", msg->id, sourceAddr);
  printfflush();

  for (i=0; i<msg->numOfSubs; i++){
    sub_item_t incomingSub = msg->subscriptions[i];
    my_sub_t sub;
    sub.address_id = (nx_uint16_t) sourceAddr;
    sub.qos = (nx_bool) incomingSub.qos;

    printf("broker: Saving SUB of %d to topic %d", sourceAddr, incomingSub.topic);
    printfflush();

    switch (incomingSub.topic){
      case (TEMPERATURE):
      tempSub[numTempSub++] = sub;

      case (HUMIDITY):
      humSub[numHumSub++] = sub;

      case (LUMINOSITY):
      lumSub[numLumSub++] = sub;
    }
  }
  /*
  sendACK(msg->id, sourceAddr, SUBACK);
  */
  return packet;
}

event message_t* ReceiveConnectMsg.receive(message_t* packet, void* payload, uint8_t len){
  connect_msg_t* msg = (connect_msg_t*) payload;

  uint16_t sourceAddr = msg->address;
  /*switch (msg->simple_msg_type){
  case CONNECT:
  printf("broker: Received CONNECT - id: %d _ from: %d\n", msg->id, sourceAddr);
  printfflush();

  sendACK(msg->id, sourceAddr, CONNACK);

  case PUBACK:
  printf("broker: Received PUBACK - id: %d _ from: %d\n", msg->id, sourceAddr);
  printfflush();
  }*/

  printf("broker: Received CONNECT - id: %d _ from: %d\n", msg->id, sourceAddr);
  printfflush();

  // trovare modo di "salvare" una publish e rimandarla eventualmente se non si riceve la puback


  return packet;
}

event message_t* ReceivePub.receive(message_t* packet, void* payload, uint8_t len){
  publish_msg_t* msg = (publish_msg_t*) payload;

  uint16_t sourceAddr = msg->address;
  printf("broker: Received PUB - id: %d _ from: %d\n", msg->id, sourceAddr);
  printfflush();

  /*if(msg->qos)
  sendACK(msg->id, sourceAddr, PUBACK);*/

  switch (msg->topic){
    case (TEMPERATURE):
    forwardPublish(tempSub, numTempSub, packet);

    case (HUMIDITY):
    forwardPublish(humSub, numHumSub, packet);

    case (LUMINOSITY):
    forwardPublish(lumSub, numLumSub, packet);
  }

  return packet;

}


event void Boot.booted()
{
  call SplitControl.start();
}

event void SplitControl.startDone(error_t err)
{
  if (err == SUCCESS) {
    printf("broker: Radio on!\n");
    printfflush();
  }
  else {
    call SplitControl.start();
  }
}

event void AMSend.sendDone(message_t* msg, error_t err)
{
  publish_msg_t* publishMsg = (publish_msg_t*) msg;

  if(publishMsg->qos && !(call PacketAcknowledgments.wasAcked(msg))){
    call AMSend.send((call AMPacket.destination(msg)), msg, sizeof(publish_msg_t));
  }
}

event void SplitControl.stopDone(error_t err) {}

}

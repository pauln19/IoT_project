#include "messages.h"

module pubSubC {
    uses{
        interface Boot;
        interface Receive;
        interface AMSend;
        interface AMPacket;
        interface Packet;
        interface PacketAcknowledgements;
        interface SplitControl;
    }
}

implementation{
    
    my_sub_t[256] tempSub;
    nx_uint8 numTempSub = 0;
    my_sub_t[256] humSub;
    nx_uint8 numHumSub = 0;
    my_sub_t[256] lumSub;
    nx_uint8 numLumSub = 0;

    event message_t* Receive.receive(message_t* packet, void* payload, uint8_t) 
    {
	    my_msg_t* mess = (my_msg_t*) payload;
	    nx_uint8_t type = mess->msg_type;
        
        if (type == CONNECT){
            am_addr_t sourceAddr = call AMPacket.source(&packet);
            my_msg_t* ack = (my_msg_t*) (call Packet.getPayload(&packetAck, sizeof(my_msg_t)));
            ack->id = mess->id;
            ack->msg_type = CONNACK;

            if(call AMSend.send(sourceAddr, &packetAck, sizeof(my_msg_t)) == SUCCESS){
                dbg("broker", "Received CONNECT - id: %d _ from: %hhu\n", mess->id, sourceAddr);
                dbg("broker", "Send CONNACK to %hhu\n", sourceAddr);
            }
        }
        else if (type == SUBSCRIBE){
            am_addr_t sourceAddr = call AMPacket.source(&packet);
            dbg("broker", "Received SUB - id: %d _ from: %hhu\n", mess->id, sourceAddr);

            for (i=0;
                i<mess->numOfSubs;i++){
                my_sub_item incomingSub = mess->subscriptions[i];
                my_sub_t sub;
                sub->address_id = sourceAddr;
                sub->qos = incomingSub->qos;

                dbg("broker", "Saving SUB of %hhu to topic %d", sourceAddr, incomingSub->topic);

                switch (incomingSub->topic){
                    case (topic_t.TEMPERATURE):
                        tempSub[numTempSub++] = sub;
                    case (topic_t.HUMIDITY):
                        humSub[numHumSub++] = sub;
                    case (topic_t.LUMINOSITY):
                        lumSub[numLumSub++] = sub;
                }
            }
            
            my_msg_t* ack = (my_msg_t*) (call Packet.getPayload(&packetAck, sizeof(my_msg_t)));
            ack->id = mess->id;
            ack->msg_type = SUBACK;
            
            if(call AMSend.send(sourceAddr, &packetAck, sizeof(my_msg_t)) == SUCCESS){
                
                dbg("broker", "Send CONNACK to %hhu\n", sourceAddr);
            }
        }
        else if (type == PUBLISH){
        
        }
        else if (type == PUBACK){
            am_addr_t sourceAddr = call AMPacket.source(&packet);
            dbg("broker", "Received PUBACK - id: %d _ from: %hhu\n", mess->id, sourceAddr);        
        }
        else {
            dbg("broker", "WRONG MESSAGE TYPE");
        }
	        
	}

    event void Boot.booted()
    {
        call SplitControl.start();
    }

    event void SplitControl.startDone(error_t err)
    {
        if (err == SUCCESS) {
            dbg("broker", "Radio on!\n");
        }
        else {
            call SplitControl.start();
        }
    }

    event void AMSend.sendDone(message_t* msg, error_t err)
    {

    }

    event void SplitControl.stopDone(error_t err) {}

} 
	 

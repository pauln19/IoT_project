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
    message_t toResendMsg;

    /*
     * Function used by both broker and clients for sending ACKS or CONNECT messages    
     */
    message_t sendGenericSimple(uint16_t destAddress, uint16_t id, uint8_t type) 
    {
        message_t packet;

        simple_msg_t* msg = (simple_msg_t*) (call Packet.getPayload(&packet, sizeof(simple_msg_t)));
        msg->id = id;
        msg->address = TOS_NODE_ID;
        msg->simple_msg_type = type;
        if(call SendSimple.send(destAddress, &packet, sizeof(simple_msg_t)) == SUCCESS){
            dbg("SimpleMessage", "%d - Send %d message to %d\n", TOS_NODE_ID, type, destAddress);
        }
        return packet;
    }

    /*********************CLIENTS**********************/
    /*
     * Task used by clients for sending the initial SUBSCRIBE message   
     */
    task void sendSubscribe() 
    {
        message_t packet;
        uint32_t subCounter = 0;
        int tmpId = TOS_NODE_ID;
        
        subscribe_msg_t* msg = (subscribe_msg_t*) (call Packet.getPayload(&packet, sizeof(subscribe_msg_t)));
        
        atomic { msg->id = counter++; }
        
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

            dbg("client","%d --- Subscribe topic %d with QoS %d\n", TOS_NODE_ID, item.topic, item.qos);
        }
        msg->numOfSubs = subCounter;
        
        if(call SendSimple.send(brokerAddress, &packet, sizeof(subscribe_msg_t)) == SUCCESS)
            dbg("client","%d - Send SUBSCRIBE - msg_id: %d\n", TOS_NODE_ID, msg->id);

        call TimerAckSub.startOneShot(ACKTIMEOUT);
        toResendMsg = packet;
    }

    /*********************BROKER**********************/
    /*
     * Forward the message msg to all the clients in the array subscribers, with their qos  
     */
    void forwardPublish(my_sub_t subscribers[256], uint8_t numOfSubs, message_t* msg){
        uint8_t i;
        publish_msg_t* publishMsg = (publish_msg_t*) msg;

        for(i=0; i<numOfSubs; i++){

            publishMsg->qos = subscribers[i].qos;

            if(call SendPub.send(subscribers[i].address_id, msg, sizeof(publish_msg_t)) == SUCCESS)
                dbg("broker", "forwardPublish %d to %d\n", publishMsg->id, subscribers[i].address_id);

            /*if(publishMsg->qos == 1)
            {
                toResendMsg = msg;
                call TimerAckPub.startOneShot(ACKTIMEOUT);
            }*/
        }
    }

    /*********************BROKER**********************/
    /*
     * return True if the address is registered, False otherwise   
     */
    bool checkRegistered(uint16_t address) {
        int i;
        for (i = 0; i < nClients; i++)
        {
            if (clients[i] == address){
                return 1;
            }
        }
        return 0;
    }

    event void Boot.booted()
    {
        call SplitControl.start();
    }

    event void SplitControl.startDone(error_t err)
    {
        if (err == SUCCESS) {
            dbg("radio", "%d - Radio on!\n", TOS_NODE_ID);

            if (TOS_NODE_ID != BROKER) {
                /*********************CLIENTS**********************/
                // Send connect message to Broker
                toResendMsg = sendGenericSimple(AM_BROADCAST_ADDR, counter++, CONNECT);
                // wait for CONNACK
                call TimerAckConnect.startOneShot(ACKTIMEOUT);
            }
            else {
                //call TimerPub.startPeriodic(3000); 
                //call TimerPub.startPeriodic(500);
            }

        } else 
            call SplitControl.start();
    }
    
    event void SplitControl.stopDone(error_t err) {}

    /*
     * The ReceiveSimple interface will receive CONNECT, CONNACK, SUBACK, PUBACK    
     */
    event message_t* ReceiveSimple.receive(message_t* packet, void* payload, uint8_t len) { 
        if (call AMPacket.isForMe(packet))
        {
            simple_msg_t* msg = (simple_msg_t*) payload;
            uint16_t sourceAddr = msg->address;
            if (TOS_NODE_ID == BROKER) {
                /*********************BROKER**********************/
                if(msg->simple_msg_type == CONNECT) {
                    /*********************CONNECT**********************/
                    dbg("broker", "Received CONNECT - from: %d\n", sourceAddr);
                    //Check if the client has already been registered
                    //atomic {
                    //    if (checkRegistered(sourceAddr)){
                    //            dbg("broker", "%d already connected\n", sourceAddr);
                    //            return packet;
                    //        }
                        //if not already registered register and send CONNACK
                    //    clients[nClients++] = sourceAddr;
                    //}
                    sendGenericSimple(sourceAddr, msg->id, CONNACK);

                    return packet;
                } else if(msg->simple_msg_type == PUBACK) {
                    call TimerAckPub.stop();
                    dbg("broker", "Received PUBACK - from: %d\n", sourceAddr);
                }
            } else { 
                /*********************CLIENTS**********************/
                if(msg->simple_msg_type == CONNACK) {
                    /*********************CONNACK**********************/
                    call TimerAckConnect.stop(); // Stops the timer for resending CONNECT
                    dbg("client", "%d - Received CONNACK\n", TOS_NODE_ID);

                    //save the broker address
                    brokerAddress = msg->address;

                    post sendSubscribe();   // send the subscribe message
                    return packet;
                } else if(msg->simple_msg_type == SUBACK) {
                    /*********************SUBACK**********************/
                    call TimerAckSub.stop(); // Stops the timer for resending SUBSCRIBE
                    dbg("client", "%d - Received SUBACK\n", TOS_NODE_ID);

                    call TimerPub.startPeriodic(3000);   // start sending PUBLISH
                    return packet;
                } else if(msg->simple_msg_type == PUBACK) {
                    /*********************PUBACK**********************/
                    call TimerAckPub.stop(); // Stops the timer for resending PUBLISH
                    dbg("client", "%d - Received PUBACK\n", TOS_NODE_ID);

                    //call TimerPub.startOneShot(3000);   // start sending PUBLISH
                    return packet;
                }
            }

        }
        dbg("broker", "ERROR\n");
        return packet;
    }

    /*
     * The ReceivePub interface will receive PUBLISH messages, by both broker (to forward) and clients  
     */
    event message_t* ReceivePub.receive(message_t* packet, void* payload, uint8_t len) {
        if (call AMPacket.isForMe(packet))
        {
            publish_msg_t* msg = (publish_msg_t*) payload;
            uint16_t sourceAddr = msg->address;
            if (TOS_NODE_ID == BROKER) {
                /*********************BROKER**********************/
                dbg("broker", "Received PUB - id: %d _ from: %d\n", msg->id, sourceAddr);

                if(msg->qos == 1)
                    sendGenericSimple(sourceAddr, msg->id, PUBACK);
                //atomic {
                    switch (msg->topic){
                        case (TEMPERATURE):
                            forwardPublish(tempSub, numTempSub, packet);

                        case (HUMIDITY):
                            forwardPublish(humSub, numHumSub, packet);

                        case (LUMINOSITY):
                            forwardPublish(lumSub, numLumSub, packet);
                //    }
                }

                return packet;

            } else {
                /*********************CLIENTS**********************/
                if (msg->qos == 1)
                    sendGenericSimple(brokerAddress, msg->id, PUBACK);

                dbg("client", "%d - Received forwarded PUB from: %d\n", TOS_NODE_ID, sourceAddr);
                dbg("client", "%d - -- id %d\n", TOS_NODE_ID, msg->id);
                dbg("client", "%d - -- topic %d\n", TOS_NODE_ID, msg->topic);
                dbg("client", "%d - -- payload %d\n", TOS_NODE_ID, msg->payload);

            }
        }
        return packet;
    }

    /*********************BROKER**********************/
    /*
     * The ReceiveSub interface will receive SUBSCRIBE messages  
     */
    event message_t* ReceiveSub.receive(message_t* packet, void* payload, uint8_t len) {
        if (call AMPacket.isForMe(packet))
        {
            if (TOS_NODE_ID == BROKER) {
                uint8_t i;
                subscribe_msg_t* msg = (subscribe_msg_t*) payload;

                uint16_t sourceAddr = msg->address;
                dbg("broker", "Received SUBSCRIBE - id: %d _ from: %d\n", msg->id, sourceAddr);
                sendGenericSimple(sourceAddr, msg->id, SUBACK); // sending SUBACK

                for (i=0; i<msg->numOfSubs; i++){
                    // Saving the client subscriptions
                    sub_item_t incomingSub = msg->subscriptions[i];
                    my_sub_t sub;
                    sub.address_id = (nx_uint16_t) sourceAddr;
                    sub.qos = incomingSub.qos;

                    dbg("broker", "Saving SUB of %d to topic %d\n", sourceAddr, incomingSub.topic);

                    atomic {
                        switch (incomingSub.topic){
                            case (TEMPERATURE):
                               tempSub[numTempSub++] = sub;

                            case (HUMIDITY):
                               humSub[numHumSub++] = sub;

                            case (LUMINOSITY):
                               lumSub[numLumSub++] = sub;
                        }
                    }
                }
                return packet;
            }
        }
        return packet;
    }

    event void SendSimple.sendDone(message_t* msg, error_t err) {}

    event void SendPub.sendDone(message_t* msg, error_t err) {}

    event void SendSub.sendDone(message_t* msg, error_t err) {}

    /*********************CLIENTS**********************/
    /*
     * Timer used to periodically send PUBLISH  
     */
    event void TimerPub.fired() {
        
        //sendGenericSimple(AM_BROADCAST_ADDR, counter++, CONNECT);
        
        message_t packet;

        publish_msg_t* msg = (publish_msg_t*) (call Packet.getPayload(&packet, sizeof(publish_msg_t)));
        atomic { msg->id = counter++; }
        msg->address = TOS_NODE_ID;

        //statically choose the topic for publish
        switch (TOS_NODE_ID%3 + 1) {
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
        } 

        msg->payload = call Read.rand16();
        

        if(call SendPub.send(AM_BROADCAST_ADDR, &packet, sizeof(publish_msg_t)) == SUCCESS){
            dbg("client", "%d - Send PUBLISH - msg_id: %d\n", TOS_NODE_ID, msg->id);
            dbg("client", "%d - -- topic %d", TOS_NODE_ID, msg->topic);
            dbg("client", "%d - -- payload %d", TOS_NODE_ID, msg->payload);
            dbg("client", "%d - -- qos %d", TOS_NODE_ID, msg->qos);
            
        }
        
        /*if (msg->qos == 1){
            call TimerAckPub.startOneShot(ACKTIMEOUT);
            toResendMsg = &packet;
        }
        else
            call TimerPub.startOneShot(3000);*/
    }

    /*********************CLIENTS**********************/
    /*
     * Timer used to resend CONNECT if the CONNACK is not received  
     */
    event void TimerAckConnect.fired() {
        // CONNACK not received in Timeout, Resend CONNECT
        if(call SendSimple.send(AM_BROADCAST_ADDR, &toResendMsg, sizeof(simple_msg_t)) == SUCCESS){
            dbg("client", "%d - Resend CONNECT message\n", TOS_NODE_ID);
        }
        // wait for CONNACK
        call TimerAckConnect.startOneShot(ACKTIMEOUT);
    }

    /*********************CLIENTS**********************/
    /*
     * Timer used to resend SUBSCRIBE if the SUBACK is not received  
     */
    event void TimerAckSub.fired() {
        // SUBACK not received, resending SUBSCRIBE
        if(call SendSub.send(brokerAddress, &toResendMsg, sizeof(subscribe_msg_t)) == SUCCESS){
            dbg("client", "%d - Resend SUBSCRIBE message\n", TOS_NODE_ID);
        }
        // wait for SUBACK
        call TimerAckSub.startOneShot(ACKTIMEOUT);
    }

    /*
     * Timer used to resend PUBLISH if the SUBACK is not received  
     */
    event void TimerAckPub.fired() {
        // PUBACK not received, resending PUBLISH
        // in case of client num will always be 0

        am_addr_t dest = call AMPacket.destination(&toResendMsg);

        if(call SendPub.send(dest, &toResendMsg, sizeof(publish_msg_t)) == SUCCESS){
            dbg("ResendPub", "%d - Resend PUBLISH message\n", TOS_NODE_ID);
        }
        // wait for PUBACK
        call TimerAckPub.startOneShot(ACKTIMEOUT);
    }

}
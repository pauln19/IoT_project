#include "messages.h"
#include "printf.h"

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
    interface PacketAcknowledgements;

    interface Timer<TMilli> as TimerPub;
    interface Timer<TMilli> as TimerAckConnect;
    interface Timer<TMilli> as TimerSub;

  }
}

implementation {

    uint16_t counter = 0;
    uint16_t brokerAddress;

    my_sub_t tempSub[NUMCLIENTS];
    uint8_t numTempSub = 0;
    my_sub_t humSub[NUMCLIENTS];
    uint8_t numHumSub = 0;
    my_sub_t lumSub[NUMCLIENTS];
    uint8_t numLumSub = 0;

    uint16_t connClients[NUMCLIENTS];
    uint8_t nConnClients = 0;

    uint16_t subClients[NUMCLIENTS];
    uint8_t nSubClients = 0;

    message_t msgQueueBuff[MSGBUFFSIZE];
    message_t * msgQueue[MSGBUFFSIZE];
    int head = 1;
    int indexToSend = 1;
    int countResend = 0;

    bool busy = FALSE;
    message_t message;

    /*
     * Function used by both broker and clients for sending CONNACK or CONNECT messages
     */
    void sendGenericSimple(uint16_t destAddress, uint16_t id, uint8_t type)
    {
        simple_msg_t* msg;
        call Packet.clear(&message);

        msg = (simple_msg_t*) (call Packet.getPayload(&message, sizeof(simple_msg_t)));
        msg->id = id;
        msg->address = TOS_NODE_ID;
        msg->simple_msg_type = type;
        if(call SendSimple.send(destAddress, &message, sizeof(simple_msg_t)) == SUCCESS){
            printf("node_%d - Send %d message to %d\n", TOS_NODE_ID, type, destAddress);
            printfflush();
        }

    }

    /*********************CLIENTS**********************/
    /*
     * Task used by clients for sending the initial SUBSCRIBE message
     */
    task void sendSubscribe()
    {
        subscribe_msg_t* msg;
        uint32_t subCounter = 0;
        int tmpId = TOS_NODE_ID;
        call Packet.clear(&message);
        msg = (subscribe_msg_t*) (call Packet.getPayload(&message, sizeof(subscribe_msg_t)));

        busy = TRUE;

        // Pseudo random choice of subscription and qos
        while(tmpId >= 1 && subCounter < 3) {
            sub_item_t item;

            switch ((int) (tmpId%3)) {
              case 0:
                item.topic = TEMPERATURE;
                break;
              case 1:
                item.topic = HUMIDITY;
                break;
              case 2:
                item.topic = LUMINOSITY;
                break;
            }

            if ((call Read.rand16()) % 2 == 0)
                item.qos = 0;
            else
                item.qos = 1;

            msg->subscriptions[subCounter] = item;
            subCounter ++;
            tmpId -= 4;

            printf("client_%d -- Subscribe topic %d with QoS %d\n", TOS_NODE_ID, item.topic, item.qos);
            printfflush();

        }
        msg->id = counter++;
        msg->address = TOS_NODE_ID;
        msg->numOfSubs = subCounter;
        call PacketAcknowledgements.requestAck(&message);

        if (call SendSub.send(brokerAddress, &message, sizeof(subscribe_msg_t)) == SUCCESS) {
            printf("client_%d -- Send SUBSCRIBE - msg_id: %d\n", TOS_NODE_ID, msg->id);
            printfflush();
        }

        return;

    }

    /*********************BROKER**********************/
    /*
     * Task used by the broker to forward the publish messages in the queue
     */
    task void forwardTask(){
        message_t * packet = msgQueue[indexToSend];
        publish_msg_t* msg;
        uint16_t dest = call AMPacket.destination(packet);
        int code = call SendPub.send(dest, packet, sizeof(publish_msg_t));

        msg = (publish_msg_t*) (call Packet.getPayload(packet, sizeof(publish_msg_t)));
        countResend++;
        printf("broker -- forwardPublish %u to %u - qos %d - with code %d\n", msg->id, dest, msg->qos, code);
        printfflush();
    }

    /*********************BROKER**********************/
    /*
     * Enqueue the messages to be forwarded
     */
    void enqueueForward(my_sub_t subscribers[NUMCLIENTS], uint8_t numOfSubs, publish_msg_t* inMsg){
        uint8_t i;
        // Check that there are actually subscribers for the given topic
        if (numOfSubs > 0)
        {
            for(i=0; i<numOfSubs; i++){
                message_t* packet = msgQueue[head++];
                publish_msg_t* msg;
                call Packet.clear(packet);
                msg = (publish_msg_t*) (call Packet.getPayload(packet, sizeof(publish_msg_t)));

                msg->address = inMsg->address;
                msg->id = inMsg->id;
                msg->topic = inMsg->topic;
                msg->data = inMsg->data;
                if (subscribers[i].qos == 1){
                    msg->qos = 1;
                    call PacketAcknowledgements.requestAck(packet);
                } else {
                    msg->qos = 0;
                    call PacketAcknowledgements.noAck(packet);
                }
                call AMPacket.setDestination(packet, subscribers[i].address_id);

            }
            printf("broker -- Enqueued PUBLISH - id: %d\n", inMsg->id);
            printfflush();
            post forwardTask();
        }
    }

    /*********************BROKER**********************/
    /*
     * return True if the address is contained in a given list (clients[NUMCLIENTS]), False otherwise
     */
    bool checkClients(uint16_t address, uint16_t clients[NUMCLIENTS], uint8_t nClients) {
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
            busy = FALSE;
            printf("radio -- node %d - Radio on!\n", TOS_NODE_ID);
            printfflush();
            if (TOS_NODE_ID != BROKER) {
                /*********************CLIENTS**********************/
                // Send connect message to Broker
                busy = TRUE;
                sendGenericSimple(AM_BROADCAST_ADDR, counter++, CONNECT);
                // wait for CONNACK
                call TimerAckConnect.startOneShot(ACKTIMEOUT);
            } else {
                /*********************BROKER**********************/
                // Prepare the queue for the publish messages
                int i;
                for (i = 0; i<=MSGBUFFSIZE; i++)
                    msgQueue[i] = &msgQueueBuff[i];
            }

        } else
            call SplitControl.start();
    }

    event void SplitControl.stopDone(error_t err) {}

    /*
     * The ReceiveSimple interface will receive CONNECT, CONNACK
     */
    event message_t* ReceiveSimple.receive(message_t* packet, void* payload, uint8_t len) {
        if (!busy) {
            if (call AMPacket.isForMe(packet))
            {
                simple_msg_t* msg = (simple_msg_t*) payload;
                uint16_t sourceAddr = msg->address;
                if (TOS_NODE_ID == BROKER) {
                    /*********************BROKER**********************/
                    if(msg->simple_msg_type == CONNECT) {
                        busy = TRUE;
                        printf("broker -- Received CONNECT - from: %d\n", sourceAddr);
                        printfflush();
                        //Check if the client has already been registered
                        atomic {
                            if (checkClients(sourceAddr, connClients, nConnClients)){
                                    return packet;
                                }
                            //if not already registered, register and send CONNACK
                            connClients[nConnClients++] = sourceAddr;
                        }
                        sendGenericSimple(sourceAddr, msg->id, CONNACK);
                        return packet;
                    }
                } else {
                    /*********************CLIENTS**********************/
                    if(msg->simple_msg_type == CONNACK) {
                        busy = TRUE;
                        call TimerAckConnect.stop(); // Stops the timer for resending CONNECT

                        printf("client_%d -- Received CONNACK\n", TOS_NODE_ID);
                        printfflush();

                        // Save the broker address
                        brokerAddress = msg->address;

                        call TimerSub.startOneShot(500);   // Send the subscribe message after the timer finishes
                        busy = FALSE;
                        return packet;

                    }
                }
            }
        }
        return packet;
    }

    /*
     * The ReceivePub interface will receive PUBLISH messages, by both clients and broker (which will forward)
     */
    event message_t* ReceivePub.receive(message_t* packet, void* payload, uint8_t len) {
        // Check that the radio is not busy
        if (!busy) {
            if (call AMPacket.isForMe(packet))
            {
                publish_msg_t* msg = (publish_msg_t*) payload;
                uint16_t sourceAddr = msg->address;
                if (TOS_NODE_ID == BROKER) {
                    /*********************BROKER**********************/
                    printf("broker -- Received PUB - id: %d _ from: %d -- topic %d\n", msg->id, sourceAddr, msg->topic);
                    printfflush();

                    busy = TRUE;

                    atomic {
                        switch (msg->topic){
                            case (TEMPERATURE):
                                enqueueForward(tempSub, numTempSub, msg);
                                break;
                            case (HUMIDITY):
                                enqueueForward(humSub, numHumSub, msg);
                                break;
                            case (LUMINOSITY):
                                enqueueForward(lumSub, numLumSub, msg);
                                break;
                        }
                    }

                    return packet;

                } else {
                    /*********************CLIENTS**********************/
                    busy = TRUE;
                    printf("client_%d -- Received forwarded PUB from: %d\n       --  id %d -- topic %d  -- qos %d\n", TOS_NODE_ID, sourceAddr, msg->id, msg->topic, msg->qos);
                    printfflush();
                    busy = FALSE;

                }
            }
        }
        return packet;
    }

    /*********************BROKER**********************/
    /*
     * The ReceiveSub interface will receive SUBSCRIBE messages
     */
    event message_t* ReceiveSub.receive(message_t* packet, void* payload, uint8_t len) {
        if (!busy) {
            if (call AMPacket.isForMe(packet))
            {
                if (TOS_NODE_ID == BROKER) {

                    uint8_t i;
                    subscribe_msg_t* msg = (subscribe_msg_t*) payload;

                    uint16_t sourceAddr = msg->address;
                    busy = TRUE;

                    atomic {
                        if (!checkClients(sourceAddr, subClients, nSubClients)){
                            // If not already subscribed...
                            for (i=0; i<msg->numOfSubs; i++){
                                // ...save the client subscriptions
                                sub_item_t incomingSub = msg->subscriptions[i];
                                my_sub_t sub;
                                sub.address_id = sourceAddr;
                                sub.qos = incomingSub.qos;

                                printf("broker -- Saving SUB of %d to topic %d\n", sourceAddr, incomingSub.topic);
                                printfflush();

                                switch (incomingSub.topic){
                                    case (TEMPERATURE):
                                       tempSub[numTempSub++] = sub;
                                       break;

                                    case (HUMIDITY):
                                       humSub[numHumSub++] = sub;
                                       break;

                                    case (LUMINOSITY):
                                       lumSub[numLumSub++] = sub;
                                       break;
                                }

                            }
                            subClients[nSubClients++] = sourceAddr;
                        }
                    }
                    busy = FALSE;
                    return packet;
                }
            }
        }
        return packet;
    }

    /*
     * Free the channel when the CONNECT/CONNACK is sent
     */
    event void SendSimple.sendDone(message_t* msg, error_t err) {
        busy = FALSE;
    }

    event void SendPub.sendDone(message_t* msg, error_t err) {
        publish_msg_t* pubMsg = (publish_msg_t*) (call Packet.getPayload(msg, sizeof(publish_msg_t)));

        if (TOS_NODE_ID != BROKER) {
          /*********************CLIENTS**********************/
            if(pubMsg->qos == 1){
                if(!(call PacketAcknowledgements.wasAcked(msg))){
                    // Send the publish again in case it wasn't acked by the PAN
                    call SendPub.send(brokerAddress, msg, sizeof(publish_msg_t));
                    return;
                }
                printf("client_%d -- PUBACK received\n", TOS_NODE_ID);
                printfflush();
            }

            busy = FALSE;
            // Start the publish timer again
            call TimerPub.startOneShot(PUBLISHTIMER);
        } else {
            /*********************BROKER**********************/
            if(pubMsg->qos == 1){
                if(!(call PacketAcknowledgements.wasAcked(msg))){
                    // Forward the publish again if it wasn't acked (max 5 times)
                    if (countResend < 5)
                        post forwardTask();
                    else {
                        printf("broker -- FAILED to send message. 5 attempts.");
                        printfflush();
                    }
                    return;
                } else {
                    printf("broker -- PUBACK received\n");
                    printfflush();
                }
            }
            indexToSend++; // Move the head to the next message

            if (indexToSend >= head){
                // If there are no other messages in the queue, reset the indexes
                busy = FALSE;
                indexToSend = 1;
                head = 1;
            }
            else {
                // Forward the next message in the queue
                post forwardTask();
            }

        }

    }

    /*********************CLIENTS**********************/
    event void SendSub.sendDone(message_t* msg, error_t err) {

        if(!(call PacketAcknowledgements.wasAcked(msg))){
            // Send again the subscription if it wasn't acked
            call SendSub.send(brokerAddress, msg, sizeof(subscribe_msg_t));
            return;
        } else

            printf("client_%d -- SUBACK received\n", TOS_NODE_ID);
            printfflush();

            busy = FALSE;
            call TimerPub.startOneShot(PUBLISHTIMER); // Start the timer for the publish messages

    }

    /*********************CLIENTS**********************/
    /*
     * Timer used to periodically send PUBLISH
     */
    event void TimerPub.fired() {

        if (!busy) {
            publish_msg_t* msg;
            call Packet.clear(&message);
            msg = (publish_msg_t*) (call Packet.getPayload(&message, sizeof(publish_msg_t)));
            busy = TRUE;

            msg->id = counter++;
            msg->address = TOS_NODE_ID;

            //statically choose the topic for publish
            switch ((TOS_NODE_ID + 1) %3) {
              case 0:
                msg->topic = TEMPERATURE;
                break;
              case 1:
                msg->topic = HUMIDITY;
                break;
              case 2:
                msg->topic = LUMINOSITY;
                break;
            }

            // Randomize the payload
            msg->data = call Read.rand16();

            // Randomize the qos
            if ((call Read.rand16()) % 2 == 0)
            {
                msg->qos = 0;
                call PacketAcknowledgements.noAck(&message);
            } else {
                msg->qos = 1;
                call PacketAcknowledgements.requestAck(&message);
            }

            if(call SendPub.send(brokerAddress, &message, sizeof(publish_msg_t)) == SUCCESS){

                printf("client_%d -- Send PUBLISH - msg_id: %d\n", TOS_NODE_ID, msg->id);
                printf("client_%d --      -- topic %d -- payload %d -- qos %d\n", TOS_NODE_ID, msg->topic, msg->data, msg->qos);
                printfflush();

            }
        }

    }

    /*********************CLIENTS**********************/
    /*
     * Timer used to resend CONNECT if the CONNACK is not received
     */
    event void TimerAckConnect.fired() {

        call SendSimple.send(AM_BROADCAST_ADDR, &message, sizeof(simple_msg_t))
        // wait for CONNACK
        call TimerAckConnect.startOneShot(ACKTIMEOUT);
    }

    /*********************CLIENTS**********************/
    /*
     * Timer used to send SUBSCRIBE
     */
    event void TimerSub.fired() {
        post sendSubscribe();
    }

}

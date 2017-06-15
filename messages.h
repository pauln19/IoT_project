
#ifndef MESSAGES_H
#define MESSAGES_H

typedef enum topic {TEMPERATURE=1, HUMIDITY=2, LUMINOSITY=3} topic_t;

#define CONNECT 1
#define SUBSCRIBE 2
#define PUBLISH 3
#define CONNACK 4
#define SUBACK 5
#define PUBACK 6

#define BROKER 0

typedef nx_struct my_sub {
    nx_uint16_t address_id;
    nx_uint8_t qos;
} my_sub_t

typedef nx_struct sub_item {
    topic_t topic;
    nx_uint8_t qos;
} my_sub_item

typedef nx_struct my_msg {
    nx_uint16_t id;
    nx_uint8_t msg_type;
    nx_uint16_t address_id;
    topic_t topic;
    nx_uint16 payload;
    my_sub_item[3] subscriptions;
} my_msg_t;


#endif

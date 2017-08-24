#ifndef MESSAGES_H
#define MESSAGES_H

enum {TEMPERATURE=0, HUMIDITY=1, LUMINOSITY=2};
enum {CONNACK=0, CONNECT=1, SUBACK=2, PUBACK=3};

#define BROKER 1
#define ACKTIMEOUT 1000

typedef struct my_sub {
    uint16_t address_id;
    uint8_t qos;
} my_sub_t;

typedef nx_struct sub_item {
    nx_uint8_t topic;
    nx_uint8_t qos;
} sub_item_t;

typedef nx_struct simple_msg {
    nx_uint16_t address;
    nx_uint16_t id;
    nx_uint8_t simple_msg_type;
} simple_msg_t;

typedef nx_struct subscribe_msg {
    nx_uint16_t address;
    nx_uint16_t id;
    nx_uint8_t numOfSubs;
    sub_item_t subscriptions[3];
} subscribe_msg_t;

typedef nx_struct publish_msg {
    nx_uint16_t address;
    nx_uint16_t id;
    nx_uint8_t topic;
    nx_uint16_t payload;
    nx_uint8_t qos;
} publish_msg_t;

enum {
    AM_CONNECT_MSG = 6,
    AM_SUBSCRIBE_MSG = 10,
    AM_PUBLISH_MSG = 14
};

#endif

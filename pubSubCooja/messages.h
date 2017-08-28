#ifndef MESSAGES_H
#define MESSAGES_H

enum {TEMPERATURE=0, HUMIDITY=1, LUMINOSITY=2};
enum {CONNACK=0, CONNECT=1};
    //, SUBACK=2, PUBACK=3};

#define BROKER 1
#define ACKTIMEOUT 5000
#define PUBLISHTIMER 7000
#define NUMCLIENTS 20
#define NEW_PRINTF_SEMANTICS

typedef struct my_sub {
    uint16_t address_id;
    bool qos;
} my_sub_t;

typedef nx_struct sub_item {
    nx_uint8_t topic;
    nx_bool qos;
} sub_item_t;

typedef nx_struct simple_msg {
    nx_uint16_t address;
    nx_uint16_t id;
    nx_uint8_t simple_msg_type;
} simple_msg_t;
//5 -> 18
typedef nx_struct subscribe_msg {
    nx_uint16_t address;
    nx_uint16_t id;
    nx_uint8_t numOfSubs;
    sub_item_t subscriptions[3];
} subscribe_msg_t;
//11 -> 24
typedef nx_struct publish_msg {
    nx_uint16_t address;
    nx_uint16_t id;
    nx_uint8_t topic;
    nx_bool qos;
    nx_uint16_t data;
} publish_msg_t;
//8 -> 24
enum {
    AM_SIMPLE_MSG = 6,
    AM_SUBSCRIBE_MSG = 7,
    AM_PUBLISH_MSG = 9
};

#endif

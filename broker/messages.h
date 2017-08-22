#ifndef MESSAGES_H
#define MESSAGES_H

enum {TEMPERATURE=0, HUMIDITY=1, LUMINOSITY=2};
//enum {CONNACK=0, SUBACK=1, PUBACK=2, CONNECT=4};

typedef struct my_sub {
    uint16_t address_id;
    bool qos;
} my_sub_t;

typedef nx_struct sub_item {
    nx_uint8_t topic;
    nx_bool qos;
} sub_item_t;

typedef nx_struct connect_msg {
    nx_uint16_t address;
    nx_uint16_t id;
    //nx_uint8_t connect_msg_type;
} connect_msg_t;

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
    nx_bool qos;
} publish_msg_t;

enum {
    AM_CONNECT_MSG = 6,
    AM_SUBSCRIBE_MSG = 10,
    AM_PUBLISH_MSG = 14
};

#endif

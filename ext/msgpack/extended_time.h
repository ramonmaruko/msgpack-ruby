#ifndef MSGPACK_RUBY_TIME_H__
#define MSGPACK_RUBY_TIME_H__

#include "compat.h"
#include "sysdep.h"

struct msgpack_time_components;
struct msgpack_time_payload;
typedef struct msgpack_time_components msgpack_time_components;
typedef struct msgpack_time_payload msgpack_time_payload;

struct msgpack_time_payload {
    uint8_t *payload;
    size_t size;
};

union msgpack_time_cast_block_sec {
    int64_t i64;
    char mem[8];
};

union msgpack_time_cast_block_nsec {
    uint32_t u32;
    char mem[4];
};

union msgpack_time_cast_block_utc_offset {
    int16_t i16;
    char mem[2];
};

struct msgpack_time_components {
    uint8_t descriptor;

    struct {
        union msgpack_time_cast_block_sec value;
        size_t size;
    } sec;

    struct {
        union msgpack_time_cast_block_nsec value;
        size_t size;
    } nsec;

    struct {
        union msgpack_time_cast_block_utc_offset value;
        size_t size;
    } utc_offset;
};

void msgpack_time_set_secs(msgpack_time_components *tc, const int64_t tv_sec);
void msgpack_time_set_nsecs(msgpack_time_components *tc, const uint32_t tv_nsec);
void msgpack_time_set_tz(msgpack_time_components *tc, const int16_t utc_offset, const bool isdst);
msgpack_time_payload *msgpack_time_create_payload(msgpack_time_components *tc);
void msgpack_time_free_payload(msgpack_time_payload *tp);

#endif


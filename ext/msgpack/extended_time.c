#include "extended_time.h"

static uint8_t msgpack_time_bytes_needed_int64(const int64_t v)
{
    uint8_t n = 0;

    if(v >= -0x80000000LL && v < 0x80000000LL) {
        if(v >= -0x800000LL && v < 0x800000LL) {
            if(v >= -0x80LL && v < 0x80LL) {
                if(v == 0) {
                    n = 0;
                } else {
                    n = 1;
                }
            } else {
                if(v >= -0x8000LL && v < 0x8000LL) {
                    n = 2;
                } else {
                    n = 3;
                }
            }
        } else {
            n = 4;
        }
    } else {
        if(v >= -0x80000000000000LL && v < 0x80000000000000LL ) {
            if(v >= -0x800000000000LL && v < 0x800000000000LL) {
                if(v >= -0x8000000000LL && v < 0x8000000000LL) {
                    n = 5;
                } else {
                    n = 6;
                }
            } else {
                n = 7;
            }
        } else {
            n = 8;
        }
    }

    return n;
}

static uint8_t msgpack_time_bytes_needed_uint32(const uint32_t v)
{
    uint8_t n = 0;

    if(v < 0x10000UL) {
        if(v < 0x100UL) {
            if(v == 0) {
                n = 0;
            } else {
                n = 1;
            }
        } else {
            n = 2;
        }
    } else {
        if(v < 0x1000000UL) {
            n = 3;
        } else {
            n = 4;
        }
    }

    return n;
}

void msgpack_time_set_secs(msgpack_time_components *tc, const int64_t tv_sec)
{
    static const uint8_t masks[] = {
        0x0, 0x80, 0x84, 0x88, 0x8c, 0x90, 0x94, 0x98, 0x9c
    };

    tc->sec.value.i64 = tv_sec;
    tc->sec.size = msgpack_time_bytes_needed_int64(tv_sec);
    tc->descriptor |= masks[tc->sec.size];
}

void msgpack_time_set_nsecs(msgpack_time_components *tc, const uint32_t tv_nsec)
{
    static const uint8_t masks[] = {
        0x0, 0x40, 0x41, 0x42, 0x43
    };

    tc->nsec.value.u32 = tv_nsec;
    tc->nsec.size = msgpack_time_bytes_needed_uint32(tv_nsec);

    tc->descriptor |= masks[tc->nsec.size];
}

void msgpack_time_set_tz(msgpack_time_components *tc, const int16_t utc_offset, const int8_t isdst)
{
    tc->utc_offset.value.i16 = utc_offset;

    if(utc_offset == 0) {
        tc->utc_offset.size = 0;
    } else {
        tc->utc_offset.size = 2;
        tc->descriptor |= 0x20;

        if(isdst == Qtrue) {
            tc->utc_offset.value.i16 |= 0xc000;
        } else {
            tc->utc_offset.value.i16 &= 0x3fff;
        }
    }
}

msgpack_time_payload *msgpack_time_create_payload(msgpack_time_components *tc)
{
    msgpack_time_payload *tp = malloc(sizeof(msgpack_time_payload));

    tp->size = tc->sec.size  +
               tc->nsec.size +
               tc->utc_offset.size;

    tp->payload = malloc(tp->size);

    const union msgpack_time_cast_block_sec sec = {
        .i64 = _msgpack_be64(tc->sec.value.i64)
    };
    const union msgpack_time_cast_block_nsec nsec = {
        .u32 = _msgpack_be32(tc->nsec.value.u32)
    };
    const union msgpack_time_cast_block_utc_offset utc_offset = {
        .i16 = _msgpack_be16(tc->utc_offset.value.i16)
    };

    /* starting address of big endian seconds and nanoseconds */
    const uint8_t offsets[2] = {
        sizeof(int64_t) - tc->sec.size,
        sizeof(uint32_t) - tc->nsec.size,
    };

    memcpy(tp->payload, sec.mem + offsets[0], tc->sec.size);
    memcpy(tp->payload + tc->sec.size, nsec.mem + offsets[1], tc->nsec.size);
    memcpy(tp->payload + tp->size - 2, utc_offset.mem, tc->utc_offset.size);

    return tp;
}

void msgpack_time_free_payload(msgpack_time_payload *tp) {
    free(tp->payload);
    free(tp);
}

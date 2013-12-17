/* *INDENT-ON* */
#ifdef __cplusplus
extern "C" {
#endif

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#define NEED_newRV_noinc
#include "ppport.h"
#include <sys/socket.h>
#include "maxminddb.h"

#define MATH_INT64_NATIVE_IF_AVAILABLE
#include "perl_math_int64.h"
#include "perl_math_int128.h"

#ifdef __cplusplus
}
#endif

static int has_highbyte(const U8 * ptr, int size)
{
    while (--size >= 0) {
        if (*ptr++ > 127) {
            return 1;
        }
    }

    return 0;
}

static SV *decode_utf8_string(MMDB_entry_data_s *entry_data)
{
    int size = entry_data->data_size;
    char *data = (char *)entry_data->utf8_string;
    SV *sv = newSVpvn(data, size);
    if (has_highbyte((const U8 *)data, size)) {
        SvUTF8_on(sv);
    }
    return sv;
}

static SV *decode_bytes(MMDB_entry_data_s *entry_data)
{
    return newSVpvn((char *)entry_data->bytes, entry_data->data_size);
}

static SV *decode_simple_value(MMDB_entry_data_list_s **current)
{
    MMDB_entry_data_s entry_data = (*current)->entry_data;
    switch (entry_data.type) {
    case MMDB_DATA_TYPE_UTF8_STRING:
        return decode_utf8_string(&entry_data);
    case MMDB_DATA_TYPE_DOUBLE:
        return newSVnv(entry_data.double_value);
    case MMDB_DATA_TYPE_BYTES:
        return decode_bytes(&entry_data);
    case MMDB_DATA_TYPE_FLOAT:
        return newSVnv(entry_data.float_value);
    case MMDB_DATA_TYPE_UINT16:
        return newSVuv(entry_data.uint16);
    case MMDB_DATA_TYPE_UINT32:
        return newSVuv(entry_data.uint32);
    case MMDB_DATA_TYPE_INT32:
        return newSViv(entry_data.int32);
    case MMDB_DATA_TYPE_UINT64:
        return newSVu64(entry_data.uint64);
    case MMDB_DATA_TYPE_UINT128:
        /* We don't handle the case where uint128 is a byte array since even
         * the pure Perl MaxMind::DB::Reader requires Math::Int128, which in
         * turn requires GCC 4.4+. Therefore we know that we have an int128
         * type available if this code is compiling at all. */
        return newSVu128(entry_data.uint128);
    case MMDB_DATA_TYPE_BOOLEAN:
        /* Note to future coders - do not use PL_sv_yes, PL_sv_no, or bool_sv
         * - these all produce read-only SVs */
        return newSViv(entry_data.boolean);
    default:
        croak(
            "MaxMind::DB::Reader::XS - error decoding unknown type number %i",
            entry_data.type
            );
    }

    /* It shouldn't be possible to reach this. */
    return NULL;
}

static SV *decode_entry_data_list(MMDB_entry_data_list_s **entry_data_list);

static SV *decode_array(MMDB_entry_data_list_s **current)
{
    int size = (*current)->entry_data.data_size;

    AV *av = newAV();
    for (uint i = 0; i < size; i++) {
        *current = (*current)->next;
        av_push(av, decode_entry_data_list(current));
    }

    return newRV_noinc((SV *)av);
}

static SV *decode_map(MMDB_entry_data_list_s **current)
{
    int size = (*current)->entry_data.data_size;

    HV *hv = newHV();
    for (uint i = 0; i < size; i++) {
        *current = (*current)->next;
        char *key = (char *)(*current)->entry_data.utf8_string;
        int key_size = (*current)->entry_data.data_size;
        *current = (*current)->next;
        SV *val = decode_entry_data_list(current);
        (void)hv_store(hv, key, key_size, val, 0);
    }

    return newRV_noinc((SV *)hv);
}

static SV *decode_entry_data_list(MMDB_entry_data_list_s **current)
{
    switch ((*current)->entry_data.type) {
    case MMDB_DATA_TYPE_MAP:
        return decode_map(current);
    case MMDB_DATA_TYPE_ARRAY:
        return decode_array(current);
    default:
        return decode_simple_value(current);
    }
}

static SV *decode_and_free_entry_data_list(
    MMDB_entry_data_list_s *entry_data_list)
{
    MMDB_entry_data_list_s *current = entry_data_list;
    SV *sv = decode_entry_data_list(&current);
    MMDB_free_entry_data_list(entry_data_list);
    return sv;
}

/* *INDENT-OFF* */

MODULE = MaxMind::DB::Reader::XS    PACKAGE = MaxMind::DB::Reader::XS

BOOT:
     PERL_MATH_INT64_LOAD_OR_CROAK;
     PERL_MATH_INT128_LOAD_OR_CROAK;

MMDB_s *
_open_mmdb(self, file, flags)
    char *file;
    U32 flags;
    PREINIT:
        MMDB_s *mmdb;
        uint16_t status;

    CODE:
        if (file == NULL) {
            croak("MaxMind::DB::Reader::XS - no file passed to _open_mmdb()\n");
        }
        mmdb = (MMDB_s *)malloc(sizeof(MMDB_s));
        status = MMDB_open(file, flags, mmdb);

        if (MMDB_SUCCESS != status) {
            const char *error = MMDB_strerror(status);
            free(mmdb);
            croak(
                "MaxMind::DB::Reader::XS - error opening database file \"%s\"- %s",
                file, error
                );
        }

        RETVAL = mmdb;
    OUTPUT:
        RETVAL

void
_close_mmdb(self, mmdb)
        MMDB_s *mmdb;
    CODE:
        MMDB_close(mmdb);
        free(mmdb);

SV *
_raw_metadata(self, mmdb)
        MMDB_s *mmdb
    PREINIT:
        MMDB_entry_data_list_s *entry_data_list;
    CODE:
        int status = MMDB_get_metadata_as_entry_data_list(mmdb, &entry_data_list);
        if (MMDB_SUCCESS != status) {
            const char *error = MMDB_strerror(status);
            MMDB_free_entry_data_list(entry_data_list);
            croak(
                "MaxMind::DB::Reader::XS - error getting metadata- %s",
                error
                );
        }

        RETVAL = decode_and_free_entry_data_list(entry_data_list);
    OUTPUT:
        RETVAL

SV *
__data_for_address(self, mmdb, ip_address)
        MMDB_s *mmdb
        char *ip_address
    PREINIT:
        int gai_status, mmdb_status, get_status;
        MMDB_lookup_result_s result;
        MMDB_entry_data_list_s *entry_data_list;
    CODE:
        result = MMDB_lookup_string(mmdb, ip_address, &gai_status, &mmdb_status);
        if (0 != gai_status) {
            const char *gai_error = gai_strerror(gai_status);
            croak(
                "MaxMind::DB::Reader::XS - lookup on invalid IP address \"%s\" - %s",
                ip_address, gai_error
                );
        }

        if (MMDB_SUCCESS != mmdb_status) {
            const char *mmdb_error = MMDB_strerror(mmdb_status);
            croak(
                "MaxMind::DB::Reader::XS - error looking up IP address \"%s\" - %s",
                ip_address, mmdb_error
                );
        }

        if (result.found_entry) {
            get_status = MMDB_get_entry_data_list(&result.entry, &entry_data_list);
            if (MMDB_SUCCESS != get_status) {
                const char *get_error = MMDB_strerror(get_status);
                MMDB_free_entry_data_list(entry_data_list);
                croak(
                    "MaxMind::DB::Reader::XS - got entry data error looking up \"%s\" - %s",
                    ip_address, get_error
                    );
            }
            RETVAL = decode_and_free_entry_data_list(entry_data_list);
        } else {
            RETVAL = &PL_sv_undef;
        }
    OUTPUT:
        RETVAL

SV *
__get_entry_data(self, mmdb, offset)
        MMDB_s *mmdb
        U32 offset
    PREINIT:
        MMDB_entry_s entry;
        int status;
        MMDB_entry_data_list_s *entry_data_list;
    CODE:
        entry.mmdb = mmdb;
        entry.offset = offset - mmdb->metadata.node_count;

        status = MMDB_get_entry_data_list(&entry, &entry_data_list);
        if (MMDB_SUCCESS != status) {
            const char *error = MMDB_strerror(status);
            MMDB_free_entry_data_list(entry_data_list);
            croak(
                "MaxMind::DB::Reader::XS - got entry data error looking at offset %i - %s",
                entry.offset, error
                );
        }
        RETVAL = decode_and_free_entry_data_list(entry_data_list);
    OUTPUT:
        RETVAL

void
__read_node(self, mmdb, node_number)
        MMDB_s *mmdb
        U32 node_number
    PREINIT:
        MMDB_search_node_s node;
        int status;
    PPCODE:
        status = MMDB_read_node(mmdb, node_number, &node);
        if (MMDB_SUCCESS != status) {
            const char *error = MMDB_strerror(status);
            croak(
                "MaxMind::DB::Reader::XS - got an error trying to read node %i - %s",
                node_number, error
                );
        }
        EXTEND(SP, 2);
        mPUSHu(node.left_record);
        mPUSHu(node.right_record);

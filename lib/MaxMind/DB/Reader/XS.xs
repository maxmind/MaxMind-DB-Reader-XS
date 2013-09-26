#ifdef __cplusplus
extern "C" {
#endif

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#define NEED_newRV_noinc
#include "ppport.h"
#include "maxminddb.h"

#ifdef __cplusplus
}
#endif

static SV *decode_entry_data_list(MMDB_entry_data_list_s **entry_data_list);
static SV *decode_map(MMDB_entry_data_list_s **entry_data_list);
static SV *decode_array(MMDB_entry_data_list_s **entry_data_list);
static SV *decode_utf8_string(MMDB_entry_data_list_s **entry_data_list);
static SV *decode_simple_value(MMDB_entry_data_list_s **entry_data_list);

static int has_highbyte(const U8 *ptr, int size)
{
    while (--size >= 0) {
        if (*ptr++ > 127) {
            return 1;
        }
    }
    return 0;
}

static SV *decode_and_free_entry_data_list(MMDB_entry_data_list_s *entry_data_list)
{
    MMDB_entry_data_list_s *current = entry_data_list;
    SV *sv = decode_entry_data_list(&current);
    MMDB_free_entry_data_list(entry_data_list);
    return sv;
}

static SV *decode_entry_data_list(MMDB_entry_data_list_s **current)
{
    switch ((*current)->entry_data.type) {
        case MMDB_DATA_TYPE_MAP:
            return decode_map(current);
        case MMDB_DATA_TYPE_ARRAY:
            return decode_array(current);
        case MMDB_DATA_TYPE_UTF8_STRING:
            return decode_utf8_string(current);
        default:
            return decode_simple_value(current);
    }
}

static SV *decode_map(MMDB_entry_data_list_s **current)
{
    SV *val;
    HV *hv = newHV();
    int size = (*current)->entry_data.data_size;
    *current = (*current)->next;

    for (uint i = 0; i < size; i++ ) {
        char *key    = (char *)(*current)->entry_data.utf8_string;
        int key_size = (*current)->entry_data.data_size;
        *current     = (*current)->next;
        val          = decode_entry_data_list(current);
        (void)hv_store(hv, key, key_size, val, 0);
    }

    return newRV_noinc((SV *) hv);
}

static SV *decode_array(MMDB_entry_data_list_s **current) {
    AV *av = newAV();
    int size = (*current)->entry_data.data_size;
    *current = (*current)->next;

    for (uint i = 0; i < size; i++ ) {
        av_push(av, decode_entry_data_list(current));
    }
    return newRV_noinc((SV *) av);
}


static SV *decode_utf8_string(MMDB_entry_data_list_s **current)
{
    SV *sv;
    int size = (*current)->entry_data.data_size;
    char *data = size ? (char *)(*current)->entry_data.utf8_string : "";
    sv = newSVpvn(data, size);
    if (has_highbyte((U8 *)data, size)) {
        SvUTF8_on(sv);
    }
    *current = (*current)->next;
    return sv;
}

static SV *decode_simple_value(MMDB_entry_data_list_s **current)
{
    SV *sv;
    MMDB_entry_data_s entry_data = (*current)->entry_data;
    switch (entry_data.type) {
        case MMDB_DATA_TYPE_INT32:
            sv = newSViv(entry_data.int32);
            break;
        case MMDB_DATA_TYPE_UINT16:
            sv = newSVuv(entry_data.uint16);
            break;
        case MMDB_DATA_TYPE_UINT32:
            sv = newSVuv(entry_data.uint32);
            break;
        case MMDB_DATA_TYPE_BOOLEAN:
            sv = newSVuv(entry_data.boolean);
            break;
        case MMDB_DATA_TYPE_DOUBLE:
            sv = newSVnv(entry_data.double_value);
            break;
        case MMDB_DATA_TYPE_FLOAT:
            sv = newSVnv(entry_data.float_value);
            break;
        case MMDB_DATA_TYPE_UINT64:
            sv = newSVuv(entry_data.uint64);
            break;
        default:
            croak(
                "MaxMind::DB::Reader::XS Error decoding type %i",
                entry_data.type
            );
    }
    *current = (*current)->next;
    return sv;
}

MODULE = MaxMind::DB::Reader::XS    PACKAGE = MaxMind::DB::Reader::XS

MMDB_s *
_open_mmdb(self, file, flags)
    char *file;
    U32 flags;
    PREINIT:
        MMDB_s *mmdb;
        uint16_t status;

    CODE:

        if (file == NULL) {
            croak("MaxMind::DB::Reader::XS File missing\n");
        }
        mmdb = (MMDB_s *)malloc(sizeof(MMDB_s));
        status = MMDB_open(file, flags, mmdb);
     
        if (MMDB_SUCCESS != status) {
            free(mmdb);
            croak(
                "MaxMind::DB::Reader::XS Error opening database file (%s). Is this a valid MaxMind DB file?",
                file
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

void
_raw_metadata(self, mmdb)
        MMDB_s *mmdb
    PREINIT:
        SV *sv;
        MMDB_entry_data_list_s *entry_data_list;
    PPCODE:
        int status = MMDB_get_metadata_as_entry_data_list(mmdb, &entry_data_list);
        if (MMDB_SUCCESS != status) {
            croak("MaxMind::DB::Reader::XS Error getting metadata: %d", status);
        }

        sv = decode_and_free_entry_data_list(entry_data_list);

        XPUSHs(sv_2mortal(sv));

void
_lookup_address(self, mmdb, ip_address)
        MMDB_s *mmdb
        char *ip_address
    PREINIT:
        SV *sv;
        int gai_error, mmdb_error, entry_error;
        MMDB_lookup_result_s result;
        MMDB_entry_data_list_s *entry_data_list;
    PPCODE:
        result = MMDB_lookup_string(mmdb, ip_address, &gai_error, &mmdb_error);
        if (0 != gai_error) {
            croak("MaxMind::DB::Reader::XS InvalidArgumentException: the value \"%s\" is not a valid IP address.", ip_address);
        }
        if (MMDB_SUCCESS != mmdb_error) {
            croak("MaxMind::DB::Reader::XS Error looking up %s", ip_address);
        }

        if (result.found_entry) {
            entry_error = MMDB_get_entry_data_list(&result.entry, &entry_data_list);
            if (MMDB_SUCCESS != entry_error) {
                croak("MaxMind::DB::Reader::XS Get entry data error looking up %s", ip_address);
            }
            sv = decode_and_free_entry_data_list(entry_data_list);
        } else {
            sv = newSViv(0);
        }

        XPUSHs(sv_2mortal(sv));


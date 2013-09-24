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

static SV *decode_map(MMDB_entry_data_list_s *entry_data_list);
static SV *decode_array(MMDB_entry_data_list_s *entry_data_list);
static SV *decode_utf8_string(MMDB_entry_data_list_s *entry_data_list);

static int has_highbyte(const U8 *ptr, int size)
{
    while (--size >= 0) {
        if (*ptr++ > 127) {
            return 1;
        }
    }
    return 0;
}

static SV *decode_entry_data_list(MMDB_entry_data_list_s *entry_data_list)
{
        printf("type=%d\n",entry_data_list->entry_data.type);
    switch (entry_data_list->entry_data.type) {
        case MMDB_DATA_TYPE_MAP:
            return decode_map(entry_data_list);
        case MMDB_DATA_TYPE_ARRAY:
            return decode_array(entry_data_list);
        case MMDB_DATA_TYPE_UTF8_STRING:
            return decode_utf8_string(entry_data_list);
        case MMDB_DATA_TYPE_INT32:
            return newSViv(entry_data_list->entry_data.int32);
        case MMDB_DATA_TYPE_UINT16:
            return newSVuv(entry_data_list->entry_data.uint16);
        case MMDB_DATA_TYPE_UINT32:
            return newSVuv(entry_data_list->entry_data.uint32);
        case MMDB_DATA_TYPE_BOOLEAN:
            return newSVuv(entry_data_list->entry_data.boolean);
        case MMDB_DATA_TYPE_DOUBLE:
            return newSVnv(entry_data_list->entry_data.double_value);
        case MMDB_DATA_TYPE_FLOAT:
            return newSVnv(entry_data_list->entry_data.float_value);
        case MMDB_DATA_TYPE_UINT64:
            return newSVuv(entry_data_list->entry_data.uint64);
        default:
            return newSViv(666);
    }
}

static SV *decode_map(MMDB_entry_data_list_s *entry_data_list)
{
    HV *hv = newHV();
    int size = entry_data_list->entry_data.data_size;
    entry_data_list = entry_data_list->next;

    for (uint i = 0; i < size && entry_data_list; i++ ) {
        SV *val;
        char *key_source = (char *)entry_data_list->entry_data.utf8_string;
        int key_size     = entry_data_list->entry_data.data_size;
        char *key        = strndup(key_source, key_size);
        entry_data_list  = entry_data_list->next;

        if (0 == key_size) {
            continue;
        }

        val = decode_entry_data_list(entry_data_list);
        (void)hv_store(hv, key, key_size, val, 0);
    }

    return newRV_noinc((SV *) hv);;

}

static SV *decode_array(MMDB_entry_data_list_s *entry_data_list) {
    AV *av = newAV();
    int size = entry_data_list->entry_data.data_size;
    entry_data_list = entry_data_list->next;

    for (uint i = 0; i < size && entry_data_list; i++ ) {
        av_push(av, decode_entry_data_list(entry_data_list));
        entry_data_list = entry_data_list->next;
    }
    return newRV_noinc((SV *) av);
}


static SV *decode_utf8_string(MMDB_entry_data_list_s *entry_data_list)
{
    SV *sv;
    int size = entry_data_list->entry_data.data_size;
    char *data = size ? (char *)entry_data_list->entry_data.utf8_string : "";
    sv = newSVpvn(data, size);
    if (has_highbyte((U8 *)data, size)) {
        SvUTF8_on(sv);
    }
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

        sv = decode_entry_data_list(entry_data_list);

        XPUSHs(sv_2mortal(sv));


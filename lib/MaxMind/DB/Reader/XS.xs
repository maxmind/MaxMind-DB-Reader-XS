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

static SV *decode_entry_data_list(MMDB_entry_data_list_s *entry_data_list);
static SV *decode_map(MMDB_entry_data_list_s *entry_data_list);


static SV *decode_entry_data_list(MMDB_entry_data_list_s *entry_data_list)
{
    switch (entry_data_list->entry_data.type) {
        case MMDB_DATA_TYPE_MAP:
            return decode_map(entry_data_list);
        default:
            return newSViv(666);
    }
}

static SV *decode_map(MMDB_entry_data_list_s *entry_data_list)
{
    HV *hv          = newHV();
    int map_size    = entry_data_list->entry_data.data_size;
    entry_data_list = entry_data_list->next;

    uint i;
    for (i = 0; i < map_size && entry_data_list; i++ ) {
        char *key_source = (char *)entry_data_list->entry_data.utf8_string;
        int key_size     = entry_data_list->entry_data.data_size;
        char *key        = strndup(key_source, key_size);
        entry_data_list  = entry_data_list->next;

        if (0 == key_size) continue;

        SV *val = decode_entry_data_list(&entry_data_list);
        hv_store(hv, key, key_size, val, 0);
    }

    return newRV_noinc((SV *) hv);;

}

MODULE = MaxMind::DB::Reader::XS    PACKAGE = MaxMind::DB::Reader::XS

MMDB_s *
_open_mmdb(self, file, flags)
    char *file;
    U32 flags;
    PREINIT:
        MMDB_s *mmdb;

    CODE:

        if ( file == NULL ) {
            croak("MaxMind::DB::Reader::XS File missing\n");
        }
        mmdb = (MMDB_s *)malloc(sizeof(MMDB_s));
        uint16_t status = MMDB_open(file, flags, mmdb);
     
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
        int err;
    PPCODE:
        MMDB_entry_data_list_s *entry_data_list;
        int status = MMDB_get_metadata_as_entry_data_list(mmdb, &entry_data_list);
        if (MMDB_SUCCESS != status) {
            croak("MaxMind::DB::Reader::XS Error getting metadata: %d", status);
        }

        sv = decode_entry_data_list(entry_data_list);

        XPUSHs(sv_2mortal(sv));



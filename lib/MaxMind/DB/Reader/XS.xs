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

MODULE = MaxMind::DB::Reader::XS    PACKAGE = MaxMind::DB::Reader::XS

MMDB_s *
_open_mmdb(self, file, flags)
    char * file;
    U32 flags;
    PREINIT:
        MMDB_s * mmdb;

    CODE:

        if ( file == NULL ) {
            croak("MaxMind::DB::Reader::XS file missing\n");
        }
        mmdb = (MMDB_s *)malloc(sizeof(MMDB_s));
        uint16_t status = MMDB_open(file, flags, mmdb);
     
        if (MMDB_SUCCESS != status) {
            croak(
                "Error opening database file (%s). Is this a valid MaxMind DB file?",
                file
            );
        }

        RETVAL = mmdb;
    OUTPUT:
        RETVAL


void
_close_mmdb(self, mmdb)
        MMDB_s * mmdb;
    CODE:
        MMDB_close(mmdb);


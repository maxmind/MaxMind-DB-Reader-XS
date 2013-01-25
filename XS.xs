#ifdef __cplusplus
extern "C" {
#endif

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"
#include "MMDB.h"

#ifdef __cplusplus
}
#endif

MODULE = MaxMind::DB::Reader::XS		PACKAGE = MaxMind::DB::Reader::XS		

const char *
lib_version(CLASS)
        char * CLASS
    CODE:
        RETVAL = MMDB_lib_version();
    OUTPUT:
        RETVAL

MMDB_s *
open(CLASS,filename,flags = MMDB_MODE_STANDARD)
        char * CLASS
        char * filename
        int flags
    CODE:
        RETVAL = ( filename != NULL ) ? MMDB_open(filename,flags) : NULL;
    OUTPUT:
        RETVAL


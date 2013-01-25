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


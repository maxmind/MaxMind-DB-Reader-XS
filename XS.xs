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

static int has_highbyte(const U8 * ptr, int size)
{
    while (--size >= 0)
        if (*ptr++ > 127)
            return 1;
    return 0;
}

static SV *mksv(MMDB_decode_all_s ** current)
{

    SV *sv;
    fprintf(stderr, "type %d\n", (*current)->decode.data.type);

    switch ((*current)->decode.data.type) {
    case MMDB_DTYPE_MAP:
        {
            HV *hv = newHV();
            int size = (*current)->decode.data.data_size;
            for (*current = (*current)->next; size; size--) {
                assert(*current != NULL);
                SV *key = mksv(current);
                SV *val = mksv(current);
                hv_store_ent(hv, key, val, 0);
            }
            sv = newRV_inc((SV *) hv);
            return sv;
        }
        break;
    case MMDB_DTYPE_ARRAY:
        {
            AV *av = newAV();
            int size = (*current)->decode.data.data_size;
            for (*current = (*current)->next; size; size--) {
                assert(*current != NULL);
                av_push(av, mksv(current));
            }
            sv = newRV_inc((SV *) av);
            return sv;
        }
        break;
    case MMDB_DTYPE_UTF8_STRING:
        {
            int size = (*current)->decode.data.data_size;
            const U8 *ptr = (const U8 *)(*current)->decode.data.ptr;
            sv = newSVpvn((const char *)ptr, size);
            if (has_highbyte(ptr, size))
                SvUTF8_on(sv);
        }
        break;
    case MMDB_DTYPE_BYTES:
        sv = newSVpvn((const char *)(*current)->decode.data.ptr,
                      (*current)->decode.data.data_size);
        break;
    case MMDB_DTYPE_DOUBLE:
        sv = newSVnv((*current)->decode.data.double_value);
        break;
    case MMDB_DTYPE_UINT16:
    case MMDB_DTYPE_UINT32:
        sv = newSVuv((*current)->decode.data.uinteger);
        break;
    case MMDB_DTYPE_UINT64:
        //sv = newSVuv( (*current)->decode.data.uinteger);
        sv = newSVpvn((const char *)(*current)->decode.data.c8, 8);
        break;
    case MMDB_DTYPE_UINT128:
        sv = newSVuv((*current)->decode.data.uinteger);
        sv = newSVpvn((const char *)(*current)->decode.data.c16, 16);
        break;
    case MMDB_DTYPE_INT32:
        sv = newSViv((*current)->decode.data.sinteger);
        break;
    default:
        assert(0);
    }

    if (*current)
        *current = (*current)->next;

    return sv;
}

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


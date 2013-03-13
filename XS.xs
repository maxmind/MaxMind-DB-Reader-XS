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
    MMDB_DBG_CARP("type %d\n", (*current)->decode.data.type);

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
            sv = newRV_noinc((SV *) hv);
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
            sv = newRV_noinc((SV *) av);
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
        //sv = newSVuv((*current)->decode.data.uinteger);
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

MODULE = MaxMind::DB::Reader::XS                PACKAGE = MaxMind::DB::Reader::XS                

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
        U32 flags
    PREINIT:
        MMDB_s * mmdb = NULL;
    CODE:
        if ( filename == NULL )
            croak("MaxMind::DB::Reader::XS filename missing\n");
        RETVAL = mmdb = MMDB_open(filename, MMDB_MODE_MEMORY_CACHE);
        if ( mmdb == NULL )
            croak("Can't open database %s\n", filename );
    OUTPUT:
        RETVAL


void
DESTROY(mmdb)
        MMDB_s * mmdb
    CODE:
        MMDB_close(mmdb);


void
metadata(mmdb)
        MMDB_s * mmdb
    PREINIT:
        SV * sv;
        int err;
    PPCODE:
        MMDB_decode_all_s *decode_all = calloc(1, sizeof(MMDB_decode_all_s));
        err = MMDB_get_tree(&mmdb->meta, &decode_all);
        if ( err != MMDB_SUCCESS ) {
            croak( "MaxMind::DB::Reader::XS Err %d", err );
        }
        sv = mksv(&decode_all);
        XPUSHs(sv_2mortal(sv));

void
lookup_by_ip(mmdb, ipstr)
        MMDB_s * mmdb
        char * ipstr
    PREINIT:
        struct in_addr ip;
        struct in6_addr ip6;
        int err;
        uint32_t ipnum;
        I32 gV = GIMME_V;
        MMDB_root_entry_s root;// = {.entry.mmdb = mmdb };
//    MMDB_root_entry_s root = {.entry.mmdb = mmdb };
    PPCODE:
        root.entry.mmdb = mmdb;
        MMDB_DBG_CARP("XS:lookup_by_ip{mmdb} fd:%d depth:%d node_count:%d\n", mmdb->fd, mmdb->depth, mmdb->node_count);
	if ( mmdb->depth == 32 ) {
            if (ipstr == NULL || 1 != inet_pton(AF_INET, ipstr, &ip))
                croak( "MaxMind::DB::Reader::XS Invalid IPv4 Address" );
            ipnum = htonl(ip.s_addr);
            err = MMDB_lookup_by_ipnum( ipnum , &root );
	} else {
	    if (ipstr == NULL || 1 != inet_pton(AF_INET6, ipstr, &ip6))
                croak( "MaxMind::DB::Reader::XS Invalid IPv6 Address" );
            err = MMDB_lookup_by_ipnum_128( ip6, &root );
	}
        if ( err != MMDB_SUCCESS ) {
            croak( "MaxMind::DB::Reader::XS lookup Err %d", err );
        }
        MMDB_decode_all_s *decode_all = calloc(1, sizeof(MMDB_decode_all_s));
        err = MMDB_get_tree(&root.entry, &decode_all);
        if ( err != MMDB_SUCCESS ) {
            croak( "MaxMind::DB::Reader::XS Err %d", err );
        }
        SV * sv = mksv(&decode_all);
        XPUSHs(sv_2mortal(sv));


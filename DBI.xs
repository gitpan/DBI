/* $Id: DBI.xs,v 1.59 1996/10/10 15:55:12 timbo Exp $
 *
 * Copyright (c) 1994, 1995  Tim Bunce
 *
 * You may distribute under the terms of either the GNU General Public
 * License or the Artistic License, as specified in the Perl README file.
 */

#define IN_DBI_XS 1	/* see DBIXS.h */

#include "DBIXS.h"	/* DBI public interface for DBD's written in C	*/

static int xsbypass = 1;	/* enable XSUB->XSUB shortcut		*/

extern int perl_destruct_level;

#define DBI_MAGIC '~'

/* Retrieve imp_??h_t struct from handle magic.	*/
/* Cast increases required alignment of target type	*/
/* not a problem since we created the pointers anyway.	*/
#define DBIh_FROM_MG(mg) ((imp_xxh_t*)SvPVX((mg)->mg_obj))

static imp_xxh_t *dbih_getcom _((SV *h));
static void       dbih_clearcom _((imp_xxh_t *imp_xxh));
static SV	 *dbih_event _((SV *h, char *name, SV*, SV*));
static SV	 *dbi_last_h;
static int        dbih_set_attr _((SV *h, SV *keysv, SV *valuesv));
static SV        *dbih_get_attr _((SV *h, SV *keysv));
static AV        *dbih_get_fbav _((imp_sth_t *imp_sth));

int imp_maxsize;
int imp_minsize;

DBISTATE_DECLARE;

struct imp_drh_st { dbih_drc_t com; };
struct imp_dbh_st { dbih_dbc_t com; };
struct imp_sth_st { dbih_stc_t com; };


/* Internal Method Attributes (attached to dispatch methods when installed) */

typedef struct dbi_ima_st {
    short minargs;
    short maxargs;
    char *usage;
    U16   flags;
} dbi_ima_t;

#define IMA_HAS_USAGE		0x0001	/* check parameter usage	*/
#define IMA_FUNC_REDIRECT	0x0002	/* is $h->func(..., "method")	*/
#define IMA_KEEP_ERR		0x0004	/* don't reset err & errstr	*/

#define DBI_LAST_HANDLE		dbi_last_h /* special fake inner handle	*/
#define DBI_LAST_HANDLE_PARENT	(DBIc_PARENT_H(DBIh_COM(DBI_LAST_HANDLE)))
#define DBI_IS_LAST_HANDLE(h)	(SvRVx(DBI_LAST_HANDLE) == SvRV(h))
#define DBI_SET_LAST_HANDLE(h)	(SvRVx(DBI_LAST_HANDLE) =  SvRV(h))
#define DBI_UNSET_LAST_HANDLE	(SvRVx(DBI_LAST_HANDLE) =  &sv_undef)
#define DBI_LAST_HANDLE_OK	(SvRVx(DBI_LAST_HANDLE) != &sv_undef )


static void
dbi_bootinit()
{
    Newz(dummy, dbis, 1, dbistate_t);
    /* store version and size so we can spot DBI/DBD version mismatch	*/
    dbis->version = DBISTATE_VERSION;
    dbis->size    = sizeof(*dbis);
    dbis->xs_version = DBIXS_VERSION;
    /* publish address of dbistate so dynaloaded DBD's can find it	*/
    sv_setiv(perl_get_sv(DBISTATE_PERLNAME,1), (IV)dbis);

    DBISTATE_INIT; /* check DBD code to set dbis from DBISTATE_PERLNAME	*/

    dbis->logfp	= stderr;
    dbis->debug	= 0;
    dbis->debugpvlen = 200;
    /* store some function pointers so DBD's can call our functions	*/
    dbis->getcom   = dbih_getcom;
    dbis->clearcom = dbih_clearcom;
    dbis->event    = dbih_event;
    dbis->set_attr = dbih_set_attr;
    dbis->get_attr = dbih_get_attr;
    dbis->get_fbav = dbih_get_fbav;

    /* Remember the last handle used. BEWARE! Sneaky stuff here!	*/
    /* We want a handle reference but we don't want to increment	*/
    /* the handle's reference count and we don't want perl to try	*/
    /* to destroy it during global destruction. */
    dbi_last_h  = newRV(&sv_undef);
    SvROK_off(dbi_last_h);	/* so sv_clean_objs() won't destroy it	*/
    DBI_UNSET_LAST_HANDLE;	/* ensure setup the correct way		*/

    imp_maxsize = sizeof(imp_sth_t);
    if (sizeof(imp_dbh_t) > imp_maxsize)
	imp_maxsize = sizeof(imp_dbh_t);
    if (sizeof(imp_drh_t) > imp_maxsize)
	imp_maxsize = sizeof(imp_drh_t);

    /* trick to avoid 'possible typo' warnings	*/
    gv_fetchpv("DBI::state",  GV_ADDMULTI|0x4, SVt_PV);
    gv_fetchpv("DBI::err",    GV_ADDMULTI|0x4, SVt_PV);
    gv_fetchpv("DBI::errstr", GV_ADDMULTI|0x4, SVt_PV);
    gv_fetchpv("DBI::lasth",  GV_ADDMULTI|0x4, SVt_PV);
    gv_fetchpv("DBI::rows",   GV_ADDMULTI|0x4, SVt_PV);
}


/* ----------------------------------------------------------------- */
/* Utility functions                                                 */


static char *
neatsvpv(sv, maxlen) /* return a tidy ascii value, for debugging only */
    SV * sv;
    STRLEN maxlen;
{
    STRLEN len;
    SV *nsv = NULL;
    char *v;
    if (!sv)
	return "NULL";
    if (!SvOK(sv))
	return "undef";
    if (SvROK(sv) && SvAMAGIC(sv)) {	/* handle Overload magic refs */
	SvAMAGIC_off(sv);	/* should really be done via local scoping */
	v = SvPV(sv,len);
	SvAMAGIC_on(sv);
    }
    else	/* handles all else, including non AMAGIC refs	*/
	v = SvPV(sv,len);
    /* numbers and (un-amagic'd) refs get no special treatment */
    if (SvNIOK(sv) || SvROK(sv))
	return v;
    /* for strings we limit the length and translate codes */
    nsv = sv_2mortal(newSVpv("'",1));
    if (maxlen == 0)
	maxlen = dbis->debugpvlen;
    if (len > maxlen) {
	sv_catpvn(nsv, v, maxlen);
	sv_catpv( nsv, "...");
    }else{
	sv_catpvn(nsv, v, len);
	sv_catpv( nsv, "'");
    }
    v = SvPV(nsv, len);
    while(len-- > 0) { /* cleanup string (map control chars to ascii etc) */
	if (!isprint(v[len]) && !isspace(v[len]))
	    v[len] = '.';
    }
    return v;
}


static char *
mkvname(stash, item, uplevel)	/* construct a variable name	*/
    HV *stash;
    char *item;
    int uplevel;
{
    SV *sv = sv_newmortal();
    sv_setpv(sv, HvNAME(stash));
    if(uplevel) {
	while(SvCUR(sv) && *SvEND(sv)!=':')
	    --SvCUR(sv);
	if (SvCUR(sv))
	    --SvCUR(sv);
    }
    sv_catpv(sv, "::");
    sv_catpv(sv, item);
    return SvPV(sv, na);
}



static SV *
dbih_inner(orv, what)	/* convert outer to inner handle else croak */
    SV *orv;         	/* ref of outer hash */
    char *what;		/* error msg, NULL=no croak and return NULL */
{
    MAGIC *mg;
    SV *hrv;
    if (!SvROK(orv) || SvTYPE(SvRV(orv)) != SVt_PVHV) {
	if (!what)
	    return NULL;
	if (!SvOK(orv))
	    croak("%s given an undefined handle (perhaps returned from a previous call which failed)",
		    what);
	croak("%s handle '%s' is not a DBI handle", what, SvPV(orv,na));
    }
    if (!SvMAGICAL(SvRV(orv))) {
	sv_dump(orv);
	croak("%s handle '%s' is not a DBI handle (has no magic)",
		what, SvPV(orv,na));
    }

    if ( (mg=mg_find(SvRV(orv),'P')) == NULL) {	/* hash tie magic	*/
	/* maybe it's already an inner handle... */
	if (mg_find(SvRV(orv), DBI_MAGIC) == NULL) {
	    if (!what)
		return NULL;
	    croak("%s handle '%s' is not a valid DBI handle",
		    what, SvPV(orv,na));
	}
	hrv = orv; /* was already a DBI handle inner hash */
    }else{
	hrv = mg->mg_obj;  /* inner hash of tie */
    }

    /* extra checks if being paranoid */
    if (dbis->debug && (!SvROK(hrv) || SvTYPE(SvRV(hrv)) != SVt_PVHV)) {
	if (!what)
	    return NULL;
	croak("panic: %s inner handle '%s' is not a hash ref",
		what, SvPV(hrv,na));
    }
    return hrv;
}



/* --------------------------------------------------------------------	*/
/* Functions to manage a DBI handle (magic and attributes etc).     	*/

static imp_xxh_t *
dbih_getcom(hrv)	/* Get com struct for handle. Must be fast.	*/
    SV *hrv;
{
    MAGIC *mg;
    SV *sv;

    /* important and quick sanity check (esp non-'safe' Oraperl)	*/
    if (!SvROK(hrv)			/* must at least be a ref */
	&& hrv != DBI_LAST_HANDLE	/* special for var::FETCH */) {
	sv_dump(hrv);
	croak("Invalid DBI handle %s", SvPV(hrv,na));
    }

    sv = SvRV(hrv);

    /* Short cut for common case. We assume that a magic var always	*/
    /* has magic and that DBI_MAGIC, if present, will be the first.	*/
    if (SvRMAGICAL(sv) && (mg=SvMAGIC(sv))->mg_type == DBI_MAGIC) {
	/* ignore 'cast increases required alignment' warning	*/
	return DBIh_FROM_MG(mg);
    }

    /* Validate handle (convert outer to inner if required)	*/
    hrv = dbih_inner(hrv, "dbih_getcom");
    mg  = mg_find(SvRV(hrv), DBI_MAGIC);

    /* ignore 'cast increases required alignment' warning	*/
    return DBIh_FROM_MG(mg);
}


static SV *
dbih_setup_attrib(h, attrib, parent)
    SV *h;
    char *attrib;
    SV *parent;
{
    STRLEN len = strlen(attrib);
    SV *asv = *hv_fetch((HV*)SvRV(h), attrib, len, 1);
    SV *psv;
    if (SvOK(asv))	/* attribute already exists */
	return asv;
    if (!parent || !SvTRUE(parent))
	croak("dbih_setup_attrib(%s): '%s' not set and no parent supplied",
		SvPV(h,na), attrib);
    psv = *hv_fetch((HV*)SvRV(parent), attrib, len, 0);
    if (!SvOK(psv)) {	/* not defined in parent */
	croak("dbih_setup_attrib(%s): '%s' not set and not in parent",
		SvPV(h,na), attrib);
    }
    sv_setsv(asv, psv); /* copy attribute from parent to handle */
    return asv;
}


static void
dbih_setup_handle(orv, imp_class, parent, imp_datasv)
    SV *orv;         /* ref of outer hash */
    char *imp_class;
    SV *parent;
    SV *imp_datasv;
{
    SV *h;
    HV *imp_stash;
    char *errmsg = "Can't dbih_setup_handle of %s to %s: %s";
    SV *dbih_imp_sv;
    SV *dbih_imp_rv;
    char imp_mem_name[300];
    HV  *imp_mem_stash;
    char *imp_size_name;
    STRLEN imp_size;
    imp_xxh_t *imp;

    h      = dbih_inner(orv, "dbih_setup_handle");
    parent = dbih_inner(parent, NULL);	/* check parent valid (& inner)	*/

    if (dbis->debug >= 2)
	fprintf(DBILOGFP,"    dbih_setup_handle(%s=>%s, %s, %s)\n",
	    SvPV(orv,na), SvPV(h,na), imp_class, neatsvpv(imp_datasv,0));

    if (mg_find(SvRV(h), DBI_MAGIC) != NULL)
	croak(errmsg, SvPV(orv,na), imp_class, "already a DBI handle");

    if ( (imp_stash = gv_stashpv(imp_class, FALSE)) == NULL)
        croak(errmsg, SvPV(orv,na), imp_class, "unknown package");

    strcpy(imp_mem_name, imp_class);
    strcat(imp_mem_name, "_mem");
    if ( (imp_mem_stash = gv_stashpv(imp_mem_name, FALSE)) == NULL)
        croak(errmsg, SvPV(orv,na), imp_mem_name, "unknown _mem package");

    /* get size of structure to allocate for common and imp specific data   */
    imp_size_name = mkvname(imp_stash, "imp_data_size", 0);
    imp_size = SvIV(perl_get_sv(imp_size_name, 0x05));
    if (imp_size == 0)
	imp_size = imp_maxsize;
/* XXX
    if (imp_size < imp_minsize)
	croak(errmsg, SvPV(orv,na), imp_class, imp_size_name);
*/

    dbih_imp_sv = newSV(imp_size);
    dbih_imp_rv = newRV(dbih_imp_sv);	/* just needed for sv_bless */
    sv_bless(dbih_imp_rv, imp_mem_stash);
    sv_free(dbih_imp_rv);
    imp = (imp_xxh_t*)SvPVX(dbih_imp_sv);
    memzero((char*)imp, imp_size);

    DBIc_MY_H(imp)      = h;	/* take copy of pointer, not new ref	*/
    DBIc_IMP_STASH(imp) = imp_stash;

    if (imp_datasv)
	DBIc_IMP_DATA(imp) = newSVsv(imp_datasv);
    else /* use imp_datasv to carry the 'name'. Handy for debugging.	*/
	DBIc_IMP_DATA(imp) = newSVpv(SvPV(h,na),0);

    if (parent) {
	imp_xxh_t *parent_com = DBIh_COM(parent);
	DBIc_PARENT_H(imp)   = SvREFCNT_inc(parent); /* ensure it lives	*/
	DBIc_PARENT_COM(imp) = parent_com;	  /* shortcut for speed	*/
	DBIc_TYPE(imp)	     = DBIc_TYPE(parent_com) + 1;	/* XXX	*/
	DBIc_FLAGS(imp)      = DBIc_FLAGS(parent_com) & DBIcf_INHERITMASK;
	++DBIc_KIDS(parent_com);

    } else {			/* only a driver (drh) has no parent	*/
	DBIc_PARENT_H(imp)   = &sv_undef;
	DBIc_PARENT_COM(imp) = NULL;
	DBIc_TYPE(imp)	     = DBIt_DR;
	DBIc_FLAGS(imp)      = 0;
	DBIc_WARN_on(imp);	/* only set here, childern inherit	*/
    }

    /* copy some attributes from parent if not defined locally and	*/
    /* also take address of attributes for speed of direct access	*/
#define COPY_PARENT(name) SvREFCNT_inc(dbih_setup_attrib(h, (name), parent))
    /* XXX we should validate that these are the right type (refs etc)	*/
    DBIc_ATTR(imp, State)    = COPY_PARENT("State");	/* scalar ref	*/
    DBIc_ATTR(imp, Err)      = COPY_PARENT("Err");	/* scalar ref	*/
    DBIc_ATTR(imp, Errstr)   = COPY_PARENT("Errstr");	/* scalar ref	*/
    DBIc_ATTR(imp, Handlers) = COPY_PARENT("Handlers");	/* array ref	*/
    DBIc_ATTR(imp, Debug)    = COPY_PARENT("Debug");	/* scalar (int)	*/

    if (DBIc_TYPE(imp) == DBIt_ST) {
        imp_sth_t *imp_sth = (imp_sth_t*)imp;
	DBIc_NUM_FIELDS(imp_sth) = -1;	/* num of fields not known yet	*/
    	DBIc_FIELDS_AV(imp_sth)  = Nullav;
    }

    DBIc_COMSET_on(imp);	/* common data now set up		*/

    /* The implementor should DBIc_IMPSET_on(imp) when setting up	*/
    /* any private data which will need clearing/freeing later.		*/

    /* Use DBI magic on inner handle to carry handle attributes 	*/
    sv_magic(SvRV(h), dbih_imp_sv, DBI_MAGIC, Nullch, 0);
    SvREFCNT_dec(dbih_imp_sv);	/* since sv_magic() incremented it	*/
    SvRMAGICAL_on(SvRV(h));	/* so magic gets sv_clear'd ok		*/

    DBI_SET_LAST_HANDLE(h);
}


static void
dbih_dumpcom(imp_xxh, msg)
    imp_xxh_t *imp_xxh;
    char *msg;
{
    SV *flags = newSVpv("",0);
    if (!msg)
	msg = "dbih_dumpcom";
    warn("%s 0x%lx (com 0x%lx)\n", msg, (IV)imp_xxh->com.std.my_h, (IV)imp_xxh);
    if (DBIc_COMSET(imp_xxh))	sv_catpv(flags,"COMSET ");
    if (DBIc_IMPSET(imp_xxh))	sv_catpv(flags,"IMPSET ");
    if (DBIc_ACTIVE(imp_xxh))	sv_catpv(flags,"ACTIVE ");
    if (DBIc_WARN(imp_xxh))	sv_catpv(flags,"WARN ");
    if (DBIc_COMPAT(imp_xxh))	sv_catpv(flags,"COMPAT ");
    warn("    FLAGS 0x%x: %s\n",	DBIc_FLAGS(imp_xxh), SvPV(flags,na));
    warn("    TYPE %d\n",	DBIc_TYPE(imp_xxh));
    warn("    PARENT %s\n",	neatsvpv(DBIc_PARENT_H(imp_xxh),0));
    warn("    KIDS %ld (%ld active)\n",
		    (long)DBIc_KIDS(imp_xxh), (long)DBIc_ACTIVE_KIDS(imp_xxh));
    warn("    IMP_DATA %s\n",	neatsvpv(DBIc_IMP_DATA(imp_xxh),0));

	if (DBIc_TYPE(imp_xxh) == DBIt_ST) {
		imp_sth_t *imp_sth = (imp_sth_t*)imp_xxh;
		warn("    NUM_OF_FIELDS %d\n", DBIc_NUM_FIELDS(imp_sth));
		warn("    NUM_OF_PARAMS %d\n", DBIc_NUM_PARAMS(imp_sth));
	}
}


static void
dbih_clearcom(imp_xxh)
    imp_xxh_t *imp_xxh;
{
    int dump = FALSE;

    /* Note that we're very much on our own here. imp_xxh->my_h almost	*/
    /* certainly points to memory which has been freed. Don't use it!	*/

    if (DBIS->debug >= 3)
	dbih_dumpcom(imp_xxh,"dbih_clearcom");

    /* --- pre-clearing sanity checks --- */

    if (!DBIc_COMSET(imp_xxh)) {	/* should never happen	*/
	warn("DBI Handle already cleared");
	return;
    }

    if (!dirty) {
	if (DBIc_ACTIVE(imp_xxh)) {	/* bad news		*/
	    warn("DBI Handle cleared whilst still active!");
	    DBIc_ACTIVE_off(imp_xxh);
	    dump = TRUE;
	}

	/* check that the implementor has done its own housekeeping	*/
	if (DBIc_IMPSET(imp_xxh)) {
	    warn("DBI Handle has uncleared implementors data");
	    dump = TRUE;
	}

	if (DBIc_KIDS(imp_xxh)) {
	    warn("DBI Handle has %d uncleared child handles",
		    (int)DBIc_KIDS(imp_xxh));
	    dump = TRUE;
	}
    }

    if (dump && DBIS->debug < 3 /* else was already dumped above */)
	dbih_dumpcom(imp_xxh);

    /* --- pre-clearing adjustments --- */

    if (DBIc_PARENT_COM(imp_xxh) && !dirty) {
	--DBIc_KIDS(DBIc_PARENT_COM(imp_xxh));
    }

    /* --- clear fields (may invoke object destructors) ---	*/

    if (DBIc_TYPE(imp_xxh) == DBIt_ST) {
	dbih_stc_t *stc = (dbih_stc_t*)imp_xxh;
	if (stc->fields_av)
	    sv_free((SV*)stc->fields_av);
    }

    sv_free(DBIc_IMP_DATA(imp_xxh));	/* do this first	*/
    sv_free(DBIc_ATTR(imp_xxh, Handlers));
    sv_free(DBIc_ATTR(imp_xxh, Debug));
    sv_free(DBIc_ATTR(imp_xxh, State));
    sv_free(DBIc_ATTR(imp_xxh, Err));
    sv_free(DBIc_ATTR(imp_xxh, Errstr));
    sv_free(DBIc_PARENT_H(imp_xxh));	/* do this last		*/

    DBIc_COMSET_off(imp_xxh);

    if (dbis->debug >= 2)
	fprintf(DBILOGFP,"    dbih_clearcom 0x%lx done\n", (long)imp_xxh);
}


/* --- Functions for handling field buffer arrays ---		*/

static AV *
dbih_setup_fbav(stc)
    dbih_stc_t *stc;
{
    AV *av;

    if ( (av = stc->fields_av) == Nullav) {
        int i = stc->num_fields;
	if (i < 0)
	    croak("dbih_get_fbav: number of fields not set");
	av = newAV();
	/* load array with writeable SV's. Do this backwards so	*/
	/* the array only gets extended once.			*/
        while(i--)		/* field 1 stored at index 0	*/
	    av_store(av, i, newSV(0));
	stc->fields_av = av;
	if (dbis->debug >= 3)
	    fprintf(DBILOGFP,"    dbih_get_fbav %d/%d => %lx\n",
			stc->num_fields, AvFILL(av)+1, (long)av);
    }
    return av;
}

static AV *
dbih_get_fbav(imp_sth)	/* Called once per-fetch: must be fast	*/
    imp_sth_t *imp_sth;
{
    dbih_stc_t *stc = (dbih_stc_t*)imp_sth;
    AV *av;

    if (DBIc_TYPE(imp_sth) != DBIt_ST)
	croak("dbih_get_fbav: bad handle type: %d", DBIc_TYPE(imp_sth));

    if ( (av = stc->fields_av) == Nullav)
	av = dbih_setup_fbav(stc);

    /* XXX fancy stuff to happen here later (re ref counting)	*/
    return av;
}


static int
dbih_sth_bind_col(sth, col, ref, attribs)
    SV *sth;
    SV *col;
    SV *ref;
    SV *attribs;
{
    D_imp_sth(sth);
    dbih_stc_t *stc = (dbih_stc_t*)imp_sth;
    AV *av;
    int idx;

    attribs = attribs;	/* avoid 'unused variable' warning	*/

    if (!SvROK(ref))
	croak("Not a reference for bind_col(%s, %s, %s,...)",
		neatsvpv(sth,0), neatsvpv(col,0), neatsvpv(ref,0));

    if ( (av = stc->fields_av) == Nullav)
	av = dbih_setup_fbav(stc);

    idx = SvIV(col);
    if (idx < 1 || idx > DBIc_NUM_FIELDS(imp_sth))
	croak("bind_col: column %s is not a valid column", SvPV(col,na));

    if (dbis->debug >= 2)
	fprintf(DBILOGFP,"    dbih_sth_bind_col %s(%d) => %s\n",
		neatsvpv(col,0), idx, neatsvpv(ref,0));

    /* use supplied scalar as storage for this column */
    av_store(av, idx-1, SvREFCNT_inc(SvRV(ref)) );
    return 1;
}


/* --- Generic Handle Attributes (for all handle types) ---	*/

static int
dbih_set_attr(h, keysv, valuesv)	/* XXX split into dr/db/st funcs */
    SV *h;
    SV *keysv;
    SV *valuesv;
{
    D_imp_xxh(h);
    STRLEN keylen;
    char  *key = SvPV(keysv, keylen);
    int    htype = DBIc_TYPE(imp_xxh);
    int    on = (SvTRUE(valuesv));
    int    cacheit = 0;

    if (dbis->debug >= 2)
	fprintf(DBILOGFP,"    STORE %s %s => %s\n",
		SvPV(h,na), neatsvpv(keysv,0), neatsvpv(valuesv,0));

    if (strEQ(key, "CompatMode")) {
	(on) ? DBIc_COMPAT_on(imp_xxh) : DBIc_COMPAT_off(imp_xxh);
    }
    else if (strEQ(key, "Warn")) {
	(on) ? DBIc_WARN_on(imp_xxh) : DBIc_WARN_off(imp_xxh);
    }
    else if (htype==DBIt_ST && strEQ(key, "NUM_OF_FIELDS")) {
	D_imp_sth(h);
	if (DBIc_NUM_FIELDS(imp_sth) >= 0)	/* don't change NUM_FIELDS! */
	    croak("NUM_OF_FIELDS already set (%d)", DBIc_NUM_FIELDS(imp_sth));
	DBIc_NUM_FIELDS(imp_sth) = SvIV(valuesv);
	cacheit = 1;
    }
    else if (htype==DBIt_ST && strEQ(key, "NUM_OF_PARAMS")) {
	D_imp_sth(h);
	DBIc_NUM_PARAMS(imp_sth) = SvIV(valuesv);
	cacheit = 1;
    }
    else {	/* XXX should really be an event	*/
	croak("Can't set %s->{%s}: unrecognised attribute",
		SvPV(h,na), SvPV(keysv,na));
    }
    if (cacheit) {
	SV **svp = hv_fetch((HV*)SvRV(h), key, keylen, 1);
	sv_free(*svp);
	*svp = valuesv;
	(void)SvREFCNT_inc(valuesv);	/* keep it around for cache	*/
    }
    return TRUE;
}

static SV *
dbih_get_attr(h, keysv)			/* XXX split into dr/db/st funcs */
    SV *h;
    SV *keysv;
{
    D_imp_xxh(h);
    STRLEN keylen;
    char  *key = SvPV(keysv, keylen);
    int    htype = DBIc_TYPE(imp_xxh);
    int    cacheit = TRUE;
    SV    *valuesv = &sv_undef;
    /* DBI quick_FETCH will service some requests	*/

    if (dbis->debug >= 2)
	fprintf(DBILOGFP,"    FETCH %s %s\n", SvPV(h,na), neatsvpv(keysv,0));

    if (htype==DBIt_ST && strEQ(key, "NUM_OF_FIELDS")) {
	D_imp_sth(h);
	valuesv = newSViv(DBIc_NUM_FIELDS(imp_sth));
    }
    else if (htype==DBIt_ST && strEQ(key, "NUM_OF_PARAMS")) {
	D_imp_sth(h);
	valuesv = newSViv(DBIc_NUM_PARAMS(imp_sth));
    }
    else {
	croak("Can't get %s->{%s}: unrecognised attribute",
	    SvPV(h,na), SvPV(keysv,na));	/* XXX should be event?	*/
    }
    if (cacheit) {
	SV **svp = hv_fetch((HV*)SvRV(h), key, keylen, 1);
	sv_free(*svp);
	*svp = valuesv;
	(void)SvREFCNT_inc(valuesv);	/* keep it around for cache	*/
    }
    return sv_2mortal(valuesv);
}


/* --------------------------------------------------------------------	*/
/* Functions implementing Error and Event Handling.                   	*/


static SV *
dbih_event(hrv, evtype, a1, a2)
    SV *hrv;    /* ref to inner hash */
    char *evtype;
    SV *a1, *a2;
{
    dSP;
    D_imp_xxh(hrv);
    /* We arrive here via DBIh_EVENT* macros (see DBIXS.h) called from	*/
    /* DBD driver C code OR $h->event() method (in DBD::_::common)	*/
    /* If an array of handlers is defined then call them in reverse	*/
    /* order until one returns true */

    AV *handlers_av = (AV*)DBIc_HANDLERS(imp_xxh);
    SV *status = &sv_undef;
    SV *evtype_sv;
    int i;

    if (dbis->debug)
	fprintf(DBILOGFP,"    %s EVENT %s %s (Handlers: %s)\n",
	    evtype, neatsvpv(a1,0), neatsvpv(a2,0), neatsvpv(handlers_av,0));

    if (SvTYPE(handlers_av) != SVt_PVAV) {	/* must be \@ or undef	*/
	if (SvOK(handlers_av))
	    warn("%s->{Handlers} (%s) is not an array reference or undef",
		neatsvpv(DBIc_MY_H(imp_xxh),0), neatsvpv(handlers_av,0));
	return &sv_undef;
    }

    evtype_sv = sv_2mortal(newSVpv(evtype,0));
    i = av_len(handlers_av) + 1;
    while(--i >= 0) {	/* Call each handler in turn	*/
	SV *sv = *av_fetch(handlers_av, i, 1);
	/* call handler */
	PUSHMARK(sp);
	EXTEND(sp, 4);
	PUSHs(hrv);
	PUSHs(evtype_sv);
	if (SvOK(a2) || SvOK(a1)) { PUSHs(a1); }
	if (SvOK(a2))             { PUSHs(a2); }
	PUTBACK;
	perl_call_sv(sv, G_SCALAR);	/* NOTE: May longjmp (die)	*/
	SPAGAIN;
	status = POPs;
	PUTBACK;
	if (dbis->debug >= 2)
	    fprintf(DBILOGFP, "    %s handler%d %s returned %s\n",
		    neatsvpv(DBIc_MY_H(imp_xxh),0), i,
		    neatsvpv(sv,0), neatsvpv(status,0));
	if (SvTRUE(status))	/* event was handled so		*/
	    break;		/* don't call any more handlers	*/
    }

    return status;	/* true if event was 'handled' (not defined)	*/
}


/* ----------------------------------------------------------------- */
/* Functions implementing DBI dispatcher shortcuts.                  */

/* This function implements the DBI FETCH shortcut mechanism.
Any handle attribute FETCH will come to this function (see dispatch).
This function returns either an SV for the fetched value or NULL.
If NULL is returned the dispatcher will call the full FETCH method.
 - If key =~ /^_/ then return NULL (so driver can hide private attribs)
 - If the key does not exist return NULL (may be a virtual attribute).
 - If value is not a ref then return value (the main shortcut).
 - If it's a CODE ref then run CODE and return it's result value!
     (actually it sets a flag so dispatch will run code for us).
 - If it's a ref to a CODE ref then return the CODE ref
     (an escape mechanism to allow real code refs to be stored).
 - Else return NULL (it's some other form of ref, let driver do it).
*/

static SV * 
quick_FETCH(hrv, keysv, imp_msv)
    SV *hrv;	/* ref to inner hash */
    SV *keysv;
    SV **imp_msv;	/* Code GV or CV */
{
    void *tmp;
    SV *sv;
    STRLEN lp;
    char *key = SvPV(keysv,lp);
    int type;
    if (*key == '_')
	return NULL;	/* never quick_FETCH a 'private' attribute */
    if ( (tmp = hv_fetch((HV*)SvRV(hrv), key, lp, 0)) == NULL)
	return NULL;	/* does not exist */
    sv = *(SV**)tmp;
    if (!SvROK(sv))	/* return value of all non-refs directly	*/
	return sv;	/* this is the main shortcut	*/
    if ( (type=SvTYPE(SvRV(sv))) == SVt_RV
	&& SvTYPE(SvRV(SvRV(sv))) == SVt_PVCV)
	return SvRV(sv); /* return deref if ref to CODE ref */
    if (type != SVt_PVCV)
	return sv;	 /* return non-code refs */
    *imp_msv = (SV*)SvRV(sv); /* tell dispatch() to execute this code instead */
    return NULL;
}


/* ----------------------------------------------------------------- */
/* ---   The DBI dispatcher. The heart of the perl DBI.          --- */

XS(XS_DBI_dispatch)         /* prototype must match XS produced code */
{
    dXSARGS;

    SV *h = ST(0);          /* the DBI handle we are working with	*/
    SV *orig_h = h;
    MAGIC *mg;
    int gimme = GIMME;
    int debug = dbis->debug;	/* local, may change during dispatch	*/
    int is_destroy = FALSE;
    int i, outitems;

    char	*meth_name = GvNAME(CvGV(cv));
    dbi_ima_t	*ima       = (dbi_ima_t*)CvXSUBANY(cv).any_ptr;
    imp_xxh_t	*imp_xxh   = NULL;
    SV		*imp_msv   = NULL; /* handle implementors method (GV or CV) */
    SV		*qsv       = NULL; /* quick result from a shortcut method   */


    if (debug >= 2) {
        fprintf(DBILOGFP,"    >> %-11s DISPATCH (%s @%ld g%x a%lx r%d)\n",
			    meth_name, neatsvpv(h,0), items,
			    (int)gimme, (long)ima, (int)runlevel);
    }

    if (!SvROK(h) || SvTYPE(SvRV(h)) != SVt_PVHV) {
        croak("%s: handle %s is not a hash reference",meth_name,SvPV(h,na));
	/* This will also catch: CLASS->method(); we might want to do */
	/* something better in that case. */
    }

    if (ima) {	/* Check method call against Internal Method Attributes */

	if (ima->flags & IMA_FUNC_REDIRECT) {
	    SV *meth_name_sv = POPs;
	    PUTBACK;
	    --items;
	    if (!SvPOK(meth_name_sv) || SvNIOK(meth_name_sv))
		croak("%s->%s() invalid redirect method name '%s'",
			SvPV(h,na), meth_name, SvPV(meth_name_sv, na));
	    meth_name = SvPV(meth_name_sv, na);
	}

	if (ima->flags & IMA_HAS_USAGE) {
	    char *err = NULL;
	    char msg[200];

	    if (ima->minargs && (items < ima->minargs
				|| (ima->maxargs>0 && items > ima->maxargs))) {
		/* the error reporting is a little tacky here */
		sprintf(msg,
		    "DBI %s: invalid number of parameters: handle + %ld\n",
		    meth_name, items-1);
		err = msg;
	    }
	    /* arg type checking could be added here later */
	    if (err) {
		croak("%sUsage: %s->%s(%s)", err, "$h", meth_name,
		    (ima->usage) ? ima->usage : "...?");
	    }
	}
    }

    if (*meth_name=='D' && strEQ(meth_name,"DESTROY"))
	is_destroy = TRUE;

    /* If h is a tied hash ref, switch to the inner ref 'behind' the tie.
       This means *all* DBI methods work with the inner (non-tied) ref.
       This makes it much easier for methods to access the real hash
       data (without having to go through FETCH and STORE methods) and
       for tie and non-tie methods to call each other.
    */
    if (SvRMAGICAL(SvRV(h)) && (mg=mg_find(SvRV(h),'P'))!=NULL) {

        if (SvPVX(mg->mg_obj)==NULL) {  /* maybe global destruction */
            if (debug >= 2)
                fprintf(DBILOGFP,"       (inner handle already deleted)\n");
	    XSRETURN(0);
        }
        /* Distinguish DESTROY of tie (outer) from DESTROY of inner ref	*/
	/* This may one day be used to manually destroy extra internal	*/
	/* refs if the application ceases to use the handle.		*/
        if (is_destroy) {
	    if (debug >= 2)
                fprintf(DBILOGFP,"       (outer handle DESTROY ignored)\n");
	    /* for now we ignore it since it'll be followed at once by	*/
	    /* a destroy of the inner hash and that'll do the real work	*/
	    XSRETURN(0);
	}
        h = mg->mg_obj; /* switch h to inner ref			*/
        ST(0) = h;      /* switch handle on stack to inner ref		*/
    }

    /* record this inner handle for use by DBI::var::FETCH	*/
    if (is_destroy) {	/* we use devious means here...	*/
	if (DBI_IS_LAST_HANDLE(h)) {	/* if destroying _this_ handle */
	    SV *lhp = DBI_LAST_HANDLE_PARENT;
	    (SvROK(lhp)) ? DBI_SET_LAST_HANDLE(lhp) : DBI_UNSET_LAST_HANDLE;
	}
	/* otherwise don't alter it */
    }
    else DBI_SET_LAST_HANDLE(h);

    imp_xxh = DBIh_COM(h); /* get common Internal Handle Attributes	*/

    if (!ima || !(ima->flags & IMA_KEEP_ERR)) {
	DBIh_CLEAR_ERROR(imp_xxh);
    }

    if ( (i = DBIc_DEBUGIV(imp_xxh)) > debug)
	debug = i;	    /* bump up debugging if handle wants it	*/

    /* Now check if we can provide a shortcut implementation here. */
    /* At the moment we only offer a quick fetch mechanism.        */
    if (*meth_name=='F' && strEQ(meth_name,"FETCH")) {
	qsv = quick_FETCH(h, ST(1), &imp_msv);
    }

    if (qsv) { /* skip real method call if we already have a 'quick' value */

	ST(0) = sv_mortalcopy(qsv);
	outitems = 1;

    }else{
	if (!imp_msv) {
	    imp_msv = (SV*)gv_fetchmethod(DBIc_IMP_STASH(imp_xxh), meth_name);
	    if (!imp_msv)
		croak("Can't locate DBI object method \"%s\" via package \"%s\"",
		    meth_name, HvNAME(DBIc_IMP_STASH(imp_xxh)));
	}

	DBIc_LAST_METHOD(imp_xxh) = meth_name;

	if (debug >= 2) {
	    /* Full pkg method name (or just meth_name for ANON CODE)	*/
	    char *imp_meth_name = (isGV(imp_msv)) ? GvNAME(imp_msv) : meth_name;
	    HV *imp_stash = DBIc_IMP_STASH(imp_xxh);
	    fprintf(DBILOGFP, "    -> %s ", imp_meth_name);
	    if (isGV(imp_msv) && GvSTASH(imp_msv) != imp_stash)
		fprintf(DBILOGFP, "in %s ", HvNAME(GvSTASH(imp_msv)));
	    fprintf(DBILOGFP, "for %s (%s", HvNAME(imp_stash),
			SvPV(orig_h,na));
	    if (h != orig_h)	/* show inner handle to aid tracing */
		fprintf(DBILOGFP, "~0x%lx", (long)SvRV(h));
	    for(i=1; i<items; ++i)
		fprintf(DBILOGFP," %s", neatsvpv(ST(i),0));
	    fprintf(DBILOGFP, ")\n");
	}

	PUSHMARK(mark);  /* mark arguments again so we can pass them on	*/

	/* Note: the handle on the stack is still an object blessed into a
	 * DBI::* class and *not* the DBD::*::* class whose method is being
	 * invoked. This *is* correct and should be largely transparent.
	 */

	/* SHORT-CUT ALERT! */
	if (xsbypass && isGV(imp_msv) && CvXSUB(GvCV(imp_msv))) {

	    /* If we are calling an XSUB we jump directly to its C code and
	     * bypass perl_call_sv(), pp_entersub() etc. This is fast.
	     * This code is copied from a small section of pp_entersub().
	     */
	    I32 markix = TOPMARK;
	    CV *xscv   = GvCV(imp_msv);
	    (void)(*CvXSUB(xscv))(xscv);	/* Call the C code directly */

	    if (gimme == G_SCALAR) {    /* Enforce sanity in scalar context */
		if (++markix != stack_sp - stack_base ) {
		    if (markix > stack_sp - stack_base)
			 *(stack_base + markix) = &sv_undef;
		    else *(stack_base + markix) = *stack_sp;
		    stack_sp = stack_base + markix;
		}
		outitems = 1;
	    } else {
		outitems = stack_sp - (stack_base + markix);
	    }

	} else {
	    outitems = perl_call_sv(imp_msv, gimme);
	}

	if (debug >= 2) { /* XXX restore local vars so ST(n) works below	*/
	    SPAGAIN; sp -= outitems; ax = (sp - stack_base) + 1; 
	}

	/* We might perform some fancy error handling here one day	*/
    }

    if (debug >= 2) {
	FILE *logfp = DBILOGFP;
	fprintf(logfp,"    <- %s=", meth_name);
	if (gimme & G_ARRAY)
	    fprintf(logfp," (");
	for(i=0; i < outitems; ++i)
	    fprintf(logfp, " %s",  neatsvpv(ST(i),0));
	if (gimme & G_ARRAY)
	    fprintf(logfp," ) [%d items]", outitems);
	if (qsv)
	    fprintf(logfp," QUICK");
	fprintf(logfp,"\n");
    }

    XSRETURN(outitems);
}



/* --------------------------------------------------------------------	*/
/* The DBI Perl interface (via XS) starts here. Currently these are 	*/
/* all internal support functions. Note install_method and see DBI.pm	*/

MODULE = DBI   PACKAGE = DBI

REQUIRE:    1.929
PROTOTYPES: DISABLE


BOOT:
    items = items;	/* avoid 'unused variable' warning		*/
    dbi_bootinit();

void
_setup_handle(sv, imp_class, parent, imp_datasv=Nullsv)
    SV *	sv
    char *	imp_class
    SV *	parent
    SV *	imp_datasv
    CODE:
    dbih_setup_handle(sv, imp_class, parent, imp_datasv);
    ST(0) = &sv_undef;

void
_get_imp_data(sv)
    SV *	sv
    CODE:
    D_imp_xxh(sv);
    ST(0) = sv_mortalcopy(DBIc_IMP_DATA(imp_xxh)); /* okay if NULL	*/

void
set_err(sv, errval, errstr=&sv_no, state=&sv_undef)
    SV *	sv
    SV *	errval
    SV *	errstr
    SV *	state
    CODE:
    {
    D_imp_xxh(sv);
    sv_setsv(DBIc_ERR(imp_xxh),    errval);
    sv_setsv(DBIc_ERRSTR(imp_xxh), errstr);
    if (SvOK(state)) {
	STRLEN len;
	if (SvPV(state, len) && len != 5)
	    croak("set_err: state must be 5 character string");
	sv_setsv(DBIc_STATE(imp_xxh), state);
    }
    else {
	(void)SvOK_off(DBIc_STATE(imp_xxh));
    }
    sv = dbih_inner(sv,"set_err");
    DBI_SET_LAST_HANDLE(sv);
    ST(0) = &sv_undef;
    }


void
neat(sv, maxlen=0)
    SV *	sv
    int	maxlen
    CODE:
    ST(0) = sv_2mortal(newSVpv(neatsvpv(sv, maxlen), 0));


void
_install_method(class, meth_name, file, attribs=Nullsv)
    char *	class
    char *	meth_name
    char *	file
    SV *	attribs
    CODE:
    {
    /* install another method name/interface for the DBI dispatcher	*/
    int debug = (dbis->debug >= 3);
    CV *cv;
    SV **svp;
    dbi_ima_t *ima = NULL;
    class = class;		/* avoid 'unused variable' warning	*/

    if (debug)
	fprintf(DBILOGFP,"install_method %s\t", meth_name);

    if (strnNE(meth_name, "DBI::", 5))	/* XXX m/^DBI::\w+::\w+$/	*/
	croak("install_method: invalid name '%s'", meth_name);

    if (attribs && SvROK(attribs)) {
	/* convert and store method attributes in a fast access form	*/
	svtype atype = SvTYPE(SvRV(attribs));
	/* ima = (dbi_ima_t*)safemalloc(sizeof(*ima)); */
	Newz(0, ima, 1, dbi_ima_t);

	if (atype != SVt_PVHV)
	    croak("install_method %s: bad attribs", meth_name);

	DBD_ATTRIB_GET_IV(attribs, "O",1, svp, ima->flags);

	if ( (svp=DBD_ATTRIB_GET_SVP(attribs, "U",1)) != NULL) {
	    AV *av = (AV*)SvRV(*svp);
	    ima->minargs=         SvIV(*av_fetch(av, 0, 1));
	    ima->maxargs=         SvIV(*av_fetch(av, 1, 1));
				  svp = av_fetch(av, 2, 0);
	    ima->usage  = savepv( (svp) ? SvPV(*svp,na) : "");
	    ima->flags |= IMA_HAS_USAGE;
	    if (dbis->debug >= 3)
		fprintf(DBILOGFP,"    usage: min %d, max %d, '%s'",
			ima->minargs, ima->maxargs, ima->usage);
	}
	if (debug)
	    fprintf(DBILOGFP,", flags 0x%x", ima->flags);

    } else if (attribs && SvOK(attribs)) {
	croak("install_method %s: attributes not a ref", meth_name);
    }
    cv = newXS(meth_name, XS_DBI_dispatch, file);
    CvXSUBANY(cv).any_ptr = ima;
    if (debug)
	fprintf(DBILOGFP,"\n");
    ST(0) = &sv_yes;
    }

int
_debug_dispatch(sv, level=dbis->debug, file=Nullch)
    SV *	sv
    int	level
    char *	file
    CODE:
    sv = sv;	/* avoid 'unused variable' warning'			*/
    /* Return old/current value. No change if new value not given.	*/
    if (file) {	/* should really be (and may become) a separate function */
	FILE *fp = fopen(file, "a+");
	if (fp == Nullfp)
	    fprintf(DBILOGFP,"Can't open %s: %s", file, Strerror(errno));
	else {
	    if (DBILOGFP != stderr)
		fclose(DBILOGFP);
	    setbuf(fp, NULL);	/* force upbuffered output */
	    DBILOGFP = fp;
	}
    }
    RETVAL = dbis->debug;
    if (level != dbis->debug && level >= 0) {
	fprintf(DBILOGFP,"    DBI dispatch debug level set to %d\n", level);
	dbis->debug = level;
	sv_setiv(perl_get_sv("DBI::dbi_debug",0x5), level);
	if (level >= 2)
	    perl_destruct_level = 2;
    }
    OUTPUT:
    RETVAL


int
_debug_handle(sv, level=0)
    SV *	sv
    int	level
    CODE:
    {
    D_imp_xxh(sv);
    SV *dsv = DBIc_ATTR(imp_xxh, Debug);
    /* Return old/current value. No change if new value not given */
    RETVAL=SvIV(dsv);
    if (items == 2 && level != RETVAL) { /* set value */
	sv_setiv(dsv, level);
	fprintf(DBILOGFP,"    %s debug level set to %d\n", SvPV(sv,na), level);
    }
    }
    OUTPUT:
    RETVAL


void
dump_handle(sv, msg="DBI::dump_handle")
    SV *	sv
    char *	msg
    CODE:
    {
    D_imp_xxh(sv);
    dbih_dumpcom(imp_xxh, msg);
    }


void
_svdump(sv)
    SV *	sv
    CODE:
    fprintf(DBILOGFP, "DBI::_svdump(%s)", SvPV(sv,na));
#ifdef DEBUGGING
    sv_dump(sv);
#endif


MODULE = DBI   PACKAGE = DBI::var

void
FETCH(sv)
    SV *	sv
    CODE:
    /* XXX TIESCALAR CODE SEEMS TO BE BUST IN Perl5.000 */
    /* Note that we do not come through the dispatcher to get here.	*/
    char *meth = SvPV(SvRV(sv),na);	/* what should this tie do ?	*/
    char type = *meth++;		/* is this a $ or & style	*/
    HV *imp_stash;
    GV *imp_gv;
    int ok  = DBI_LAST_HANDLE_OK;
    imp_xxh_t *imp_xxh = (ok) ? DBIh_COM(DBI_LAST_HANDLE) : NULL;

    if (dbis->debug >= 2 || (ok && DBIc_DEBUGIV(imp_xxh) >= 2)) {
	fprintf(DBILOGFP,"    <> $DBI::%s (%c) FETCH from lasth=", meth, type);
	if (ok) {
	    SvROK_on(DBI_LAST_HANDLE);
	    fprintf(DBILOGFP,"%s\n", SvPV(DBI_LAST_HANDLE,na));
	    SvROK_off(DBI_LAST_HANDLE);
	} else {
	    fprintf(DBILOGFP,"none\n");
	}
    }

    if (type == '!') {	/* special case for $DBI::lasth */
	if (!ok) {
	    XSRETURN_UNDEF;
	}
	/* Currently we can only return the INNER handle.	*/
	/* This handle should only be used for true/false tests	*/
	SvROK_on(DBI_LAST_HANDLE);
	ST(0) = sv_mortalcopy(DBI_LAST_HANDLE);
	if (dbis->debug >= 2)
	    fprintf(DBILOGFP,"   $DBI::%s = %s (inner)\n",
				meth, SvPV(DBI_LAST_HANDLE,na));
	SvROK_off(DBI_LAST_HANDLE);
	XSRETURN(1);
    }
    if ( !ok ) {		/* warn() may be changed to a debug later */
	warn("Can't read $DBI::%s, lost last handle", meth);
	XSRETURN_UNDEF;
    }

    if (type == '*') {	/* special case for $DBI::err	*/
	SV *errsv = DBIc_ERR(imp_xxh);
	if (dbis->debug >= 2)
	    fprintf(DBILOGFP,"	err = '%s'\n", neatsvpv(errsv,0));
	ST(0) = sv_mortalcopy(errsv);
	XSRETURN(1);
    }
    if (type == '"') {	/* special case for $DBI::state	*/
	SV *errsv = DBIc_STATE(imp_xxh);
	if (!SvOK(errsv)) {	/* SQLSTATE not implemented by driver	*/
	    if (SvTRUE(DBIc_ERR(imp_xxh)))		/* use DBI::err	*/
		ST(0) = sv_2mortal(newSVpv("S1000",5));	/* General error */
	    else
		ST(0) = &sv_no;			/* Success ("00000")	*/
	} else {
	    /* map "00000" to false, all else is true			*/
	    if (strEQ(SvPV(errsv,na), "00000"))
		ST(0) = &sv_no;
	    else
		ST(0) = sv_mortalcopy(errsv);
	}
	if (dbis->debug >= 2)
	    fprintf(DBILOGFP,"	state = '%s'\n", neatsvpv(ST(0),0));
	XSRETURN(1);
    }
    if (type == '$') { /* lookup scalar variable in implementors stash */
	char *vname = mkvname(DBIc_IMP_STASH(imp_xxh), meth, 0);
	SV *vsv = perl_get_sv(vname, 1);
	if (dbis->debug >= 2)
	    fprintf(DBILOGFP,"%s = %s\n", vname, neatsvpv(vsv,0));
	ST(0) = sv_mortalcopy(vsv);
	XSRETURN(1);
    }
    /* default to method call via stash of implementor of DBI_LAST_HANDLE */
    imp_stash = DBIc_IMP_STASH(imp_xxh);
    if (dbis->debug >= 2)
	fprintf(DBILOGFP,"%s::%s\n", HvNAME(imp_stash), meth);
    ST(0) = DBI_LAST_HANDLE;
    if ((imp_gv = gv_fetchmethod(imp_stash,meth)) == NULL) {
	warn("Can't locate $DBI::%s object method \"%s\" via package \"%s\"",
	    meth, meth, HvNAME(imp_stash));
	XSRETURN_UNDEF;
    }
/* something here is not quite right ! (wrong number of args to method for example) */
    PUSHMARK(mark);  /* reset mark (implies one arg as we were called with one arg?) */
    perl_call_sv(imp_gv, GIMME);



MODULE = DBI   PACKAGE = DBD::_::st

void
bind_col(sth, col, ref, attribs=Nullsv)
    SV *	sth
    SV *	col
    SV *	ref
    SV *	attribs
    CODE:
    DBD_ATTRIBS_CHECK("bind_col", sth, attribs);
    ST(0) = dbih_sth_bind_col(sth, col, ref, attribs) ? &sv_yes : &sv_no;

void
bind_columns(sth, attribs, ...)
    SV *	sth
    SV *	attribs
    CODE:
    D_imp_sth(sth);
    SV *colsv;
    int i;
    if (items-2 != DBIc_NUM_FIELDS(imp_sth))
	croak("bind_columns called with %ld refs when %d needed.",
		items-2, DBIc_NUM_FIELDS(imp_sth));
    ST(0) = &sv_yes;
    DBD_ATTRIBS_CHECK("bind_columns", sth, attribs);
    colsv = sv_2mortal(newSViv(0));
    for(i=1; i < items-1; ++i) {
	sv_setiv(colsv, i);
	if (!dbih_sth_bind_col(sth, colsv, ST(i+1), attribs)) {
	    ST(0) = &sv_no;
	    break;
	}
    }


void
fetchrow(sth)
    SV *	sth
    PPCODE:
    SV *retsv;
    if (CvDEPTH(cv) == 99)
        croak("Deep recursion. Probably fetchrow-fetch-fetchrow loop.");
    PUSHMARK(sp);
    XPUSHs(sth);
    PUTBACK;
    if (perl_call_method("fetch", G_SCALAR) != 1)
	croak("panic: DBI fetch");	/* should never happen */
    SPAGAIN;
    retsv = POPs;
    PUTBACK;
    if (SvROK(retsv) && SvTYPE(SvRV(retsv)) == SVt_PVAV) {
	D_imp_sth(sth);
	int num_fields, i;
	AV *bound_av;
	AV *av = (AV*)SvRV(retsv);
	num_fields = AvFILL(av)+1;
	EXTEND(sp, num_fields+1);

	/* We now check for bind_col() having been called but fetch	*/
	/* not returning the fields_av array. Probably because the	*/
	/* driver is implemented in perl. This logic may change later.	*/
	bound_av = DBIc_FIELDS_AV(imp_sth); /* bind_col() called ?	*/
	if (bound_av && av != bound_av) {
	    /* let dbih_get_fbav know what's going on	*/
	    bound_av = dbih_get_fbav(imp_sth);
	    for(i=0; i < num_fields; ++i) {	/* copy over the row	*/
		sv_setsv(AvARRAY(bound_av)[num_fields], AvARRAY(av)[i]);
	    }
	}
	for(i=0; i < num_fields; ++i) {
	    PUSHs(AvARRAY(av)[i]);
	}
    }

void
fetch(sth)
    SV *	sth
    CODE:
    int num_fields;
    if (CvDEPTH(cv) == 99)
        croak("Deep recursion. Probably fetch-fetchrow-fetch loop.");
    PUSHMARK(sp);
    XPUSHs(sth);
    PUTBACK;
    num_fields = perl_call_method("fetchrow", G_ARRAY);
    if (num_fields == 0) {
	ST(0) = &sv_undef;
    } else {
	D_imp_sth(sth);
	AV *av = dbih_get_fbav(imp_sth);
	if (num_fields != AvFILL(av)+1)
	    croak("fetchrow returned %d fields, expected %d",
		    num_fields, AvFILL(av)+1);
	SPAGAIN;
	while(--num_fields >= 0)
	    sv_setsv(AvARRAY(av)[num_fields], POPs);
	PUTBACK;
	ST(0) = sv_2mortal(newRV((SV*)av));
    }



MODULE = DBI   PACKAGE = DBD::_::common


void
STORE(h, keysv, valuesv)
    SV *	h
    SV *	keysv
    SV *	valuesv
    CODE:
    /* Likely to be split into dr, db, st + common code for speed	*/
    ST(0) = &sv_yes;
    if (!dbih_set_attr(h, keysv, valuesv))
	    ST(0) = &sv_no;
 

void
FETCH(h, keysv)
    SV *	h
    SV *	keysv
    CODE:
    /* Likely to be split into dr, db, st + common code for speed	*/
    ST(0) = dbih_get_attr(h, keysv);


void
event(h, type, a1=&sv_undef, a2=&sv_undef)
    SV *	h
    char *	type
    SV *	a1
    SV *	a2
    CODE:
    ST(0) = sv_mortalcopy(DBIh_EVENT2(h, type, a1, a2));


void
private_data(h)
    SV *	h
    CODE:
    D_imp_xxh(h);
    ST(0) = sv_mortalcopy(DBIc_IMP_DATA(imp_xxh));


MODULE = DBI   PACKAGE = DBD::_mem::common

void
DESTROY(imp_xxh_rv)
    SV *	imp_xxh_rv
    CODE:
    /* ignore 'cast increases required alignment' warning	*/
    imp_xxh_t *imp_xxh = (imp_xxh_t*)SvPVX(SvRV(imp_xxh_rv));
    DBIS->clearcom(imp_xxh);

# end

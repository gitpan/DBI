/*
#  $Id: Driver_xst.h,v 1.1 2002/06/13 12:25:54 timbo Exp $
#  Copyright (c) 2002  Tim Bunce  Ireland
#
#  You may distribute under the terms of either the GNU General Public
#  License or the Artistic License, as specified in the Perl README file.
*/


static int
dbdxst_bind_params(SV *sth, imp_sth_t *imp_sth, I32 items, I32 ax)
{
    /* Handle binding supplied values to placeholders.		*/
    /* items = one greater than the number of params		*/
    /* ax = ax from calling sub, maybe adjusted to match items	*/
    int i;
    SV *idx;
    if (items-1 != DBIc_NUM_PARAMS(imp_sth)
	&& DBIc_NUM_PARAMS(imp_sth) != DBIc_NUM_PARAMS_AT_EXECUTE
    ) {
	char errmsg[99];
	sprintf(errmsg,"called with %ld bind variables when %d are needed",
		items-1, DBIc_NUM_PARAMS(imp_sth));
	sv_setpv(DBIc_ERRSTR(imp_sth), errmsg);
	sv_setiv(DBIc_ERR(imp_sth), (IV)-1);
	return 0;
    }
    idx = sv_2mortal(newSViv(0));
    for(i=1; i < items ; ++i) {
	SV* value = ST(i);
	if (SvGMAGICAL(value))
	    mg_get(value);	/* trigger magic to FETCH the value     */
	sv_setiv(idx, i);
	if (!dbd_bind_ph(sth, imp_sth, idx, value, 0, Nullsv, FALSE, 0)) {
	    return 0;	/* dbd_bind_ph already registered error	*/
	}
    }
    return 1;
}

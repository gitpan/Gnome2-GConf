/*
 * Copyright (c) 2003 by Emmanuele Bassi (see the file AUTHORS)
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public
 * License along with this library; if not, write to the 
 * Free Software Foundation, Inc., 59 Temple Place - Suite 330, 
 * Boston, MA  02111-1307  USA.
 */

#include "gconfperl.h"

/* Since GConfEntry and GConfValue are not registered types, we create a
 * hashref containing their data, in order to mask them from the Perl
 * developer. (eb)
 */

SV *
newSVGConfEntry (GConfEntry * e)
{
	HV * h;
	SV * r;
	const gchar * key;
	GConfValue * value;
	GConfValueType type;
	
	if (! e)
		return newSVsv(&PL_sv_undef);
	
	h = newHV ();
	r = newRV_noinc ((SV *) h);	/* safe */
	
	/* store the key inside the hashref. */
	key = gconf_entry_get_key (e);
	
	hv_store (h, "key", 3, newSVGChar (gconf_entry_get_key (e)), 0);
	
	/* this GConfValue is not a copy, and it should not be modified nor
	 * freed, according to GConf documentation.  If value is NULL, the key
	 * is unset.
	 */
	value = gconf_entry_get_value (e);
	if (! value)
		return r;
	
	hv_store (h, "value", 5, newSVGConfValue (value), 0);	
	
	return r;
}

GConfEntry *
SvGConfEntry (SV * data)
{
	HV * h;
	SV ** s;
	GConfValue * v;
	GConfEntry * e;

	if ((!data) || (!SvOK(data)) || (!SvRV(data)) || (SvTYPE(SvRV(data)) != SVt_PVHV))
		croak ("value must be an hashref");

	h = (HV *) SvRV (data);
	
	/* we require the 'value' key */
	if (! ((s = hv_fetch (h, "value", 5, 0)) && SvOK (*s)))
		croak ("'value' key needed");
	
	v = SvGConfValue (*s);
	
	if (! ((s = hv_fetch (h, "key", 3, 0)) && SvOK (*s)))
		croak ("'key' key needed");
	e = gconf_entry_new (SvGChar (*s), v);
	
	gconf_value_free (v);

	return e;
}

MODULE = Gnome2::GConf::Entry	PACKAGE = Gnome2::GConf::Entry	PREFIX = gconf_entry_



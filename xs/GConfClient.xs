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
#include <gperl_marshal.h>

/* Here's some magic.  In C, the notify function has the following parameters:
 * the GConfClient that is monitoring the keys, the connection id for notifier
 * handler and a GConfEntry, which is an opaque container for the key which is
 * being monitored and its value, stored as a GConfValue dynamic type (similar
 * to GValue).  Both GConfEntry and GConfValue should not be accessed directly
 * from the programmer (except for the "type" field of GConfValue, which is
 * used for type detection); so, these two objects do not have a type inside
 * Glib.  In order to expose the data contained inside those two objects, we
 * create an hashref and fill it with the key and the value; then, we pass it
 * to the notify marshaller.
 */
static GPerlCallback *
gconfperl_notify_func_create (SV * func, SV * data)
{
	GType param_types [] = {
		GCONF_TYPE_CLIENT,
		G_TYPE_INT,
		GPERL_TYPE_SV,
	};
	return gperl_callback_new (func, data,
			           G_N_ELEMENTS (param_types),
				   param_types, 0);
}

static void
gconfperl_notify_func (GConfClient * client,
		       guint cnxn_id,
		       GConfEntry * entry,
		       gpointer data)
{
	gperl_callback_invoke ((GPerlCallback*)data, NULL,
			       client,
			       cnxn_id,
			       newSVGConfEntry (entry));
}

/* the "error" and "unreturned_error" signals pass a GError to the callbacks
 * attached to them.  GError is an opaque struct which contains the error
 * message string.  Since GError is not a Glib type, we pass to the Perl
 * marshallers directly the message string.
 */
static void
gconfperl_client_error_marshal (GClosure * closure,
                                GValue * return_value,
                                guint n_param_values,
                                const GValue * param_values,
                                gpointer invocation_hint,
                                gpointer marshal_data)
{
	dGPERL_CLOSURE_MARSHAL_ARGS;
	GError *err;

	GPERL_CLOSURE_MARSHAL_INIT (closure, marshal_data);

	PERL_UNUSED_VAR (return_value);
	PERL_UNUSED_VAR (n_param_values);
	PERL_UNUSED_VAR (invocation_hint);

	ENTER;
	SAVETMPS;

	PUSHMARK (SP);

	GPERL_CLOSURE_MARSHAL_PUSH_INSTANCE (param_values);
	
	/* the second parameter for this signal is defined as a GError
	 * instance, but since we do not have the corresponding type for Perl,
	 * we simply pass the error message that GError contains. */
	err = (GError *) g_value_get_pointer (param_values + 1);
	XPUSHs (sv_2mortal (newSVpv (err->message, 0)));

	GPERL_CLOSURE_MARSHAL_PUSH_DATA;
	
	PUTBACK;

	GPERL_CLOSURE_MARSHAL_CALL (G_DISCARD);
	
	FREETMPS;
	LEAVE;
}


MODULE = Gnome2::GConf::Client	PACKAGE = Gnome2::GConf::Client PREFIX = gconf_client_

BOOT:
	gperl_signal_set_marshaller_for (GCONF_TYPE_CLIENT, "unreturned_error",
	                                 gconfperl_client_error_marshal);
	gperl_signal_set_marshaller_for (GCONF_TYPE_CLIENT, "error",
					 gconfperl_client_error_marshal);


GConfClient_noinc *
gconf_client_get_default (SV * class)
    C_ARGS:
     	/* void */

void
gconf_client_add_dir (client, dir, preload)
	GConfClient * client
	const gchar * dir
	GConfClientPreloadType preload
    PREINIT:
     	GError * err = NULL;
    CODE:
     	gconf_client_add_dir (client, dir, preload, &err);
	if (err)
		gperl_croak_gerror (dir, err);

void
gconf_client_remove_dir (client, dir)
	GConfClient * client
	const gchar * dir
    PREINIT:
     	GError * err = NULL;
    CODE:
     	gconf_client_remove_dir (client, dir, &err);
	if (err)
		gperl_croak_gerror (dir, err);

guint
gconf_client_notify_add (client, namespace_section, func, data=NULL)
	GConfClient * client
	const gchar * namespace_section
	SV * func
	SV * data
    PREINIT:
     	GPerlCallback * callback;
	GError * err = NULL;
	guint cnxn_id = 0;
    CODE:
     	callback = gconfperl_notify_func_create (func, data);
	cnxn_id = gconf_client_notify_add (client, namespace_section,
					   gconfperl_notify_func,
					   callback,
					   (GFreeFunc) gperl_callback_destroy,
					   &err);
	if (err)
		gperl_croak_gerror (namespace_section, err);
	RETVAL = cnxn_id;
    OUTPUT:
     	RETVAL

void
gconf_client_notify_remove (GConfClient * client, guint cnxn_id)

##void gconf_client_set_error_handling (GConfClient *client, GConfClientErrorHandlingMode mode);
##void gconf_client_set_global_default_error_handler (GConfClientErrorHandlerFunc func);

void
gconf_client_clear_cache (GConfClient * client)

void
gconf_client_preload (client, dirname, type)
	GConfClient * client
	const gchar * dirname
	GConfClientPreloadType type
    PREINIT:
    	GError * err = NULL;
    CODE:
    	gconf_client_preload (client, dirname, type, &err);
	if (err)
		gperl_croak_gerror (dirname, err);


### Get/Set methods

##void gconf_client_set (GConfClient *client, const gchar *key, const GConfValue *val, GError **err);
void
gconf_client_set (client, key, val)
	GConfClient * client
	const gchar * key
	SV * val
    PREINIT:
     	GError * err = NULL;
	GConfValue * value;
    CODE:
     	value = SvGConfValue (val);
	gconf_client_set (client, key, value, &err);
	gconf_value_free (value);	/* leaks otherwise */
	if (err)
		gperl_croak_gerror (key, err);


##GConfValue* gconf_client_get (GConfClient *client, const gchar *key, GError **err);
void
gconf_client_get (client, key)
	GConfClient * client
	const gchar * key
    PREINIT:
     	GError * err = NULL;
	GConfValue * val;
    PPCODE:
     	val = gconf_client_get (client, key, &err);
	if (err)
		gperl_croak_gerror (key, err);
	XPUSHs (sv_2mortal (newSVGConfValue (val)));


##GConfValue* gconf_client_get_without_default (GConfClient *client, const gchar *key, GError **err);
void
gconf_client_get_without_default (client, key)
	GConfClient * client
	const gchar * key
    PREINIT:
     	GError * err = NULL;
	GConfValue * val;
    PPCODE:
     	val = gconf_client_get_without_default (client, key, &err);
	if (err)
		gperl_croak_gerror (key, err);
	XPUSHs (sv_2mortal (newSVGConfValue (val)));

##GConfEntry* gconf_client_get_entry (GConfClient *client, const gchar *key, const gchar *locale, gboolean use_schema_default, GError **err);
void
gconf_client_get_entry (client, key, locale, use_schema_default)
	GConfClient * client
	const gchar * key
	const gchar * locale
	gboolean use_schema_default
    PREINIT:
     	GError * err = NULL;
	GConfEntry * e;
    PPCODE:
     	e = gconf_client_get_entry (client, key, locale, use_schema_default, &err);
	if (err)
		gperl_croak_gerror (key, err);
	XPUSHs (sv_2mortal (newSVGConfEntry (e)));

##GConfValue* gconf_client_get_default_from_schema (GConfClient *client, const gchar *key, GError **err);
void
gconf_client_get_default_from_schema (client, key)
	GConfClient * client
	const gchar * key
    PREINIT:
     	GError * err = NULL;
	GConfValue * val;
    PPCODE:
     	val = gconf_client_get_default_from_schema (client, key, &err);
	if (err)
		gperl_croak_gerror (key, err);
	XPUSHs (sv_2mortal (newSVGConfValue (val)));

##gboolean gconf_client_unset (GConfClient* client, const gchar* key, GError** err);
gboolean
gconf_client_unset (client, key)
	GConfClient * client
	const gchar * key
    PREINIT:
     	GError * err = NULL;
    CODE:
     	RETVAL = gconf_client_unset (client, key, &err);
	if (err)
		gperl_croak_gerror (key, err);
    OUTPUT:
     	RETVAL

##GSList* gconf_client_all_entries (GConfClient *client, const gchar *dir, GError **err);
void
gconf_client_all_entries (client, dir)
	GConfClient * client
	const gchar * dir
    PREINIT:
     	GError * err = NULL;
	GSList * l, * tmp;
    PPCODE:
     	l = gconf_client_all_entries (client, dir, &err);
		
	if (err)
		gperl_croak_gerror (dir, err);
	for (tmp = l; tmp != NULL; tmp = tmp->next) 
		XPUSHs (sv_2mortal (newSVGChar (gconf_entry_get_key(tmp->data))));
	g_slist_free (l);

##GSList* gconf_client_all_dirs (GConfClient *client, const gchar *dir, GError **err);
void
gconf_client_all_dirs (client, dir)
	GConfClient * client
	const gchar * dir
    PREINIT:
     	GError * err = NULL;
	GSList * l, * tmp;
    PPCODE:
     	l = gconf_client_all_dirs (client, dir, &err);
	if (err)
		gperl_croak_gerror (dir, err);
	for (tmp = l; tmp != NULL; tmp = tmp->next)
		XPUSHs (sv_2mortal (newSVGChar (tmp->data)));
	g_slist_free (l);

##void gconf_client_suggest_sync (GConfClient* client, GError** err);
void
gconf_client_suggest_sync (client)
	GConfClient * client
    PREINIT:
     	GError * err = NULL;
    CODE:
     	gconf_client_suggest_sync (client, &err);
	if (err)
		gperl_croak_gerror (NULL, err);

##gboolean gconf_client_dir_exists (GConfClient* client, const gchar* dir, GError** err);
gboolean
gconf_client_dir_exists (client, dir)
	GConfClient * client
	const gchar * dir
    PREINIT:
	GError * err = NULL;
    CODE:
	RETVAL = gconf_client_dir_exists (client, dir, &err);
	if (err)
		gperl_croak_gerror (dir, err);
    OUTPUT:
     	RETVAL

##gboolean gconf_client_key_is_writable (GConfClient* client, const gchar* key, GError** err);
gboolean
gconf_client_key_is_writable (client, key)
	GConfClient * client
	const gchar * key
    PREINIT:
     	GError * err = NULL;
    CODE:
     	RETVAL = gconf_client_key_is_writable (client, key, &err);
	if (err)
		gperl_croak_gerror (key, err);
    OUTPUT:
     	RETVAL

##gdouble gconf_client_get_float (GConfClient* client, const gchar* key, GError** err);
gdouble
gconf_client_get_float (client, key)
	GConfClient * client
	const gchar * key
    PREINIT:
     	GError * err = NULL;
    CODE:
     	RETVAL = gconf_client_get_float (client, key, &err);
	if (err)
		gperl_croak_gerror (key, err);
    OUTPUT:
     	RETVAL

##gint gconf_client_get_int (GConfClient* client, const gchar* key, GError** err);
gint
gconf_client_get_int (client, key)
	GConfClient * client
	const gchar * key
    PREINIT:
     	GError * err = NULL;
    CODE:
     	RETVAL = gconf_client_get_int (client, key, &err);
	if (err)
		gperl_croak_gerror (key, err);
    OUTPUT:
     	RETVAL

##/* free the retval, if non-NULL */
##gchar* gconf_client_get_string(GConfClient* client, const gchar* key, GError** err);
gchar_own *
gconf_client_get_string (client, key)
	GConfClient * client
	const gchar * key
    PREINIT:
     	GError * err = NULL;
    CODE:
     	RETVAL = gconf_client_get_string (client, key, &err);
	if (err)
		gperl_croak_gerror (key, err);
    OUTPUT:
     	RETVAL

##gboolean gconf_client_get_bool  (GConfClient* client, const gchar* key, GError** err);
gboolean
gconf_client_get_bool (client, key)
	GConfClient * client
	const gchar * key
     PREINIT:
     	GError * err = NULL;
     CODE:
     	RETVAL = gconf_client_get_bool (client, key, &err);
	if (err)
		gperl_croak_gerror (key, err);
     OUTPUT:
     	RETVAL

##GConfSchema* gconf_client_get_schema  (GConfClient* client,
##                                       const gchar* key, GError** err);
void
gconf_client_get_schema (client, key)
	GConfClient * client
	const gchar * key
    PREINIT:
    	GConfSchema * s;
	GError * err = NULL;
    PPCODE:
	s = gconf_client_get_schema (client, key, &err);
	if (err)
		gperl_croak_gerror (key, err);
	XPUSHs (sv_2mortal (newSVGConfSchema (s)));
	gconf_schema_free (s);


##GSList*      gconf_client_get_list    (GConfClient* client, const gchar* key,
##                                       GConfValueType list_type, GError** err);

##gboolean     gconf_client_get_pair    (GConfClient* client, const gchar* key,
##                                       GConfValueType car_type, GConfValueType cdr_type,
##                                       gpointer car_retloc, gpointer cdr_retloc,
##                                       GError** err);
	
## gboolean gconf_client_set_float (GConfClient* client, const gchar* key, gdouble val, GError** err);
gboolean
gconf_client_set_float (client, key, val)
	GConfClient * client
	const gchar * key
	gdouble val
    PREINIT:
     	GError * err = NULL;
    CODE:
     	RETVAL = gconf_client_set_float (client, key, val, &err);
	if (err)
		gperl_croak_gerror (key, err);
    OUTPUT:
     	RETVAL

## gboolean gconf_client_set_int (GConfClient* client, const gchar* key, gint val, GError** err);
gboolean
gconf_client_set_int (client, key, val)
	GConfClient * client
	const gchar * key
	gint val
    PREINIT:
     	GError * err = NULL;
    CODE:
     	RETVAL = gconf_client_set_int (client, key, val, &err);
	if (err)
		gperl_croak_gerror (key, err);
    OUTPUT:
     	RETVAL

## gboolean gconf_client_set_string (GConfClient* client, const gchar* key, const gchar* val, GError** err);
gboolean
gconf_client_set_string (client, key, val)
	GConfClient * client
	const gchar * key
	const gchar * val
    PREINIT:
     	GError * err = NULL;
    CODE:
     	RETVAL = gconf_client_set_string (client, key, val, &err);
	if (err)
		gperl_croak_gerror (key, err);
    OUTPUT:
     	RETVAL

## gboolean gconf_client_set_bool (GConfClient* client, const gchar* key, gboolean val, GError** err);
gboolean
gconf_client_set_bool (client, key, val)
	GConfClient * client
	const gchar * key
	gboolean val
    PREINIT:
     	GError * err = NULL;
    CODE:
     	RETVAL = gconf_client_set_bool (client, key, val, &err);
	if (err)
		gperl_croak_gerror (key, err);
    OUTPUT:
     	RETVAL

##gboolean     gconf_client_set_schema  (GConfClient* client, const gchar* key,
##                                       const GConfSchema* val, GError** err);
gboolean
gconf_client_set_schema (client, key, schema)
	GConfClient * client
	const gchar * key
	SV * schema
    PREINIT:
     	GConfSchema * val = NULL;
	GError * err = NULL;
    CODE:
     	val = SvGConfSchema (schema);
	RETVAL = gconf_client_set_schema (client, key, val, &err);
	gconf_schema_free (val);	/* leaks otherwise */
	if (err)
		gperl_croak_gerror (key, err);
    OUTPUT:
     	RETVAL

##/* List should be the same as the one gconf_client_get_list() would return */
##gboolean     gconf_client_set_list    (GConfClient* client, const gchar* key,
##                                       GConfValueType list_type,
##                                       GSList* list,
##                                       GError** err);

##gboolean     gconf_client_set_pair    (GConfClient* client, const gchar* key,
##                                       GConfValueType car_type, GConfValueType cdr_type,
##                                       gconstpointer address_of_car,
##                                       gconstpointer address_of_cdr,
##                                       GError** err);

##/* Functions to emit signals */
##void         gconf_client_error                  (GConfClient* client, GError* error);
##void         gconf_client_unreturned_error       (GConfClient* client, GError* error);
##
##void         gconf_client_value_changed          (GConfClient* client,
##                                                  const gchar* key,
##                                                  GConfValue* value);

##/*
## * Change set stuff
## */
##
##gboolean        gconf_client_commit_change_set   (GConfClient* client,
##                                                  GConfChangeSet* cs,
##                                                  /* remove all
##                                                     successfully
##                                                     committed changes
##                                                     from the set */
##                                                  gboolean remove_committed,
##                                                  GError** err);
void
gconf_client_commit_change_set (client, cs, remove_committed)
	GConfClient * client
	SV * cs
	gboolean remove_committed
    PREINIT:
	GError * err = NULL;
	GConfChangeSet * set;
	gboolean res;
    PPCODE:
    	set = SvGConfChangeSet (cs);
	res = gconf_client_commit_change_set (client, set, remove_committed, &err);
	if (err) {
		gperl_croak_gerror (NULL, err);
	}
	if ((GIMME_V != G_ARRAY) || (! remove_committed)) {
		/* push on the stack the returned boolean value if the user
		 * wants only that, or if the user does not want to remove
		 * the successfully committed keys. */
		XPUSHs (sv_2mortal (newSViv (res)));
	}
	else {
		/* push on the stack the reduced set. */
		XPUSHs (sv_2mortal (newSVGConfChangeSet (set)));
	}

##/* Create a change set that would revert the given change set for the given GConfClient */
##GConfChangeSet* gconf_client_reverse_change_set  (GConfClient* client,
##                                                  GConfChangeSet* cs,
##                                                  GError** err);
void
gconf_client_reverse_change_set (client, cs)
	GConfClient * client
	SV * cs
    PREINIT:
     	GError * err = NULL;
	GConfChangeSet * set, * res;
    PPCODE:
     	set = SvGConfChangeSet (cs);
     	res = gconf_client_reverse_change_set (client, set, &err);
	if (err)
		gperl_croak_gerror (NULL, err);
	XPUSHs (sv_2mortal (newSVGConfChangeSet (res)));

### Gnome2::GConf::Client::change_set_from_current is really
### change_set_from_currentv for implementation ease, but the calling signature
### is the same of change_set_from_current, so here it goes.
##GConfChangeSet* gconf_client_change_set_from_currentv (GConfClient* client,
##                                                       const gchar** keys,
##                                                       GError** err);
##GConfChangeSet* gconf_client_change_set_from_current (GConfClient* client,
##                                                      GError** err,
##                                                      const gchar* first_key,
##                                                      ...);
void
gconf_client_change_set_from_current (client, data, ...)
	GConfClient * client
    PREINIT:
     	char ** keys;
	int i;
	GError * err = NULL;
	GConfChangeSet * res;
    PPCODE:
    	keys = g_new0 (char *, items - 1);
	for (i = 1; i < items; i++)
		keys[i-1] = SvPV_nolen (ST (i));
	res = gconf_client_change_set_from_currentv (client, (const gchar **) keys, &err);
	g_free(keys);
	if (err)
		gperl_croak_gerror (NULL, err);
	XPUSHs (sv_2mortal (newSVGConfChangeSet (res)));

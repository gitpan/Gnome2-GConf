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

#ifndef _GNOME_GCONF_PERL_H_
# define _GNOME_GCONF_PERL_H_

# include "gperl.h"

/* basic include files */
# include <gconf/gconf-changeset.h>
# include <gconf/gconf-client.h>
# include <gconf/gconf-engine.h>
# include <gconf/gconf-enum-types.h>
# include <gconf/gconf-error.h>
# include <gconf/gconf-listeners.h>
# include <gconf/gconf-schema.h>
# include <gconf/gconf-value.h>
# include <gconf/gconf.h>

# include "gconfperl-autogen.h"
# include "gconfperl-version.h"

GType gconfperl_gconf_error_get_type(void);
# define GCONFPERL_TYPE_GCONF_ERROR gconfperl_gconf_error_get_type()

/* forward declaration for opaque containers converters */
SV * newSVGConfEntry (GConfEntry *);
SV * newSVGConfValue (GConfValue *);
SV * newSVGConfSchema (GConfSchema *);
SV * newSVGConfChangeSet (GConfChangeSet *);

GConfEntry * SvGConfEntry (SV *);
GConfValue * SvGConfValue (SV *);
GConfSchema * SvGConfSchema (SV *);
GConfChangeSet * SvGConfChangeSet (SV *);

#endif /* _GNOME_GCONF_PERL_H_ */


#
# Copyright (c) 2003 by Emmanuele Bassi (see the file AUTHORS)
#
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Library General Public
# License as published by the Free Software Foundation; either
# version 2 of the License, or (at your option) any later version.
#
# This library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Library General Public License for more details.
#
# You should have received a copy of the GNU Library General Public
# License along with this library; if not, write to the 
# Free Software Foundation, Inc., 59 Temple Place - Suite 330, 
# Boston, MA  02111-1307  USA.

package Gnome2::GConf;

use 5.008;
use strict;
use warnings;

use Gtk2;
use Gnome2;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Gnome2::Print ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.42';

sub dl_load_flags { 0x01 }

require XSLoader;
XSLoader::load('Gnome2::GConf', $VERSION);

# Preloaded methods go here.

1;
__END__

=head1 NAME

Gnome2::GConf - Perl wrappers for the GConf configuration engine.

=head1 SYNOPSIS

  use Gnome2::GConf;

  my $client = Gnome2::GConf::Client->get_default;
  my $app_key = "/apps/myapp/mykey";
  
  $client->add_dir($app_key, 'preload-none');
  
  # add a notify for the key
  my $notify_id = $client->notify_add($app_key, sub {
  		my ($client, $cnxn_id, $entry) = @_;
		return unless $entry->{value};

		if ($entry->{value}->{type} eq 'string')
		{
			printf "key '%s' changed to '%s'\n",
					$entry->{key},
					$entry->{value}->{data};
		}
	});
  
  my $string = $client->get_string($app_key);
  $string = 'some string' unless $string;
  
  $client->set($app_key, { type => 'string', data => $string });
  $client->set_schema ($app_key, {
  		type => 'string',
		locale => 'C',
		short_desc => 'Some key.',
		long_desc => 'This key does something.',
		owner => 'some_program'
	});

  $client->notify_remove($notify_id);

=head1 ABSTRACT

  Perl bindings to the 2.2 series of the GConf configuration engine
  libraries, for use with gtk2-perl.

=head1 DESCRIPTION

This module allows you to use the GConf configuration system in order to
store/retrieve the configuration of an application.  The GConf system is a
powerful configuration manager based on a user daemon that handles a set of
key and value pairs, and notifies any changes of the value to every program
that monitors those keys.  GConf is used by GNOME 2.x.

To discuss gtk2-perl, ask questions and flame/praise the authors,
join gtk-perl-list@gnome.org at lists.gnome.org.

Find out more about Gnome at http://www.gnome.org.

=head1 DIFFERENT DATA TYPES

Some opaque data types in GConf are not registered inside the Glib type
system.  Thus, they have been implemented in a more perlish way, when
possible, for the sake of coherency and following the principle of least
surprise for the perl developer.  These changes tried to preserve semantics,
to add syntactic sugar and to remove the need for accessor methods.

=over

=item GConfEntry

In C, C<GConfEntry> is a opaque container for the key string and for the
C<GConfValue> bound to that key.  In perl, it's an hashref consisting of
these keys:

=over

=item B<key>

The key that is being monitored.

=item B<value>

An hashref, representing a C<GConfValue>, which contains the type and the
value of the key; it may be undef if the key has been unset.  See C<GConfValue>
below.

=back

=item GConfValue

In C, C<GConfValue> is a dynamic type similar to C<GValue>; it contains the
value bound to a key, and its type.  In perl, it's an hashref containing these
keys:

=over

=item B<type>

The type of the data.  Fundamental types are 'string', 'int', 'float' and
'bool'.  Lists are handled by passing an arrayref as the payload of the C<value>
key:
	
	$client->set($key, { type => 'string', value => 'some string' });
	$client->set($key, { type => 'float',  value => 0.5           });
	$client->set($key, { type => 'bool',   value => FALSE         });
	$client->set($key, { type => 'int',    value => [0..15]       });
	
Pairs are handled by using the special type 'pair', and passing, in place
of the C<value> key, the C<car> and the C<cdr> keys, each containing an hashref
representing a GConfValue:

	$client->set($key, {
			type => 'pair',
			car  => { type => 'string', value => 'some string' },
			cdr  => { type => 'int',    value => 42            },
		});

This is needed since pairs might have different types; lists, instead, are of
the same type.

=item B<value>

The payload, containing the value of type C<type>.  It is used only for
fundamental types (scalars or lists).

=item B<car>, B<cdr>

Special keys, that must be used only when working with the 'pair' type.

=back

=item GConfChangeSet

In C, C<GConfChangeSet> is an hash containing keys and C<GConfValue>s to be
committed in a single pass (though not yet with an atomic operation).  Since
perl has hashes as a built-in type, C<GConfChangeSet> is threated as an hash
with the GConf keys as keys, and their relative C<GConfValue> as payload.

	$cs = {
		'/apps/someapp/some_int_key' => { type => 'int', value => 42 },
		'/apps/someapp/some_string_key' => { type => 'string', value => 'hi' },
	};

	$reverse_cs = $client->reverse_change_set($cs);
	$client->commit_change_set($cs, FALSE);

=item GConfSchema

In C, C<GConfSchema> is an opaque type for a "schema", that is a collection of
useful informations about a key/value pair. It may contain a description of
the key, a default value, the program which owns the key, etc.  In perl, it
is represented using an hashref containing any of these keys:

=over 4

=item B<type>

The type of the value the key points to.  It's similar to the corresponding
'type' key of GConfValue, but it explicitly tags lists and pairs using the
'list' and 'pair' types (the 'type' key is just an indication of what should
be expected inside the C<default_value> field).

=item B<default_value>

The default value of the key.  In C, this should be a GConfValue, so, in perl,
it becomes an hashref (see GConfValue above).

=item B<short_desc>

A string containing a short description (a phrase, no more) of the key.

=item B<long_desc>

A string containing a longer description (a paragraph or more) of the key.

=item B<owner>

A string containing the name of the program which uses ('owns') the key to
which the schema is bound.

=item B<locale>

The locale for the three strings above (above strings are UTF-8, and the
locale is needed for translations purposes).

=back

=back

=head1 DIFFERENT CALL SIGNATURES

Reflecting the changes operated for the data types, some methods that use
those type have had the call signature modified.

=over

=item GConfNotifyFunc

In C, the function passed to C<Gnome2::GConf::notify_add> must have the
following signature:
	
	void (GConfNotifyFunc *) (GConfClient * client,
	                          guint cnxn_id,
	                          GConfEntry * entry);

Where C<GConfEntry> is a container for the key/value pair.  Since in perl
there's no C<GConfEntry> (see above), the C<entry> parameter is an hashref.

=item GConfClient::get

=item GConfClient::set

In C, these accessor methods return/use a C<GConfValue>.  In perl, they
return/use an hashref representing that C<GConfValue>:

	$client->set($key, { type => 'int', value => 42 });
	$data = $client->get($key)->{value};

=item GConfClient::get_schema

=item GConfClient::set_schema

Similarly to the get/set pair above, these two methods return/use an hashref
representing a C<GConfSchema> (see above):

	$client->set_schema($key, {
			owner		=> 'some_program',
			short_desc	=> 'Some key.',
			long_desc	=> 'A key that does something to some_program.',
			locale		=> 'C',
			type		=> 'int',
			default_value => { type => 'int', value => 42 }
		});
	$description['short'] = $client->get_schema($key)->{short_desc};

=back

=head1 ERROR HANDLING

In C, GConf offers a complex and flexible error handling system.  Each fallible
function has a GError parameter: if you want to retrieve the error message in
case of failure, you could pass a pointer to an empty GError structure, and
then use it; on error, though, the default error handler will be invoked.  If
you don't want to know what happened, and let the default error handler deal
with the failure, you might pass a NULL value.  In case of failure, the "error"
signal is emitted; you might want to attach a callback to that signal and
control signal propagation.  Also, if you pass a NULL value instead of a GError
structure, the "unreturned_error" is emitted, thus allowing a finer grained
error control; e.g.: just pass a GError to every function you want the default
error handler to check on failure, and pass a NULL value to the functions you
want to check using the "unreturned_error" signal.

In perl, you don't have all these options, mainly because there's no GError
type.  By default, every fallible method will croak on failure, which is The
Right Thing To Do(R) when debugging; also, the "error" signal is emitted, so
you might connect a callback to it.  If you want to catch the error, just wrap
the method with eval, e.g.:
	
	eval { $s = $client->get_string($some_key); 1; };
	if ($@)
	{
		# do domething with $@
	}

=head1 SEE ALSO

perl(1), Glib(3pm), Gtk2(3pm), Gnome2(3pm).

=head1 AUTHOR

Emmanuele Bassi E<lt>emmanuele.bassi@iol.itE<gt>

gtk2-perl created by the gtk2-perl team: http://gtk2-perl.sf.net

=head1 COPYRIGHT AND LICENSE

Copyright 2003 by Emmanuele Bassi

This library is free software; you can redistribute it and/or
modify it under the terms of the GNU Library General Public
License as published by the Free Software Foundation; either
version 2 of the License, or (at your option) any later version.

This library is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
Library General Public License for more details.

You should have received a copy of the GNU Library General Public
License along with this library; if not, write to the 
Free Software Foundation, Inc., 59 Temple Place - Suite 330, 
Boston, MA  02111-1307  USA.

=cut

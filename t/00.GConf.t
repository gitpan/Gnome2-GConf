#########################
# Gnome2::GConf Tests
#       - ebb
#########################

#########################

use strict;
use Gnome2::GConf;

use constant TESTS => 7; # number of skippable tests 
use Test::More tests => TESTS + 1;

my @version = Gnome2::GConf->GET_VERSION_INFO;
is( @version, 3, 'version is three items long' );

my $c = Gnome2::GConf::Client->get_default;

SKIP: {
  skip("Couldn't connect to the GConf defaul client.", TESTS)
    unless ($c);

  skip("basic-gconf-app directory not found in GConf.", TESTS)
    unless ($c->dir_exists('/apps/basic-gconf-app'));

  our $app_dir = '/apps/basic-gconf-app';
  our $client = Gnome2::GConf::Client->get_default;
  isa_ok( $client, 'Gnome2::GConf::Client' );
  
  $client->add_dir($app_dir, 'preload-recursive');
  ok( 1 );
  
  our $key_foo = $app_dir . '/foo';
  is( $client->get($key_foo)->{'type'}, 'string' );
  
  ok( $client->get_string($key_foo) );
  
  our $id = $client->notify_add($key_foo, sub { warn @_; });
  ok( $id );
  
  ok( $client->set_string($key_foo, 'test') );

  $client->notify_remove($id);
  ok( 1 );
}

#########################

#
# $Header: /cvsroot/gtk2-perl/gtk2-perl-xs/Gnome2-GConf/Makefile.PL,v 1.12 2004/03/24 14:26:34 ebassi Exp $
#

use 5.008;
use strict;
use warnings;
use Cwd;
use File::Spec;
use ExtUtils::MakeMaker;

# minimum required version of dependancies we need to build
our %build_reqs = (
	'perl-ExtUtils-Depends'   => '0.2',
	'perl-ExtUtils-PkgConfig' => '1.03',
	'perl-Glib'               => '1.040', # for Glib::MakeHelper
	'perl-Gtk2'               => '1.040', # for Gtk2::CodeGen
	'GConf'                   => '1.2.0',
);

# Writing a fake Makefile ensures that CPAN will pick up the correct
# dependencies and install them.
unless (eval "use ExtUtils::Depends;"
           . "use ExtUtils::PkgConfig;"
	   . "use Gtk2::CodeGen;"
           # just seeing if Glib is available isn't enough, make sure
           # it's recent enough, too 
           . "use Glib '$build_reqs{'perl-Glib'}';"
           . "use Gtk2 '$build_reqs{'perl-Gtk2'}';"
           . "use Glib::MakeHelper;"
           . "1") {
   warn "$@\n";
   WriteMakefile(
         PREREQ_FATAL => 1,
         PREREQ_PM    => {
            'Glib'                => $build_reqs{'perl-Glib'},
            'Gtk2'                => $build_reqs{'perl-Gtk2'},
            'ExtUtils::Depends'   => $build_reqs{'perl-ExtUtils-Depends'},
            'ExtUtils::PkgConfig' => $build_reqs{'perl-ExtUtils-PkgConfig'},
         },
   );
   exit 1; # not reached
}

mkdir 'build', 0777;

our %pkgcfg = ExtUtils::PkgConfig->find ('gconf-2.0 >= '.$build_reqs{GConf});


our @xs_files = <xs/*.xs>;
our %pm_files = (
    'GConf.pm'		=> '$(INST_LIBDIR)/GConf.pm',
);
our %pod_files = (
    'GConf.pm'		=> '$(INST_MAN3DIR)/Gnome2::GConf.$(MAN3EXT)',
    Glib::MakeHelper->do_pod_files (@xs_files),
);

ExtUtils::PkgConfig->write_version_macros ("build/gconfperl-version.h",
                                           'gconf-2.0' => 'GCONF');

#
# autogeneration
#
Gtk2::CodeGen->parse_maps ('gconfperl');
Gtk2::CodeGen->write_boot (ignore => '^Gnome2::GConf$');

# now we're ready to start creating the makefile.
# we need to use ExtUtils::Depends to get relevant information out of
# the Glib extension, and to save config information for other modules which
# will chain from this one.
our $gconf = ExtUtils::Depends->new ('Gnome2::GConf', 'Glib');
$gconf->set_inc ($pkgcfg{cflags} . ' -I./build ');
$gconf->set_libs ($pkgcfg{libs});
$gconf->add_xs (@xs_files);
$gconf->add_pm (%pm_files);
my $cwd = cwd();
$gconf->add_typemaps (map { File::Spec->catfile($cwd, $_) }
                      'build/gconfperl.typemap', 'gconf.typemap');
$gconf->install (qw(gconfperl.h
		build/gconfperl-autogen.h
		build/gconfperl-version.h));
$gconf->save_config ('build/IFiles.pm');

WriteMakefile(
    NAME          => 'Gnome2::GConf',
    VERSION_FROM  => 'GConf.pm', # finds $VERSION
    PREREQ_PM     => {}, # e.g., Module::Name => 1.1
    ABSTRACT_FROM => 'GConf.pm', # retrieve abstract from module
    XSPROTOARG    => '-noprototypes',
    MAN3PODS	  => \%pod_files,
    $gconf->get_makefile_vars,
);

sub MY::postamble
{
	return Glib::MakeHelper->postamble_clean ()
	     . Glib::MakeHelper->postamble_docs_full (
		DEPENDS => $gconf,
		DOCTYPES => 'doctypes',
		COPYRIGHT_FROM => 'copyright.pod',
	       )
	     . Glib::MakeHelper->postamble_rpms (
		'GCONF' => $build_reqs{'GConf'},
		'PERL_EXTUTILS_DEPENDS' => 
			$build_reqs{'perl-ExtUtils-Depends'},
		'PERL_EXTUTILS_PKGCONFIG' => 
			$build_reqs{'perl-ExtUtils-PkgConfig'},
		'PERL_GLIB' => $build_reqs{'perl-Glib'},
		'PERL_GTK' => $build_reqs{'perl-Gtk2'},
	       );
}

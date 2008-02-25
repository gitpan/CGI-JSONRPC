#!perl
  
use strict;
use warnings FATAL => 'all';
  
use lib qw(lib);
use base q(Apache::TestRunPerl);
use Apache::TestConfig ();

my $self = main::->new->run(@ARGV);

sub pre_configure {
  my $self = shift;

  # mod_bt doesn't like to be loaded if it isn't configured.
  Apache::TestConfig::autoconfig_skip_module_add('mod_bt.c');
  $self->SUPER::pre_configure(@_);
}

# for some reason, cgi doesnt get loaded by default (at least on my system)
# anymore... :-(

sub configure {
  my $self = shift;
  my $cgi = $self->{test_config}->{vars}->{"cgi_module"};
  if($cgi) {
    $cgi =~ s{\..+$}{.so};
    $self->{test_config}->find_and_load_module($cgi);
  } else {
    warn "couldn't find CGI-module.";
  }
  return $self->SUPER::configure(@_);
}

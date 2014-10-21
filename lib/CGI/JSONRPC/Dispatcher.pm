#!perl

package CGI::JSONRPC::Dispatcher;

use strict;
use warnings;
our $AUTOLOAD;

return 1;

sub AUTOLOAD {
    my($class, $id, $to) = splice(@_, 0, 3);
    (my $method = $AUTOLOAD) =~ s{^.*::}{};
    $to =~ s{\.}{::}g;
    my $object = $to->new_from_jsonrpc($id);
    return $object->$method(@_);
}

=pod

=head1 NAME

CGI::JSONRPC::Dispatcher - Dispatch JSONRPC requests to objects

=head1 SYNOPSIS

package Hello;

sub new_from_json_rpc {
    my($class, $id) = @_;
    my $self = bless { id => $id }, $class;
}

sub hi {
    return "hey";
}

=head1 DESCRIPTION

Apache2::JSONRPC::Dispatcher receives JSONRPC class method calls and translates
them into perl object method calls. Here's how it works:

=head1 FUNCTION

=over

=item AUTOLOAD($my_class, $id, $desired_class, @args)

When any function is called in Apache2::JSONRPC::Dispatcher, the
C<AUTOLOAD> sub runs.

=over

=item *

C<$desired_class> has all of it's dots (.) converted to double-colons (::)
to translate JavaScript class names into perl.

=item *

The C<new_from_json_rpc> method in the resulting class is called with
$id passed in as the first argument. An object should be returned from
C<new_from_json_rpc> in your code.

=item *

The returned object has the desired method invoked, with any remaining
arguments to AUTOLOAD passed in.

=back

If new_from_json_rpc does not exist in the requested package, a fatal error
will occur. This both provides you with a handy state mechanism, and ensures
that packages that aren't supposed to be accessed from the web aren't.

L<Apache2::JSONRPC> attempts to call dispatchers with this set of arguments,
and then takes any return values, serializes them to JSON, and sends a response
back to the client.

=head1 AUTHOR

Tyler "Crackerjack" MacDonald <japh@crackerjack.net> and
David Labatte <buggyd@justanotherperlhacker.com>

=head1 LICENSE

Copyright 2006 Tyler "Crackerjack" MacDonald <japh@crackerjack.net>

This is free software; You may distribute it under the same terms as perl
itself.

=head1 SEE ALSO

The "examples/httpd.conf" file bundled with the distribution shows how to
create a new JSONRPC::Dispatcher-compatible class, and also shows a rather
hacky method for making an existing class accessable from JSON.

L<Apache2::JSONRPC>

=cut

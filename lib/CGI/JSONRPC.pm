#!perl

package CGI::JSONRPC;

use strict;
use warnings;
use JSON::Syck;
use JSON::Syck qw(Dump Load);
use CGI::JSONRPC::Dispatcher;
use CGI;

our $VERSION = "0.01";
(our $JAVASCRIPT = __FILE__) =~ s{\.pm$}{.js};

return 1;

sub new {
    my($class, %args) = @_;
    return bless { dispatcher => $class->default_dispatcher, %args }, $class;
}

sub default_dispatcher {
    'CGI::JSONRPC::Dispatcher'
}

sub handler {
    my($class, $cgi) = @_;
    
    $cgi ||= CGI->new;
    my $self = $class->new(
        path        =>  $cgi->url(-absolute => 1, -full => 0, -path_info => 0),
        path_info   =>  $cgi->path_info()
    );
    
    my $method = $cgi->request_method;
    
    if($method eq 'GET' || $method eq 'HEAD') {
        print $cgi->header("text/javascript"), $self->return_javascript;
        return 1;
    } elsif($method eq 'POST') {
        my $json = $cgi->param('POSTDATA') or die "No POST data was sent!";
        print $cgi->header("text/json"), $self->run_json_request($json);
        return 1;
    } else {
        die "Unsupported method: ", $cgi->method;
    }
}

sub run_json_request {
    my($self, $json) = @_;
    
    my $data = (JSON::Syck::Load($json))[0];
    
    die "Did not get a hash from RPC request!"
        unless(ref($data) && ref($data) eq 'HASH');
    
    unless($data->{method}) {
        warn "JSONRPC payload did not have a method!";
        return $self->return_error($data, "JSONRPC payload did not have a method!"); 
    }

    return $self->run_data_request($data);
}

sub run_data_request {
    my($self, $data) = @_;
    
    $data->{params} ||= [];
    
    my @rv = eval {
        my $method = "$self->{dispatcher}\::$data->{method}";
        warn $method;
        no strict 'refs';
        return(&{$method}($self->{dispatcher}, $data->{id}, @{$data->{params}}));
    };
    
    if(my $error = $@) {
        warn $error;
        return $self->return_error($data, $error);
    }
    
    if(defined $data->{id}) {
        return $self->return_result($data, \@rv);
    } else {
        return "";
    }
}

sub return_result {
    my($self, $data, $result) = @_;
    return JSON::Syck::Dump({ id => $data->{id}, result => $result })
}

sub return_error {
    my($self, $data, $error) = @_;
    return JSON::Syck::Dump({
        id      =>  (defined $data->{id} ? $data->{id} : undef),
        error   =>  $error
    });
}

sub return_javascript {
    my $self = shift;
    if(my $class = $self->{path_info}) {
        $class =~ s{^/|/$}{};
        $class =~ s{[\.\/]}{::}g;
        $class ||= $self;
        return $class->jsonrpc_javascript($self);
    } else {
        return $self->jsonrpc_javascript($self);
    }
}

sub jsonrpc_javascript {
    my $self = shift;
    my $fh;
    open($fh, '<', $JAVASCRIPT) or die $!;
    my @rv = <$fh>;
    if($self->{path}) {
        push(@rv, "\nJSONRPC.URL = '$self->{path}';\n");
    }
    return join('', @rv);
}
    

=pod

=head1 NAME

CGI::JSONRPC - CGI handler for JSONRPC

=head1 SYNOPSIS

  use CGI;
  use CGI::JSONRPC;
  my $cgi = new CGI;
  CGI::JSONRPC->handler($cgi);
  exit;

=head1 DESCRIPTION

CGI::JSONRPC implements the JSONRPC protocol as defined at
L<http://www.json-rpc.org/>. When a JSONRPC request is received by
this handler, it is translated into a method call. The method and
it's arguments are determined by the JSON payload coming from the
browser, and the package to call this method on is determined by
the C<JSONRPC_Class> apache config directive.

A sample "dispatcher" module is supplied,
L<CGI::JSONRPC::Dispatcher|CGI::JSONRPC::Dispatcher>

B<Note:> I<This documentation is INCOMPLETE and this is an alpha release.
The interface is somewhat stable and well-tested, but other changes may
come as I work in implementing this on my website.>

=head1 USAGE

When contacted with a GET request, CGI::JSONRPC will reply with the
contents of JSONRPC.js, which contains code that can be used to create
JavaScript classes that can communicate with their Perl counterparts.
See the /examples/hello.html file for some sample JavaScript that uses
this library, and /examples/httpd.conf for the corresponding Perl.

When contacted with a POST request, CGI::JSONRPC will attempt to
process and dispatch a JSONRPC request. If a valid JSONRPC request was
sent in the POST data, the dispatcher class will be called, with the
following arguments:

=over

=item $class

Just like any other class method, the first argument passed in will be
name of the class being invoked.

=item $id

The object ID string from the JSONRPC request. In accordance with the
json-rpc spec, your response will only be sent to the client if this
value is defined.

=item @params

All further arguments to the method will be the arugments passed in
the "params" section of the JSONRPC request.

=back

If the client specified an C<id>, your method's return value will be serialized
into a JSON array and sent to the client as the "result" section of the
JSONRPC response.

=head2 The default dispatcher

The default dispatcher adds another layer of functionality; it expects the
first argument in @params to be the name of the class the method is being
invoked on. See L<CGI::JSONRPC::Dispatcher> for more details on that.

=head1 AUTHOR

Tyler "Crackerjack" MacDonald <japh@crackerjack.net> and
David Labatte <buggyd@justanotherperlhacker.com>.

A lot of the JavaScript code was borrowed from Ingy döt Net's
L<Jemplate|Jemplate> package.

=head1 LICENSE

Copyright 2006 Tyler "Crackerjack" MacDonald <japh@crackerjack.net>

This is free software; You may distribute it under the same terms as perl
itself.

=head1 SEE ALSO

The "examples" directory (examples/httpd.conf and examples/hello.html),
L<JSON::Syck>, L<http://www.json-rpc.org/>.

=cut

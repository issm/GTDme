package GTDme::API;
use strict;
use warnings;
use utf8;
use parent qw(GTDme Amon2::Web);
use File::Spec;

# dispatcher
use GTDme::API::Dispatcher;
sub dispatch {
    return GTDme::API::Dispatcher->dispatch($_[0]) or die "response is not generated";
}

# setup view class
use Text::Xslate;
{
    my $view_conf = __PACKAGE__->config->{'Text::Xslate'} || +{};
    unless (exists $view_conf->{path}) {
        $view_conf->{path} = [ File::Spec->catdir(__PACKAGE__->base_dir(), 'tmpl/api') ];
    }
    my $view = Text::Xslate->new(+{
        'syntax'   => 'TTerse',
        'module'   => [ 'Text::Xslate::Bridge::Star' ],
        'function' => {
            c => sub { Amon2->context() },
            uri_with => sub { Amon2->context()->req->uri_with(@_) },
            uri_for  => sub { Amon2->context()->uri_for(@_) },
            static_file => do {
                my %static_file_cache;
                sub {
                    my $fname = shift;
                    my $c = Amon2->context;
                    if (not exists $static_file_cache{$fname}) {
                        my $fullpath = File::Spec->catfile($c->base_dir(), $fname);
                        $static_file_cache{$fname} = (stat $fullpath)[9];
                    }
                    return $c->uri_for($fname, { 't' => $static_file_cache{$fname} || 0 });
                }
            },
        },
        %$view_conf
    });
    sub create_view { $view }
}


# load plugins
__PACKAGE__->load_plugins(
    'Web::JSON',
);

sub show_error {
    my ( $c, $msg, $code ) = @_;
    my $res = $c->render( 'error.tt', { message => $msg } );
    $res->code( $code || 500 );
    return $res;
}

# for your security
__PACKAGE__->add_trigger(
    BEFORE_DISPATCH => sub {
        my ($c) = @_;
        my $req = $c->req;
        my $apikey = $req->param('apikey');

        my $m_user = $c->model('user');
        my $my;

        # query param "apikey" is specified
        if ( $apikey ) {
            $my = $m_user->search( apikey => $apikey )->{list}[0];
        }
        # has logged in
        elsif ( my $my_id = $c->session->get('my_id') ) {
            $my = $m_user->search( id => $my_id )->{list}[0];
        }

        unless ( defined $my ) {
            my $res = $c->render_json({ status => 403 });
            $res->status(403);
            return $res;
        }

        $c->stash->{my} = $my;
        $c->stash->{is_loggedin} = $my->{id} ? 1 : 0;
    },

    AFTER_DISPATCH => sub {
        my ( $c, $res ) = @_;

        $res->header('Content-Type' => 'application/json; charset=utf-8' );

        # http://blogs.msdn.com/b/ie/archive/2008/07/02/ie8-security-part-v-comprehensive-protection.aspx
        $res->header( 'X-Content-Type-Options' => 'nosniff' );

        # http://blog.mozilla.com/security/2010/09/08/x-frame-options/
        $res->header( 'X-Frame-Options' => 'DENY' );

        # Cache control.
        $res->header( 'Cache-Control' => 'private' );
    },
);

1;

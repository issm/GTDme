package GTDme::PC;
use strict;
use warnings;
use utf8;
use parent qw(GTDme Amon2::Web);
use File::Spec;

# dispatcher
use GTDme::PC::Dispatcher;
sub dispatch {
    return GTDme::PC::Dispatcher->dispatch($_[0]) or die "response is not generated";
}

# setup view class
use Text::Xslate;
{
    my $view_conf = __PACKAGE__->config->{'Text::Xslate'} || +{};
    unless (exists $view_conf->{path}) {
        $view_conf->{path} = [ File::Spec->catdir(__PACKAGE__->base_dir(), 'tmpl/pc') ];
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
    'Web::FillInFormLite',
    'Web::CSRFDefender',
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
        my $my;
        if ( defined ( my $my_id = $c->session->get('my_id') ) ) {
            my $m_user = $c->model('user');
            $my = $m_user->search( id => $my_id )->{list}[0];
        }
        unless ( defined $my ) {
            $my = { id => 0 };
        }
        $c->stash->{my} = $my;
        $c->stash->{is_loggedin} = $my->{id} ? 1 : 0;
        $c->stash->{is_deployment} = $ENV{PLACK_ENV} eq 'deployment' ? 1 : 0;
    },


    AFTER_DISPATCH => sub {
        my ( $c, $res ) = @_;

        # http://blogs.msdn.com/b/ie/archive/2008/07/02/ie8-security-part-v-comprehensive-protection.aspx
        $res->header( 'X-Content-Type-Options' => 'nosniff' );

        # http://blog.mozilla.com/security/2010/09/08/x-frame-options/
        $res->header( 'X-Frame-Options' => 'DENY' );

        # Cache control.
        $res->header( 'Cache-Control' => 'private' );
    },
);

1;

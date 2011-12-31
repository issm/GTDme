package GTDme::PC::C::Auth;
use strict;
use warnings;
use utf8;
use Smart::Args;
use OAuth::Lite::Consumer;
use JSON;


sub login {
    my ($class, $c) = @_;
    my ($mode) = @{$c->{args}{splat}};

    {
        no strict;
        return *{"$class\::_login_$mode"}->(@_);
    };
}

sub _login_twitter {
    my ($class, $c) = @_;
    my ($req, $session) = ($c->req, $c->session);

    use Data::Dumper;

    # should be loaded from config
    my $oauth_conf = $c->config->{OAuth}{twitter};
    my $oauth_consumer;
    my $request_token;

    $oauth_consumer = _new_oauth_consumer($oauth_conf);

    $request_token = $oauth_consumer->get_request_token(
        callback_url => $req->base . $oauth_conf->{callback_url},
    );

    $session->set( oauth_request_token => $request_token );
    $session->set( auth_type => 'twitter' );


    #return $c->render('index.tx');
    return $c->redirect(
        $oauth_consumer->url_to_authorize( token => $request_token ),
    );
}



sub callback {
    my ($class, $c) = @_;
    my ($req, $session) = ($c->req, $c->session);
    my $vars = {};

    # cancelled
    if ( defined $req->param('denied') ) {
        $vars->{denied} = $req->param('denied');
    }
    # authorized
    else {
        my $verifier      = $req->param('oauth_verifier');
        my $request_token = $session->get('oauth_request_token');
        my $auth_type     = $session->get('auth_type');

        my $oauth_conf = $c->config->{'OAuth'}{$auth_type};
        my $oauth_consumer = _new_oauth_consumer($oauth_conf);

        # if (0) {
        #     die 'auth_type is not defined!';
        # }

        my $access_token = $oauth_consumer->get_access_token(
            token    => $request_token,
            verifier => $verifier,
        );

        $session->set( oauth_access_token => $access_token );
        $session->remove('oauth_request_token');
        $session->remove('auth_type');

        # （存在していなければ）ユーザ情報を登録する
        # twitter
        if ( $auth_type eq 'twitter' ) {
            my $res = $oauth_consumer->request(
                method => 'GET',
                url    => 'http://api.twitter.com/1/account/verify_credentials.json',
                token  => $access_token,
                params => {
                    include_entities => 0,
                    skip_status      => 1,
                },
            );

            # 200
            if ( $res->code eq '200' ) {
                my $user = decode_json( $res->decoded_content );
                my $m_user = $c->model('user');
                my $up = $m_user->update(
                    service_type    => 'twitter',
                    service_user_id => $user->{id},
                    nickname        => $user->{screen_name},
                );
                $session->set( my_id => $up->user_id );
            }
            # non-200
            else {
            }
        }
    }

    $c->redirect( $req->base . 'home/' );
}


sub logout {
    my ($class, $c) = @_;
    $c->session->expire;
    $c->redirect('/');
}



#
# utils
#
sub _new_oauth_consumer {
    args_pos (
        my $conf => { isa => 'HashRef', default => +{} },
    );
    my $ret = OAuth::Lite::Consumer->new(
        map {
            ( $_, $conf->{$_} );
        } qw/consumer_key
             consumer_secret
             request_token_path
             access_token_path
             authorize_path
            /,
    );
    return $ret;
}

1;

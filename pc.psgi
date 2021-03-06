use strict;
use utf8;
use File::Spec;
use File::Basename;
use lib File::Spec->catdir(dirname(__FILE__), 'extlib', 'lib', 'perl5');
use lib File::Spec->catdir(dirname(__FILE__), 'lib');
use Plack::Builder;

use GTDme::PC;
use Plack::App::File;
use Plack::Util;
use Plack::Session::Store::DBI;
use Plack::Session::State::Cookie;
use DBI;
use Scope::Container;

my $basedir = File::Spec->rel2abs(dirname(__FILE__));
my $db_config = GTDme->config->{DBI} || die "Missing configuration for DBI";
builder {
    enable 'Plack::Middleware::Static',
        path => qr{^(?:/robots\.txt|/favicon\.ico)$},
        root => File::Spec->catdir(dirname(__FILE__), 'static', 'pc');
    enable 'Plack::Middleware::ReverseProxy';
    enable 'Plack::Middleware::Scope::Container';
    enable 'Plack::Middleware::Log::Minimal';
    enable 'Plack::Middleware::Session',
        store => Plack::Session::Store::DBI->new(
            get_dbh => sub {
                if ( my $dbh = scope_container('dbh') ) {
                    return $dbh;
                } else {
                    my $dbh = DBI->connect( @$db_config )
                        or die $DBI::errstr;
                    scope_container('dbh', $dbh);
                    return $dbh;
                }
            }
        ),
        state => Plack::Session::State::Cookie->new(
            httponly => 1,
        );

    mount '/static/' => Plack::App::File->new(root => File::Spec->catdir($basedir, 'static', 'pc'));
    mount '/' => GTDme::PC->to_app();
};

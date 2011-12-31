use strict;
use utf8;
use File::Spec;
use File::Basename;
use lib File::Spec->catdir(dirname(__FILE__), 'extlib', 'lib', 'perl5');
use lib File::Spec->catdir(dirname(__FILE__), 'lib');
use Plack::Builder;

use GTDme::PC;
use Plack::Util;
use Plack::Builder;

builder {
    mount '/admin/' => Plack::Util::load_psgi('admin.psgi');
    mount '/api/'   => Plack::Util::load_psgi('api.psgi');
    mount '/'       => Plack::Util::load_psgi('pc.psgi');
};
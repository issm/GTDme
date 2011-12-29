use strict;
use warnings;
use Test::More;

use_ok $_ for qw(
    GTDme
    GTDme::PC
    GTDme::PC::Dispatcher
    GTDme::PC::C::Root
    GTDme::PC::C::Account
    GTDme::Admin
    GTDme::Admin::Dispatcher
    GTDme::Admin::C::Root
);

done_testing;

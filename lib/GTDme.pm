package GTDme;
use strict;
use warnings;
use utf8;
use parent qw/Amon2/;
our $VERSION='0.01';
use 5.008001;

#__PACKAGE__->load_plugin(qw/DBI/);
__PACKAGE__->load_plugins(qw/
    DBI
    Teng
    Model
    Stash
/);

1;

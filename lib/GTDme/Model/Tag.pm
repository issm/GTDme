package GTDme::Model::Tag;
use strict;
use warnings;
use utf8;
use parent 'GTDme::Model::Base';
use Smart::Args;
use Encode;
use Data::Recursive::Encode;
use Time::Piece;
use Data::Dumper;


sub search {
    args (
        my $self,
        my $id              => { isa => 'Int', optional => 1 },
        my $user_id         => { isa => 'Int' },
        my $name            => { isa => 'Str|Undef', optional => 1 },
        my $item_project_id => { isa => 'Int', optional => 1 },
        my $item_belongs    => { isa => 'Str', optional => 1 },

        my $with_count      => { isa => 'Int', default => 0 },
        my $with_iterator   => { isa => 'Int', default => 0 },
    );
    my $ret = { list => [], count => 0 };

    my $db = $self->c->db;
    my ($rs, $itr, @select, @where, @join, @order);

    ### select
    @select = (
        [qw/tag_id -t -/, sub { "DISTINCT($_[1])" }],
        [qw/name   -t/],
    );

    ### where
    @where = (
        [qw/user_id -t/] => $user_id,
    );
    push @where, [qw/tag_id -t/] => $id    if defined $id;
    push @where, [qw/name   -t/] => $name  if defined $name;

    push @where, [qw/project_id -i/] => $item_project_id  if defined $item_project_id;
    push @where, [qw/belongs -i/]    => $item_belongs     if defined $item_belongs;


    ### join
    if ( defined $item_project_id  ||  defined $item_belongs ) {
        push @join, (
            [qw/tag t/] => [
                {
                    table     => [qw/item_2_tag i2t/],
                    type      => 'inner',
                    condition => 'i2t.tag_id = t.tag_id',
                },
            ],
            [qw/item_2_tag i2t/] => [
                {
                    table     => [qw/item i/],
                    type      => 'inner',
                    condition => 'i.item_id = i2t.item_id',
                },
            ],
        );
    }

    my %params_rs = (
        select => \@select,
        where  => \@where,
    );
    if ( @join ) { $params_rs{join} = \@join }
    else         { $params_rs{from} = $db->table(qw/tag t/) }

    $rs = $db->resultset(%params_rs);

    ### group

    ### order
    $rs->add_order_by( $db->column(qw/t_up -t/), 'desc' );


    $itr = $db->search_from_resultset($rs);
    $itr->suppress_object_creation(1);

    if ( $with_count ) {
        $ret->{count} = $db->count_from_resultset( $rs, [qw/tag_id -t/] );
    }

    if ( $with_iterator ) {
        $ret->{iterator} = $itr;
        return $ret;
    }

    while ( my $row = $itr->next ) {
        my $data = Data::Recursive::Encode->decode_utf8( $row );
        push @{$ret->{list}}, $data;
    }

    return $ret;
}


1;

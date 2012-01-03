package GTDme::Model::Project;
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
        my $id      => { isa => 'Int|Undef', optional => 1 },
        my $user_id => { isa => 'Int' },
        my $code    => { isa => 'Str|Undef', optional => 1 },
        my $name    => { isa => 'Str|Undef', optional => 1 },

        my $done          => { isa => 'Int', default => 0 },
        my $undone        => { isa => 'Int', default => 0 },

        my $item_belongs  => { isa => 'Str', optional => 1 },

        my $order_by_ord  => { isa => 'Str', optional => 1 },

        my $with_count    => { isa => 'Int', default => 0 },
        my $with_iterator => { isa => 'Int', default => 0 },
    );
    my $ret = { list => [], count => 0 };
    my $db = $self->c->db;

    my ($rs, $itr, @select, @where, @join, @order);

    ### select
    @select = (
        [qw/project_id  -pr -/, sub { "DISTINCT $_[1]" }],
        [qw/code        -pr/],
        [qw/name        -pr/],
        [qw/description -pr/],
        [qw/t_done      -pr is_done/, sub { "IF($_[1] > 0, 1, 0)" }],
    );

    ### where
    @where = (
        [qw/user_id -pr/] => $user_id,
        [qw/flg_del -pr/] => 0,
    );
    push @where, [qw/project_id -pr/] => $id    if defined $id;
    push @where, [qw/code       -pr/] => $code  if defined $code;
    push @where, [qw/name       -pr/] => $name  if defined $name;

    if ( defined $item_belongs ) {
        push @where, (
            [qw/belongs -i/] => $item_belongs,
        );
    }

    ### join
    @join = (
    );
    if ( defined $item_belongs ) {
        push @join, (
            [qw/project pr/] => [
                {
                    table     => [qw/item i/],
                    type      => 'right',
                    condition => 'i.project_id = pr.project_id',
                },
            ],
        );
    }


    $rs = $db->resultset(
        select => \@select,
        where  => \@where,
        @join
            ? ( join => \@join )
            : ( from => $db->table(qw/project pr/) ),
    );


    ### group

    ### order
    if ( defined $order_by_ord  &&  $order_by_ord =~ /^(?:asc|desc)$/i ) {
        $rs->add_order_by( $db->column(qw/ord -pr/) => $order_by_ord );
    }

    $itr = $db->search_from_resultset($rs);
    $itr->suppress_object_creation(1);

    if ( $with_count ) {
        $ret->{count} = $db->count_from_resultset( $rs, [qw/project_id -pr/] );
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


sub update {
    args (
        my $self,
        my $id          => { isa => 'Int', optional => 1 },
        my $user_id     => { isa => 'Int' },
        my $name        => { isa => 'Str', optional => 1 },
        my $code        => { isa => 'Str', optional => 1 },
        my $description => { isa => 'Str', optional => 1 },
    );
    my $ret;
    my $db = $self->c->db;
    my $time = time;
    my $row;
    my $content_options = [];

    my $table = $db->table('project');

    if ( defined $id ) {
        $row = $db->single(
            $table,
            { project_id => $id, user_id => $user_id, flg_del => 0 },
        );
    }

    my %params_up = do {
        my %h = (
            user_id => $user_id,
            t_up    => $time,
        );
        $h{name}        = $name         if defined $name;
        $h{code}        = $code         if defined $code;
        $h{description} = $description  if defined $description;
        %h;
    };

    my $txn = $db->txn_scope;

    ### update
    if ( defined $row ) {
        $row->update( Data::Recursive::Encode->encode_utf8(\%params_up) );
    }
    ### insert
    else {
        $row = $db->insert(
            $table,
            Data::Recursive::Encode->encode_utf8({
                %params_up,
                t_add => $time,
            }),
        );
    }

    $txn->commit;

    $ret = Data::Recursive::Encode->decode_utf8( $row->get_columns );
    return $ret;
}



sub update_order {
    args (
        my $self,
        my $id      => { isa => 'Int' },
        my $id_prev => { isa => 'Int|Undef' },
        my $id_next => { isa => 'Int|Undef' },
        my $user_id => { isa => 'Int' },
    );
    my $ret;

    my $db = $self->c->db;
    my $table = $db->table('project');

    $db->suppress_row_objects(1);

    my ($row, $row_prev, $row_next);
    $row      = $db->single($table, { project_id => $id, user_id => $user_id });
    $row_prev = $db->single($table, { project_id => $id_prev, user_id => $user_id })  if defined $id_prev;
    $row_next = $db->single($table, { project_id => $id_next, user_id => $user_id })  if defined $id_next;
    ## die  if not exists

    my ($ord, $ord_prev, $ord_next) = (
        $row->{ord},
        ( defined $row_prev ? $row_prev->{ord} : 0 ),
        ( defined $row_next ? $row_next->{ord} : 0 ),
    );

    my ($is_up, $is_down);
    $is_up   = 1  if defined $row_prev  &&  $ord < $ord_prev;
    $is_down = 1  if defined $row_next  &&  $ord > $ord_next;

    my $txn = $db->txn_scope;

    if ( $is_up ) {
        my $itr = $db->search_by_sql( << "        ...", [ $ord + 1, $ord_prev ] );
SELECT project_id, ord
  FROM $table
  WHERE ord BETWEEN ? AND ?
    ORDER BY ord ASC
        ...
        $itr->suppress_object_creation(0);
        while ( my $_row = $itr->next ) {
            $_row->update({ ord => $_row->ord - 1 });
        }

        $db->update(
            $table,
            { ord => $ord_prev },
            { project_id => $id },
        );
    }
    elsif ( $is_down ) {
        my $itr = $db->search_by_sql( << "        ...", [ $ord_next, $ord - 1 ] );
SELECT project_id, ord
  FROM $table
  WHERE ord BETWEEN ? AND ?
    ORDER BY ord ASC
        ...
        $itr->suppress_object_creation(0);
        while ( my $_row = $itr->next ) {
            $_row->update({ ord => $_row->ord + 1 });
        }

        $db->update(
            $table,
            { ord => $ord_next },
            { project_id => $id },
        );
    }

    $txn->commit;

    return $ret;
}





1;

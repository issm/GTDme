package GTDme::Model::Item;
use strict;
use warnings;
use utf8;
use parent 'GTDme::Model::Base';
use Data::Dumper;
use Smart::Args;
use Encode;
use Data::Recursive::Encode;
use List::MoreUtils qw/first_index/;
use Time::Piece;

my $wday_map = {qw/
    sun 1  mon 2  tue 3  wed 4  thu 5  fri 6  sat 7
    日  1 月   2  火  3  水  4  木  5  金  6  土  7
/};


sub search {
    args (
        my $self,

        my $id            => { isa => 'Int', optional => 1 },
        my $user_id       => { isa => 'Int' },
        my $project_id    => { isa => 'Int', optional => 1 },
        my $belongs       => { isa => 'Str', optional => 1 },
        my $tag           => { isa => 'Str', optional => 1 },

        my $is_action     => { isa => 'Int', optional => 1 },

        my $done          => { isa => 'Int', default => 0 },
        my $undone        => { isa => 'Int', default => 0 },

        my $with_datetime => { isa => 'Int', default => 0 },
        my $with_project  => { isa => 'Int', default => 0 },
        my $with_tag      => { isa => 'Int', default => 0 },

        my $order_by_ord  => { isa => 'Str', optional => 1 },
        my $order_by_add  => { isa => 'Str', optional => 1 },

        my $with_count    => { isa => 'Int', default => 0 },
        my $with_iterator => { isa => 'Int', default => 0 },
    );
    my $ret = { count => 0, list => [], iterator => undef };
    my $db = $self->c->db;
    my ($rs, @select, @where, @join, $itr);
    my @ids ;


    if ( defined $tag ) {
        @ids = $self->_ids_in_tag(
            user_id    => $user_id,
            tag        => $tag,
            project_id => $project_id,
            belongs    => $belongs,
        );
    }


    ### select
    @select = (
        [qw/item_id     -i -/, sub { "DISTINCT $_[1]" }],
        [qw/user_id     -i/],
        [qw/project_id  -i/],
        [qw/raw_text    -i/],
        [qw/content     -i/],
        [qw/step        -i/],
        [qw/step_attain -i/],
        [qw/step_inc    -i/],
        [qw/step_attain -i rate_attain/, sub {
             my $c0 = $_[1];
             my $c1 = $db->column(qw/step -i/);
             "COALESCE( 100 * $c1 / $c0, 0 )";
         }],
        [qw/belongs     -i/],
        [qw/t_done      -i is_done/, sub { "IF($_[1] > 0, 1, 0)" }],

        [qw/t_start -i_opt option_t_start/],
        [qw/t_end   -i_opt option_t_end/],
        [qw/wday    -i_opt option_wday/],
        [qw/mday    -i_opt option_mday/],
        [qw/mwday   -i_opt option_mwday/],

        [qw/t_start -i_opt option_datetime_start/, sub { "DATE_FORMAT( FROM_UNIXTIME($_[1]), '%Y-%m-%d %H:%i' )" }],
        [qw/t_end   -i_opt option_datetime_end/,   sub { "DATE_FORMAT( FROM_UNIXTIME($_[1]), '%Y-%m-%d %H:%i' )" }],
    );
    if ( $with_datetime ) {
        push @select, (
            [qw/t_add   -i datetime_add/,  sub { "DATE_FORMAT( FROM_UNIXTIME($_[1]), '%Y-%m-%d %H:%i' )"}],
            [qw/t_up    -i datetime_up/,   sub { "DATE_FORMAT( FROM_UNIXTIME($_[1]), '%Y-%m-%d %H:%i' )"}],
            [qw/t_done  -i datetime_done/, sub { "DATE_FORMAT( FROM_UNIXTIME($_[1]), '%Y-%m-%d %H:%i' )"}],
        );
    }
    if ( $with_project ) {
        push @select, (
            [qw/name        -pr project_name/],
            [qw/code        -pr project_code/],
            [qw/description -pr project_description/]
        );
    }
    if ( $with_tag ) {
        push @select, (
            [qw/tag_id -t tag_ids/,   sub { "COALESCE( GROUP_CONCAT($_[1] SEPARATOR '::'), '' )" }],
            [qw/name   -t tag_names/, sub { "COALESCE( GROUP_CONCAT($_[1] SEPARATOR '::'), '' )" }],
        );
    }

    ### where
    @where = (
        [qw/user_id -i/] => $user_id,
        [qw/flg_del -i/] => 0,
    );

    if    ( defined $id ) { push @where, [qw/item_id -i/] => $id }
    elsif ( @ids )        { push @where, [qw/item_id -i/] => \@ids }

    if ( defined $project_id ) { push @where, [qw/project_id -i/] => $project_id }
    if ( defined $belongs ) {
        # calendar_unclassified, calendar_theday, calendar_weekly, calendar_monthly
        if ( my ($calendar_class) = $belongs =~ /calendar_(unclassified|theday|weekly|monthly)/ ) {
            push @where, [qw/belongs -i/] => 'calendar';
            if ( $calendar_class eq 'theday' ) {
                push @where, (
                    [qw/t_start -i_opt/] => { '>' => 0 },
                );
            }
            elsif ( $calendar_class eq 'weekly' ) {
                push @where, (
                    [qw/wday -i_opt/] => { '>' => 0 },
                );
            }
            elsif ( $calendar_class eq 'monthly' ) {
                push @where, (
                    # i_opt.mday > 0 OR i_opt.mwday > 0
                    [qw/mday -i_opt -/, sub {
                         my $c0 = $_[1];
                         my $c1 = $db->column(qw/mwday -i_opt/);
                         "$c0 + $c1";
                     }] => { '>' => 0 },
                );
            }
            else {  # unclassified
                push @where, (
                    [qw/t_start -i_opt/] => 0,
                    [qw/t_end   -i_opt/] => 0,
                    [qw/wday    -i_opt/] => 0,
                    [qw/mday    -i_opt/] => 0,
                    [qw/mwday   -i_opt/] => 0,
                );
            }
        }
        else {
            push @where, [qw/belongs -i/] => $belongs;
        }
    }

    if ( defined $is_action ) {
        push @where, [qw/t_act -i/] => ( $is_action ? { '>' => 0 } : 0 );
    }

    if ( $done )   { push @where, [qw/t_done -i/] => { '>' => 0 } }
    if ( $undone ) { push @where, [qw/t_done -i/] => 0 }

    ### join
    @join = (
        [qw/item i/] => [
            {
                table     => [qw/project pr/],
                type      => 'left',
                condition => 'pr.project_id = i.project_id',
            },
            {
                table     => [qw/item_options i_opt/],
                type      => 'left',
                condition => 'i_opt.item_id = i.item_id',
            },
        ],
    );
    # with tag
    if ( $with_tag ) {
        push @join, (
            [qw/item i/] => [
                {
                    table     => [qw/item_2_tag i2t/],
                    type      => 'left',
                    condition => 'i2t.item_id = i.item_id',
                },
            ],
            [qw/item_2_tag i2t/] => [
                {
                    table     => [qw/tag t/],
                    type      => 'left',
                    condition => 't.tag_id = i2t.tag_id',
                },
            ],
        );
    }

    $rs = $db->resultset(
        select => \@select,
        where  => \@where,
        join   => \@join,
    );

    ### group
    if ( defined $with_tag ) {
        $rs->add_group_by( $db->column(qw/item_id -i/) );
    }

    ### order
    if ( defined $order_by_ord  &&  $order_by_ord =~ /^(?:asc|desc)$/i ) {
        $rs->add_order_by( $db->column(qw/ord -i/) => $order_by_ord );
    }
    if ( defined $order_by_add  &&  $order_by_add =~ /^(?:asc|desc)$/i ) {
        $rs->add_order_by( $db->column(qw/t_add -i/) => $order_by_add );
    }

    if ( defined $belongs ) {
        if ( $belongs eq 'calendar_theday' ) {
            $rs->add_order_by( $db->column(qw/t_start -i_opt/) => 'asc' );
        }
        if ( $belongs eq 'calendar_weekly' ) {
            $rs->add_order_by( $db->column(qw/wday -i_opt/) => 'asc' );
        }
        if ( $belongs eq 'calendar_monthly' ) {
            $rs
                ->add_order_by( $db->column(qw/mday  -i_opt/) => 'asc' )
                ->add_order_by( $db->column(qw/mwday -i_opt/) => 'asc' )
            ;
        }
    }


    if ( $with_count ) {
        $ret->{count} = $db->count_from_resultset( $rs, [qw/item_id -i/] );
    }

    $itr = $db->search_from_resultset($rs);
    $itr->suppress_object_creation(1);

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

sub _ids_in_tag {
    args (
        my $self,
        my $user_id    => { isa => 'Int' },
        my $tag        => { isa => 'Str' },
        my $project_id => { isa => 'Undef|Int', optional => 1 },
        my $belongs    => { isa => 'Undef|Str', optional => 1 },
    );
    my @ret;
    my $db = $self->c->db;
    my ($rs, $itr, @where, @join);

    ### where
    @where = (
        [qw/user_id -t/] => $user_id,
        [qw/name    -t/] => $tag,
    );
    push @where, [qw/project_id -i/] => $project_id  if defined $project_id;
    # same as in ->search
    if ( defined $belongs ) {
        # calendar_unclassified, calendar_theday, calendar_weekly, calendar_monthly
        if ( my ($calendar_class) = $belongs =~ /calendar_(unclassified|theday|weekly|monthly)/ ) {
            push @where, [qw/belongs -i/] => 'calendar';
            if ( $calendar_class eq 'theday' ) {
                push @where, (
                    [qw/t_start -i_opt/] => { '>' => 0 },
                );
            }
            elsif ( $calendar_class eq 'weekly' ) {
                push @where, (
                    [qw/wday -i_opt/] => { '>' => 0 },
                );
            }
            elsif ( $calendar_class eq 'monthly' ) {
                push @where, (
                    # i_opt.mday > 0 OR i_opt.mwday > 0
                    [qw/mday -i_opt -/, sub {
                         my $c0 = $_[1];
                         my $c1 = $db->column(qw/mwday -i_opt/);
                         "$c0 + $c1";
                     }] => { '>' => 0 },
                );
            }
            else {  # unclassified
                push @where, (
                    [qw/t_start -i_opt/] => 0,
                    [qw/t_end   -i_opt/] => 0,
                    [qw/wday    -i_opt/] => 0,
                    [qw/mday    -i_opt/] => 0,
                    [qw/mwday   -i_opt/] => 0,
                );
            }
        }
        else {
            push @where, [qw/belongs -i/] => $belongs;
        }
    }


    @join = (
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
    if ( defined $belongs ) {
        push @join, (
            [qw/item i/] => [
                {
                    table     => [qw/item_options i_opt/],
                    type      => 'left',
                    condition => 'i_opt.item_id = i.item_id',
                },
            ],
        );
    }



    $rs = $db->resultset(
        select => [
            [qw/item_id -i2t/],
        ],
        where => \@where,
        join  => \@join,
    );

    $itr = $db->search_from_resultset($rs);
    $itr->suppress_object_creation(1);
    while ( my $row = $itr->next ) {
        push @ret, $row->{item_id};
    }

    return @ret;
}


sub update {
    args (
        my $self,
        my $id          => { isa => 'Int', optional => 1 },
        my $user_id     => { isa => 'Int' },
        my $project_id  => { isa => 'Int', optional => 1 },
        my $belongs     => { isa => 'Str', optional => 1 },
        my $content     => { isa => 'Str', optional => 1 },
        my $step_attain => { isa => 'Str', optional => 1 },
    );
    my $ret;
    my $db = $self->c->db;
    my $time = time;
    my $row;
    my $content_options = [];

    if ( defined $id ) {
        $row = $db->single(
            $db->table('item'),
            { item_id => $id, user_id => $user_id, flg_del => 0 },
        );
    }

    my %params_up = do {
        my %h = (
            user_id => $user_id,
            t_up    => $time,
        );
        $h{project_id}  = $project_id   if defined $project_id;
        $h{content}     = $content      if defined $content;
        $h{belongs}     = $belongs      if defined $belongs;
        $h{step_attain} = $step_attain  if defined $project_id;
        $h{t_act}       = 0             if defined $belongs  &&  $belongs eq 'trash';
        %h;
    };
    if ( defined $params_up{content} ) {
        $params_up{raw_text} = $params_up{content};

        ( $params_up{content}, $content_options ) = $self->_split_content_options(text => $content);
    }

    my $txn = $db->txn_scope;

    # update
    if ( $row ) {
        $row->update( Data::Recursive::Encode->encode_utf8(\%params_up) );
    }
    # insert
    else {
        $row = $db->insert(
            $db->table('item'),
            Data::Recursive::Encode->encode_utf8({
                %params_up,
                t_add => $time,
            }),
        );
    }

    # update content options (if needed)
    if ( defined $params_up{content} ) {
        $self->_update_content_options(
            id      => $row->item_id,
            user_id => $user_id,
            options => $content_options,
        );
    }

    $txn->commit;

    $ret = Data::Recursive::Encode->decode_utf8( $row->get_columns );
    return $ret;
}


sub update_order {
    args (
        my $self,
        my $id         => { isa => 'Int' },
        my $id_prev    => { isa => 'Int|Undef' },
        my $id_next    => { isa => 'Int|Undef' },
        my $user_id    => { isa => 'Int' },
        my $belongs    => { isa => 'Str|Undef', optional => 1 },
        my $project_id => { isa => 'Int|Undef', optional => 1 },
        my $tag        => { isa => 'Str|Undef', optional => 1 },
    );
    my $ret;

    my $db = $self->c->db;
    my $table = $db->table('item');

    $self->_uniquifiy_order( user_id => $user_id );

    $db->suppress_row_objects(1);

    my ($row, $row_prev, $row_next);
    $row      = $db->single($table, { user_id => $user_id, item_id => $id });
    $row_prev = $db->single($table, { user_id => $user_id, item_id => $id_prev })  if defined $id_prev;
    $row_next = $db->single($table, { user_id => $user_id, item_id => $id_next })  if defined $id_next;
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

    my ($rs, $itr, @select, @where);
    @select = (
        [qw/item_id/],
        [qw/ord/],
    );
    @where = (
        [qw/user_id/] => $user_id,
    );
    push @where, [qw/belongs/]    => $belongs     if defined $belongs;
    push @where, [qw/project_id/] => $project_id  if defined $project_id;
    if ( defined $tag ) {
        my @_ids = $self->_ids_in_tag(
            user_id    => $user_id,
            tag        => $tag,
            project_id => $project_id,
            belongs    => $belongs,
        );
        push @where, [qw/item_id/] => \@_ids;
    }

    if ( $is_up ) {
        push @where, [qw/ord/] => { between => [ $ord, $ord_prev ] };

        $rs = $db->resultset(
            select => \@select,
            from   => [ [qw/item/] ],
            where  => \@where,
        );
        $rs->add_order_by( $db->column(qw/ord/) => 'asc' );

        $itr = $db->search_from_resultset($rs);
        $itr->suppress_object_creation(1);

        my (@_id, @_ord);
        while ( my $_row = $itr->next ) {
            push @_id,  $_row->{item_id};
            push @_ord, $_row->{ord};
        }
        unshift @_ord, pop @_ord;  # 1,2,3,4,5 -> 5,1,2,3,4

        while ( @_id ) {
            my ($_id, $_ord) = ( shift(@_id), shift(@_ord) );
            $db->update(
                $table,
                { ord => $_ord },
                { item_id => $_id },
            );
        }
    }
    elsif ( $is_down ) {
        push @where, [qw/ord/] => { between => [ $ord_next, $ord ] };

        $rs = $db->resultset(
            select => \@select,
            from   => [ [qw/item/] ],
            where  => \@where,
        );
        $rs->add_order_by( $db->column(qw/ord/) => 'asc' );

        $itr = $db->search_from_resultset($rs);
        $itr->suppress_object_creation(1);

        my (@_id, @_ord);
        while ( my $_row = $itr->next ) {
            push @_id,  $_row->{item_id};
            push @_ord, $_row->{ord};
        }
        push @_ord, shift @_ord;  # 1,2,3,4,5 -> 2,3,4,5,1

        while ( @_id ) {
            my ($_id, $_ord) = ( shift(@_id), shift(@_ord) );
            $db->update(
                $table,
                { ord => $_ord },
                { item_id => $_id },
            );
        }
    }

    $txn->commit;

    return $ret;
}

sub _uniquifiy_order {
    args (
        my $self,
        my $user_id => { isa => 'Int' },
    );
    my $db = $self->c->db;
    my $table = $db->table('item');

    my $is_unique;
    my $itr_is_unique = $db->search_by_sql(
        << "        ...",
SELECT IF(
  ( SELECT COUNT(ord)          FROM $table WHERE flg_del = 0 AND user_id = ? ) =
  ( SELECT COUNT(DISTINCT ord) FROM $table WHERE flg_del = 0 AND user_id = ? ),
  1, 0
) is_unique
        ...
        [ $user_id, $user_id ],
    );
    $itr_is_unique->suppress_object_creation(1);
    $is_unique = $itr_is_unique->next->{is_unique};
    return 0  if $is_unique;

    my $itr = $db->search_by_sql(
        << "        ...",
SELECT item_id, ord
  FROM $table
  WHERE flg_del = 0
    AND user_id = ?
  ORDER BY ord ASC, item_id ASC
        ...
        [ $user_id ],
    );

    my $txn = $db->txn_scope;

    my $order = 0;
    while ( my $row = $itr->next ) {
        $row->update({ ord => ++$order });
    }

    $txn->commit;
    return 1;
}


sub increment_step {
    args (
        my $self,
        my $id      => { isa => 'Int' },
        my $user_id => { isa => 'Int' },
        my $n       => { isa => 'Int', default => 1 },
    );
    my $ret;
    my $db = $self->c->db;
    my $time = time;
    my $row = $db->single(
        $db->table('item'),
        { item_id => $id, user_id => $user_id, flg_del => 0 },
    );
    if ( defined $row ) {
        my $n_to = $row->step + $n;
        $n_to = 0  if $n_to < 0;
        $row->update(Data::Recursive::Encode->encode_utf8({
            step => $n_to,
            t_up => $time,
        }));
        $ret = Data::Recursive::Encode->decode_utf8( $row->get_columns );
    }
    return $ret;
}


sub mark_done {
    args (
        my $self,
        my $id      => { isa => 'Int' },
        my $user_id => { isa => 'Int' },
        my $revert  => { isa => 'Int', default => 0 },
    );
    my $ret;
    my $db = $self->c->db;
    my $time = time;
    my $row = $db->single(
        $db->table('item'),
        { item_id => $id, user_id => $user_id, flg_del => 0 },
    );
    if ( defined $row ) {
        my %params_up = do {
            my %h = (
                t_up => $time,
            );

            my $step_inc = $row->step_inc;

            my $row_opt = $db->single(
                $db->table('item_options'),
                { item_id => $row->item_id },
            );

            ### weekly or monthly item
            if (
                defined $row_opt  &&
                ( $row_opt->wday  ||  $row_opt->mday  ||  $row_opt->mwday )
            ) {
                $h{t_act} = 0;
                $h{step}  = $row->step + $step_inc  if $step_inc;
            }
            ### $step_inc != 0
            elsif ( $step_inc ) {
                $h{t_act} = 0;
                $h{step}  = $row->step + $step_inc;
            }
            ###
            else {
                $h{t_done} = $time;
            }
            $h{t_done} = 0  if $revert;

            %h;
        };

        $row->update( Data::Recursive::Encode->encode_utf8(\%params_up) );
        $ret = Data::Recursive::Encode->decode_utf8( $row->get_columns );
    }
    return $ret;
}


sub _split_content_options {
    args (
        my $self,
        my $text => { isa => 'Str' },
    );
    my ($content, $opts) = ($text, []);

    my @token = split /[ \n]+/, $text;
    my $conf = $self->c->config->{re_item_content_options};

    my $re_opts = qr/^(?:
          $conf->{tag} | $conf->{datetime}
        | $conf->{datetime} [-\.]{2} $conf->{datetime}  # datetime "range"
        | $conf->{weekly}
        | $conf->{monthly_date} | $conf->{monthly_wday}
        | $conf->{step}
        | $conf->{step_inc}
    )$/x;

    my $i_content = first_index { $_ !~ $re_opts } @token;

    if ( $i_content >= 0 ) {
        push @$opts, (shift @token)  for 0 .. ($i_content - 1);
    }
    else {
        push @$opts, (shift @token)  while @token;
    }

    $content = join ' ', @token;

    return wantarray
        ? ( $content, $self->_parse_content_options(options => $opts) )
        : $content
    ;
}

sub _parse_content_options {
    args (
        my $self,
        my $options => { isa => 'ArrayRef', default => [] },
    );
    my $ret = {};

    my $conf = $self->c->config->{re_item_content_options};

    my (@tag, @datetime, @weekly, @monthly_date, @monthly_wday, @step, @step_inc);

    while ( my $i = shift @$options ) {
        # tag
        if ( my ($a) = $i =~ qr/^$conf->{tag}$/ ) {
            push @tag, $a;
            next;
        }
        # datetime
        elsif ( $i =~ qr/^$conf->{datetime}$/ ) {
            (my $a = $i) =~ s/[-: T]//g;
            my $l = length($a);

            my $t;
            if ( $l == 8 ) {  # yyyymmdd
                $t = localtime->strptime($a, '%Y%m%d');
            }
            elsif ( $l == 12 ) {  # yyyymmddhhmm
                $t = localtime->strptime($a, '%Y%m%d%H%M');
            }
            elsif ( $l == 14 ) {  # yyyymmddhhmmss
                $t = localtime->strptime($a, '%Y%m%d%H%M%S');
            }

            if ( defined $t ) {
                push @datetime, $t;
                next;
            }
        }
        # datetime range
        elsif ( my ($d1, $d2) = $i =~ qr/^ ($conf->{datetime}) [-\.]{2} ($conf->{datetime}) $/x ) {
            unshift @$options, $d1, $d2;
        }
        # weekly
        elsif ( my ($w) = $i =~ qr/^$conf->{weekly}$/ ) {
            push @weekly, $w;
            next;
        }
        # monthly_date
        elsif ( my ($md) = $i =~ qr/^$conf->{monthly_date}$/ ) {
            push @monthly_date, $md;
            next;
        }
        # monthly_wday
        elsif ( my ($mw) = $i =~ qr/^$conf->{monthly_wday}$/ ) {
            push @monthly_wday, $mw;
            next;
        }
        # step
        elsif ( my ($step) = $i =~ qr/^$conf->{step}$/ ) {
            push @step, $step;
            next;
        }
        # step_inc
        elsif ( my ($step_inc) = $i =~ qr/^$conf->{step_inc}$/ ) {
            push @step_inc, $step_inc;
            next;
        }
    }

    $ret = +{
        _count       => scalar( map $_, @tag, @datetime, @weekly, @monthly_date, @monthly_wday ),
        tag          => \@tag,
        datetime     => \@datetime,
        weekly       => \@weekly,
        monthly_date => \@monthly_date,
        monthly_wday => \@monthly_wday,
        step         => \@step,
        step_inc     => \@step_inc,
    };
}

sub _update_content_options {
    args (
        my $self,
        my $id      => { isa => 'Int' },
        my $user_id => { isa => 'Int' },
        my $options => { isa => 'HashRef', default => [] },
    );
    my $db = $self->c->db;
    my $re = $self->c->config->{re};
    my $time = time;

    my (%params_item, %params_item_options);

    ### tag
    # clear old data belongs to item_id == $id
    $db->delete(
        $db->table('item_2_tag'),
        { item_id => $id },
    );

    if ( my @tag = @{$options->{tag}} ) {
        my @rows;

        ### tag
        while ( my $tag = shift @tag ) {
            my $row = $db->single(
                $db->table('tag'),
                { user_id => $user_id, name => $tag },
            );
            unless ( defined $row ) {
                $row = $db->insert(
                    $db->table('tag'),
                    {
                        user_id => $user_id,
                        name    => $tag,
                        t_add   => $time,
                        t_up    => $time,
                    },
                );
            }
            push @rows, $row;
        }

        ### item_2_tag
        # insert new data
        while ( my $row = shift @rows ) {
            $db->insert(
                $db->table('item_2_tag'),
                {
                    item_id => $id,
                    tag_id  => $row->tag_id,
                },
            );
        }
    };

    ### datetime
    {
        @params_item_options{qw/t_start t_end/} = (0, 0);

        if ( my @datetime = @{$options->{datetime}} ) {
            my @d = sort { $a <=> $b } @datetime;
            $params_item_options{t_start} = $d[0]->epoch  if $d[0];
            $params_item_options{t_end}   = $d[1]->epoch  if $d[1];
        }
    };

    ### weekly
    {
        $params_item_options{wday} = 0;
        if ( defined ( my $wday = $options->{weekly}[0] ) ) {
            $params_item_options{wday} = $wday_map->{ lc($wday) } || 0;
        }
    };

    ### monthly_date
    {
        $params_item_options{mday} = 0;
        if ( defined ( my $mday = $options->{monthly_date}[0] ) ) {
            $params_item_options{mday} = $mday;
        }
    };

    ### monthly_wday
    {
        $params_item_options{mwday} = 0;
        if ( defined ( my $mwday = $options->{monthly_wday}[0] ) ) {
            my ($wday, $n) = $mwday =~ /^($re->{wday})(\d)$/;
            $params_item_options{mwday} = $n * 10 + $wday_map->{$wday};
        }
    };

    ### step
    {
        $params_item{step_attain} = 0;
        if ( defined ( my $step = $options->{step}[0] ) ) {
            $params_item{step_attain} = $step;
        }
    };

    ### step_inc
    {
        $params_item{step_inc} = 0;
        if ( defined ( my $step_inc = $options->{step_inc}[0] ) ) {
            $params_item{step_inc} = $step_inc;
        }
    };

    ### update / insert
    my ($row_item, $row_item_options);

    # item
    if ( keys %params_item ) {
        $db->update(
            $db->table('item'),
            \%params_item,
            { item_id => $id },
        );
    }

    # item_options
    $row_item_options = $db->single(
        $db->table('item_options'),
        { item_id => $id },
    );
    if ( defined $row_item_options ) {
        $row_item_options->update( \%params_item_options );
    }
    else {
        $row_item_options = $db->insert(
            $db->table('item_options'),
            {
                item_id => $id,
                %params_item_options,
            },
        );
    }

    return $row_item_options;
}



sub to_action {
    args (
        my $self,
        my $id      => { isa => 'Int' },
        my $user_id => { isa => 'Int' },
        my $belongs => { isa => 'Str' },
    );
    my $ret;
    my $db = $self->c->db;
    my $time = time;

    my $row_item = $db->single(
        $db->table('item'),
        { item_id => $id, user_id => $user_id },
    );
    unless ( defined $row_item ) {
        die;
    }

    my $txn = $db->txn_scope;

    $belongs = 'action'  if $belongs eq 'inbox';

    $row_item->update({
        belongs => $belongs,
        t_act   => $time,
    });

    $txn->commit;

    $ret = Data::Recursive::Encode->decode_utf8( $row_item->get_columns );
    return $ret;
}



sub to_project {
    args (
        my $self,
        my $id      => { isa => 'Int' },
        my $user_id => { isa => 'Int' },
    );
    my $ret;
    my $db = $self->c->db;
    my $time = time;

    my $row_item = $db->single(
        $db->table('item'),
        { item_id => $id, user_id => $user_id },
    );
    unless ( defined $row_item ) {
        die;
    }

    my $txn = $db->txn_scope;

    my $row_project = $db->insert(
        $db->table('project'),
        {
            user_id     => $row_item->user_id,
            name        => $row_item->content,
            # code        => '',
            # description => '',
            ord         => 0,  # make "new project" be first in list
            t_add       => $row_item->t_add,
            t_up        => $row_item->t_up,
        },
    );

    $row_item->update({
        belongs    => 'project',
        project_id => $row_project->project_id,
        flg_del    => 1,
    });

    # タグ情報とかどうする？

    $txn->commit;

    $ret = Data::Recursive::Encode->decode_utf8( $row_item->get_columns );
    return $ret;
}


1;

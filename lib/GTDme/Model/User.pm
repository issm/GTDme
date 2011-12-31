package GTDme::Model::User;
use strict;
use warnings;
use utf8;
use parent 'GTDme::Model::Base';
use Data::Dumper;
use Smart::Args;
use Encode;
use Data::Recursive::Encode;
use String::Random qw/random_regex/;

sub search {
    args (
        my $self,
        my $id              => { isa => 'Int', optional => 1 },
        my $service_type    => { isa => 'Str', optional => 1 },
        my $service_user_id => { isa => 'Int', optional => 1 },
        my $apikey          => { isa => 'Str', optional => 1 },
        my $nickname        => { isa => 'Str', optional => 1 },
    );
    my $ret = { count => 0, list => [] };

    my $db = $self->c->teng;
    my ($rs, $itr, @select, @where);

    # select
    @select = (
        [qw/user_id         -u id/],
        [qw/service_type    -u service_type/],
        [qw/service_user_id -u service_user_id/],
        [qw/apikey          -u apikey/],
        [qw/nickname        -u nickname/],
    );

    # where
    @where = (
        [qw/flg_del -u/] => 0,
    );
    push @where, [qw/user_id -u/] => $id                       if defined $id;
    push @where, [qw/service_type -u/] => $service_type        if defined $service_type;
    push @where, [qw/service_user_id -u/] => $service_user_id  if defined $service_user_id;
    push @where, [qw/apikey -u/] => $apikey                    if defined $apikey;
    push @where, [qw/nickname -u/] => $nickname                if defined $nickname;

    $rs = $db->resultset(
        select => \@select,
        from   => [ [qw/user u/] ],
        where  => \@where,
    );

    # get "count"
    $ret->{count} = $db->count_from_resultset($rs, [qw/user_id -u/]);

    $itr = $db->search_from_resultset($rs);
    $itr->suppress_object_creation(1);

    while ( my $row = $itr->next ) {
        $row = Data::Recursive::Encode->decode_utf8($row);
        push @{ $ret->{list} }, $row;
    }

    return $ret;
}


sub update {
    args (
        my $self,
        my $id              => { isa => 'Int', optional => 1 },
        my $service_type    => { isa => 'Str', optional => 1 },
        my $service_user_id => { isa => 'Str', optional => 1 },
        my $nickname        => { isa => 'Str', optional => 1 },
    );

    my $db = $self->c->teng;
    my $time = time;

    my %cond;
    $cond{user_id} = $id  if defined $id;
    if ( defined $service_type  &&  defined $service_user_id ) {
        @cond{qw/service_type service_user_id/} = ( $service_type, $service_user_id );
    }
    if ( ! keys %cond ) {
        die 'parameter "id" or ( "service_type" and "service_user_id" ) is/are required.';
    }

    my %data_up = (
        t_up => $time,
    );
    $data_up{nickname} = $nickname  if defined $nickname;

    my $row = $db->single( $db->table(qw/user/), \%cond );
    if ( defined $row ) {
        # update
        $row->update( Data::Recursive::Encode->encode_utf8({ %data_up }) );
    } else {
        # insert
        unless ( defined $service_type  &&  defined $service_user_id ) {
            die 'parameter "service_type" and "service_user_id" are required when INSERT.';
        }
        $row = $db->insert(
            $db->table(qw/user/),
            Data::Recursive::Encode->encode_utf8({
                service_type    => $service_type,
                service_user_id => $service_user_id,
                t_add => $time,
                %data_up,
            }),
        );
    }

    return $row;
}

sub add {
    args (
        my $self,
        my $service_type    => { isa => 'Str' },
        my $service_user_id => { isa => 'Str' },
        my $nickname        => { isa => 'Str' },
    );

    return $self->update(
        service_type    => $service_type,
        service_user_id => $service_user_id,
        nickname        => $nickname,
    );
}


sub update_apikey {
    args (
        my $self,
        my $id => { isa => 'Int', optional => 1 },
    );
    my $apikey;
    my $is_apikey_uniq = 0;

    my ( $loop_limit, $loop ) = ( 100, 0 );
    do {
        $apikey = random_regex '[0-9a-zA-Z]{64}';
        $self->search( apikey => $apikey )->{count}  ||  ( $is_apikey_uniq = 1 );
    } until $is_apikey_uniq  ||  ++$loop >= $loop_limit;

    unless ( $is_apikey_uniq ) {
        die '[Model::User::update_apikey] apikey is not unique.';
    }

    my $db = $self->c->teng;
    my $up = $db->update(
        $db->table(qw/user/),
        { apikey => $apikey, t_up => time },
        { user_id => $id },
    );

    unless ( $up ) {
        die '[Model::User::update_apikey] update failed.';
    }

    return $apikey;
}



1;
__END__

=head1 NAME

Nicograph::Model::User -


=head1 SYNOPSIS


=head1 DESCRIPTION


=head1 METHODS

=over 4

=item $user->search(%params): HashRef

=item $user->update(%params): Teng::Row

=item $user->add(%params): Teng::Row

=item $user->update_apikey: Str

generates and updates "API key" which pattern is /^[0-9a-zA-Z]{48}$/.

returns "API key" string whih generated, if update is successful.

=back


=cut
















1;

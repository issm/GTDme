package GTDme::PC::C::Root;
use strict;
use warnings;
use utf8;
use Data::Recursive::Encode;

sub index {
    my ($class, $c, $a) = @_;
    my $my = $c->stash->{my};
    $c->render('index.tx');
}



sub my_index {
    my ($class, $c) = @_;
    $c->stash->{navi_main}{my} = 1;
    $c->render('my/index.tx');
}


sub my_settings {
    my ($class, $c) = @_;
    $c->stash->{navi_main}{my} = 1;
    $c->render('my/settings.tx');
}


sub my_trigger_list {
    my ($class, $c) = @_;
    $c->stash->{navi_main}{my} = 1;
    $c->render('my/trigger_list.tx');
}



sub home_index {
    my ($class, $c, $a) = @_;
    my $my = $c->stash->{my};
    $c->stash->{navi_main}{home} = 1;

    unless ( $c->stash->{is_loggedin} ) {
        return $c->render('home/guest.tx');
    }

    my $tag = Data::Recursive::Encode->decode_utf8( $c->{args}{tag} );

    my %params_search = (
        user_id       => $my->{id},
        belongs       => 'action',
        with_datetime => 1,
        with_tag      => 1,
        order_by_ord  => 'asc',
        order_by_add  => 'asc',
        with_iterator => 1,
    );
    $params_search{tag} = $tag  if defined $tag;

    my $m_item = $c->model('item');
    my $hit_item = $m_item->search(%params_search);

    $c->stash->{tag} = $tag;
    $c->stash->{iterator_item} = $hit_item->{iterator};
    $c->render('home/index.tx');
}



sub inbox_index {
    my ($class, $c) = @_;
    my $req = $c->req;
    my $my = $c->stash->{my};

    unless ( $c->stash->{is_loggedin} ) {
        return $c->render('home/guest.tx');
    }

    my $tag = Data::Recursive::Encode->decode_utf8( $c->{args}{tag} );
    my %params_search = (
        user_id       => $my->{id},
        belongs       => 'inbox',
        undone        => 1,
        with_datetime => 1,
        with_tag      => 1,
        order_by_add  => 'asc',
        with_iterator => 1,
    );
    $params_search{tag} = $tag  if defined $tag;

    my $m_item = $c->model('item');
    my $hit_item = $m_item->search(%params_search);

    $c->stash->{tag} = $tag;
    $c->stash->{iterator_item} = $hit_item->{iterator};
    $c->stash->{navi_main}{inbox} = 1;
    $c->render('inbox/index.tx');
}



sub calendar_index {
    my ($class, $c) = @_;
    $c->stash->{navi_main}{calendar} = 1;
    $c->render('calendar/index.tx');
}


sub calendar_mode {
    my ($class, $c) = @_;
    my $req = $c->req;
    my $my = $c->stash->{my};

    my $mode = $c->{args}{mode};
    my $tag  = Data::Recursive::Encode->decode_utf8( $c->{args}{tag} );

    my %params_search = (
        user_id       => $my->{id},
        belongs       => 'calendar_' . $mode,
        undone        => 1,
        with_datetime => 1,
        with_tag      => 1,
        with_iterator => 1,
    );
    $params_search{tag} = $tag  if defined $tag;

    my $m_item = $c->model('item');
    my $hit_item = $m_item->search(%params_search);

    $c->stash->{mode} = $mode;
    $c->stash->{tag}  = $tag;
    $c->stash->{iterator_item} = $hit_item->{iterator};
    $c->stash->{navi_main}{calendar} = 1;
    $c->render("calendar/${mode}.tx");
}



sub background_index {
    my ($class, $c) = @_;
    my $req = $c->req;
    my $my = $c->stash->{my};

    my $tag  = Data::Recursive::Encode->decode_utf8( $c->{args}{tag} );

    my %params_search = (
        user_id       => $my->{id},
        belongs       => 'background',
        undone        => 1,
        with_datetime => 1,
        with_tag      => 1,
        order_by_ord  => 'asc',
        order_by_add  => 'asc',
        with_iterator => 1,
    );
    $params_search{tag} = $tag  if defined $tag;

    my $m_item = $c->model('item');
    my $hit_item = $m_item->search(%params_search);

    $c->stash->{tag} = $tag;
    $c->stash->{iterator_item} = $hit_item->{iterator};
    $c->stash->{navi_main}{background} = 1;
    $c->render('background/index.tx');
}



sub materials_index {
    my ($class, $c) = @_;
    my $req = $c->req;
    my $my = $c->stash->{my};

    my $tag  = Data::Recursive::Encode->decode_utf8( $c->{args}{tag} );

    my %params_search = (
        user_id       => $my->{id},
        belongs       => 'material',
        undone        => 1,
        with_datetime => 1,
        with_tag      => 1,
        order_by_ord  => 'asc',
        order_by_add  => 'asc',
        with_iterator => 1,
    );
    $params_search{tag} = $tag  if defined $tag;

    my $m_item = $c->model('item');
    my $hit_item = $m_item->search(%params_search);

    $c->stash->{tag} = $tag;
    $c->stash->{iterator_item} = $hit_item->{iterator};
    $c->stash->{navi_main}{materials} = 1;
    $c->render('materials/index.tx');
}



sub someday_index {
    my ($class, $c) = @_;
    my $req   = $c->req;
    my $my    = $c->stash->{my};
    my $tag = Data::Recursive::Encode->decode_utf8( $c->{args}{tag} );

    my %params_search = (
        user_id       => $my->{id},
        belongs       => 'someday',
        undone        => 1,
        with_datetime => 1,
        with_tag      => 1,
        order_by_ord  => 'asc',
        order_by_add  => 'asc',
        with_iterator => 1,
    );
    $params_search{tag} = $tag  if defined $tag;

    my $m_item = $c->model('item');
    my $hit_item = $m_item->search(%params_search);

    $c->stash->{tag} = $tag;
    $c->stash->{iterator_item} = $hit_item->{iterator};
    $c->stash->{navi_main}{someday} = 1;
    $c->render('someday/index.tx');
}



sub projects_index {
    my ($class, $c) = @_;
    $c->stash->{navi_main}{projects} = 1;
    $c->render('projects/index.tx');
}


1;

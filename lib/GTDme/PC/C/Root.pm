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

    my ($m_pr, $m_item, $m_tag) = $c->model(qw/project item tag/);

    my $tag = Data::Recursive::Encode->decode_utf8( $c->{args}{tag} );

    my %params_search_item = (
        undone        => 1,
        user_id       => $my->{id},
        belongs       => 'action',
        with_datetime => 1,
        with_project  => 1,
        with_tag      => 1,
        order_by_ord  => 'asc',
        order_by_add  => 'asc',
        with_iterator => 1,
    );
    $params_search_item{tag} = $tag  if defined $tag;

    my %params_search_tag = (
        user_id       => $my->{id},
        item_belongs  => 'action',
        with_iterator => 1,
    );

    my $hit_project = $m_pr->search(
        user_id       => $my->{id},
        item_belongs  => 'action',
        item_undone   => 1,
        with_iterator => 1,
    );
    my $hit_item = $m_item->search(%params_search_item);
    my $hit_tag  = $m_tag->search(%params_search_tag);

    $c->stash->{tag} = $tag;
    $c->stash->{iterator_project} = $hit_project->{iterator};
    $c->stash->{iterator_item}    = $hit_item->{iterator};
    $c->stash->{iterator_tag}     = $hit_tag->{iterator};
    $c->render('home/index.tx');
}

sub home_index_in_project {
    my ($class, $c, $a) = @_;
    my $my = $c->stash->{my};
    $c->stash->{navi_main}{home} = 1;

    unless ( $c->stash->{is_loggedin} ) {
        return $c->render('home/guest.tx');
    }

    my ($m_pr, $m_item, $m_tag) = $c->model(qw/project item tag/);

    my $project_id = $c->{args}{project_id};

    my %params_search_item = (
        undone        => 1,
        user_id       => $my->{id},
        project_id    => $project_id,
        belongs       => 'action',
        with_datetime => 1,
        with_project  => 1,
        with_tag      => 1,
        order_by_ord  => 'asc',
        order_by_add  => 'asc',
        with_iterator => 1,
    );

    my %params_search_tag = (
        user_id         => $my->{id},
        item_project_id => $project_id,
        item_belongs    => 'action',
        with_iterator   => 1,
    );

    my $project  = $m_pr->search({ id => $project_id, user_id => $my->{id} })->{list}[0];
    my $hit_project = $m_pr->search(
        user_id       => $my->{id},
        item_belongs  => 'action',
        item_undone   => 1,
        with_iterator => 1,
    );
    my $hit_item = $m_item->search(%params_search_item);
    my $hit_tag  = $m_tag->search(%params_search_tag);

    $c->stash->{project}          = $project,
    $c->stash->{iterator_project} = $hit_project->{iterator};
    $c->stash->{iterator_item}    = $hit_item->{iterator};
    $c->stash->{iterator_tag}     = $hit_tag->{iterator};
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

    my ($m_item, $m_tag) = $c->model(qw/item tag/);

    my $tag  = Data::Recursive::Encode->decode_utf8( $c->{args}{tag} );

    my %params_search_item = (
        user_id       => $my->{id},
        belongs       => 'background',
        undone        => 1,
        with_datetime => 1,
        with_tag      => 1,
        order_by_ord  => 'asc',
        order_by_add  => 'asc',
        with_iterator => 1,
    );
    $params_search_item{tag} = $tag  if defined $tag;

    my %params_search_tag = (
        user_id       => $my->{id},
        item_belongs  => 'background',
        with_iterator => 1,
    );

    my $hit_item = $m_item->search(%params_search_item);
    my $hit_tag  = $m_tag->search(%params_search_tag);

    $c->stash->{tag} = $tag;
    $c->stash->{iterator_item} = $hit_item->{iterator};
    $c->stash->{iterator_tag}  = $hit_tag->{iterator};
    $c->stash->{navi_main}{background} = 1;
    $c->render('background/index.tx');
}



sub materials_index {
    my ($class, $c) = @_;
    my $req = $c->req;
    my $my = $c->stash->{my};

    my ($m_item, $m_tag) = $c->model(qw/item tag/);

    my $tag  = Data::Recursive::Encode->decode_utf8( $c->{args}{tag} );

    my %params_search_item = (
        user_id       => $my->{id},
        belongs       => 'material',
        undone        => 1,
        with_datetime => 1,
        with_tag      => 1,
        order_by_ord  => 'asc',
        order_by_add  => 'asc',
        with_iterator => 1,
    );
    $params_search_item{tag} = $tag  if defined $tag;

    my %params_search_tag = (
        user_id       => $my->{id},
        item_belongs  => 'material',
        with_iterator => 1,
    );

    my $hit_item = $m_item->search(%params_search_item);
    my $hit_tag  = $m_tag->search(%params_search_tag);

    $c->stash->{tag} = $tag;
    $c->stash->{iterator_item} = $hit_item->{iterator};
    $c->stash->{iterator_tag}  = $hit_tag->{iterator};
    $c->stash->{navi_main}{materials} = 1;
    $c->render('materials/index.tx');
}



sub someday_index {
    my ($class, $c) = @_;
    my $req   = $c->req;
    my $my    = $c->stash->{my};
    my $tag = Data::Recursive::Encode->decode_utf8( $c->{args}{tag} );

    my ($m_item, $m_tag) = $c->model(qw/item tag/);

    my %params_search_item = (
        user_id       => $my->{id},
        belongs       => 'someday',
        undone        => 1,
        with_datetime => 1,
        with_tag      => 1,
        order_by_ord  => 'asc',
        order_by_add  => 'asc',
        with_iterator => 1,
    );
    $params_search_item{tag} = $tag  if defined $tag;

    my %params_search_tag = (
        user_id       => $my->{id},
        item_belongs  => 'someday',
        with_iterator => 1,
    );

    my $hit_item = $m_item->search(%params_search_item);
    my $hit_tag  = $m_tag->search(%params_search_tag);

    $c->stash->{tag} = $tag;
    $c->stash->{iterator_item} = $hit_item->{iterator};
    $c->stash->{iterator_tag}  = $hit_tag->{iterator};
    $c->stash->{navi_main}{someday} = 1;
    $c->render('someday/index.tx');
}



sub projects_index {
    my ($class, $c) = @_;
    my $req = $c->req;
    my $my  = $c->stash->{my};
    my ($m_pr) = $c->model(qw/project/);

    my %params_search_project = (
        user_id       => $my->{id},
        with_iterator => 1,
        order_by_ord  => 'asc',
    );

    my $hit_project = $m_pr->search(%params_search_project);


    $c->stash->{iterator_project} = $hit_project->{iterator};
    $c->stash->{navi_main}{projects} = 1;
    $c->render('projects/index.tx');
}


sub projects_detail {
    my ($class, $c) = @_;
    my $req = $c->req;
    my $my  = $c->stash->{my};

    my $project_id = $c->{args}{project_id};
    my $tag  = Data::Recursive::Encode->decode_utf8( $c->{args}{tag} );

    my ($m_pr, $m_item, $m_tag) = $c->model(qw/project item tag/);
    my ($hit_project, $hit_item, $hit_tag);

    $hit_project = $m_pr->search(
        id      => $project_id,
        user_id => $my->{id},
    );

    unless ( $hit_project->{list}[0] ) {
        # 404
    }

    my %params_search_item = (
        user_id       => $my->{id},
        project_id    => $project_id,
        belongs       => 'project',
        order_by_ord  => 'asc',
        order_by_add  => 'asc',
        with_tag      => 1,
        with_iterator => 1,
    );
    $params_search_item{tag} = $tag  if defined $tag;

    $hit_item = $m_item->search(%params_search_item);

    $hit_tag = $m_tag->search (
        user_id         => $my->{id},
        item_project_id => $project_id,
        with_iterator   => 1,
    );


    $c->stash->{tag} = $tag;
    $c->stash->{project}       = $hit_project->{list}[0];
    $c->stash->{iterator_item} = $hit_item->{iterator};
    $c->stash->{iterator_tag}  = $hit_tag->{iterator};
    $c->stash->{navi_main}{projects} = 1;
    $c->render('projects/detail.tx');
}

1;

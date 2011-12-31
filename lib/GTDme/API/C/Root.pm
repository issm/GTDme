package GTDme::API::C::Root;
use strict;
use warnings;
use utf8;
use Encode;
use Try::Tiny;
use Log::Minimal;


sub index {
    my ($class, $c) = @_;

    $c->render_json({ status => 200 });
}



sub item_update {
    my ($class, $c) = @_;
    my $req = $c->req;
    my $my = $c->stash->{my};

    my $item_id    = $req->param('id');
    my $project_id = $req->param('project_id');
    my $content    = $req->param('content');
    my $belongs    = $req->param('belongs');

    my %params_up = (
        user_id => $my->{id},
    );
    $params_up{content}    = decode_utf8($content)  if defined $content;
    $params_up{id}         = $item_id               if defined $item_id;
    $params_up{project_id} = $project_id            if defined $project_id;
    $params_up{belongs}    = $belongs               if defined $belongs;

    my ($data, $status) = ({}, 200);
    try {
        my $m_item = $c->model('item');
        my $up = $m_item->update(%params_up);
        my $item = $m_item->search(
            id            => $up->{item_id},
            user_id       => $my->{id},
            with_datetime => 1,
            with_tag      => 1,
        )->{list}[0];

        ##
        #$item->{tag_names} = [ split '::', $item->{tag_names}
        ##
        $item->{option_wday_name} = $c->config->{wday_name}{$item->{option_wday}} || '';
        ##
        if ( $item->{option_mwday} ) {
            use GTDme::Xslate::Bridge::Functions;
            $item->{option_mwday_name}
                = GTDme::Xslate::Bridge::Functions::parse_mwday($item->{option_mwday});
        };

        $data = {
            item => $item,
        };
    } catch {
        my $msg = shift;

        $data = {
            status => 500,
            error_message => $msg,
        };
        $status = 500;
    };
    $data->{status} = $status;

    my $res = $c->render_json($data);
    $res->status($status || 200);
    return $res;
}


sub item_update_step {
    my ($class, $c) = @_;
    my $req = $c->req;
    my $my = $c->stash->{my};

    my $item_id = $req->param('id');
    my $n       = $req->param('n');

    my ($data, $status) = ({}, 200);
    try {
        my $m_item = $c->model('item');
        my $up = $m_item->increment_step(
            id      => $item_id,
            user_id => $my->{id},
            n       => int($n),
        );
        my $item = $m_item->search(
            id            => $item_id,
            user_id       => $my->{id},
            with_datetime => 1,
            with_tag      => 1,
        )->{list}[0];

        ##
        #$item->{tag_names};
        ##
        $item->{option_wday_name} = $c->config->{wday_name}{$item->{option_wday}} || '';
        ##
        if ( $item->{option_mwday} ) {
            use GTDme::Xslate::Bridge::Functions;
            $item->{option_mwday_name}
                = GTDme::Xslate::Bridge::Functions::parse_mwday($item->{option_mwday});
        };

        $data = {
            item => $item,
        };
    } catch {
        my $msg = shift;
        $data = {
            status        => 500,
            error_message => $msg,
        };
        $status = 500;
    };

    my $res = $c->render_json($data);
    $res->status($status || 200);
    return $res;
}


sub item_update_order {
    my ($class, $c) = @_;
    my $req = $c->req;
    my $my = $c->stash->{my};

    my $item_id      = $req->param('id');
    my $item_id_prev = $req->param('id_prev');
    my $item_id_next = $req->param('id_next');

    my ($data, $status) = ({}, 200);
    try {
        my $m_item = $c->model('item');
        $m_item->update_order(
            id      => $item_id,
            id_prev => $item_id_prev,
            id_next => $item_id_next,
            user_id     => $my->{id},
        );
    } catch {
        my $msg = shift;
        warnf $msg;
        $data = {
            status        => 500,
            error_message => $msg,
        };
        $status = 500;
    };

    my $res = $c->render_json($data);
    $res->status($status || 200);
    return $res;
}


sub item_mark_done {
    my ($class, $c) = @_;
    my $req = $c->req;
    my $my = $c->stash->{my};

    my $item_id = $req->param('id');

    my ($data, $status) = ({}, 200);
    try {
        my $m_item = $c->model('item');
        my $up = $m_item->mark_done(
            id      => $item_id,
            user_id => $my->{id},
        );
        my $item = $m_item->search(
            id            => $item_id,
            user_id       => $my->{id},
            with_datetime => 1,
        )->{list}[0];

        $data = {
            item => $item,
        };
    } catch {
        my $msg = shift;
        $data = {
            status        => 500,
            error_message => $msg,
        };
        $status = 500;
    };
    $data->{status} = $status;

    my $res = $c->render_json($data);
    $res->status($status || 200);
    return $res;
}



1;

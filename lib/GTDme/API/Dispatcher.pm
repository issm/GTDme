package GTDme::API::Dispatcher;
use strict;
use warnings;
use utf8;
use Router::Simple::Declare;
use Mouse::Util qw(get_code_package);
use String::CamelCase qw(decamelize);
use Module::Pluggable::Object;

# define roots here.
my $router = router {
    connect '/' => { controller => 'Root', action => 'index' };

    connect '/item/update'       => { controller => 'Root', action => 'item_update'       }, { method => 'POST' };
    connect '/item/update_step'  => { controller => 'Root', action => 'item_update_step'  }, { method => 'POST' };
    connect '/item/update_order' => { controller => 'Root', action => 'item_update_order' }, { method => 'POST' };
    connect '/item/mark_done'    => { controller => 'Root', action => 'item_mark_done'    }, { method => 'POST' };

    connect '/inbox/post'        => { controller => 'Root', action => 'inbox_post'        }, { method => 'POST' };

    connect '/project/list'         => { controller => 'Root', action => 'project_list'         }, { method => 'GET' };
    connect '/project/update'       => { controller => 'Root', action => 'project_update'       }, { method => 'POST' };
    connect '/project/update_order' => { controller => 'Root', action => 'project_update_order' }, { method => 'POST' };
};

my @controllers = Module::Pluggable::Object->new(
    require     => 1,
    search_path => ['GTDme::API::C'],
)->plugins;

sub dispatch {
    my ($class, $c) = @_;
    my $req = $c->request;
    if (my $p = $router->match($req->env)) {
        my $action = $p->{action};
        $c->{args} = $p;
        "@{[ ref Amon2->context ]}::C::$p->{controller}"->$action($c, $p);
    } else {
        my $res = $c->render_json({ status => 404 });
        $res->status(404);
        return $res;
    }
}

1;

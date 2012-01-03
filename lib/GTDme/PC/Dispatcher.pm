package GTDme::PC::Dispatcher;
use strict;
use warnings;
use utf8;
use Router::Simple::Declare;
use Mouse::Util qw(get_code_package);
use String::CamelCase qw(decamelize);
use Module::Pluggable::Object;

# define roots here.
my $router = router {
    connect '/'                           => { controller => 'Root', action => 'index' };

    connect qr{^ /auth/login/(.+) $}x     => { controller => 'Auth', action => 'login' };
    connect qr{^ /auth/oauth/callback $}x => { controller => 'Auth', action => 'callback' };
    connect qr{^ /auth/logout $}x         => { controller => 'Auth', action => 'logout' };


    connect '/my/'             => { controller => 'Root', action => 'my_index' };
    connect '/my/settings'     => { controller => 'Root', action => 'my_settings' };
    connect '/my/trigger_list' => { controller => 'Root', action => 'my_trigger_list' };


    connect '/home/'                   => { controller => 'Root', action => 'home_index' };
    connect '/home/t/{tag:[^/]+}'      => { controller => 'Root', action => 'home_index' };
    connect '/home/p/{project_id:\d+}' => { controller => 'Root', action => 'home_index_in_project' };


    connect '/inbox/'              => { controller => 'Root', action => 'inbox_index' };
    connect '/inbox/t/{tag:[^/]+}' => { controller => 'Root', action => 'inbox_index' };


    connect '/calendar/'             => { controller => 'Root', action => 'calendar_index' };
    connect '/calendar/{mode:(?:theday|weekly|monthly|unclassified)}'               => { controller => 'Root', action => 'calendar_mode' };
    connect '/calendar/{mode:(?:theday|weekly|monthly|unclassified)}/t/{tag:[^/]+}' => { controller => 'Root', action => 'calendar_mode' };


    connect '/background/'              => { controller => 'Root', action => 'background_index' };
    connect '/background/t/{tag:[^/]+}' => { controller => 'Root', action => 'background_index' };


    connect '/materials/'              => { controller => 'Root', action => 'materials_index' };
    connect '/materials/t/{tag:[^/]+}' => { controller => 'Root', action => 'materials_index' };


    connect '/someday/'              => { controller => 'Root', action => 'someday_index' };
    connect '/someday/t/{tag:[^/]+}' => { controller => 'Root', action => 'someday_index' };


    connect '/projects/'                               => { controller => 'Root', action => 'projects_index'  };
    connect '/projects/{project_id:\d+}'               => { controller => 'Root', action => 'projects_detail' };
    connect '/projects/{project_id:\d+}/t/{tag:[^/]+}' => { controller => 'Root', action => 'projects_detail' };
};

my @controllers = Module::Pluggable::Object->new(
    require     => 1,
    search_path => ['GTDme::PC::C'],
)->plugins;
# {
#     no strict 'refs';
#     for my $controller (@controllers) {
#         my $p0 = $controller;
#         $p0 =~ s/^GTDme::PC::C:://;
#         my $p1 = $p0 eq 'Root' ? '' : decamelize($p0) . '/';

#         for my $method (sort keys %{"${controller}::"}) {
#             next if $method =~ /(?:^_|^BEGIN$|^import$)/;
#             my $code = *{"${controller}::${method}"}{CODE};
#             next unless $code;
#             next if get_code_package($code) ne $controller;
#             my $p2 = $method eq 'index' ? '' : $method;
#             my $path = "/$p1$p2";
#             $router->connect($path => {
#                 controller => $p0,
#                 action     => $method,
#             });
#             print STDERR "map: $path => ${p0}::${method}\n" unless $ENV{HARNESS_ACTIVE};
#         }
#     }
# }

sub dispatch {
    my ($class, $c) = @_;
    my $req = $c->request;
    if (my $p = $router->match($req->env)) {
        my $action = $p->{action};
        $c->{args} = $p;
        "@{[ ref Amon2->context ]}::C::$p->{controller}"->$action($c, $p);
    } else {
        $c->res_404();
    }
}

1;

use utf8;
use File::Spec;
use File::Basename qw(dirname);
my $basedir = File::Spec->rel2abs(File::Spec->catdir(dirname(__FILE__), '..'));
my $dbpath;
if ( -d '/home/dotcloud/') {
    $dbpath = "/home/dotcloud/development.db";
} else {
    $dbpath = File::Spec->catfile($basedir, 'db', 'development.db');
}

my %re = (
    wday => qr/(?:sun|mon|tue|wed|thu|fri|sat|[日月火水木金土])/i,
);

+{
    'Teng' => {
        schema_class => 'GTDme::DB',
        dsn          => 'dbi:mysql:gtdme_dev:localhost',
        username     => '...',
        password     => '...',

        table_prefix => 'gtd_',
        connect_options => {
            mysql_enable_utf8 => 1,
        },
        plugins => [qw/
            Utils
            Resultset
        /],
    },

    'DBI' => [
        "dbi:mysql:gtdme_dev:localhost",
        '...',
        '...',
        +{}
    ],

    'Text::Xslate' => {
        syntax => 'Kolon',
        module => [
            'Text::Xslate::Bridge::Star',
            'GTDme::Xslate::Bridge::Functions',
        ],
    },

    'OAuth' => {
        twitter => {
            consumer_key        => '...',
            consumer_secret     => '...',
            request_token_path  => '...',
            access_token_path   => 'https://api.twitter.com/oauth/access_token',
            authorize_path      => 'https://api.twitter.com/oauth/authorize',
            callback_url        => 'auth/oauth/callback',
            access_token        => '...',
            access_token_secret => '...',
        },
    },

    're' =>  \%re,

    're_item_content_options' => {
        tag      => qr/:(\S+)/,
        datetime => qr/(?:
            20\d{2}-\d{2}-\d{2} |
            20\d{6} |
            20\d{2}-\d{2}-\d{2}[-T\s]\d{2}:\d{2}(?::\d{2})? |
            20(?:\d{12}|\d{10})
        )/x,
        weekly       => qr/w:($re{wday})/,
        monthly_date => qr/m:(\d+)/,
        monthly_wday => qr/m:($re{wday}\d)/,
        step         => qr/step:(\d+)/,
    },

    wday_name => {qw/ 1 Sun  2 Mon  3 Tue  4 Wed  5 Thu  6 Fri  7 Sat /},
};

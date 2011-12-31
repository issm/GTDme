#!/usr/bin/env perl
# ref: http://d.hatena.ne.jp/memememomo/20110213/1297565345
use 5.10.0;
use warnings;
use DBI;
use FindBin;
use File::Spec;
use lib File::Spec->catdir($FindBin::Bin, '..', 'lib');
use lib File::Spec->catdir($FindBin::Bin, '..', 'extlib', 'lib', 'perl5');
use Teng::Schema::Dumper;
use Data::Section::Simple qw/get_data_section/;
use Text::Xslate qw/mark_raw/;
use Getopt::Long;

my ($env, $namespace);
GetOptions (
    'env|e=s'        => \$env,
    'namespace|ns=s' => \$namespace,
);
$env       //= 'development';
$namespace //= 'GTDme::DB';

my ($conf_file, $conf);

-f ( $conf_file = File::Spec->catfile($FindBin::Bin, '..', 'config', "${env}.pl") )  or  die "$!: $conf_file";
$conf = (do $conf_file)->{Teng}  or  die 'Configuration "Teng" is undefined.';

my $dbh = DBI->connect($conf->{dsn}, $conf->{username}, $conf->{password}, $conf->{connect_options}) or die "Cannot connect to DB:: " . $DBI::errstr;
my $schema = Teng::Schema::Dumper->dump(dbh => $dbh, namespace => $namespace);

my $out = Text::Xslate->new->render_string(
    get_data_section('template.tx'),
    {
        namespace => $namespace,
        schema    => mark_raw( $schema ),
        plugins   => $conf->{plugins} || [],
    },
);

print $out;

__DATA__

@@ template.tx
package <: $namespace :>;
use parent 'Teng';
: for $plugins -> $plugin {
__PACKAGE__->load_plugin('<: $plugin :>');
: }
1;

<: $schema :>

package GTDme::Xslate::Bridge::Functions;
use parent qw/Text::Xslate::Bridge/;
use strict;
use warnings;
use utf8;
use Amon2;
use Encode;


sub split {
    my ($n, $delimiter) = @_;
    return [ split($delimiter, $n) ];
}

sub wday_name {
    my ($wday) = @_;
    return encode_utf8( Amon2->context()->config->{wday_name}{$wday} || '' );
}

sub parse_mwday {
    my ($mwday) = @_;
    my ($ord, $wday) = $mwday =~ /^(\d)(\d)$/;
    sprintf '%s/%d', wday_name($wday), $ord;
}

sub mark_commas {
    my ($n) = @_;
    # ref: http://www.din.or.jp/~ohzaki/perl.htm#NumberWithComma
    if ($n =~ /^[-+]?\d\d\d\d+/g) {
        for (my $i = pos($n) - 3, my $j = $n =~ /^[-+]/; $i > $j; $i -= 3) {
            substr($n, $i, 0) = ',';
        }
    }
    return $n;
}


sub abs {
    return abs $_[0];
}



my %scalar_methods = (
    split          => \&split,
    wday_name      => \&wday_name,
    parse_mwday    => \&parse_mwday,

    mark_commas    => \&mark_commas,
    abs            => \&abs,
);



__PACKAGE__->bridge (
    nil      => {},
    scalar   => \%scalar_methods,
    array    => {},
    hash     => {},
    function => \%scalar_methods,
);


1;
__END__

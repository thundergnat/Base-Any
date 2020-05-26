use v6.c;
use Test;
use Base::Any;
use Base::Any::Digits;

my %base = @__base-any-digits.pairs;

plan 9028;

my $n = 10000000000.rand;
for 2..4515 {
    my $b = ($n).&to-base-hash($_);
    is-approx ($n).&to-base-hash($_).&from-base-hash, $n, "$n base $_ - roundtrip";
    my $hash = join '', %base{ |$b<whole>>>.Str }, '.', %base{ $b<fraction>.skip(1)>>.Str };
    my $direct = $n.&to-base($_);
    my $min = ($hash.chars min $direct.chars) - 3;
    $min -= 2 if .abs < 30; # less precision for smaller bases
    $min -= 1 if .abs < 10; # even less for bases less than 10
    is $hash.substr(0,$min), $direct.substr(0,$min), "$n base $_: $direct - hash vs direct";
}

done-testing;

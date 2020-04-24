use v6.c;
use Test;
use Base::Any;

plan 1300;

for ^10 {
    my $r = 1000.rand.round(.0001) * (1, -1).roll;
    my $i = (1000.rand * 1i).round(.0001) * (1, -1).roll;

    for flat -66.. -2, 2..66 {
        my $t =  sum ($r+$i).&to-base($_ * 1i).&from-base($_ * 1i).reals».round(.0001) »*» [1,1i];
        is $t, "{$r+$i}", "{$r+$i} base {$_ * 1i}";
    }
}

done-testing;

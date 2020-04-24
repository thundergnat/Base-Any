use v6.c;
use Test;
use Base::Any;

plan 1910;

for ^5 {
    my $n = 10000000.rand * (1, -1).roll;

    for flat -100000, -25000, -7003, -3456, -4444, -100 .. -10,
              10 .. 100, 4444, 7003, 25000, 100000 -> $r {
        
        my %h = $n.&to-base-hash($r);
        is-approx $n, %h.&from-base-hash, "hash $n, base $r round trips ok";

        my @a = $n.&to-base-array($r);
        is-approx $n, @a.&from-base-array, "array $n, base $r round trips ok";
    }
}

done-testing;

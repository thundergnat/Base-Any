use v6.c;
use Test;
use Base::Any;

plan 707;

for ^10 {
my $n = 1000.rand;
    for 2..36 {
        is $n.&to-base($_), $n.base($_), 'Tests ok against internal';
        is $n.&to-base($_).&from-base($_), $n.base($_).parse-base($_), 'Tests ok against internal';
    }
}

is 'R_a_k_u'.&from-base(62), 'Raku'.&from-base(62), 'Underscores in numeric strings ok';
dies-ok { 222.&from-base(22) }, 'from-base needs a string';
dies-ok { '222'.&to-base(22) }, 'to-base needs a numeric';
is-deeply 0.&to-base-hash(15), { :whole([0]), :fraction([0]), :base(15) }, 'sensible hash return type for 0 - fast path';
is-deeply 0.&to-base-hash(45), { :whole([0]), :fraction([0]), :base(45) }, 'sensible hash return type for 0 - slow path';
is-deeply 0.&to-base-array(15), ([0], [0], 15), 'sensible array return type for 0 - fast path';
is-deeply 0.&to-base-array(45), ([0], [0], 45), 'sensible array return type for 0 - slow path';

done-testing;

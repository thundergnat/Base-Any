use v6.c;
use Test;
use Base::Any;

plan 703;

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

done-testing;

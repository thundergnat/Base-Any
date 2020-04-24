use v6.c;
use Test;
use Base::Any;

for ^10 {
my $n = 1000.rand;
    for 2..36 {
        is $n.&to-base($_), $n.base($_), 'Tests ok against internal';
        is $n.&to-base($_).&from-base($_), $n.base($_).parse-base($_), 'Tests ok against internal';
    }
}

done-testing;

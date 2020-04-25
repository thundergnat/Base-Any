use v6.c;
use Test;
use Base::Any;

plan 728;

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
is-deeply 0.&to-base-hash(-45), { :whole([0]), :fraction([0]), :base(-45) }, 'sensible hash return type for 0 - negative';

is-deeply 0.&to-base-array(15), ([0], [0], 15), 'sensible array return type for 0 - fast path';
is-deeply 0.&to-base-array(45), ([0], [0], 45), 'sensible array return type for 0 - slow path';
is-deeply 0.&to-base-array(-45), ([0], [0], -45), 'sensible array return type for 0 - negative';

is 'raku'.&from-base(-36), 'RAKU'.&from-base(-36), 'Ignores case in negative -36 <-> -2';

dies-ok { '12374'.&from-base(-7) }, 'dies ok with out-of-range, negative base';
dies-ok { '123Ɛ4'.&from-base(-7) }, 'dies ok with out-of-range, negative base';
dies-ok { '12374'.&from-base(7) }, 'dies ok with out-of-range, "small" positive base';
dies-ok { '123Ɛ4'.&from-base(7) }, 'dies ok with out-of-range, "small" positive base';
dies-ok { '123z4'.&from-base(57) }, 'dies ok with out-of-range, "large" positive base';
dies-ok { '123Ɛ4'.&from-base(57) }, 'dies ok with out-of-range, "large" positive base';

lives-ok { 1234.&to-base(4516) }, 'ok with threshold positive radix';
lives-ok { 1234.&to-base(-4516) }, 'ok with threshold negative radix';

lives-ok { '123Ɛ4'.&from-base(4516) }, 'ok with threshold positive radix';
lives-ok { '123Ɛ4'.&from-base(-4516) }, 'ok with threshold negative radix';

dies-ok { 1234.&to-base(4517) }, 'dies ok with out-of-range positive radix';
dies-ok { 1234.&to-base(-4517) }, 'dies ok with out-of-range negative radix';

dies-ok { '123Ɛ4'.&from-base(4517) }, 'dies ok with out-of-range positive radix';
dies-ok { '123Ɛ4'.&from-base(-4517) }, 'dies ok with out-of-range negative radix';

dies-ok { '1.23.4'.&from-base(-7) }, 'dies ok invalid, too many radicimal points';
dies-ok { '1.23.4'.&from-base(7) }, 'dies ok invalid, too many radicimal points';
dies-ok { '1.23.4'.&from-base(47) }, 'dies ok invalid, too many radicimal points';
dies-ok { '1.23.4'.&from-base(-47) }, 'dies ok invalid, too many radicimal points';

done-testing;

use Test;
use Base::Any;

plan 107;

set-digits('9876543210');

is(123456789.&to-base(10), '876543210', 'custom');

set-digits('A'..'F');

for ^100 {
    my $n = $_ * 2351;
    is-approx($n.&to-base(5).&from-base(5), $n, "Roundtrip $n with custom digits ok");
}

dies-ok( { 'WAT'.from-base(5) }, 'Out of custom range dies ok' );
dies-ok( { 'WAT'.from-base(2i) }, 'Custom range imaginary base dies ok' );
dies-ok( { set-digits( < Aa Bb > ) }, 'Multi-char "digits" dies ok' );

reset-digits();

is-approx('Rakudo'.&from-base(6i).round(1e-8), 11904+205710i, 'Back to standard renables');

set-digits < 👨‍👩‍👦 🇫🇷 >;

is( 1234.56.&to-base(2), '🇫🇷👨‍👩‍👦👨‍👩‍👦🇫🇷🇫🇷👨‍👩‍👦🇫🇷👨‍👩‍👦👨‍👩‍👦🇫🇷👨‍👩‍👦.🇫🇷👨‍👩‍👦👨‍👩‍👦👨‍👩‍👦🇫🇷🇫🇷🇫🇷🇫🇷👨‍👩‍👦🇫🇷👨‍👩‍👦🇫🇷🇫🇷🇫🇷👨‍👩‍👦', 'Multibyte digits work ok to-base' );
is( '🇫🇷👨‍👩‍👦👨‍👩‍👦🇫🇷🇫🇷👨‍👩‍👦🇫🇷👨‍👩‍👦👨‍👩‍👦🇫🇷👨‍👩‍👦.🇫🇷👨‍👩‍👦👨‍👩‍👦👨‍👩‍👦🇫🇷🇫🇷🇫🇷🇫🇷👨‍👩‍👦🇫🇷👨‍👩‍👦🇫🇷🇫🇷🇫🇷👨‍👩‍👦'.&from-base(2).round(.01), 1234.56, 'Multibyte dogits work ok from-base' );

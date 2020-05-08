use v6.c;
unit module Base::Any:ver<0.0.6>;

use Base::Any::Digits; # import @__base-any-digits

# Initially glyphs were generated on the fly. Saved to a file now for better startup speed
#constant @__base-any-digits = (32 .. 125228).grep( {.chr ~~ /<:Lu>|<:Ll>|<:Nd>/} ).map( { .chr } ).unique; #4517

my Int $threshold = +@__base-any-digits;

# Common case is base 62: 0..9, A..Z, a..z
my %active-base = @__base-any-digits[^62].pairs.invert;


####  to-base multis   ########################################################

# Detect and die for radicies outside the threshold
multi to-base ( Any $num, Int $radix where * > $threshold ) is export {
    nan-inf($num) if $num === NaN or $num == Inf;
    die "Sorry, can not convert to base $radix, to-base() only handles up to base { $threshold - 1 }." ~
        " Try to-base-array() or to-bash-hash() maybe?";
 }


# Normal base 2 <-> 36
multi to-base ( Real $num, Int $radix where 1 < * < 37 ) is export {
    nan-inf($num) if $num === NaN or $num == Inf; # shouldn't be necessary for Int multis
    $num.base($radix)
}


# Integer base 37 <-> 4516
multi to-base ( Int $num, Int $radix where 36 < * <= $threshold ) is export {
    nan-inf($num) if $num === NaN or $num == Inf; # shouldn't be necessary for Int multis
    @__base-any-digits[$num.polymod( $radix xx * ).reverse].join || '0'
}


# Positive Real base 37 <-> 4516
multi to-base ( Real $num, Int $radix where 36 < * <= $threshold, :$precision = -15 ) is export {
    nan-inf($num) if $num === NaN or $num == Inf;
    my $sign = $num < 0 ?? '-' !! '';
    return '0' unless $num;

    # Adjust active glyph set if necessary
    %active-base = @__base-any-digits[^$radix.abs].pairs.invert if +%active-base < $radix.abs;

    my $value  = $num.abs;
    my $result = '';
    my $place  = 0;
    my $lower-bound = 1 / $radix;
    my $upper-bound = $radix * $lower-bound;
    $value = $num.abs / $radix ** ++$place until $lower-bound <= $value < $upper-bound;
    while ($value or $place > 0) and $place > $precision {
        my $digit = ($radix * $value).Int;
        $value    =  $radix * $value - $digit;
        $result ~= '.' unless $place or $result.contains: '.';
        $result ~= $digit == $radix ?? ($digit-1).&to-base($radix)~'0' !! $digit.&to-base($radix);
        $place--
    }
    $sign ~ $result
}


# Negative Real base -4516 <-> -2
multi to-base ( Real $num, Int $radix where -$threshold <= * < -1, :$precision = -15 ) is export {
    nan-inf($num) if $num === NaN or $num == Inf;
    return '0' unless $num;


    # Adjust active glyph set if necessary
    %active-base = @__base-any-digits[^$radix.abs].pairs.invert if +%active-base < -$radix;

    my $value  = $num;
    my $result = '';
    my $place  = 0;
    my $upper-bound = 1 / (-$radix + 1);
    my $lower-bound = $radix * $upper-bound;
    $value = $num / $radix ** ++$place until $lower-bound <= $value < $upper-bound;
    while ($value or $place > 0) and $place > $precision {
        my $digit = ($radix * $value - $lower-bound).Int;
        $value    =  $radix * $value - $digit;
        $result ~= '.' unless $place or $result.contains: '.';
        $result ~= $digit == -$radix ?? ($digit-1).&to-base(-$radix)~'0' !! $digit.&to-base(-$radix);
        $place--
    }
    $result
}


# Imaginary radicies
multi to-base ( Numeric $num, Complex $radix where *.re == 0, :$precision = -12 ) is export {
    die "Sorry. Only supports complex bases -67i through -2i and 2i through 67i." if 67 < $radix.abs or 1 > $radix.abs;
    nan-inf($num) if $num === NaN or $num == Inf;
    my ($re, $im) = $num.Complex.reals;
    my ($re-wh, $re-fr) =             $re.&to-base( -$radix.im².Int, :precision($precision) ).split: '.';
    my ($im-wh, $im-fr) = ($im/$radix.im).&to-base( -$radix.im².Int, :precision($precision) ).split: '.';
    $_ //= '' for $re-fr, $im-fr;

    sub zip (Str $a, Str $b) {
        my $l = '0' x ($a.chars - $b.chars).abs;
        ([~] flat ($a~$l).comb Z flat ($b~$l).comb).subst(/ '0'+ $ /, '') || '0'
    }

    my $whole = flip zip $re-wh.flip, $im-wh.flip;
    my $fraction = zip $im-fr, $re-fr;
    $fraction eq 0 ?? "$whole" !! "$whole.$fraction"
}


####  from-base multis   ######################################################

# Detect and die for radicies outside the threshold
multi from-base ( Any $num, Int $radix where * > $threshold ) is export {
    die "Sorry, can not convert to base $radix, from-base() only handles up to base { $threshold - 1 }."
}


# Normal 2 - 36 "parse-base" conversion, let the system handle it
multi from-base ( Str $str, Int $radix where 1 < * < 37 ) is export {
    $str.subst('_', '', :g).parse-base($radix)
}


# All other real integer bases
multi from-base ( Str $str is copy, Int $radix where {-$threshold <= $_ < -1 or 36 < $_ <= $threshold } ) is export {
    return -1 * $str.substr(1).&from-base($radix) if $str.substr(0,1) eq '-'; # illegal in negative bases

    $str.=subst('_', '', :g); # Ignore underscores

    $str.=uc if -37 < $radix < -1;  # Ignore case if radix.abs < 37

    # Adjust active glyph set if necessary
    %active-base = @__base-any-digits[^$radix.abs].pairs.invert if +%active-base < $radix.abs;

    # Detect out-of-range glyphs
    if my $k = $str.comb.first( { next if $_ eq '.'; !%active-base{$_}.defined or %active-base{$_} >= $radix.abs } ) {
        die "Cannot convert string to number: malformed base $radix number. " ~
            "Character out of range: '\e[32m{ $str.subst(/$k/, "\e[31m$k\e[32m") }\e[0m'"
    }

    # Do the conversion
    my ($whole, $frac, $die) = $str.split: '.';
    die "Invalid numeric string. Too many radicimal points: '\e[32m{ $str.subst(/'.'/, "\e[31m.\e[32m", :g) }\e[0m'" if $die;
    my $fraction = 0;
    $fraction = [+] $frac.comb.kv.map: { %active-base{$^v} * $radix ** -($^k+1) } if $frac;
    $fraction + [+] $whole.flip.comb.kv.map: { %active-base{$^v} * $radix ** $^k }
}


# Imaginary radicies
multi from-base ( Str $str, Complex $radix where *.re == 0 ) is export {
    return -1 * $str.substr(1).&from-base($radix) if $str.substr(0,1) eq '-'; # technically illegal

    my ($whole, $frac, $die) = $str.subst('_', '', :g).split: '.';
    die "Invalid numeric string. Too many radicimal points: '\e[32m{ $str.subst(/'.'/, "\e[31m.\e[32m", :g) }\e[0m'" if $die;
    my $fraction = 0;
    $fraction = [+] $frac.comb.kv.map: { $^v.&from-base($radix.im².Int) * $radix ** -($^k+1) } if $frac;
    $fraction + [+] $whole.flip.comb.kv.map: { $^v.&from-base($radix.im².Int) * $radix ** $^k }
}


####  to-base-hash multis   ###################################################


# Positive Integer radix and Int number - faster for the common case
# Precision is ignored for Integers
multi to-base-hash ( Int $num, Int $radix where 1 < *,  :$precision ) {
    { :whole([$num.abs.polymod( $radix xx * ).reverse »*» $num.sign || 0]), :fraction([0]), :base($radix) }
}


# Positive Int radix and Real number
multi to-base-hash ( Real $num, Int $radix where * > 1, :$precision = -15 ) is export {
    nan-inf($num) if $num === NaN or $num == Inf;
    my @whole;
    my @fraction = 0;
    return { :whole([0]), :fraction(@fraction), :base($radix) } unless +$num;
    my $value  = $num.abs;
    my $sign = $num.sign;
    my $place  = 0;
    my $lower-bound = 1 / $radix;
    my $upper-bound = $radix * $lower-bound;
    $value = $num.abs / $radix ** ++$place until $lower-bound <= $value < $upper-bound;
    while ($value or $place > 0) and $place > $precision {
        my $digit = ($radix * $value).Int;
        $value    =  $radix * $value - $digit;
        if $place > 0 {
            push @whole, $digit == $radix ?? ($digit - 1, 0)!! $digit;
        } else {
            push @fraction, $digit == $radix ?? ($digit - 1, 0)!! $digit;
        }
        $place--
    }
    @whole    »*=» $sign;
    @fraction »*=» $sign;
    { :whole(@whole), :fraction(@fraction), :base($radix) }
}


# Negative Int radix and Real number
multi to-base-hash ( Real $num, Int $radix where * < -1, :$precision = -15 ) is export {
    nan-inf($num) if $num === NaN or $num == Inf;
    my @whole;
    my @fraction = 0;
    return { :whole([0]), :fraction([0]), :base($radix) } unless +$num;
    my $value  = $num;
    my $place  = 0;
    my $upper-bound = 1 / (-$radix + 1);
    my $lower-bound = $radix * $upper-bound;
    $value = $num / $radix ** ++$place until $lower-bound <= $value < $upper-bound;
    while ($value or $place > 0) and $place > $precision {
        my $digit = ($radix * $value - $lower-bound).Int;
        $value    =  $radix * $value - $digit;
        if $place > 0 {
            push @whole, $digit == -$radix ?? ($digit - 1, 0)!! $digit;
        } else {
            push @fraction, $digit == -$radix ?? ($digit - 1, 0)!! $digit;
        }
        $place--
    }
    { :whole(@whole), :fraction(@fraction), :base($radix) }
}


####  to-base-array multis   ##################################################

# Reuse and rewrite the *-hash multis
sub to-base-array ( $num, $radix, :$precision = -15 ) is export {
    to-base-hash($num, $radix, :$precision)< whole fraction base >
}


####  from-base-hash   #######################################################

sub from-base-hash( %p ) is export {
    sum flat %p<whole>.reverse.kv.map( {$^v * (%p<base> **  $^k)} ),
             %p<fraction>\    .kv.map( {$^v * (%p<base> ** -$^k)} )
}


####  from-base-array  #######################################################

sub from-base-array( @p ) is export {
    sum flat @p[0].reverse.kv.map( {$^v * (@p[2] **  $^k)} ),
             @p[1]\       .kv.map( {$^v * (@p[2] ** -$^k)} )
}


sub nan-inf ( $num ) { die "Can't convert \e[31m$num\e[0m, (it's \e[31m$num\e[0m in any base anyway)." }


=begin pod

=head1 NAME

Base::Any - Convert numbers to or from pretty much any base

[![Build Status](https://travis-ci.org/thundergnat/Base-Any.svg?branch=master)](https://travis-ci.org/thundergnat/Base-Any)

=head1 SYNOPSIS

=begin code :lang<perl6>

use Base::Any;

# Regular positive and negative bases

say 123456789.&to-base(1391); # À୧Ꮣ

say 'À୧Ꮣ'.&from-base(1391); # 123456789

say 6576148.249614.&to-base( 62, :precision(-3) ); # Raku.FTW

say 99999.&to-base(-10); # 1900019

say '1900019'.&from-base(-10); # 99999

say (2**256).&to-base(1000); # õѶÛŰǄņȳΖՀ8ЍӱһƐԿϷϝΐdɕΥ7ӷĄϜԎ


# Imaginary bases

say (5+5i).&to-base(-3i); # 1085.6

say (227.65625+10.859375i).&to-base(37i, :precision(-6)); # 1ŧ.Ԯɣ২Άí೭ÂႬ௫ǚȣᎴ

say 'Rakudo'.&from-base(6i).round(1e-8); # 11904+205710i


# Hash encoded

say (2**256).&to-base-hash(10000);
#`{
    whole    => [11 5792 892 3731 6195 4235 7098 5008 6879 785 3269 9846 6564 564 394 5758 4007 9131 2963 9936],
    fraction => [0],
    base     => 10000
  }


# Array encoded

say (-2**256).&to-base-array(10000);
# ( [-11 -5792 -892 -3731 -6195 -4235 -7098 -5008 -6879 -785 -3269 -9846 -6564 -564 -394 -5758 -4007 -9131 -2963 -9936], [0], 10000 )

=end code

=head1 DESCRIPTION

Rakudo has built-in operators .base and .parse-base to do base conversions, but
they only handle bases 2 through 36.

Base::Any provides convenient tools to transform numbers to and from nearly any
positional, non-streaming base. (A streaming base is one where characters are
packed so that one glyph does not necessarily correspond to one character. E.G.
MIME Base32, Base64, Base85, etc.) Nor does it handle some specialized bases
with customized glyph sets and attached  checksums: e.g. Bitcoin Base58check.
(It could be used in calculating Base58 with the correct mapped glyph set, but
doesn't do it by default.)

For general base conversion, handles positive bases 2 through 4516, negative
bases -4516 through -2, imaginary bases -67i through -2i and 2i through 67i.

The rather arbitrary threshold of 4516 was chosen because that is how many
unique and discernible digit and letter glyphs are in the basic and first
Unicode planes. (There's 4517 actually, but one of them needs to represent
zero... and conveniently enough, it's 0) Punctuation, symbols, white-space and
combining characters as digit glyphs are problematic when trying to round-trip
an encoded number. Font coverage tends to get spotty in the higher Unicode
planes as well.

If 4516 bases is not enough, also provides array encoded numbers to nearly any
imaginable magnitude integer base.

You may also choose to map the arrays to your own selection of glyphs to
enumerate a custom base definition. The default glyph set is enumerated in the
file C<Base::Any::Digits>.


=head4 BASIC USAGE:

    sub to-base(Real $number, Integer $radix, :$precision = -15)

* Where $radix is ±2 through ±4516. Works with any Real type value, though Rats
  and Nums will have limited precision in the less significant digits. You may
  set a precision parameter if desired. Defaults to -15 (1e-15). Negative base
  numbers are encoded to always produce a positive result. Technically, there is
  no such thing as a negative Negative based number.

--

    sub from-base(Str $number, Integer $radix)

* Where $radix is ±2 through ±4516. Takes a String of the encoded number.
  Returns the number encoded in base 10.

=head5 CASE INSENSITIVITY

Base::Any mimics the built-in operators in that bases with an absolute magnitude
36 (-36) and below ignore case when converting C<from-base()>.

    'raku'.&from-base(36) == 'RAKU'.&from-base(36); # 76999005259948

and

    'raku'.&from-base(-36) == 'RAKU'.&from-base(-36); # 75428091766540


For bases positive 2 through 36, Base::Any just hands off the transform to the
built-in commands. A consequence to be aware of:  C<.&from-base().&to-base()> in
radicies ±11 through ±36 may not round-trip to the same string.


=head5 UNDERSCORE SEPARATORS

Raku allows underscores in numeric values as a visual aid to keep track of
orders of magnitude. Since the numbers fed to the C<to-base()> routine are
standard Raku numerics, Base::Any will automatically allow them as well. The
C<from-base()> routines take strings however, and  normally underscores would be
disallowed; this module has code to specifically allow (and ignore) underscores
in numeric strings. Something like this would be valid:

    say 'Raku_Rocks'.&from-base(62); # 6024625501917586

equivalent to:

    say 'RakuRocks'.&from-base(62); # 6024625501917586


=head5 IMAGINARY BASES

C<sub to-base()> will also handle converting to imaginary bases. The radix must
be imaginary, not Complex, (any Real portion must be zero,) and it will only
handle radicies ±2i through ±67i. The number to convert may be any positive or
negative Complex number. Imaginary base encoded numbers never produce a negative
or complex result.

There is no support at this time for imaginary radices in the C<to-base-hash> or
C<to-base-array> routines. The imaginary bases in general seem to be more of a
curiosity than of any great use.


=head4 HASH ENCODED

    sub to-base-hash(Real $number, Integer $radix, :$precision = -15)

* Where $radix is any non ±1 or 0 Integer.
  Returns a hash with 3 elements:

  + :base(the base)
  + :whole(An array of the whole portion positive orders of magnitude in base 10)
  + :fraction(An array of the fractional portion negative orders of magnitude in base 10)

For illustration, using base 10 to make it easier to follow:

    my %hash = 123456789.987654321.&to-base-hash(10);

yields:

    {base => 10, fraction => [0 9 8 7 6 5 4 3 2 1], whole => [1 2 3 4 5 6 7 8 9]}

The 'whole' array is in reverse order, the most significant 'digit' is to the
left, the least significant to the right. Each 'digit' is the value in that
position (order-of-magnitude) encoded in base 10. To convert it to a number,
reverse the array, multiply each element by the corresponding order of magnitude
then sum the values.

    sum %hash<whole>.reverse.kv.map( { $^value * (%hash<base> ** $^key) } );

    123456789

Do the same thing with the fractional portion. The 'fraction' array is not
reversed. The most significant is to the left, least significant to the right.
The first element is always zero so you don't need to worry about skipping it.
Do the same operation but with negative powers of the radix.

    sum %hash<fraction>.kv.map( { $^value * (%hash<base> ** -$^key) } );

    0.987654321

Add the whole and fractional parts together and you get the original number back.

   123456789 + 0.987654321 == 123456789.987654321

There is a provided sub C<from-base-hash()> that does exactly this operation, so
you don't need to do it manually. This was exposition to make it easier to
understand what is going on behind the scenes.


    sub from-base-hash( { :whole(@whole), :fraction(@fraction), :base($base) } )


Round trip:

    say 123456789.987654321.&to-base-hash(10).&from-base-hash;

    123456789.987654321


=head4 ARRAY ENCODED

In the same vein, there is a set of subs that work with arrays.

    sub to-base-array( Real $number, Integer $radix, :$precision = -15 )

and

    sub from-base-array( [ @whole, @fraction, $base ] )

They do very nearly the same thing except C<to-base-array()> returns the 'whole'
Array, the 'fraction' Array and the base as a list of three positionals rather
than a hash of named values, and C<from-base-array()> takes an array of those
three positionals. They work pretty much identically internally though. (And in
fact, use the exact same code path.)

Note that both the C<to-base-hash()> and C<to-base-array()> include the base as
part of the encoded number so it is already include when round-tripping.

Be aware. There are about twenty-two thousand tests done during install to
exercise the module. Testing takes a while. Theoretically, the tests are highly
parallelizable but the present ecosystem tooling doesn't seem to like it.

=head1 AUTHOR

Steve Schulze (thundergnat)

=head1 COPYRIGHT AND LICENSE

Copyright 2020 Steve Schulze

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

=end pod

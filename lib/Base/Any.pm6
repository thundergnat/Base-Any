use v6.c;
unit module Base::Any:ver<0.0.2>;

use Base::Any::Digits;

#constant @__base-any-digits = (32 .. 125228).grep( {.chr ~~ /<:Lu>|<:Ll>|<:Nd>/} ).map( { .chr } ).unique; #4483

my Int $threshold = +@__base-any-digits;

our %active-base = @__base-any-digits[^62].pairs.invert;

multi to-base ( Any $n, Int $r where * > $threshold ) is export {
    die "Sorry, can not convert to base $r, to-base() only handles up to base { $threshold }. Try to-base-array() or to-bash-hash() maybe?";
 }

# Normal base 2 <-> 36
multi to-base (Real $n, Int $r where 1 < * < 37) is export { $n.base($r) }

# Integer base 37 <-> 4483
multi to-base (Int $n, Int $r where 36 < * <= $threshold ) is export {
    @__base-any-digits[$n.polymod( $r xx * ).reverse].join || '0'
}

# Negative Real base -4483 <-> -2
multi to-base ( Real $num, Int $r where -$threshold <= * < -1, :$precision = -16 ) is export {
    return '0' unless $num;
    %active-base = @__base-any-digits[^$r.abs].pairs.invert if +%active-base < $r.abs;
    my $value  = $num;
    my $result = '';
    my $place  = 0;
    my $upper-bound = 1 / (-$r + 1);
    my $lower-bound = $r * $upper-bound;
    $value = $num / $r ** ++$place until $lower-bound <= $value < $upper-bound;
    while ($value or $place > 0) and $place > $precision {
        my $digit = ($r * $value - $lower-bound).Int;
        $value    =  $r * $value - $digit;
        $result ~= '.' unless $place or $result.contains: '.';
        $result ~= $digit == -$r ?? ($digit-1).&to-base(-$r)~'0' !! $digit.&to-base(-$r);
        $place--
    }
    $result
}

# Positive Real base 37 <-> 4483
multi to-base ( Real $num, Int $r where 36 < * <= $threshold, :$precision = -16 ) is export {
    my $sign = $num < 0 ?? '-' !! '';
    return '0' unless $num;
    %active-base = @__base-any-digits[^$r.abs].pairs.invert if +%active-base < $r.abs;
    my $value  = $num.abs;
    my $result = '';
    my $place  = 0;
    my $lower-bound = 1 / $r;
    my $upper-bound = $r * $lower-bound;
    $value = $num.abs / $r ** ++$place until $lower-bound <= $value < $upper-bound;
    while ($value or $place > 0) and $place > $precision {
        my $digit = ($r * $value).Int;
        $value    =  $r * $value - $digit;
        $result ~= '.' unless $place or $result.contains: '.';
        $result ~= $digit == $r ?? ($digit-1).&to-base($r)~'0' !! $digit.&to-base($r);
        $place--
    }
    $sign ~ $result
}

# Complex radicies
multi to-base (Numeric $num, Complex $radix where *.re == 0, :$precision = -8 ) is export {
    die "Sorry. Only supports complex bases -66i through -2i and 2i through 66i." if 66 < $radix.abs or 1 > $radix.abs;
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

# Normal 2 - 36 "parse-base" conversion
multi from-base ($n, Int $r where 1 < * < 37) is export { $n.parse-base($r) }

multi from-base (Str $str, Int $r where {-$threshold <= $_ < -1 or 36 < $_ <= $threshold }) is export {
    return -1 * $str.substr(1).&from-base($r) if $str.substr(0,1) eq '-';
    %active-base = @__base-any-digits[^$r.abs].pairs.invert if +%active-base < $r.abs;
    my ($whole, $frac) = $str.split: '.';
    my $fraction = 0;
    $fraction = [+] $frac.comb.kv.map: { %active-base{$^v} * $r ** -($^k+1) } if $frac;
    $fraction + [+] $whole.flip.comb.kv.map: { %active-base{$^v} * $r ** $^k }
}

# Complex radicies
multi from-base (Str $str, Complex $radix where *.re == 0) is export {
    return -1 * $str.substr(1).&from-base($radix) if $str.substr(0,1) eq '-';
    my ($whole, $frac) = $str.split: '.';
    my $fraction = 0;
    $fraction = [+] $frac.comb.kv.map: { $^v.&from-base($radix.im².Int) * $radix ** -($^k+1) } if $frac;
    $fraction + [+] $whole.flip.comb.kv.map: { $^v.&from-base($radix.im².Int) * $radix ** $^k }
}

sub to-base-array ($n, $r, :$prec = -16) is export { to-base-hash($n, $r, :$prec )< whole fraction base > }

multi to-base-hash (Int $n, Int $r where 1 < * ) {
    { :whole([$n.abs.polymod( $r xx * ).reverse]), :fraction([0]), :base($r) }
}

# Base to hash for positive radix
multi to-base-hash ( Real $num, Int $r where * > 1, :$prec = -16 ) is export {
    my @whole;
    my @fraction = 0;
    return ([0], [0]) unless $num;
    my $value  = $num;
    my $place  = 0;
    my $lower-bound = 1 / $r;
    my $upper-bound = $r * $lower-bound;
    $value = $num / $r ** ++$place until $lower-bound <= $value < $upper-bound;
    while ($value or $place > 0) and $place > $prec {
        my $digit = ($r * $value).Int;
        $value    =  $r * $value - $digit;
        if $place > 0 {
            push @whole, $digit == -$r ?? ($digit - 1, 0)!! $digit;
        } else {
            push @fraction, $digit == -$r ?? ($digit - 1, 0)!! $digit;
        }
        $place--
    }
    { :whole(@whole), :fraction(@fraction), :base($r) }
}

# Base to hash for negative radix
multi to-base-hash ( Real $num, Int $r where * < -1, :$prec = -16 ) is export {
    my @whole;
    my @fraction = 0;
    return ([0], [0]) unless $num;
    my $value  = $num;
    my $place  = 0;
    my $upper-bound = 1 / (-$r + 1);
    my $lower-bound = $r * $upper-bound;
    $value = $num / $r ** ++$place until $lower-bound <= $value < $upper-bound;
    while ($value or $place > 0) and $place > $prec {
        my $digit = ($r * $value - $lower-bound).Int;
        $value    =  $r * $value - $digit;
        if $place > 0 {
            push @whole, $digit == -$r ?? ($digit - 1, 0)!! $digit;
        } else {
            push @fraction, $digit == -$r ?? ($digit - 1, 0)!! $digit;
        }
        $place--
    }
    { :whole(@whole), :fraction(@fraction), :base($r) }
}

multi from-base-hash( %p ) is export {
    sum flat %p<whole>.reverse.kv.map( {$^v * (%p<base> ** $^k)} ), %p<fraction>.kv.map( {$^v * (%p<base> ** -$^k)} )
}

multi from-base-array( @p ) is export {
    sum flat @p[0].reverse.kv.map( {$^v * (@p[2] ** $^k)} ), @p[1].kv.map( {$^v * (@p[2] ** -$^k)} )
}


=begin pod

=head1 NAME

Base::Any - Convert numbers to or from pretty much any base

[![Build Status](https://travis-ci.org/thundergnat/Base-Any.svg?branch=master)](https://travis-ci.org/thundergnat/Base-Any)

=head1 SYNOPSIS

=begin code :lang<perl6>

use Base::Any;

say 123456789.&to-base(1391); # À୧Ꮣ

say 'À୧Ꮣ'.&from-base(1391); # 123456789

=end code

=head1 DESCRIPTION

Base::Any provides convenient tools to transform numbers to and from nearly any
non-encoding base. (An encoding base is one where characters are packed so that
one glyph does not necessarily correspond to one character. E.G. MIME64,
Base58check. etc.)

For general base conversion, handles positive bases 2 through 4482, negative
bases -4482 through -2, imaginary bases -66 through -2 and 2 through 66.

The rather arbitrary threshold of 4482 was chosen because that is how many
unique and discernible digit and letter glyphs are in the basic and first BMP
planes. Punctuation, symbols, white-space and combining characters as digit glyphs
are problematic when trying to round-trip an encoded number.

If 4482 bases is not enough, also provides array encoded numbers to any
magnitude base imaginable.

You may also easily choose to map the arrays to your own selection of glyphs to
enumerate a custom base definition. The default glyph set is enumerated in the
file C<Base::Any::Digits>.

Basic usage:

    sub to-base(Real $number, Integer $radix, :$prec = -16)

* Where $radix is ±2 through ±4482. Works with any Real type value, though Rats
  and Nums will have limited precision in the less significant digits. You may
  set a precision (:prec) parameter if desired. Defaults to -16 (1e-16).

--

    sub from-base(Str $number, Integer $radix)

* Where $radix is ±2 through ±4482. Needs a String of the encoded number.
  Returns the number encoded in base 10.

HASH ENCODED

    sub to-base-hash(Real $number, Integer $radix, :$prec = -16)

* Where $radix is any non ±1 or 0 Integer.
  Returns a hash with 3 elements:

  + :base(the base)
  + :whole(An array of the whole portion positive orders of magnitude in base 10)
  + :fraction(An array of the fractional portion negative orders of magnitude in base 10)

For Illustration, using base 10 to make it easier to follow:

     say my %h = 123456789.0987654321.&to-base-hash(10);

     yields:

     {base => 10, fraction => [0 0 9 8 7 6 5 4 3 2 1], whole => [1 2 3 4 5 6 7 8 9]}

The 'whole' array is in reverse order, the most significant 'digit' is to the left,
the least significant to the right. Each 'digit' is the value in that position
encoded in base 10. To convert it to a number, reverse the array,
multiply each element by the corresponding order of magnitude then sum the values.

    sum %h<whole>.reverse.kv.map( {$^v * (%h<base> ** $^k)} )

    123456789

Do the same thing with the fractional portion. The fraction array is not reversed.
The least significant is to the left, most significant to the right. The first
element is always zero so you don't need to worry about skipping it. Do the same
operation but with negative powers of the radix.

    sum %h<fraction>.kv.map( {$^v * (%h<base> ** -$^k)}

    0.0987654321

Add the whole and fractional parts together and you get the original number back.

   123456789 + 0.0987654321 == 123456789.0987654321

There is a provided C<sub from-base-hash()> that does exactly this operation so you
don't need to do it manually. This was just exposition to make it easier to
understand the process.

Round trip:

    say my %h = 123456789.0987654321.&to-base-hash(10).&from-base-hash;

    123456789.0987654321

ARRAY ENCODED

In the same vein, there is a provided set of subs that work with arrays.

    sub to-base-array(Real $number, Integer $radix, :$prec = -16)

and

    sub from-base-array()

They do very nearly the same thing except they return the base, whole Array and
fraction Array as a list of three positionals rather than a hash of named values.
They work pretty much exactly the same way though.

IMAGINARY BASES

C<sub to-base()> will also handle converting to imaginary bases. The radix must
be imaginary, not Complex. (Any Real portion must be zero.) And it only handles
radicies ±2i through ±66i. There is not at this time imaginary support in the
C<to-base-hash> or C<to-base-array> routines. The imaginary bases are more of a
curiosity than of great use.

=head1 AUTHOR

Steve Schulze (thundergnat)

=head1 COPYRIGHT AND LICENSE

Copyright 2020 Steve Schulze

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

=end pod

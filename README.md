NAME
====

Base::Any - Convert numbers to or from pretty much any base

[![Build Status](https://travis-ci.org/thundergnat/Base-Any.svg?branch=master)](https://travis-ci.org/thundergnat/Base-Any)

SYNOPSIS
========

```perl6
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

# Set a custom digit set

set-digits('ABCDEFGHIJ');

# or

set-digits('A'..'J');

# Reset to default digit set

reset-digits();
```

DESCRIPTION
===========

Rakudo has built-in operators .base and .parse-base to do base conversions, but they only handle bases 2 through 36.

Base::Any provides convenient tools to transform numbers to and from nearly any positional, non-streaming base. (A streaming base is one where characters are packed so that one glyph does not necessarily correspond to one character. E.G. MIME Base32, Base64, Base85, etc.) Nor does it handle some specialized bases with customized glyph sets and attached checksums: e.g. Bitcoin Base58check. (It could be used in calculating Base58 with the correct mapped glyph set, but doesn't do it by default.)

For general base conversion, handles positive bases 2 through 4516, negative bases -4516 through -2, imaginary bases -67i through -2i and 2i through 67i.

The rather arbitrary threshold of 4516 was chosen because that is how many unique and discernible digit and letter glyphs are in the basic and first Unicode planes. (Under Unicode 12.1) (There's 4517 actually, but one of them needs to represent zero... and conveniently enough, it's 0) Punctuation, symbols, white-space and combining characters as digit glyphs are problematic when trying to round-trip an encoded number. Font coverage tends to get spotty in the higher Unicode planes as well.

If 4516 bases is not enough, also provides array encoded numbers to nearly any imaginable magnitude integer base.

You may also choose to map the arrays to your own selection of glyphs to enumerate a custom base definition. The default glyph set is enumerated in the file `Base::Any::Digits`.

#### BASIC USAGE:

    sub to-base(Real $number, Integer $radix, :$precision = -15)

* Where $radix is ±2 through ±4516.

Works with any Real type value, though Rats and Nums will have limited precision in the least significant digits. You may set a precision parameter if desired. Defaults to -15 (1e-15). Converting a Rat or Num to a base and back likely will not return the exact same number. Some rounding will likely be necessary if that is critical.

Negative base numbers are encoded to always produce a positive result. Technically, there is no such thing as a negative Negative based number.

--

    sub from-base(Str $number, Integer $radix)

* Where $radix is ±2 through ±4516. Takes a String of the encoded number. Returns the number encoded in base 10.

##### CASE INSENSITIVITY

As long as the default digit set is loaded Base::Any mimics the built-in operators, in that bases with an absolute magnitude 36 (-36) and below ignore case when converting `from-base()`.

    'raku'.&from-base(36) == 'RAKU'.&from-base(36); # 76999005259948

and

    'raku'.&from-base(-36) == 'RAKU'.&from-base(-36); # 75428091766540

A consequence to be aware of: `.&from-base().&to-base()` in radicies ±11 through ±36 may not round-trip to the same string.

If a custom digit set is loaded, Base::Any makes no assumptions about case equivalence.

##### UNDERSCORE SEPARATORS

Raku allows underscores in numeric values as a visual aid to keep track of orders of magnitude. Since the numbers fed to the `to-base()` routine are standard Raku numerics, Base::Any will automatically allow them as well. The `from-base()` routines take strings however, and normally underscores would be disallowed; this module has code to specifically allow (and ignore) underscores in numeric strings. Something like this would be valid:

    say 'Raku_Rocks'.&from-base(62); # 6024625501917586

equivalent to:

    say 'RakuRocks'.&from-base(62); # 6024625501917586

##### IMAGINARY BASES

`sub to-base()` will also handle converting to imaginary bases. The radix must be imaginary, not Complex, (any Real portion must be zero,) and it will only handle radicies ±2i through ±67i. The number to convert may be any positive or negative Complex number. Imaginary base encoded numbers never produce a negative or complex result.

There is no support at this time for imaginary radices in the `to-base-hash` or `to-base-array` routines. The imaginary bases in general seem to be more of a curiosity than of any great use.

#### CUSTOM DIGIT SETS

If you want to use a custom, non-standard digit set, you may easily load a replacement set of glyphs to use for digits.

`sub set-digits(String)` or `sub set-digits(List)` will alter the standard table of digits to whatever you pass in. There are some caveats.

* The string (or list) may not have any repeated glyphs. Repeated glyphs would hinder reversibility.

* Each element (for lists) must have only one character.

* Custom digit sets disable imaginary base number routines. They are too fiddly to deal with possibly "out-of-order" characters.

There is some error trapping but you are given a lot of leeway to shoot yourself in the foot.

The digit set order determines which character represents which number.

Note that the digit set may be larger than the base you are converting to. You may load 'A' .. 'Z', but then convert to base 8 which would only use 'A' through 'H'. 'A' .. 'Z' will support any base from 2 to 26.

The custom characters can be any valid Unicode character, even multibyte characters, as long as they are detected as a single character by Raku. They may be in any order, and from any Unicode block, as long as they are unique and discernable. It is highly recommended that the characters be restricted to printable, standalone characters (no white-space, control, or combining characters) but it isn't forbidden. Do not be suprised if the standard routines do not deal well with them though.

```perl6
set-digits < 😟 😀 >;

say 1234.5678.&to-base(2);

# 😀😟😟😀😀😟😀😟😟😀😟.😀😟😟😀😟😟😟😀😟😀😟😀😀😟😀
```

You may change back to the standard digit set at any time with:

`sub reset-digits();` This will revert back to the default digit set and re-enable any routines disabled while custom digits were loaded.

#### HASH ENCODED

    sub to-base-hash(Real $number, Integer $radix, :$precision = -15)

* Where $radix is any non ±1 or 0 Integer. Returns a hash with 3 elements:

    + :base(the base)
    + :whole(An array of the whole portion positive orders of magnitude in base 10)
    + :fraction(An array of the fractional portion negative orders of magnitude in base 10)

For illustration, using base 10 to make it easier to follow:

    my %hash = 123456789.987654321.&to-base-hash(10);

yields:

    {base => 10, fraction => [0 9 8 7 6 5 4 3 2 1], whole => [1 2 3 4 5 6 7 8 9]}

The 'whole' array is in reverse order, the most significant 'digit' is to the left, the least significant to the right. Each 'digit' is the value in that position (order-of-magnitude) encoded in base 10. To convert it to a number, reverse the array, multiply each element by the corresponding order of magnitude then sum the values.

    sum %hash<whole>.reverse.kv.map( { $^value * (%hash<base> ** $^key) } );

    123456789

Do the same thing with the fractional portion. The 'fraction' array is not reversed. The most significant is to the left, least significant to the right. The first element is always zero so you don't need to worry about skipping it. Do the same operation but with negative powers of the radix.

    sum %hash<fraction>.kv.map( { $^value * (%hash<base> ** -$^key) } );

    0.987654321

Add the whole and fractional parts together and you get the original number back.

    123456789 + 0.987654321 == 123456789.987654321

There is a provided sub `from-base-hash()` that does exactly this operation, so you don't need to do it manually. This was exposition to make it easier to understand what is going on behind the scenes.

    sub from-base-hash( { :whole(@whole), :fraction(@fraction), :base($base) } )

Round trip:

    say 123456789.987654321.&to-base-hash(10).&from-base-hash;

    123456789.987654321

#### ARRAY ENCODED

In the same vein, there is a set of subs that work with arrays.

    sub to-base-array( Real $number, Integer $radix, :$precision = -15 )

and

    sub from-base-array( [ @whole, @fraction, $base ] )

They do very nearly the same thing except `to-base-array()` returns the 'whole' Array, the 'fraction' Array and the base as a list of three positionals rather than a hash of named values, and `from-base-array()` takes an array of those three positionals. They work pretty much identically internally though. (And in fact, use the exact same code path.)

Note that both the `to-base-hash()` and `to-base-array()` include the base as part of the encoded number so it is already include when round-tripping.

Be aware. There are about twenty-two thousand tests done during install to exercise the module. Testing takes a while. Theoretically, the tests are highly parallelizable but the present ecosystem tooling doesn't seem to like it.

AUTHOR
======

Steve Schulze (thundergnat)

COPYRIGHT AND LICENSE
=====================

Copyright 2020 Steve Schulze

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.


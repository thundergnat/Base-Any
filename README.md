NAME
====

Base::Any - Convert numbers to or from pretty much any base

[![Build Status](https://travis-ci.org/thundergnat/Base-Any.svg?branch=master)](https://travis-ci.org/thundergnat/Base-Any)

SYNOPSIS
========

```perl6
use Base::Any;

say 123456789.&to-base(1391); # À୧Ꮣ

say 'À୧Ꮣ'.&from-base(1391); # 123456789
```

DESCRIPTION
===========

Base::Any provides convenient tools to transform numbers to and from nearly any non-encoding base. (An encoding base is one where characters are packed so that one glyph does not necessarily correspond to one character. E.G. MIME64, Base58check. etc.)

For general base conversion, handles positive bases 2 through 4482, negative bases -4482 through -2, imaginary bases -66 through -2 and 2 through 66.

The rather arbitrary threshold of 4482 was chosen because that is how many unique and discernible digit and letter glyphs are in the basic and first BMP planes. Punctuation, symbols, white-space and combining characters as digit glyphs are problematic when trying to round-trip an encoded number.

If 4482 bases is not enough, also provides array encoded numbers to any magnitude base imaginable.

You may also easily choose to map the arrays to your own selection of glyphs to enumerate a custom base definition. The default glyph set is enumerated in the file `Base::Any::Digits`.

Basic usage:

    sub to-base(Real $number, Integer $radix, :$prec = -16)

* Where $radix is ±2 through ±4482. Works with any Real type value, though Rats and Nums will have limited precision in the less significant digits. You may set a precision (:prec) parameter if desired. Defaults to -16 (1e-16).

--

    sub from-base(Str $number, Integer $radix)

* Where $radix is ±2 through ±4482. Needs a String of the encoded number. Returns the number encoded in base 10.

HASH ENCODED

    sub to-base-hash(Real $number, Integer $radix, :$prec = -16)

* Where $radix is any non ±1 or 0 Integer. Returns a hash with 3 elements:

    + :base(the base)
    + :whole(An array of the whole portion positive orders of magnitude in base 10)
    + :fraction(An array of the fractional portion negative orders of magnitude in base 10)

For Illustration, using base 10 to make it easier to follow:

    say my %h = 123456789.0987654321.&to-base-hash(10);

    yields:

    {base => 10, fraction => [0 0 9 8 7 6 5 4 3 2 1], whole => [1 2 3 4 5 6 7 8 9]}

The 'whole' array is in reverse order, the most significant 'digit' is to the left, the least significant to the right. Each 'digit' is the value in that position encoded in base 10. To convert it to a number, reverse the array, multiply each element by the corresponding order of magnitude then sum the values.

    sum %h<whole>.reverse.kv.map( {$^v * (%h<base> ** $^k)} )

    123456789

Do the same thing with the fractional portion. The fraction array is not reversed. The least significant is to the left, most significant to the right. The first element is always zero so you don't need to worry about skipping it. Do the same operation but with negative powers of the radix.

    sum %h<fraction>.kv.map( {$^v * (%h<base> ** -$^k)}

    0.0987654321

Add the whole and fractional parts together and you get the original number back.

    123456789 + 0.0987654321 == 123456789.0987654321

There is a provided `sub from-base-hash()` that does exactly this operation so you don't need to do it manually. This was just exposition to make it easier to understand the process.

Round trip:

    say my %h = 123456789.0987654321.&to-base-hash(10).&from-base-hash;

    123456789.0987654321

ARRAY ENCODED

In the same vein, there is a provided set of subs that work with arrays.

    sub to-base-array(Real $number, Integer $radix, :$prec = -16)

and

    sub from-base-array()

They do very nearly the same thing except they return the base, whole Array and fraction Array as a list of three positionals rather than a hash of named values. They work pretty much exactly the same way though.

IMAGINARY BASES

`sub to-base()` will also handle converting to imaginary bases. The radix must be imaginary, not Complex. (Any Real portion must be zero.) And it only handles radicies ±2i through ±66i. There is not at this time imaginary support in the `to-base-hash` or `to-base-array` routines. The imaginary bases are more of a curiosity than of great use.

AUTHOR
======

Steve Schulze (thundergnat)

COPYRIGHT AND LICENSE
=====================

Copyright 2020 Steve Schulze

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.


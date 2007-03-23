=head1 NAME

JSON::XS - JSON serialising/deserialising, done correctly and fast

=head1 SYNOPSIS

 use JSON::XS;

 # exported functions, croak on error

 $utf8_encoded_json_text = to_json $perl_hash_or_arrayref;
 $perl_hash_or_arrayref  = from_json $utf8_encoded_json_text;

 # oo-interface

 $coder = JSON::XS->new->ascii->pretty->allow_nonref;
 $pretty_printed_unencoded = $coder->encode ($perl_scalar);
 $perl_scalar = $coder->decode ($unicode_json_text);

=head1 DESCRIPTION

This module converts Perl data structures to JSON and vice versa. Its
primary goal is to be I<correct> and its secondary goal is to be
I<fast>. To reach the latter goal it was written in C.

As this is the n-th-something JSON module on CPAN, what was the reason
to write yet another JSON module? While it seems there are many JSON
modules, none of them correctly handle all corner cases, and in most cases
their maintainers are unresponsive, gone missing, or not listening to bug
reports for other reasons.

See COMPARISON, below, for a comparison to some other JSON modules.

See MAPPING, below, on how JSON::XS maps perl values to JSON values and
vice versa.

=head2 FEATURES

=over 4

=item * correct handling of unicode issues

This module knows how to handle Unicode, and even documents how and when
it does so.

=item * round-trip integrity

When you serialise a perl data structure using only datatypes supported
by JSON, the deserialised data structure is identical on the Perl level.
(e.g. the string "2.0" doesn't suddenly become "2").

=item * strict checking of JSON correctness

There is no guessing, no generating of illegal JSON strings by default,
and only JSON is accepted as input by default (the latter is a security
feature).

=item * fast

Compared to other JSON modules, this module compares favourably in terms
of speed, too.

=item * simple to use

This module has both a simple functional interface as well as an OO
interface.

=item * reasonably versatile output formats

You can choose between the most compact guarenteed single-line format
possible (nice for simple line-based protocols), a pure-ascii format (for
when your transport is not 8-bit clean), or a pretty-printed format (for
when you want to read that stuff). Or you can combine those features in
whatever way you like.

=back

=cut

package JSON::XS;

BEGIN {
   $VERSION = '0.3';
   @ISA = qw(Exporter);

   @EXPORT = qw(to_json from_json);
   require Exporter;

   require XSLoader;
   XSLoader::load JSON::XS::, $VERSION;
}

=head1 FUNCTIONAL INTERFACE

The following convinience methods are provided by this module. They are
exported by default:

=over 4

=item $json_string = to_json $perl_scalar

Converts the given Perl data structure (a simple scalar or a reference to
a hash or array) to a UTF-8 encoded, binary string (that is, the string contains
octets only). Croaks on error.

This function call is functionally identical to C<< JSON::XS->new->utf8->encode ($perl_scalar) >>.

=item $perl_scalar = from_json $json_string

The opposite of C<to_json>: expects an UTF-8 (binary) string and tries to
parse that as an UTF-8 encoded JSON string, returning the resulting simple
scalar or reference. Croaks on error.

This function call is functionally identical to C<< JSON::XS->new->utf8->decode ($json_string) >>.

=back

=head1 OBJECT-ORIENTED INTERFACE

The object oriented interface lets you configure your own encoding or
decoding style, within the limits of supported formats.

=over 4

=item $json = new JSON::XS

Creates a new JSON::XS object that can be used to de/encode JSON
strings. All boolean flags described below are by default I<disabled>.

The mutators for flags all return the JSON object again and thus calls can
be chained:

   my $json = JSON::XS->new->utf8(1)->space_after(1)->encode ({a => [1,2]})
   => {"a": [1, 2]}

=item $json = $json->ascii ([$enable])

If C<$enable> is true (or missing), then the C<encode> method will
not generate characters outside the code range C<0..127>. Any unicode
characters outside that range will be escaped using either a single
\uXXXX (BMP characters) or a double \uHHHH\uLLLLL escape sequence, as per
RFC4627.

If C<$enable> is false, then the C<encode> method will not escape Unicode
characters unless necessary.

  JSON::XS->new->ascii (1)->encode (chr 0x10401)
  => \ud801\udc01

=item $json = $json->utf8 ([$enable])

If C<$enable> is true (or missing), then the C<encode> method will encode
the JSON string into UTF-8, as required by many protocols, while the
C<decode> method expects to be handled an UTF-8-encoded string.  Please
note that UTF-8-encoded strings do not contain any characters outside the
range C<0..255>, they are thus useful for bytewise/binary I/O.

If C<$enable> is false, then the C<encode> method will return the JSON
string as a (non-encoded) unicode string, while C<decode> expects thus a
unicode string.  Any decoding or encoding (e.g. to UTF-8 or UTF-16) needs
to be done yourself, e.g. using the Encode module.

Example, output UTF-16-encoded JSON:

=item $json = $json->pretty ([$enable])

This enables (or disables) all of the C<indent>, C<space_before> and
C<space_after> (and in the future possibly more) flags in one call to
generate the most readable (or most compact) form possible.

Example, pretty-print some simple structure:

   my $json = JSON::XS->new->pretty(1)->encode ({a => [1,2]})
   =>
   {
      "a" : [
         1,
         2
      ]
   }

=item $json = $json->indent ([$enable])

If C<$enable> is true (or missing), then the C<encode> method will use a multiline
format as output, putting every array member or object/hash key-value pair
into its own line, identing them properly.

If C<$enable> is false, no newlines or indenting will be produced, and the
resulting JSON strings is guarenteed not to contain any C<newlines>.

This setting has no effect when decoding JSON strings.

=item $json = $json->space_before ([$enable])

If C<$enable> is true (or missing), then the C<encode> method will add an extra
optional space before the C<:> separating keys from values in JSON objects.

If C<$enable> is false, then the C<encode> method will not add any extra
space at those places.

This setting has no effect when decoding JSON strings. You will also most
likely combine this setting with C<space_after>.

Example, space_before enabled, space_after and indent disabled:

   {"key" :"value"}

=item $json = $json->space_after ([$enable])

If C<$enable> is true (or missing), then the C<encode> method will add an extra
optional space after the C<:> separating keys from values in JSON objects
and extra whitespace after the C<,> separating key-value pairs and array
members.

If C<$enable> is false, then the C<encode> method will not add any extra
space at those places.

This setting has no effect when decoding JSON strings.

Example, space_before and indent disabled, space_after enabled:

   {"key": "value"}

=item $json = $json->canonical ([$enable])

If C<$enable> is true (or missing), then the C<encode> method will output JSON objects
by sorting their keys. This is adding a comparatively high overhead.

If C<$enable> is false, then the C<encode> method will output key-value
pairs in the order Perl stores them (which will likely change between runs
of the same script).

This option is useful if you want the same data structure to be encoded as
the same JSON string (given the same overall settings). If it is disabled,
the same hash migh be encoded differently even if contains the same data,
as key-value pairs have no inherent ordering in Perl.

This setting has no effect when decoding JSON strings.

=item $json = $json->allow_nonref ([$enable])

If C<$enable> is true (or missing), then the C<encode> method can convert a
non-reference into its corresponding string, number or null JSON value,
which is an extension to RFC4627. Likewise, C<decode> will accept those JSON
values instead of croaking.

If C<$enable> is false, then the C<encode> method will croak if it isn't
passed an arrayref or hashref, as JSON strings must either be an object
or array. Likewise, C<decode> will croak if given something that is not a
JSON object or array.

Example, encode a Perl scalar as JSON value with enabled C<allow_nonref>,
resulting in an invalid JSON text:

   JSON::XS->new->allow_nonref->encode ("Hello, World!")
   => "Hello, World!"

=item $json = $json->shrink ([$enable])

Perl usually over-allocates memory a bit when allocating space for
strings.  This flag optionally resizes strings generated by either
C<encode> or C<decode> to their minimum size possible. This can save
memory when your JSON strings are either very very long or you have many
short strings. It will also try to downgrade any strings to octet-form
if possible: perl stores strings internally either in an encoding called
UTF-X or in octet-form. The latter cannot store everything but uses less
space in general.

If C<$enable> is true (or missing), the string returned by C<encode> will be shrunk-to-fit,
while all strings generated by C<decode> will also be shrunk-to-fit.

If C<$enable> is false, then the normal perl allocation algorithms are used.
If you work with your data, then this is likely to be faster.

In the future, this setting might control other things, such as converting
strings that look like integers or floats into integers or floats
internally (there is no difference on the Perl level), saving space.

=item $json_string = $json->encode ($perl_scalar)

Converts the given Perl data structure (a simple scalar or a reference
to a hash or array) to its JSON representation. Simple scalars will be
converted into JSON string or number sequences, while references to arrays
become JSON arrays and references to hashes become JSON objects. Undefined
Perl values (e.g. C<undef>) become JSON C<null> values. Neither C<true>
nor C<false> values will be generated.

=item $perl_scalar = $json->decode ($json_string)

The opposite of C<encode>: expects a JSON string and tries to parse it,
returning the resulting simple scalar or reference. Croaks on error.

JSON numbers and strings become simple Perl scalars. JSON arrays become
Perl arrayrefs and JSON objects become Perl hashrefs. C<true> becomes
C<1>, C<false> becomes C<0> and C<null> becomes C<undef>.

=back

=head1 MAPPING

This section describes how JSON::XS maps Perl values to JSON values and
vice versa. These mappings are designed to "do the right thing" in most
circumstances automatically, preserving round-tripping characteristics
(what you put in comes out as something equivalent).

For the more enlightened: note that in the following descriptions,
lowercase I<perl> refers to the Perl interpreter, while uppcercase I<Perl>
refers to the abstract Perl language itself.

=head2 JSON -> PERL

=over 4

=item object

A JSON object becomes a reference to a hash in Perl. No ordering of object
keys is preserved.

=item array

A JSON array becomes a reference to an array in Perl.

=item string

A JSON string becomes a string scalar in Perl - Unicode codepoints in JSON
are represented by the same codepoints in the Perl string, so no manual
decoding is necessary.

=item number

A JSON number becomes either an integer or numeric (floating point)
scalar in perl, depending on its range and any fractional parts. On the
Perl level, there is no difference between those as Perl handles all the
conversion details, but an integer may take slightly less memory and might
represent more values exactly than (floating point) numbers.

=item true, false

These JSON atoms become C<0>, C<1>, respectively. Information is lost in
this process. Future versions might represent those values differently,
but they will be guarenteed to act like these integers would normally in
Perl.

=item null

A JSON null atom becomes C<undef> in Perl.

=back

=head2 PERL -> JSON

The mapping from Perl to JSON is slightly more difficult, as Perl is a
truly typeless language, so we can only guess which JSON type is meant by
a Perl value.

=over 4

=item hash references

Perl hash references become JSON objects. As there is no inherent ordering
in hash keys, they will usually be encoded in a pseudo-random order that
can change between runs of the same program but stays generally the same
within the single run of a program. JSON::XS can optionally sort the hash
keys (determined by the I<canonical> flag), so the same datastructure
will serialise to the same JSON text (given same settings and version of
JSON::XS), but this incurs a runtime overhead.

=item array references

Perl array references become JSON arrays.

=item blessed objects

Blessed objects are not allowed. JSON::XS currently tries to encode their
underlying representation (hash- or arrayref), but this behaviour might
change in future versions.

=item simple scalars

Simple Perl scalars (any scalar that is not a reference) are the most
difficult objects to encode: JSON::XS will encode undefined scalars as
JSON null value, scalars that have last been used in a string context
before encoding as JSON strings and anything else as number value:

   # dump as number
   to_json [2]                      # yields [2]
   to_json [-3.0e17]                # yields [-3e+17]
   my $value = 5; to_json [$value]  # yields [5]

   # used as string, so dump as string
   print $value;
   to_json [$value]                 # yields ["5"]

   # undef becomes null
   to_json [undef]                  # yields [null]

You can force the type to be a string by stringifying it:

   my $x = 3.1; # some variable containing a number
   "$x";        # stringified
   $x .= "";    # another, more awkward way to stringify
   print $x;    # perl does it for you, too, quite often

You can force the type to be a number by numifying it:

   my $x = "3"; # some variable containing a string
   $x += 0;     # numify it, ensuring it will be dumped as a number
   $x *= 1;     # same thing, the choise is yours.

You can not currently output JSON booleans or force the type in other,
less obscure, ways. Tell me if you need this capability.

=item circular data structures

Those will be encoded until memory or stackspace runs out.

=back

=head1 COMPARISON

As already mentioned, this module was created because none of the existing
JSON modules could be made to work correctly. First I will describe the
problems (or pleasures) I encountered with various existing JSON modules,
followed by some benchmark values. JSON::XS was designed not to suffer
from any of these problems or limitations.

=over 4

=item JSON 1.07

Slow (but very portable, as it is written in pure Perl).

Undocumented/buggy Unicode handling (how JSON handles unicode values is
undocumented. One can get far by feeding it unicode strings and doing
en-/decoding oneself, but unicode escapes are not working properly).

No roundtripping (strings get clobbered if they look like numbers, e.g.
the string C<2.0> will encode to C<2.0> instead of C<"2.0">, and that will
decode into the number 2.

=item JSON::PC 0.01

Very fast.

Undocumented/buggy Unicode handling.

No roundtripping.

Has problems handling many Perl values (e.g. regex results and other magic
values will make it croak).

Does not even generate valid JSON (C<{1,2}> gets converted to C<{1:2}>
which is not a valid JSON string.

Unmaintained (maintainer unresponsive for many months, bugs are not
getting fixed).

=item JSON::Syck 0.21

Very buggy (often crashes).

Very inflexible (no human-readable format supported, format pretty much
undocumented. I need at least a format for easy reading by humans and a
single-line compact format for use in a protocol, and preferably a way to
generate ASCII-only JSON strings).

Completely broken (and confusingly documented) Unicode handling (unicode
escapes are not working properly, you need to set ImplicitUnicode to
I<different> values on en- and decoding to get symmetric behaviour).

No roundtripping (simple cases work, but this depends on wether the scalar
value was used in a numeric context or not).

Dumping hashes may skip hash values depending on iterator state.

Unmaintained (maintainer unresponsive for many months, bugs are not
getting fixed).

Does not check input for validity (i.e. will accept non-JSON input and
return "something" instead of raising an exception. This is a security
issue: imagine two banks transfering money between each other using
JSON. One bank might parse a given non-JSON request and deduct money,
while the other might reject the transaction with a syntax error. While a
good protocol will at least recover, that is extra unnecessary work and
the transaction will still not succeed).

=item JSON::DWIW 0.04

Very fast. Very natural. Very nice.

Undocumented unicode handling (but the best of the pack. Unicode escapes
still don't get parsed properly).

Very inflexible.

No roundtripping.

Does not generate valid JSON (key strings are often unquoted, empty keys
result in nothing being output)

Does not check input for validity.

=back

=head2 SPEED

It seems that JSON::XS is surprisingly fast, as shown in the following
tables. They have been generated with the help of the C<eg/bench> program
in the JSON::XS distribution, to make it easy to compare on your own
system.

First is a comparison between various modules using a very simple JSON
string, showing the number of encodes/decodes per second (JSON::XS is
the functional interface, while JSON::XS/2 is the OO interface with
pretty-printing and hashkey sorting enabled).

   module     |     encode |     decode |
   -----------|------------|------------|
   JSON       |      14006 |       6820 |
   JSON::DWIW |     200937 |     120386 |
   JSON::PC   |      85065 |     129366 |
   JSON::Syck |      59898 |      44232 |
   JSON::XS   |    1171478 |     342435 |
   JSON::XS/2 |     730760 |     328714 |
   -----------+------------+------------+

That is, JSON::XS is 6 times faster than than JSON::DWIW and about 80
times faster than JSON, even with pretty-printing and key sorting.

Using a longer test string (roughly 8KB, generated from Yahoo! Locals
search API (http://nanoref.com/yahooapis/mgPdGg):

   module     |     encode |     decode |
   -----------|------------|------------|
   JSON       |        673 |         38 |
   JSON::DWIW |       5271 |        770 |
   JSON::PC   |       9901 |       2491 |
   JSON::Syck |       2360 |        786 |
   JSON::XS   |      37398 |       3202 |
   JSON::XS/2 |      13765 |       3153 |
   -----------+------------+------------+

Again, JSON::XS leads by far in the encoding case, while still beating
every other module in the decoding case.

=head1 RESOURCE LIMITS

JSON::XS does not impose any limits on the size of JSON texts or Perl
values they represent - if your machine can handle it, JSON::XS will
encode or decode it. Future versions might optionally impose structure
depth and memory use resource limits.

=head1 BUGS

While the goal of this module is to be correct, that unfortunately does
not mean its bug-free, only that I think its design is bug-free. It is
still very young and not well-tested. If you keep reporting bugs they will
be fixed swiftly, though.

=cut

1;

=head1 AUTHOR

 Marc Lehmann <schmorp@schmorp.de>
 http://home.schmorp.de/

=cut

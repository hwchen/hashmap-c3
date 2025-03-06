# Hashmap for c3.

Generally better performance (speed and memory) than the current std HashMap implementation.

I've taken the general idea of the zig hashmap
- open address, linear probing
- metadata array, where each metadata is a char with 1 bit `used` and 7 bits `fingerprint`

Performance is slightly slower than the zig hashmap. (Tried zig's one-allocation strategy, was not able to make it perform well in C3).

It's a drop-in replacement for the std hashmap, API is the same except for addition of `get_ref_or_default`.

## Motivation

Main motivation is performance, but also:

- std HashMap copies keys, I want to manage the memory.
- has a get_or_put (in zig) API, I hit this extremely often.
- could also implement an ordered map (but this is not high priority)

## TODO

- fuzz?
- more tests?
- finish martin benchmarks
- docs and review

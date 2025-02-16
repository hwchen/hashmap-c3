# Hashmap for c3.

Generally better performance (speed and memory) than the current std HashMap implementation.

I've taken the general idea of the zig hashmap
- open address, linear probing
- metadata array, where each metadata is a char with 1 bit `used` and 7 bits `fingerprint`
- more naive for removal, does not use tombstones (but this may change in the future)

Performance is basically the same as the zig hashmap.

It's a drop-in replacement for the std hashmap, API is the same except for addition of `get_ref_or_default`.

## Motivation

Main motivation is performance, but also:

- std HashMap copies keys, I want to manage the memory.
- has a get_or_put (in zig) API, I hit this extremely often.
- could also implement an ordered map (but this is not high priority)

## TODO

- compare to odin as well as zig
- implement removal with tombstones?
- check that Metadata bitstruct and fingerprint is used correctly.
- check that clear with `zero` is done correctly.
- more tests?
- fuzz?
- finish martin benchmarks
- test on c3 hashmap tests
- docs and review

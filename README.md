# Hashmap for c3.

I've taken the general idea of the zig hashmap:
- open address, linear probing
- metadata array, where each metadata is a char with 1 bit `used` and 7 bits `fingerprint`. This should allow a higher load factor, but I have not rigorously tested this.

The c3 std hashmap is chained; there are pros and cons using open addressing vs. chaining, you should choose according to your workload.

Performance is slightly slower than the zig hashmap. (Tried zig's one-allocation strategy, was not able to make it perform well in C3).

It's a drop-in replacement for the std hashmap, API is the same except for addition of `get_ref_or_default`.

(There's also an ordered map in this repo; development is not serious at this time)

## Motivation

- exploring performance
- std HashMap copies keys, I want to manage the memory and not copy keys.
- has a get_or_put (in zig) API, I hit this extremely often.
- could also implement an ordered map (but this is not high priority)

# Some Numbers

From my workstation, "AMD Ryzen 7 3700X 8-Core Processor", 64GB RAM.

This is just one benchmark, please take with a grain of salt and measure your own workload.

Note that random number generation took a non-trivial amount of time. For C3 benchmarks, I used a
port of the zig random number generator.

Also, sorry for those that don't use [`werk`](https://github.com/simonask/werk), I may set up a shell script
or something at some point.

In the following benches, `UnorderedMap` is this repo's implementation, `HashMap` is C3's std implementation.

`werk quickbench` 1M ints
```
Insert and erase 1000000 int UnorderedMap
  insert 1000000 int:           63ms821µs799ns
  get 1000000 int:              27ms959µs903ns
  clear:                        27µs20ns
  reinsert 1000000 int:         22ms986µs580ns
  remove 1000000 int:           27ms566µs675ns
Insert and erase 1000000 int HashMap
  insert 1000000 int:           258ms304µs955ns
  get 1000000 int:              42ms557µs553ns
  clear:                        36ms430µs934ns
  reinsert 1000000 int:         130ms975µs957ns
  remove 1000000 int:           56ms144µs486ns
Insert and erase 1000000 int: zig hashmap
  insert 1000000 int: 56ms
  get 1000000 int: 23ms
  clear: 0ms
  reinsert 1000000 int: 20ms
  remove 1000000 int: 18ms
Insert and erase 1000000 int odin hashmap
  insert 1000000 int: 276.177661ms
  get 1000000 int: 96.390677ms
  clear: 761.041µs
  reinsert 1000000 int: 119.684118ms
  remove 1000000 int: 111.459781ms
```

`werk bench`, 100M ints
```
Insert and erase 100000000 int UnorderedMap
  insert 100000000 int:         10.772s
  get 100000000 int:            7.784s
  clear:                        8ms602µs403ns
  reinsert 100000000 int:               7.475s
  remove 100000000 int:         7.893s
Insert and erase 100000000 int HashMap
  insert 100000000 int:         32.36s
  get 100000000 int:            7.809s
  clear:                        5.45s
  reinsert 100000000 int:               21.528s
  remove 100000000 int:         13.962s
Insert and erase 100000000 int: zig hashmap
  insert 100000000 int: 12139ms
  get 100000000 int: 8171ms
  clear: 8ms
  reinsert 100000000 int: 8041ms
  remove 100000000 int: 5682ms
Insert and erase 100000000 int odin hashmap
  insert 100000000 int: 51.809027928s
  get 100000000 int: 21.678941781s
  clear: 69.622163ms
  reinsert 100000000 int: 27.410020723s
  remove 100000000 int: 23.921319843s
```

Eyeballed memory usage on `werk bench` 100M ints with htop:
```
unordered map: 2.3GB
hashmap: 8GB on first insert -> 13.7GB on reinsert
zig: 2.3GB
odin: 3.0GB (but strange pattern, "overallocated" to 4.6GB before dropping back to 3.0GB? Same pattern happened on the way also.)
```

Other perf notes: For smaller inputs, like `/usr/share/dict/words` (100,000 words) or [`related_post_gen`](https://github.com/jinyus/related_post_gen), zig and c3 stdlib hashmaps perform about the same for speed, but odin is still noticeably slower.

## TODO

- fuzz?
- more tests?
- finish martin benchmarks
- docs and review

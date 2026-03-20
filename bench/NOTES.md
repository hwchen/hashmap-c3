# 2025-02-16

Started doing real benchmarks, following

https://martin.ankerl.com/2019/04/01/hashmap-benchmarks-01-overview/

On laptop so far:
```
hashmap-c3 ttrv|🈳 > werk
Construct/destruct OrderedMap: 122ns
Construct/destruct UnorderedMap: 76ns
Construct/destruct HashMap: 59ns
Construct, insert one int, destruct OrderedMap: 8.985s
Construct, insert one int, destruct UnorderedMap: 5.56s
Construct, insert one int, destruct HashMap: 4.932s
Insert and erase 100M int UnorderedMap
  insert 100M int: 15.783s
Insert and erase 100M int HashMap
```

On chenbot (desktop workstation):
```
hashmap-c3 rsvt|🈳 > werk
Construct/destruct OrderedMap: 110ns
Construct/destruct UnorderedMap: 30ns
Construct/destruct HashMap: 30ns
Construct, insert one int, destruct OrderedMap: 3.836s
Construct, insert one int, destruct UnorderedMap: 2.187s
Construct, insert one int, destruct HashMap: 2s
Insert and erase 100M int UnorderedMap
  insert 100M int: 11.68s
Insert and erase 100M int HashMap
  insert 100M int: 36.663s
```
Visual inspection of htop shows about 9.2GB usage, which is why I can't run the benchmark on my laptop.

Max memory for unordered_map is about 2.4GB, which seems to be more expected considering martin's numbers.

TODO:
- Should probably make sure to add some more tests, I'm a little nervous that unordered_map is just not work because of a bug.
- ordered_map I might keep around, but it's currently much slower.
- should add a memory tracker.

# 2025-02-17

I made changes to the hash: to always use fnv64a to get 64bits for the fingerprint.

Also added zig to benchmark. Maybe should add odin?

on chenbot:
```
hashmap-c3 rsvt| > werk bench
[ ok ] /zig-insert-100M
Insert and erase 100M int OrderedMap
  insert 100M int: 23.844s
  clear: 228ms670µs434ns
  reinsert 100M int: 10.639s
  remove 100M int: 22.809s
Insert and erase 100M int UnorderedMap
  insert 100M int: 11.648s
  clear: 232ms434µs64ns
  reinsert 100M int: 7.998s
  remove 100M int: 6.482s
Insert and erase 100M int HashMap
  insert 100M int: 34.999s
  clear: 6.517s
  reinsert 100M int: 22.508s
  remove 100M int: 12.947s
Insert and erase 100M int: zig hashmap
  insert 100M int: 12s
  clear: 0s
  reinsert 100M int: 7s
  remove 100M int: 5s
[ ok ] bench
```
3.6GB ordered map
2.3GB unordered map
9.5GB initial insert, 16.5 on reinsert std hashmap
2.3GB zig hashmap

Now with odin, on chenbot:
```
Parent commit: urzyywzt 9d1fd2f0 main | Bench odin insert_100M
hashmap-c3 rsvt| > werk bench
[ ok ] /odin-insert-100M
[ ok ] /benchit
Insert and erase 100M int OrderedMap
  insert 100M int: 23.898s
  clear: 225ms669µs525ns
  reinsert 100M int: 10.656s
  remove 100M int: 22.924s
Insert and erase 100M int UnorderedMap
  insert 100M int: 11.686s
  clear: 8ms887µs633ns
  reinsert 100M int: 8.4s
  remove 100M int: 6.579s
Insert and erase 100M int HashMap
  insert 100M int: 34.241s
  clear: 6.532s
  reinsert 100M int: 22.777s
  remove 100M int: 11.642s
Insert and erase 100M int: zig hashmap
  insert 100M int: 12s
  clear: 0s
  reinsert 100M int: 8s
  remove 100M int: 5s
Insert and erase 100M int odin hashmap
  insert 100M int: 51.872967706s
  clear: 72.220116ms
  reinsert 100M int: 27.339313099s
  remove 100M int: 23.947247196s
[ ok ] bench
```
3GB odin hashmap (but weird allocation pattern, goes up and down during realloc)

Odin is quite slow, I manually checked the times to make sure I didn't somehow implement the timer incorrectly. Maybe it's not a big deal for the language because they use it mostly for config or small hashmaps (because most users make games with Odin) and vectors/array do the heavy lifting.

But for data processing (like checking uniqueness), fast hashmaps for all scales are important.

## 2025-02-26

I think there's a bug with the fingerprint.

- After implementing `get` benchmark, zig's get is way faster
- zig's get is faster than reinsert, but unorderedmap get is slower than reinsert.

```
chenbot% ./target/benchit-zig 1000000
Insert and erase 1000000 int: zig hashmap
  insert 1000000 int: 59ms
  get 1000000 int: 13ms
  clear: 0ms
  reinsert 1000000 int: 19ms
  remove 1000000 int: 14ms
chenbot% ./target/benchit 1000000
Insert and erase 1000000 int UnorderedMap
  insert 1000000 int:           63ms583µs71ns
  get 1000000 int:              32ms275µs35ns
  clear:                        28µs330ns
  reinsert 1000000 int:         27ms46µs909ns
  remove 1000000 int:           26ms411µs159ns
```

## 2025-07-20

Moving from wyhash (my port from zig) to new wyhash2 implementation in std.

Numbers from my laptop:

wyhash
```
Insert and erase 100000000 int UnorderedMap
  insert 100000000 int:         16.241s
  get 100000000 int:            10.958s
  clear:                        14ms635µs110ns
  reinsert 100000000 int:               9.673s
  remove 100000000 int:         11.202s
```

wyhash2
```
Insert and erase 100000000 int UnorderedMap
  insert 100000000 int:         13.517s
  get 100000000 int:            8.627s
  clear:                        16ms197µs871ns
  reinsert 100000000 int:               9.147s
  remove 100000000 int:         8.674s
Insert and erase 100000000 int HashMap
```

I might have made a mistake in my port, with unaligned loads (those were specifically fixed in wyhash2 PR). But it's in stdlib, so I'd rather use it anyways.

# 2026-03-20

Some quick benches, on new (old) laptop: Thinkpad T14s 3rd gen, AMD Ryzen 5 PRO 6650U (12) @ 4.58 GHz.

Added swisstable port (from Rust), AndrewCodeDev: https://github.com/andrewCodeDev/metaphor/blob/main/src/utils/swisstable.c3

```
hashmap-c3 uolo| > werk quickbench
[ ok ] /benchit
Insert and erase 1000000 int SwissTable{int, int}
  insert 1000000 int:           54ms61µs130ns
  get 1000000 int:              34ms4µs810ns
  clear:                        34µs571ns
  reinsert 1000000 int:         26ms322µs201ns
  remove 1000000 int:           42ms46µs56ns
Insert and erase 1000000 int UnorderedMap{int, int}
  insert 1000000 int:           58ms179µs252ns
  get 1000000 int:              41ms639µs999ns
  clear:                        36µs178ns
  reinsert 1000000 int:         24ms568µs276ns
  remove 1000000 int:           34ms166µs493ns
Insert and erase 1000000 int HashMap{int, int}
  insert 1000000 int:           232ms811µs852ns
  get 1000000 int:              45ms383µs771ns
  clear:                        50ms272µs521ns
  reinsert 1000000 int:         175ms980µs676ns
  remove 1000000 int:           64ms14µs421ns
Insert and erase 1000000 int: zig hashmap
  insert 1000000 int: 59ms
  get 1000000 int: 31ms
  clear: 0ms
  reinsert 1000000 int: 24ms
  remove 1000000 int: 25ms
Insert and erase 1000000 int odin hashmap
  insert 1000000 int: 315.428288ms
  get 1000000 int: 76.878067ms
  clear: 1.06459ms
  reinsert 1000000 int: 145.81106ms
  remove 1000000 int: 146.101041ms
```

```
hashmap-c3 uolo| ❯ werk bench
[ ok ] /benchit
Insert and erase 100000000 int SwissTable{int, int}
  insert 100000000 int:         11.438s
  get 100000000 int:            8.119s
  clear:                        11ms219µs583ns
  reinsert 100000000 int:               9.586s
  remove 100000000 int:         10.441s
Insert and erase 100000000 int UnorderedMap{int, int}
  insert 100000000 int:         12.472s
  get 100000000 int:            8.98s
  clear:                        11ms364µs923ns
  reinsert 100000000 int:               8.247s
  remove 100000000 int:         7.86s
Insert and erase 100000000 int: zig hashmap
  insert 100000000 int: 13914ms
  get 100000000 int: 9027ms
  clear: 11ms
  reinsert 100000000 int: 9079ms
  remove 100000000 int: 6505ms
```
(On my laptop, HashMap bombs out, as does odin)

TODO: switch to std hash, check load factor for zig hashmap (80%)

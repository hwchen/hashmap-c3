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

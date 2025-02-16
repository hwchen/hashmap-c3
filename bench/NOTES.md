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
9.5GB std hashmap

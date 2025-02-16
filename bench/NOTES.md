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

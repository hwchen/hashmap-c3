module test_std @test;
import std::collections::list;
import std::collections::map;
import std::sort;
import std::io;

import unordered_map;

alias TestHashMap = UnorderedMap{String, usz};

struct MapTest
{
    String key;
    usz value;
}
alias ListMap = List{MapTest};

fn void map()
{
    TestHashMap m;
    assert(!m.is_initialized());
    m.tinit();
    assert(m.is_initialized());
    assert(m.is_empty());
    assert(m.len() == 0);

    m.set("a", 1);
    assert(!m.is_empty());
    assert(m.len() == 1);
    m.remove("a");
    assert(m.is_empty());

    MapTest[] tcases = { {"key1", 0}, {"key2", 1}, {"key3", 2} };
    foreach (tc : tcases)
    {
        m.set(tc.key, tc.value);
    }
    assert(m.len() == tcases.len);
    foreach (tc : tcases)
    {
        usz v = m.get(tc.key)!!;
        assert(tc.value == v);
    }

    ListMap list;
    list.tinit();
    m.@each(;String key, usz value)
    {
        list.push({key, value});
    };
    assert(list.len() == tcases.len);
    quicksort(&list, fn int (MapTest a, MapTest b) => (int)(a.value - b.value));
    foreach (i, tc : tcases)
    {
        assert(tc.key == list[i].key);
        assert(tc.value == list[i].value);
    }
}

alias FooMap = UnorderedMap{char, Foobar};
enum Foobar : inline char
{
    FOO,
    BAR,
    BAZ
}

enum Foobar2 : const inline int
{
	ABC = 3,
	DEF = 5,
}

fn void map_inline_enum()
{
	FooMap x;
	x[Foobar.BAZ] = FOO;
	x[Foobar2.ABC] = BAR;
	// test should be fixed; depends on order
	//test::eq(string::tformat("%s", x), "{ 2: FOO, 3: BAR }");
	test::eq(x.len(), 2);
	test::eq(x.get(Foobar.BAZ)!!, Foobar.FOO);
	test::eq(x.get(Foobar2.ABC)!!, Foobar.BAR);
	x.free();
}

fn void map_remove()
{
	TestHashMap m;
	assert(!@ok(m.remove("A")));
	m.tinit();
	assert(!@ok(m.remove("A")));
	m.set("A", 0);
	assert(@ok(m.remove("A")));
}

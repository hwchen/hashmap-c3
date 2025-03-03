module test;
import std::collections;
import ordered_map;
import unordered_map;

fn void test_ordered_map_basic() @test {
	test_map_basic(OrderedMap(<String, usz>));
}

fn void test_unordered_map_basic() @test {
	test_map_basic(UnorderedMap(<String, usz>));
}

macro debug_cells(map) {
	foreach (idx, cell : map.cells) {
		io::printfn("idx %d", idx);
		io::printfn("key %s", cell.entry.key);
		io::printfn("value %d", cell.entry.value);
		io::printfn("used %s", cell.used);
	}
}

macro test_map_basic($MapImpl) {
	$MapImpl map;
	map.init(allocator::temp(), capacity: 2);
	map.set("A", 0);
	map.set("AC", 1);
	map.set("AC", 2);
	map.set("ACGT", 3);

	assert(map.has_key("A"));
	assert(map.has_key("AC"));
	assert(map.has_key("ACGT"));
	assert(!map.has_key("ZZZZ"));

	assert(map.get("A")!! == 0);
	assert(map.get("AC")!! == 2);
	assert(map.get("ACGT")!! == 3);

	usz total = 0;
	map.@each(; String k, usz v) {
		//io::printfn("%s, %d", k, v);
		total += 1;
	};
	assert(total == 3);
	assert(map.len() == 3, "Found %d, expected 3", map.len());

	map.remove("A");
	assert(map.len() == 2);
	assert(!map.has_key("A"));
}

fn void test_ordered_map_copy() @test {
	test_map_copy(OrderedMap(<String, usz>));
}

fn void test_unordered_map_copy() @test {
	test_map_copy(UnorderedMap(<String, usz>));
}

macro test_map_copy($MapImpl) {
	$MapImpl old_map;
	old_map.init(allocator::temp(), capacity: 2);
	old_map.set("A", 0);
	old_map.set("AC", 1);
	old_map.set("ACGT", 2);

	$MapImpl new_map = old_map.copy(allocator::temp());

	assert(new_map.has_key("A"));
	assert(new_map.has_key("AC"));
	assert(new_map.has_key("ACGT"));

	assert(new_map.get("A")!! == 0);
	assert(new_map.get("AC")!! == 1);
	assert(new_map.get("ACGT")!! == 2);

	assert(new_map.len() == 3, "Found %d, expected 3", new_map.len());
}

def IntList = List(<int>);
fn void test_unordered_map_get_ref_or_default() @test {
	test_map_get_ref_or_default(UnorderedMap(<String, IntList>));
}

macro test_map_get_ref_or_default($MapImpl) {
	$MapImpl map;
	map.init(allocator::temp(), capacity: 2);
	IntList intlist;
	intlist.temp_init();
	map.get_ref_or_default("A", intlist);
	assert(map.has_key("A"));
	assert(map.get("A")!!.len() == 0);
	map.get_ref("A")!!.push(1);
	assert(map.get("A")!![0] == 1);
}

fn void test_ordered_map_clear() @test {
	test_map_clear(OrderedMap(<int, int>));
}

fn void test_unordered_map_clear() @test {
	test_map_clear(UnorderedMap(<int, int>));
}

macro test_map_clear($MapImpl) {
	$MapImpl map;
	map.init(allocator::temp(), capacity: 2);
	map.set(0, 10);
	map.set(1, 11);
	assert(map.get(0)!! == 10);
	assert(map.get(1)!! == 11);
	assert(map.len() == 2);
	map.clear();
	assert(map.len() == 0);
	map.set(2, 12);
	map.set(3, 13);
	map.set(4, 14);
	assert(map.get(2)!! == 12);
	assert(map.get(3)!! == 13);
	assert(map.get(4)!! == 14);
	assert(map.len() == 3);
}

fn void test_fingerprint() @test {
	ulong hash = ulong.max;
	char fingerprint = unordered_map::take_fingerprint(<int, int>)(hash);
	assert(fingerprint == char.max >> 1);
	assert(fingerprint == (char)(hash >> (64 - 7)));
}

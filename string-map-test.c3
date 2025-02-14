module test;
import string_map;

fn void! test_string_map() @test {
	StringMap(<usz>) map;
	map.init(allocator::temp(), capacity: 3);
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

fn void! test_string_map_copy() @test {
	StringMap(<usz>) old_map;
	old_map.init(allocator::temp(), capacity: 3);
	old_map.set("A", 0);
	old_map.set("AC", 1);
	old_map.set("ACGT", 2);

	StringMap(<usz>) new_map = old_map.copy(allocator::temp());

	assert(new_map.has_key("A"));
	assert(new_map.has_key("AC"));
	assert(new_map.has_key("ACGT"));

	assert(new_map.get("A")!! == 0);
	assert(new_map.get("AC")!! == 1);
	assert(new_map.get("ACGT")!! == 2);

	assert(new_map.len() == 3, "Found %d, expected 3", new_map.len());
}

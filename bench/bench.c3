// Benchmark from
// - https://martin.ankerl.com/2019/04/01/hashmap-benchmarks-01-overview/
// - https://github.com/ziglang/zig/pull/5999

module bench;
import std::collections;
import std::io;
import std::time::clock;
import std::math::random;
import ordered_map;
import unordered_map;

fn void main() {
	//construction_destruction(OrderedMap(<String, ulong>));
	//construction_destruction(UnorderedMap(<String, ulong>)no-capture );
	//construction_destruction(HashMap(<String, ulong>));
	//construction_insert_one_int_destruction(OrderedMap(<int, int>));
	//construction_insert_one_int_destruction(UnorderedMap(<int, int>));
	//construction_insert_one_int_destruction(HashMap(<int, int>));

	//insert_erase_100M_int(OrderedMap(<int, int>));
	insert_erase_100M_int(UnorderedMap(<int, int>));

	// On chenbot, takes 9.2GB, where unordered_map takes 2.4GB
	//insert_erase_100M_int(HashMap(<int, int>));
}

macro construction_destruction($MapImpl) {
	usz result;
	Clock start = clock::now();
	for (usz n = 0; n < 100_000_000; n += 1) {
		$MapImpl mymap;
		result += mymap.len();
	}
	NanoDuration end = start.to_now();
	assert(result == 0);
	io::eprintfn("Construct/destruct %s: %s", $MapImpl.nameof, end);
}

macro construction_insert_one_int_destruction($MapImpl) {
	usz result;
	Clock start = clock::now();
	for (int n = 0; n < 50_000_000; n += 1) {
		@pool() {
			$MapImpl mymap;
			mymap.init(allocator::temp());
			mymap.set(n, 0);
			result += mymap.len();
		};
	}
	NanoDuration end = start.to_now();
	assert(result == 0);
	io::eprintfn("Construct, insert one int, destruct %s: %s", $MapImpl.nameof, end);
}

macro insert_erase_100M_int($MapImpl) {
	io::eprintfn("Insert and erase 100M int %s", $MapImpl.nameof);
	Sfc64Random rng;
	int seed = 29301093;
	random::seed(&rng, seed);
	@pool() {
		$MapImpl mymap;
		mymap.init(allocator::temp());

		// 100M inserts
		random::seed(&rng, seed);
		Clock clock = clock::now();
		for (int n = 0; n < 100_000_000; n += 1) {
			int x = random::next_in_range(&rng, 0, int.max);
			mymap.set(x, n);
		}
		NanoDuration insert_0_time = clock.mark();
		io::eprintfn("  insert 100M int: %s", insert_0_time);

		// Clear
		clock.mark();
		mymap.clear();
		NanoDuration clear_time = clock.mark();
		io::eprintfn("  clear: %s", clear_time);

		// 100M inserts
		random::seed(&rng, seed);
		clock.mark();
		for (int n = 0; n < 100_000_000; n += 1) {
			int x = random::next_in_range(&rng, 0, int.max);
			mymap.set(x, n);
		}
		NanoDuration insert_1_time = clock.mark();
		io::eprintfn("  reinsert 100M int: %s", insert_1_time);

		// 100M removals
		random::seed(&rng, seed);
		clock.mark();
		for (int n = 0; n < 100_000_000; n += 1) {
			int x = random::next_in_range(&rng, 0, int.max);
			mymap.remove(x);
		}
		NanoDuration remove_time = clock.mark();
		assert(mymap.len() == 0);
		io::eprintfn("  remove 100M int: %s", remove_time);
	};
}

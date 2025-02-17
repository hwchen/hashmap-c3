package insert_100M

import "core:fmt"
import "core:math/rand"
import "core:time"

main :: proc() {
	fmt.eprintfln("Insert and erase 100M int odin hashmap")
	seed: u64 = 29301093
	mymap := make(map[int]int)

	// 100M inserts
	rand.reset(seed)
	clock := time.tick_now()
	for n := 0; n < 100_000_000; n += 1 {
		x := rand.int_max(max(int))
		mymap[x] = n
	}
	insert_0_time := time.tick_lap_time(&clock)
	fmt.eprintfln("  insert 100M int: %s", insert_0_time)

	// Clear
	clear(&mymap)
	clear_time := time.tick_lap_time(&clock)
	fmt.eprintfln("  clear: %s", clear_time)

	// 100M inserts
	rand.reset(seed)
	for n := 0; n < 100_000_000; n += 1 {
		x := rand.int_max(max(int))
		mymap[x] = n
	}
	insert_1_time := time.tick_lap_time(&clock)
	fmt.eprintfln("  reinsert 100M int: %s", insert_1_time)

	// 100M removals
	rand.reset(seed)
	for n := 0; n < 100_000_000; n += 1 {
		x := rand.int_max(max(int))
		delete_key(&mymap, x)
	}
	remove_time := time.tick_lap_time(&clock)
	assert(len(mymap) == 0)
	fmt.eprintfln("  remove 100M int: %s", remove_time)
}

package insert_100M

import "core:fmt"
import "core:math/rand"
import "core:os"
import "core:strconv"
import "core:time"

main :: proc() {
	limit := 100_000_000
	if len(os.args) == 2 {
		limit, _ = strconv.parse_int(os.args[1])
	}
	fmt.eprintfln("Insert and erase %d int odin hashmap", limit)
	seed: u64 = 29301093
	mymap := make(map[int]int)

	// 100M inserts
	rand.reset(seed)
	clock := time.tick_now()
	for n := 0; n < limit; n += 1 {
		x := rand.int_max(max(int))
		mymap[x] = n
	}
	insert_0_time := time.tick_lap_time(&clock)
	fmt.eprintfln("  insert %d int: %s", limit, insert_0_time)

	// Gets
	rand.reset(seed)
	for n := 0; n < limit; n += 1 {
		x := rand.int_max(max(int))
		n := mymap[x]
	}
	get_time := time.tick_lap_time(&clock)
	fmt.eprintfln("  get %d int: %s", limit, get_time)

	// Clear
	clear(&mymap)
	clear_time := time.tick_lap_time(&clock)
	fmt.eprintfln("  clear: %s", clear_time)

	// 100M inserts
	rand.reset(seed)
	for n := 0; n < limit; n += 1 {
		x := rand.int_max(max(int))
		mymap[x] = n
	}
	insert_1_time := time.tick_lap_time(&clock)
	fmt.eprintfln("  reinsert %d int: %s", limit, insert_1_time)

	// 100M removals
	rand.reset(seed)
	for n := 0; n < limit; n += 1 {
		x := rand.int_max(max(int))
		delete_key(&mymap, x)
	}
	remove_time := time.tick_lap_time(&clock)
	assert(len(mymap) == 0)
	fmt.eprintfln("  remove %d int: %s", limit, remove_time)
}

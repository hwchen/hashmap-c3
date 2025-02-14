// A basic bench; reads /usr/share/dict/words and inserts into hashmap

module bench;
import std::collections;
import std::io;
import std::time::clock;
import string_map;

def MyMap = StringMap(<ulong>);

fn void main() {
	String words = (String)file::load_new("/usr/share/dict/words", allocator::heap())!!;
	String[] lines = words.split("\n");

	benchit("mymap", MyMap, lines);
	benchit("stdhashmap", HashMap(<String, ulong>), lines);
}

macro benchit(label, $MapImpl, lines) {
	$MapImpl mymap;
	mymap.init(allocator::heap());
	Clock clock = clock::now();
	foreach (line : lines) {
		mymap.set(line, 1);
	}
	NanoDuration insert_timing = clock.mark();
	io::eprintfn("%s insert time: %s", label, insert_timing);
	foreach (line : lines) {
		mymap.get(line)!!;
	}
	NanoDuration get_timing = clock.mark();
	io::eprintfn("%s get time: %s", label, get_timing);
	NanoDuration total = insert_timing + get_timing;
	io::eprintfn("%s total time: %s", label, total);
}

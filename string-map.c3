// Doesn't make much difference perf-wise
module string_map(<Value>);
import std::collections::list;
import std::io;

def StringList = List(<String>);
def ValueList = List(<Value>);

// Does not handle empty strings as keys.
struct StringMap {
	Allocator alloc;
	usz count; // TODO remove count, now that we're an arraylist
	usz[] entries; // contains index to key/value array
	StringList keys;
	ValueList values;
}

fn void StringMap.init(&self, Allocator allocator, int capacity = 16) {
	self.alloc = allocator;
	self.entries = allocator::new_array(self.alloc, usz, capacity);

	StringList stringlist;
	stringlist.new_init(allocator: self.alloc);
	stringlist.push(""); // junk value to prevent pointer to 0 in entries
	self.keys = stringlist;

	ValueList valuelist;
	valuelist.new_init(allocator: self.alloc);
	valuelist.push(usz.max); // junk value to prevent pointer to 0 in entries
	self.values = valuelist;
}

// returns true if entry already exists.
fn bool StringMap.set(&self, String key, Value value) {
	// If the map isn't initialized, use the defaults to initialize it.
	if (!self.alloc) {
		self.init(allocator::heap());
	}

	// max load 50%
	if ((self.count + 1) * 2 >= self.entries.len) {
	    self.realloc();
	}

	return self.add_entry(key, value);
}

fn bool StringMap.add_entry(&self, String key, Value value) @local {
	usz hash = key.hash();
	usz idx = hash % self.entries.len;
	while (true) {
		usz entry_idx = self.entries[idx];
		if (entry_idx == 0) {
			self.count += 1;
			self.entries[idx] = self.keys.len();
			self.keys.push(key);
			self.values.push(value);
			return true;
		}
		String k = self.keys[entry_idx];
		if (k == key) {
			self.values[entry_idx] = value;
			return false;
		}
		idx = (idx + 1) % self.entries.len;
	}
}

fn Value*! StringMap.get_ref(&self, String key) {
	if (!self.count) return SearchResult.MISSING?;
	usz hash = key.hash();
	usz idx = hash % self.entries.len;

	while (true) {
		usz entry_idx = self.entries[idx];
		if (entry_idx == 0) {
			return SearchResult.MISSING?;
		}
		String k = self.keys[entry_idx];
		if (k == key) {
			return &self.values[entry_idx];
		}
		idx = (idx + 1) % self.entries.len;
	}
}

fn Value! StringMap.get(&self, String key) {
	return *self.get_ref(key);
}

fn bool StringMap.has_key(&self, String key) {
	return @ok(self.get_ref(key));
}

fn void StringMap.realloc(&self) {
	// TODO can I do this without reallocating the strings and values?
	usz[] old_entries = self.entries;
	StringList old_keys = self.keys;
	ValueList old_values = self.values;

	self.entries = allocator::new_array(self.alloc, usz, old_entries.len * 2);

	StringList new_keys;
	new_keys.new_init(old_keys.len(), self.alloc);
	new_keys.push(""); // junk value to prevent pointer to 0 in entries
	self.keys = new_keys;

	ValueList new_values;
	new_values.new_init(old_values.len(), self.alloc);
	new_values.push(usz.max); // junk value to prevent pointer to 0 in entries
	self.values = new_values;

	// Start at 1, because 0 is junk value
	for (usz i = 1; i < old_keys.len(); i += 1) {
		self.add_entry(old_keys[i], old_values[i]);
	}
	self.count = old_keys.len() - 1; // account for junk value

	allocator::free(self.alloc, old_entries);
	old_keys.free();
	old_values.free();
}

macro StringMap.@each(self; @body(key, value)) {
	// start at 1 because 0 is junk value
	for (usz i = 1; i < self.keys.len(); i += 1) {
		@body(self.keys[i], self.values[i]);
	}
}

fn usz StringMap.len(&map) @inline {
	return map.count;
}

fn void! StringMap.remove(&self, String key) @maydiscard {
	if (!self.count) return SearchResult.MISSING?;
	usz hash = key.hash();
	usz idx = hash % self.entries.len;

	while (true) {
		usz entry_idx = self.entries[idx];
		if (entry_idx == 0) {
			return SearchResult.MISSING?;
		}
		String k = self.keys[entry_idx];
		if (k == key) {
			self.keys.remove_at(entry_idx);
			self.values.remove_at(entry_idx);
			self.entries[idx] = 0;
			self.count -= 1;
			// TODO swap remove?
			return;
		}
		idx = (idx + 1) % self.entries.len;
	}
}

// Shallow copy on keys string data, only copies the fat pointer.
fn StringMap StringMap.copy(&old, Allocator alloc) {
	StringMap(<Value>) new;
	new.alloc = alloc;
	new.count = old.count;
	new.entries = allocator::new_array(new.alloc, usz, old.entries.len);
	new.entries[..] = old.entries[..];

	String[] old_keys = old.keys.to_new_array();
	StringList new_keys;
	new_keys.new_init_with_array(old_keys, new.alloc);
	new.keys = new_keys;

	Value[] old_values = old.values.to_new_array();
	ValueList new_values;
	new_values.new_init_with_array(old_values, new.alloc);
	new.values = new_values;

	return new;
}

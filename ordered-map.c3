module ordered_map(<Key, Value>);
import std::collections::list;
import std::io;

def KeyList = List(<Key>);
def ValueList = List(<Value>);

// Does not handle empty strings as keys.
struct OrderedMap {
	Allocator alloc;
	usz count; // TODO remove count, now that we're an arraylist
	usz[] entries; // contains index to key/value array
	KeyList keys;
	ValueList values;
}

fn void OrderedMap.init(&self, Allocator allocator, int capacity = 16) {
	// check that capacity is a power of 2
	assert((capacity & (capacity - 1)) == 0, "capacity must be a power of 2");

	self.alloc = allocator;
	self.entries = allocator::new_array(self.alloc, usz, capacity);

	KeyList keylist;
	keylist.new_init(allocator: self.alloc);
	keylist.push({}); // junk value to prevent pointer to 0 in entries
	self.keys = keylist;

	ValueList valuelist;
	valuelist.new_init(allocator: self.alloc);
	valuelist.push({}); // junk value to prevent pointer to 0 in entries
	self.values = valuelist;
}

// returns true if entry already exists.
fn bool OrderedMap.set(&self, Key key, Value value) {
	// If the map isn't initialized, use the defaults to initialize it.
	if (!self.alloc) {
		self.init(allocator::heap());
	}
	// max load 80%
	if ((float)self.count * 1.25 >= self.entries.len) {
		self.realloc();
	}

	return self.add_entry(key, value);
}

fn bool OrderedMap.add_entry(&self, Key key, Value value) @local {
	usz hash = key.hash();
	usz mask = self.entries.len - 1;
	usz idx = hash & mask;
	while (true) {
		usz entry_idx = self.entries[idx];
		if (entry_idx == 0) {
			self.count += 1;
			self.entries[idx] = self.keys.len();
			self.keys.push(key);
			self.values.push(value);
			return true;
		}
		Key k = self.keys[entry_idx];
		if (k == key) {
			self.values[entry_idx] = value;
			return false;
		}
		idx = (idx + 1) & mask;
	}
}

fn Value*! OrderedMap.get_ref(&self, Key key) {
	if (!self.count) return SearchResult.MISSING?;
	usz hash = key.hash();
	usz mask = self.entries.len - 1;
	usz idx = hash & mask;

	while (true) {
		usz entry_idx = self.entries[idx];
		if (entry_idx == 0) {
			return SearchResult.MISSING?;
		}
		Key k = self.keys[entry_idx];
		if (k == key) {
			return &self.values[entry_idx];
		}
		idx = (idx + 1) & mask;
	}
}

fn Value! OrderedMap.get(&self, Key key) {
	return *self.get_ref(key);
}

fn bool OrderedMap.has_key(&self, Key key) {
	return @ok(self.get_ref(key));
}

fn void OrderedMap.realloc(&self) {
	// TODO can I do this without reallocating the strings and values?
	usz[] old_entries = self.entries;
	KeyList old_keys = self.keys;
	ValueList old_values = self.values;

	self.entries = allocator::new_array(self.alloc, usz, old_entries.len * 2);

	KeyList new_keys;
	new_keys.new_init(old_keys.len(), self.alloc);
	new_keys.push({}); // junk value to prevent pointer to 0 in entries
	self.keys = new_keys;

	ValueList new_values;
	new_values.new_init(old_values.len(), self.alloc);
	new_values.push({}); // junk value to prevent pointer to 0 in entries
	self.values = new_values;

	// Start at 1, because 0 is junk value
	usz old_count = self.count;
	self.count = 0;
	for (usz i = 1; i < old_keys.len(); i += 1) {
		self.add_entry(old_keys[i], old_values[i]);
	}
	self.count = old_keys.len() - 1; // account for junk value

	allocator::free(self.alloc, old_entries);
	old_keys.free();
	old_values.free();
}

macro OrderedMap.@each(self; @body(key, value)) {
	// start at 1 because 0 is junk value
	for (usz i = 1; i < self.keys.len(); i += 1) {
		@body(self.keys[i], self.values[i]);
	}
}

fn usz OrderedMap.len(&map) @inline {
	return map.count;
}

fn void! OrderedMap.remove(&self, Key key) @maydiscard {
	if (!self.count) return SearchResult.MISSING?;
	usz hash = key.hash();
	usz idx = hash % self.entries.len;

	while (true) {
		usz entry_idx = self.entries[idx];
		if (entry_idx == 0) {
			return SearchResult.MISSING?;
		}
		Key k = self.keys[entry_idx];
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
fn OrderedMap OrderedMap.copy(&old, Allocator alloc) {
	OrderedMap(<Key, Value>) new;
	new.alloc = alloc;
	new.count = old.count;
	new.entries = allocator::new_array(new.alloc, usz, old.entries.len);
	new.entries[..] = old.entries[..];

	Key[] old_keys = old.keys.to_new_array(new.alloc);
	KeyList new_keys;
	new_keys.new_init_with_array(old_keys, new.alloc);
	new.keys = new_keys;

	Value[] old_values = old.values.to_new_array(alloc);
	ValueList new_values;
	new_values.new_init_with_array(old_values, new.alloc);
	new.values = new_values;

	return new;
}

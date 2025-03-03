<*
 @require $defined(Key{}.myhash()) `No .myhash function found on the key`
*>
module unordered_map(<Key, Value>);
import std::collections::list;
import std::io;
import hash;

struct Entry {
	Key key;
	Value value;
}

bitstruct Metadata: char {
	char fingerprint: 0..6;
	bool used: 7;
}

// uses high 7 bits of hash for fingerprint, as low bits are
// already used to find the index.
fn void Metadata.set_fingerprint(&m, ulong hash) @inline {
	m.fingerprint = (char)(hash >> (64 - 7));
}

fn bool Metadata.matches_fingerprint(m, ulong hash) @inline {
	return m.fingerprint == (char)(hash >> (64 - 7));
}

fn void Metadata.set_tombstone(&m) @inline {
	m.fingerprint = 1;
	m.used = false;
}

fn bool Metadata.is_tombstone(m) @inline {
	// depends on layout of bitstruct
	return (char)m == 1;
}

// Does not handle empty strings as keys.
struct UnorderedMap (Printable) {
	Allocator allocator;
	usz count;
	Metadata[] metadatas;
	Entry[] entries;
}

fn void UnorderedMap.init(&self, Allocator allocator, int capacity = 16) {
	// check that capacity is a power of 2
	assert((capacity & (capacity - 1)) == 0, "capacity must be a power of 2");

	self.allocator = allocator;
	self.metadatas = allocator::new_array(self.allocator, Metadata, capacity);
	self.entries = allocator::new_array(self.allocator, Entry, capacity);
}

fn void UnorderedMap.temp_init(&self, int capacity = 16) {
	self.init(allocator::temp());
}

fn bool UnorderedMap.is_initialized(&self) {
	return (bool)self.allocator;
}

fn void UnorderedMap.free(&self) {
	if (!self.allocator) return;
	allocator::free(self.allocator, self.metadatas);
	allocator::free(self.allocator, self.entries);
}

fn bool UnorderedMap.is_empty(self) {
	return self.count == 0;
}

// returns true if entry already exists.
fn bool UnorderedMap.set(&self, Key key, Value value) @operator([]=) {
	// If the map isn't initialized, use the defaults to initialize it.
	if (!self.allocator) {
		self.init(allocator::heap());
	}
	// max load 80%
	if ((float)self.count * 1.25 >= self.metadatas.len) {
		self.reallocator();
	}

	return self.add_entry(key, value);
}

fn bool UnorderedMap.add_entry(&self, Key key, Value value) @local {
	ulong hash = key.myhash();
	ulong mask = self.metadatas.len - 1;
	ulong idx = hash & mask;
	while (true) {
		if (!self.metadatas[idx].used) {
			self.metadatas[idx].used = true;
			self.metadatas[idx].set_fingerprint(hash);
			self.count += 1;
			self.entries[idx].key = key;
			self.entries[idx].value = value;
			return true;
		}

		char fingerprint = (char)(hash >> (64 - 7));
		if (self.metadatas[idx].matches_fingerprint(hash)) {
			Key k = self.entries[idx].key;
			if (k == key) {
				self.entries[idx].value = value;
				return false;
			}
		}

		idx = (idx + 1) & mask;
	}
}

fn Value*! UnorderedMap.get_ref(&self, Key key) {
	if (!self.count) return SearchResult.MISSING?;
	ulong hash = key.myhash();
	ulong mask = self.metadatas.len - 1;
	ulong idx = hash & mask;

	while (true) {
		if (!self.metadatas[idx].used) {
			return SearchResult.MISSING?;
		}
		if (self.metadatas[idx].matches_fingerprint(hash)) {
			Key k = self.entries[idx].key;
			if (k == key) {
				return &self.entries[idx].value;
			}
		}
		idx = (idx + 1) & mask;
	}
}

fn Value* UnorderedMap.get_ref_or_default(&self, Key key, Value default_value) {
	// If the map isn't initialized, use the defaults to initialize it.
	if (!self.allocator) {
		self.init(allocator::heap());
	}
	// max load 80%
	if ((float)self.count * 1.25 >= self.metadatas.len) {
		self.reallocator();
	}
	ulong hash = key.myhash();
	ulong mask = self.metadatas.len - 1;
	ulong idx = hash & mask;

	while (true) {
		if (!self.metadatas[idx].used) {
			self.metadatas[idx].used = true;
			self.metadatas[idx].set_fingerprint(hash);
			self.count += 1;
			self.entries[idx].key = key;
			self.entries[idx].value = default_value;
			return &self.entries[idx].value;
		}
		if (self.metadatas[idx].matches_fingerprint(hash)) {
			Key k = self.entries[idx].key;
			if (k == key) {
				return &self.entries[idx].value;
			}
		}
		idx = (idx + 1) & mask;
	}
}

fn Value! UnorderedMap.get(&self, Key key) {
	return *self.get_ref(key);
}

fn bool UnorderedMap.has_key(&self, Key key) {
	return @ok(self.get_ref(key));
}

fn void UnorderedMap.reallocator(&self) {
	Metadata[] old_metadatas = self.metadatas;
	self.metadatas = allocator::new_array(self.allocator, Metadata, old_metadatas.len * 2);
	Entry[] old_entries = self.entries;
	self.entries = allocator::new_array(self.allocator, Entry, old_entries.len * 2);

	usz old_count = self.count;
	self.count = 0;
	foreach (idx, metadata : old_metadatas) {
		if (metadata.used) {
			self.add_entry(old_entries[idx].key, old_entries[idx].value);
		}
		if (self.count == old_count) break;
	}

	allocator::free(self.allocator, old_metadatas);
	allocator::free(self.allocator, old_entries);
}

macro UnorderedMap.@each(self; @body(key, value)) {
	foreach (idx, metadata : self.metadatas) {
		if (metadata.used) {
			@body(self.entries[idx].key, self.entries[idx].value);
		}
	}
}

// TODO improve iteration?
macro UnorderedMap.@each_entry(self; @body(entry)) {
	foreach (idx, metadata : self.metadatas) {
		if (metadata.used) {
			@body(self.entries[idx]);
		}
	}
}

fn usz UnorderedMap.len(&map) @inline {
	return map.count;
}

fn void! UnorderedMap.remove(&self, Key key) @maydiscard {
	if (!self.count) return SearchResult.MISSING?;
	ulong hash = key.myhash();
	ulong mask = self.metadatas.len - 1;
	ulong idx = hash & mask;

	while (true) {
		switch {
			case self.metadatas[idx].is_tombstone():
				break;
			case !self.metadatas[idx].used:
				return SearchResult.MISSING?;
			case self.entries[idx].key == key:
				// TODO use fingerprint
				self.metadatas[idx].set_tombstone();
				self.count -= 1;
				return;
		}
		idx = (idx + 1) & mask;
	}
}

// Shallow copy on keys string data, only copies the fat pointer.
fn UnorderedMap UnorderedMap.copy(&old, Allocator allocator) {
	UnorderedMap(<Key, Value>) new;
	new.allocator = allocator;
	new.count = old.count;
	new.metadatas = allocator::new_array(new.allocator, Metadata, old.metadatas.len);
	new.metadatas[..] = old.metadatas[..];
	new.entries = allocator::new_array(new.allocator, Entry, old.entries.len);
	new.entries[..] = old.entries[..];

	return new;
}

fn void UnorderedMap.clear(&self) {
	// TODO is this correct?
	mem::zero_volatile(bitcast(self.metadatas, char[]));
	//foreach (&metadata : self.metadatas) {
	//	*metadata = {};
	//}
	self.count = 0;
}

fn usz! UnorderedMap.to_format(&self, Formatter* f) @dynamic {
	usz len;
	len += f.print("{ ")!;
	self.@each_entry(; Entry entry) {
		if (len > 2) len += f.print(", ")!;
		len += f.printf("%s: %s", entry.key, entry.value)!;
    };
	return len + f.print(" }");
}

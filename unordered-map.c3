<*
 @require $defined(Key{}.myhash()) `No .myhash function found on the key`
*>
module unordered_map(<Key, Value>);
import std::collections::list;
import hash;

struct Entry {
	Key key;
	Value value;
}

bitstruct Metadata: char {
	bool used: 0;
	char fingerprint: 1..7;
}

// uses high 7 bits of has for fingerprint, as low bits are
// already used to find the index.
fn void Metadata.set_fingerprint(&m, ulong hash) {
	m.fingerprint = (char)(hash >> (64 - 7));
}

// Does not handle empty strings as keys.
struct UnorderedMap {
	Allocator alloc;
	usz count;
	Metadata[] metadatas;
	Entry[] entries;
}

fn void UnorderedMap.init(&self, Allocator allocator, int capacity = 16) {
	// check that capacity is a power of 2
	assert((capacity & (capacity - 1)) == 0, "capacity must be a power of 2");

	self.alloc = allocator;
	self.metadatas = allocator::new_array(self.alloc, Metadata, capacity);
	self.entries = allocator::new_array(self.alloc, Entry, capacity);
}

// returns true if entry already exists.
fn bool UnorderedMap.set(&self, Key key, Value value) {
	// If the map isn't initialized, use the defaults to initialize it.
	if (!self.alloc) {
		self.init(allocator::heap());
	}
	// max load 80%
	if ((float)self.count * 1.25 >= self.metadatas.len) {
		self.realloc();
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
		if (self.metadatas[idx].fingerprint == fingerprint) {
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
		char fingerprint = (char)(hash >> (64 - 7));
		if (self.metadatas[idx].fingerprint == fingerprint) {
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
	if (!self.alloc) {
		self.init(allocator::heap());
	}
	// max load 80%
	if ((float)self.count * 1.25 >= self.metadatas.len) {
		self.realloc();
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
		char fingerprint = (char)(hash >> (64 - 7));
		if (self.metadatas[idx].fingerprint == fingerprint) {
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

fn void UnorderedMap.realloc(&self) {
	Metadata[] old_metadatas = self.metadatas;
	self.metadatas = allocator::new_array(self.alloc, Metadata, old_metadatas.len * 2);
	Entry[] old_entries = self.entries;
	self.entries = allocator::new_array(self.alloc, Entry, old_entries.len * 2);

	usz old_count = self.count;
	self.count = 0;
	foreach (idx, metadata : old_metadatas) {
		if (metadata.used) {
			self.add_entry(old_entries[idx].key, old_entries[idx].value);
		}
		if (self.count == old_count) break;
	}

	allocator::free(self.alloc, old_metadatas);
	allocator::free(self.alloc, old_entries);
}

macro UnorderedMap.@each(self; @body(key, value)) {
	foreach (idx, metadata : self.metadatas) {
		if (metadata.used) {
			@body(self.entries[idx].key, self.entries[idx].value);
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
		if (!self.metadatas[idx].used) {
			return SearchResult.MISSING?;
		}
		// TODO use fingerprint
		Key k = self.entries[idx].key;
		if (k == key) {
			self.metadatas[idx].used = false;
			self.count -= 1;
			return;
		}
		idx = (idx + 1) % self.metadatas.len;
	}
}

// Shallow copy on keys string data, only copies the fat pointer.
fn UnorderedMap UnorderedMap.copy(&old, Allocator alloc) {
	UnorderedMap(<Key, Value>) new;
	new.alloc = alloc;
	new.count = old.count;
	new.metadatas = allocator::new_array(new.alloc, Metadata, old.metadatas.len);
	new.metadatas[..] = old.metadatas[..];
	new.entries = allocator::new_array(new.alloc, Entry, old.entries.len);
	new.entries[..] = old.entries[..];

	return new;
}

fn void UnorderedMap.clear(&self) {
	foreach (&metadata : self.metadatas) {
		*metadata = {};
	}
	self.count = 0;
}

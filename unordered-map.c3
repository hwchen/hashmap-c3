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

// uses high 7 bits of hash for fingerprint, as low bits are
// already used to find the index.
bitstruct Metadata: char {
	char fingerprint: 0..6;
	bool used: 7;
}

fn char take_fingerprint(ulong hash) @inline {
	return (char)(hash >> (64 - 7));
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
	uint count;
	Metadata* metadatas;
}

struct Header {
	uint capacity;
	Entry* entries;
}

fn void* UnorderedMap.alloc_start(&self) @inline {
	return self.metadatas - Header.sizeof;
}

fn usz alloc_len(uint capacity) @private {
	return entries_start(capacity) + (Entry.sizeof * capacity);
}

fn usz entries_start(uint capacity) @inline @private {
	usz metadatas_len = Header.sizeof + (Metadata.sizeof * capacity);
	return mem::aligned_offset(metadatas_len, 8);
}

fn void* entries_ptr(void* ptr, uint capacity) @inline @private {
	usz metadatas_end = (uptr)ptr + Header.sizeof + (Metadata.sizeof * capacity);
	return mem::aligned_pointer((void*)metadatas_end, 8);
}

fn void UnorderedMap.init(&self, Allocator allocator, uint capacity = 16) {
	// check that capacity is a power of 2
	assert((capacity & (capacity - 1)) == 0, "capacity must be a power of 2");

	self.allocator = allocator;
	void* ptr = allocator::calloc(self.allocator, alloc_len(capacity));
	self.metadatas = ptr + Header.sizeof;
	self.header().capacity = capacity;
	self.header().entries = entries_ptr(ptr, capacity);
}

fn Header* UnorderedMap.header(&self) @inline {
	return bitcast(self.metadatas - Header.sizeof, Header*);
}

fn void UnorderedMap.temp_init(&self, int capacity = 16) {
	self.init(allocator::temp());
}

fn bool UnorderedMap.is_initialized(&self) {
	return (bool)self.allocator;
}

fn void UnorderedMap.free(&self) {
	if (!self.allocator) return;
	allocator::free(self.allocator, self.metadatas - Header.sizeof);
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
	if ((float)self.count * 1.25 >= self.header().capacity) {
		self.reallocator();
	}

	return self.add_entry(key, value);
}

fn bool UnorderedMap.add_entry(&self, Key key, Value value) @local {
	ulong hash = key.myhash();
	uint mask = self.header().capacity - 1;
	ulong idx = hash & mask;
	char fingerprint = take_fingerprint(hash);

	while (true) {
		if (!self.metadatas[idx].used) {
			self.metadatas[idx].used = true;
			self.metadatas[idx].fingerprint = fingerprint;
			self.count += 1;
			self.header().entries[idx].key = key;
			self.header().entries[idx].value = value;
			return true;
		}

		if (self.metadatas[idx].fingerprint == fingerprint) {
			Key k = self.header().entries[idx].key;
			if (k == key) {
				self.header().entries[idx].value = value;
				return false;
			}
		}

		idx = (idx + 1) & mask;
	}
}

fn Value*! UnorderedMap.get_ref(&self, Key key) {
	if (!self.count) return SearchResult.MISSING?;
	ulong hash = key.myhash();
	uint mask = self.header().capacity - 1;
	ulong idx = hash & mask;
	char fingerprint = take_fingerprint(hash);

	while (true) {
		if (!self.metadatas[idx].used) {
			return SearchResult.MISSING?;
		}
		if (self.metadatas[idx].fingerprint == fingerprint) {
			Key k = self.header().entries[idx].key;
			if (k == key) {
				return &self.header().entries[idx].value;
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
	if ((float)self.count * 1.25 >= self.header().capacity) {
		self.reallocator();
	}
	ulong hash = key.myhash();
	uint mask = self.header().capacity - 1;
	ulong idx = hash & mask;
	char fingerprint = take_fingerprint(hash);

	while (true) {
		if (!self.metadatas[idx].used) {
			self.metadatas[idx].used = true;
			self.metadatas[idx].fingerprint = fingerprint;
			self.count += 1;
			self.header().entries[idx].key = key;
			self.header().entries[idx].value = default_value;
			return &self.header().entries[idx].value;
		}
		if (self.metadatas[idx].fingerprint == fingerprint) {
			Key k = self.header().entries[idx].key;
			if (k == key) {
				return &self.header().entries[idx].value;
			}
		}
		idx = (idx + 1) & mask;
	}
}

fn Value! UnorderedMap.get(&self, Key key) {
	return *self.get_ref(key) @inline;
}

fn bool UnorderedMap.has_key(&self, Key key) {
	return @ok(self.get_ref(key));
}

fn void UnorderedMap.reallocator(&self) {
	uint old_capacity = self.header().capacity;
	uint capacity = self.header().capacity * 2;
	Metadata* old_metadatas = self.metadatas;
	Entry* old_entries = self.header().entries;

	void* ptr = allocator::calloc(self.allocator, Header.sizeof + (Metadata.sizeof * capacity) + (Entry.sizeof * capacity));
	self.metadatas = ptr + Header.sizeof;
	self.header().capacity = capacity;
	self.header().entries = entries_ptr(ptr, capacity);

	usz old_count = self.count;
	self.count = 0;
	foreach (idx, metadata : old_metadatas[:old_capacity]) {
		if (metadata.used) {
			self.add_entry(old_entries[idx].key, old_entries[idx].value);
		}
		if (self.count == old_count) break;
	}

	allocator::free(self.allocator, old_metadatas - Header.sizeof);
}

macro UnorderedMap.@each(self; @body(key, value)) {
	foreach (idx, metadata : self.metadatas[:self.header().capacity]) {
		if (metadata.used) {
			@body(self.header().entries[idx].key, self.header().entries[idx].value);
		}
	}
}

// TODO improve iteration?
macro UnorderedMap.@each_entry(self; @body(entry)) {
	foreach (idx, metadata : self.metadatas[:self.header().capacity]) {
		if (metadata.used) {
			@body(self.header().entries[idx]);
		}
	}
}

fn usz UnorderedMap.len(&map) @inline {
	return map.count;
}

fn void! UnorderedMap.remove(&self, Key key) @maydiscard {
	if (!self.count) return SearchResult.MISSING?;
	ulong hash = key.myhash();
	uint mask = self.header().capacity - 1;
	ulong idx = hash & mask;
	char fingerprint = take_fingerprint(hash);

	while (true) {
		switch {
			case self.metadatas[idx].is_tombstone():
				break;
			case !self.metadatas[idx].used:
				return SearchResult.MISSING?;
			case self.metadatas[idx].fingerprint == fingerprint:
				if (self.header().entries[idx].key == key) {
					self.metadatas[idx].set_tombstone();
					self.count -= 1;
					return;
				}
		}
		idx = (idx + 1) & mask;
	}
}

// Shallow copy on keys string data, only copies the fat pointer.
fn UnorderedMap UnorderedMap.copy(&old, Allocator allocator) {
	UnorderedMap(<Key, Value>) new;
	new.allocator = allocator;
	new.count = old.count;
	void* ptr = allocator::calloc(new.allocator, alloc_len(old.header().capacity));
	ptr[:alloc_len(old.header().capacity)] = old.alloc_start()[:alloc_len(old.header().capacity)];
	new.metadatas = ptr + Header.sizeof;

	return new;
}

fn void UnorderedMap.clear(&self) {
	// TODO is this correct?
	mem::zero_volatile(bitcast(self.metadatas[:self.header().capacity], char[]));
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

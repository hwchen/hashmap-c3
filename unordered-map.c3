<*
 @require $defined(Key{}.myhash()) `No .myhash function found on the key`
*>
module unordered_map(<Key, Value>);
import std::collections::list;
import std::io;
import hash;

// Does not handle empty strings as keys.
struct UnorderedMap (Printable) {
	Allocator allocator;
	uint count;
	Metadata* metadatas;
}

fn void UnorderedMap.init(&self, Allocator allocator, uint capacity = 16) {
	// check that capacity is a power of 2
	assert((capacity & (capacity - 1)) == 0, "capacity must be a power of 2");

	self.allocator = allocator;
	void* ptr = allocator::calloc(self.allocator, alloc_len(capacity));
	self.metadatas = ptr + Header.sizeof;
	self.header().capacity = capacity;
	self.header().keys = keys_ptr(ptr, capacity);
	self.header().values = values_ptr(ptr, capacity);
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
	if ((float)self.count * 1.25 >= self.capacity()) {
		self.reallocator();
	}
	return self.add_entry(key, value);
}

fn bool UnorderedMap.add_entry(&self, Key key, Value value) @local {
	ulong hash = key.myhash();
	uint mask = self.capacity() - 1;
	ulong idx = hash & mask;
	char fingerprint = take_fingerprint(hash);

	// TODO try pointer?
	Metadata metadata = self.metadatas[idx];
	while (metadata.is_used) {
		if (metadata.fingerprint == fingerprint) {
			Key k = self.keys()[idx];
			if (k == key) {
				self.values()[idx] = value;
				return false;
			}
		}
		idx = (idx + 1) & mask;
		metadata = self.metadatas[idx];
	}
	// Found an empty slot
	self.metadatas[idx].is_used = true;
	self.metadatas[idx].fingerprint = fingerprint;
	self.count += 1;
	self.keys()[idx] = key;
	self.values()[idx] = value;
	return true;
}

fn Value*! UnorderedMap.get_ref(&self, Key key) {
	if (!self.count) return SearchResult.MISSING?;
	ulong hash = key.myhash();
	uint mask = self.capacity() - 1;
	ulong idx = hash & mask;
	char fingerprint = take_fingerprint(hash);

	Metadata metadata = self.metadatas[idx];
	while (metadata.is_used) {
		if (metadata.fingerprint == fingerprint) {
			Key k = self.keys()[idx];
			if (k == key) {
				return &self.values()[idx];
			}
		}
		idx = (idx + 1) & mask;
		metadata = self.metadatas[idx];
	}
	return SearchResult.MISSING?;
}

fn Value* UnorderedMap.get_ref_or_default(&self, Key key, Value default_value) {
	// If the map isn't initialized, use the defaults to initialize it.
	if (!self.allocator) {
		self.init(allocator::heap());
	}
	// max load 80%
	if ((float)self.count * 1.25 >= self.capacity()) {
		self.reallocator();
	}
	ulong hash = key.myhash();
	uint mask = self.capacity() - 1;
	ulong idx = hash & mask;
	char fingerprint = take_fingerprint(hash);

	Metadata metadata = self.metadatas[idx];
	while (metadata.is_used) {
		if (metadata.fingerprint == fingerprint) {
			Key k = self.keys()[idx];
			if (k == key) {
				return &self.values()[idx];
			}
		}
		idx = (idx + 1) & mask;
		metadata = self.metadatas[idx];
	}
	// Found empty slot
	self.metadatas[idx].is_used = true;
	self.metadatas[idx].fingerprint = fingerprint;
	self.count += 1;
	self.keys()[idx] = key;
	self.values()[idx] = default_value;
	return &self.values()[idx];
}

fn Value! UnorderedMap.get(&self, Key key) {
	return *self.get_ref(key) @inline;
}

fn bool UnorderedMap.has_key(&self, Key key) {
	return @ok(self.get_ref(key));
}

fn void UnorderedMap.reallocator(&self) {
	uint old_capacity = self.capacity();
	uint capacity = self.capacity() * 2;
	Metadata* old_metadatas = self.metadatas;
	Key* old_keys = self.keys();
	Value* old_values = self.values();

	void* ptr = allocator::calloc(self.allocator, Header.sizeof + (Metadata.sizeof * capacity) + (Entry.sizeof * capacity));
	self.metadatas = ptr + Header.sizeof;
	self.header().capacity = capacity;
	self.header().keys = keys_ptr(ptr, capacity);
	self.header().values = values_ptr(ptr, capacity);

	usz old_count = self.count;
	self.count = 0;
	foreach (idx, metadata : old_metadatas[:old_capacity]) {
		if (metadata.is_used) {
			self.add_entry(old_keys[idx], old_values[idx]);
		}
		if (self.count == old_count) break;
	}

	allocator::free(self.allocator, old_metadatas - Header.sizeof);
}

macro UnorderedMap.@each(self; @body(key, value)) {
	foreach (idx, metadata : self.metadatas[:self.capacity()]) {
		if (metadata.is_used) {
			@body(self.keys()[idx], self.values()[idx]);
		}
	}
}

// TODO improve iteration?
macro UnorderedMap.@each_entry(self; @body(entry)) {
	foreach (idx, metadata : self.metadatas[:self.capacity()]) {
		if (metadata.is_used) {
			@body({self.keys()[idx], self.values()[idx]});
		}
	}
}

fn usz UnorderedMap.len(&map) @inline {
	return map.count;
}

fn void! UnorderedMap.remove(&self, Key key) @maydiscard {
	if (!self.count) return SearchResult.MISSING?;
	ulong hash = key.myhash();
	uint mask = self.capacity() - 1;
	ulong idx = hash & mask;
	char fingerprint = take_fingerprint(hash);

	Metadata* metadata = &self.metadatas[idx];
	while (metadata.is_used) {
		switch {
			case metadata.is_tombstone():
				break;
			case metadata.fingerprint == fingerprint:
				if (self.keys()[idx] == key) {
					metadata.set_tombstone();
					self.count -= 1;
					return;
				}
		}
		idx = (idx + 1) & mask;
		metadata = &self.metadatas[idx];
	}
	// Found empty slot
	return SearchResult.MISSING?;
}

// Shallow copy on keys string data, only copies the fat pointer.
fn UnorderedMap UnorderedMap.copy(&old, Allocator allocator) {
	UnorderedMap(<Key, Value>) new;
	new.allocator = allocator;
	new.count = old.count;
	void* ptr = allocator::calloc(new.allocator, alloc_len(old.capacity()));
	ptr[:alloc_len(old.capacity())] = old.alloc_start()[:alloc_len(old.capacity())];
	new.metadatas = ptr + Header.sizeof;

	return new;
}

fn void UnorderedMap.clear(&self) {
	// TODO is this correct?
	mem::zero_volatile(bitcast(self.metadatas[:self.capacity()], char[]));
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

// ======= Helper structs/methods/fns =======

struct Entry {
	Key key;
	Value value;
}

struct Header {
	uint capacity;
	Key* keys;
	Value* values;
}

// uses high 7 bits of hash for fingerprint, as low bits are
// already used to find the index.
bitstruct Metadata: char {
	char fingerprint: 0..6;
	bool is_used: 7;
}

fn char take_fingerprint(ulong hash) @inline {
	return (char)(hash >> (64 - 7));
}

fn void Metadata.set_tombstone(&m) @inline {
	m.fingerprint = 1;
	m.is_used = false;
}

fn bool Metadata.is_tombstone(m) @inline {
	// depends on layout of bitstruct
	return (char)m == 1;
}

fn void* UnorderedMap.alloc_start(&self) @inline {
	return self.metadatas - Header.sizeof;
}

fn usz alloc_len(uint capacity) @inline @private {
	return values_start(capacity) + (Value.sizeof * capacity);
}

fn usz keys_start(uint capacity) @inline @private {
	usz metadatas_len = Header.sizeof + (Metadata.sizeof * capacity);
	return mem::aligned_offset(metadatas_len, 8);
}

fn usz values_start(uint capacity) @inline @private {
	usz values_len = keys_start(capacity) + (Key.sizeof * capacity);
	return mem::aligned_offset(values_len, 8);
}

fn void* keys_ptr(void* ptr, uint capacity) @inline @private {
	usz metadatas_end = (uptr)ptr + Header.sizeof + (Metadata.sizeof * capacity);
	return mem::aligned_pointer((void*)metadatas_end, 8);
}

fn void* values_ptr(void* ptr, uint capacity) @inline @private {
	void* keys_end = keys_ptr(ptr, capacity) + (Key.sizeof * capacity);
	return mem::aligned_pointer(keys_end, 8);
}

fn Header* UnorderedMap.header(&self) @inline {
	return (Header*)(self.metadatas - Header.sizeof);
}

fn Key* UnorderedMap.keys(&self) @inline {
	return self.header().keys;
}

fn Value* UnorderedMap.values(&self) @inline {
	return self.header().values;
}

fn uint UnorderedMap.capacity(&self) @inline {
	return self.header().capacity;
}

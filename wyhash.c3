module wyhash;
import std::core::bitorder;

const ulong[4] WYHASH_SECRET = {
	0xa0761d6478bd642f,
	0xe7037ed1a0b428db,
	0x8ebc6af09c88c6e3,
	0x589965cc75374cc3,
};

struct Wyhash {
	ulong a;
	ulong b;
	ulong[3] state;
	usz total_len;
	char[48] buf;
	usz buf_len;
}

fn void Wyhash.init(&self, ulong seed) {
	self.state[0] = seed ^ mix(seed ^ WYHASH_SECRET[0], WYHASH_SECRET[1]);
	self.state[1] = self.state[0];
	self.state[2] = self.state[0];
}

// This is subtly different from other hash function update calls. Wyhash requires the last
// full 48-byte block to be run through final1 if is exactly aligned to 48-bytes.
fn void Wyhash.update(&self, char[] input) {
	self.total_len += input.len;

	if (input.len <= 48 - self.buf_len) {
		mem::copy(self.buf[self.buf_len..].ptr, input.ptr, input.len);
		self.buf_len += input.len;
		return;
	}

	usz i;

	if (self.buf_len > 0) {
		i = 48 - self.buf_len;
		mem::copy(self.buf[self.buf_len..].ptr, input[0..].ptr, i);
		self.round(&self.buf);
		self.buf_len = 0;
	}

	while (i + 48 < input.len) {
		self.round(input[i:48]);
		i += 48;
	}

	char[] remaining_bytes = input[i..];
	if (remaining_bytes.len < 16 && i >= 48) {
		usz rem = 16 - remaining_bytes.len;
		mem::copy(self.buf[self.buf.len - rem ..].ptr, input[i - rem..].ptr, i);
	}
	mem::copy(self.buf[0..].ptr, remaining_bytes.ptr, remaining_bytes.len);
	self.buf_len = remaining_bytes.len;
}

fn ulong Wyhash.final(&self) {
	char[] input = self.buf[0:self.buf_len];
	Wyhash new_self = self.shallow_copy(); // ensure idempotency

	if (self.total_len <= 16) {
		new_self.small_key(input);
	} else {
		usz offset;
		if (self.buf_len < 16) {
			char[16] scratch;
			usz rem = 16 - self.buf_len;
			mem::copy(scratch[0..].ptr, self.buf[self.buf.len - rem..].ptr, rem);
			mem::copy(scratch[rem..].ptr, self.buf[0..].ptr, self.buf.len);

			// Same as input but with additional bytes preceding start in case of a short buffer
			input = &scratch;
			offset = rem;
		}

		new_self.final0();
		new_self.final1(input, offset);
	}

	return new_self.final2();
}

// Copies the core wyhash state but not any internal buffers.
fn Wyhash Wyhash.shallow_copy(&self) @inline {
	return {
		.a = self.a,
		.b = self.b,
		.state = self.state,
		.total_len = self.total_len,
		//.buf = undefined,
		//.buf_len = undefined,
	};
}

fn void Wyhash.small_key(&self, char[] input) @inline {
	assert(input.len <= 16);

	if (input.len >= 4) {
		usz end = input.len - 4;
		usz quarter = (input.len >> 3) << 2;
		self.a = (@read(UIntLE, input[0..]) << 32) | @read(UIntLE, input[quarter..]);
		self.b = (@read(UIntLE, input[end..]) << 32) | @read(UIntLE, input[end - quarter ..]);
	} else if (input.len > 0) {
		self.a = ((ulong)(input[0]) << 16) | ((ulong)(input[input.len >> 1]) << 8) | input[input.len - 1];
		self.b = 0;
	} else {
		self.a = 0;
		self.b = 0;
	}
}

fn void Wyhash.round(&self, char[] input) @inline {
	assert(input.len == 48);
	// TODO inline
	for (int i; i < 3; i += 1) {
		ulong a = @read(ULongLE, input[8 * (2 * i) ..]);
		ulong b = @read(ULongLE, input[8 * (2 * i + 1) ..]);
		self.state[i] = mix(a ^ WYHASH_SECRET[i + 1], b ^ self.state[i]);
	}
}

// TODO can just remove macro?
macro ulong @read($Integer, char[] data) {
	return bitorder::read(data, $Integer);
}

fn void mum(ulong* a, ulong* b) @inline {
	// Wrapping multiplication
	uint128 x = (uint128)(*a) * (*b);
	// Truncates
	*a = (ulong)x;
	*b = (ulong)(x >> 64);
}

fn ulong mix(ulong a_, ulong b_) @inline {
	ulong a = a_;
	ulong b = b_;
	mum(&a, &b);
	return a ^ b;
}

fn void Wyhash.final0(&self) @inline {
	self.state[0] ^= self.state[1] ^ self.state[2];
}

// input_lb must be at least 16-bytes long (in shorter key cases the small_key function will be
// used instead). We use an index into a slice to for comptime processing as opposed to if we
// used pointers.
fn void Wyhash.final1(&self, char[] input_lb, usz start_pos) @inline {
	assert(input_lb.len >= 16);
	assert(input_lb.len - start_pos <= 48);
	char[] input = input_lb[start_pos..];

	usz i;
	while (i + 16 < input.len) {
		self.state[0] = mix(@read(ULongLE, input[i..]) ^ WYHASH_SECRET[1], @read(ULongLE, input[i + 8 ..]) ^ self.state[0]);
		i += 16;
	}

	self.a = @read(ULongLE, input_lb[input_lb.len - 16:8]);
	self.b = @read(ULongLE, input_lb[input_lb.len - 8:8]);
}

fn ulong Wyhash.final2(&self) @inline {
	self.a ^= WYHASH_SECRET[1];
	self.b ^= self.state[0];
	mum(&self.a, &self.b);
	return mix(self.a ^ WYHASH_SECRET[0] ^ self.total_len, self.b ^ WYHASH_SECRET[1]);
}

fn ulong hash(ulong seed, char[] input) {
	Wyhash self;
	self.init(seed);

	if (input.len <= 16) {
		self.small_key(input);
	} else {
		usz i;
		if (input.len >= 48) {
			while (i + 48 < input.len) {
				self.round(input[i:48]);
				i += 48;
			}
			self.final0();
		}
		self.final1(input, i);
	}

	self.total_len = input.len;
	return self.final2();
}

struct TestVector{
	ulong expected;
	ulong seed;
	char[] input;
}

// Run https://github.com/wangyi-fudan/wyhash/blob/77e50f267fbc7b8e2d09f2d455219adb70ad4749/test_vector.cpp directly.
TestVector[?] vectors = {
	{ .seed = 0, .expected = 0x409638ee2bde459,  .input = "" },
	{ .seed = 1, .expected = 0xa8412d091b5fe0a9, .input = "a" },
	{ .seed = 2, .expected = 0x32dd92e4b2915153, .input = "abc" },
	{ .seed = 3, .expected = 0x8619124089a3a16b, .input = "message digest" },
	{ .seed = 4, .expected = 0x7a43afb61d7f5f40, .input = "abcdefghijklmnopqrstuvwxyz" },
	{ .seed = 5, .expected = 0xff42329b90e50d58, .input = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789" },
	{ .seed = 6, .expected = 0xc39cab13b115aad3, .input = "12345678901234567890123456789012345678901234567890123456789012345678901234567890" },
};

fn void test_vectors() @test {
	foreach (e : vectors) {
		assert(e.expected == wyhash::hash(e.seed, e.input));
	}
}

module hash;
import std::hash::fnv64a;

macro ulong int.myhash(int i) => fnv64a::encode(@as_char_view(i));
macro ulong uint.myhash(uint i) => fnv64a::encode(@as_char_view(i));
macro ulong short.myhash(short s) => fnv64a::encode(@as_char_view(s));
macro ulong ushort.myhash(ushort s) => fnv64a::encode(@as_char_view(s));
macro ulong char.myhash(char c) => fnv64a::encode(@as_char_view(c));
macro ulong ichar.myhash(ichar c) => fnv64a::encode(@as_char_view(c));
macro ulong long.myhash(long i) => fnv64a::encode(@as_char_view(i));
macro ulong ulong.myhash(ulong i) => fnv64a::encode(@as_char_view(i));
macro ulong int128.myhash(int128 i) => fnv64a::encode(@as_char_view(i));
macro ulong uint128.myhash(uint128 i) => fnv64a::encode(@as_char_view(i));
macro ulong bool.myhash(bool b) => fnv64a::encode(@as_char_view(b));
macro ulong typeid.myhash(typeid t) => ((ulong)(uptr)t).myhash();
macro ulong String.myhash(String c) => fnv64a::encode(c);
macro ulong char[].myhash(char[] c) => fnv64a::encode(c);

module hash;
import std::hash::fnv64a;

macro ulong int.myhash(int i) => i;
macro ulong uint.myhash(uint i) => i;
macro ulong short.myhash(short s) => s;
macro ulong ushort.myhash(ushort s) => s;
macro ulong char.myhash(char c) => c;
macro ulong ichar.myhash(ichar c) => c;
macro ulong long.myhash(long i) => i;
macro ulong ulong.myhash(ulong i) => i;
macro ulong int128.myhash(int128 i) => (ulong)((i >> 96) ^ (i >> 64) ^ (i >> 32) ^ i);
macro ulong uint128.myhash(uint128 i) => (ulong)((i >> 96) ^ (i >> 64) ^ (i >> 32) ^ i);
macro ulong bool.myhash(bool b) => (ulong)b;
macro ulong typeid.myhash(typeid t) => ((ulong)(uptr)t).myhash();
macro ulong String.myhash(String c) => (ulong)fnv64a::encode(c);
macro ulong char[].myhash(char[] c) => (ulong)fnv64a::encode(c);

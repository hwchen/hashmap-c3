module hash;
import std::hash::fnv64a;

macro ulong int.myhash(int i) => fnv64a::encode(&&bitcast(i, char[4]));
macro ulong uint.myhash(uint i) => fnv64a::encode(&&bitcast(i, char[4]));
macro ulong short.myhash(short s) => fnv64a::encode(&&bitcast(i, char[2]));
macro ulong ushort.myhash(ushort s) => fnv64a::encode(&&bitcast(i, char[2]));
macro ulong char.myhash(char c) => fnv64a::encode(&&bitcast(i, char[1]));
macro ulong ichar.myhash(ichar c) => fnv64a::encode(&&bitcast(i, char[1]));
macro ulong long.myhash(long i) => fnv64a::encode(&&bitcast(i, char[8]));
macro ulong ulong.myhash(ulong i) => fnv64a::encode(&&bitcast(i, char[8]));
macro ulong int128.myhash(int128 i) => fnv64a::encode(&&bitcast(i, char[16]));
macro ulong uint128.myhash(uint128 i) => fnv64a::encode(&&bitcast(i, char[16]));
macro ulong bool.myhash(bool b) => fnv64a::encode(&&bitcast(i, char[i]));
macro ulong typeid.myhash(typeid t) => ((ulong)(uptr)t).myhash();
macro ulong String.myhash(String c) => fnv64a::encode(c);
macro ulong char[].myhash(char[] c) => fnv64a::encode(c);

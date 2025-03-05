module hash;
import std::core::mem;
import wyhash;

macro ulong int.myhash(int i) => wyhash::hash(0, &&bitcast(i, char[4]));
macro ulong uint.myhash(uint i) => wyhash::hash(0, &&bitcast(i, char[4]));
macro ulong short.myhash(short s) => wyhash::hash(0, &&bitcast(s, char[2]));
macro ulong ushort.myhash(ushort s) => wyhash::hash(0, &&bitcast(s, char[2]));
macro ulong char.myhash(char c) => wyhash::hash(0, &&bitcast(c, char[1]));
macro ulong ichar.myhash(ichar c) => wyhash::hash(0, &&bitcast(c, char[1]));
macro ulong long.myhash(long i) => wyhash::hash(0, &&bitcast(i, char[8]));
macro ulong ulong.myhash(ulong i) => wyhash::hash(0, &&bitcast(i, char[8]));
macro ulong int128.myhash(int128 i) => wyhash::hash(0, &&bitcast(i, char[16]));
macro ulong uint128.myhash(uint128 i) => wyhash::hash(0, &&bitcast(i, char[16]));
macro ulong bool.myhash(bool b) => wyhash::hash(0, &&bitcast(b, char[i]));
macro ulong typeid.myhash(typeid t) => ((ulong)(uptr)t).myhash();
macro ulong String.myhash(String c) => wyhash::hash(0, c);
macro ulong char[].myhash(char[] c) => wyhash::hash(0, c);

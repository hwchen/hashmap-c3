module hash;
import std::core::mem;
import wyhash;

macro ulong int.myhash(int i) => wyhash::hash(0, @as_char_view(i));
macro ulong uint.myhash(uint i) => wyhash::hash(0, @as_char_view(i));
macro ulong short.myhash(short s) => wyhash::hash(0, @as_char_view(s));
macro ulong ushort.myhash(ushort s) => wyhash::hash(0, @as_char_view(s));
macro ulong char.myhash(char c) => wyhash::hash(0, @as_char_view(c));
macro ulong ichar.myhash(ichar c) => wyhash::hash(0, @as_char_view(c));
macro ulong long.myhash(long i) => wyhash::hash(0, @as_char_view(i));
macro ulong ulong.myhash(ulong i) => wyhash::hash(0, @as_char_view(i));
macro ulong int128.myhash(int128 i) => wyhash::hash(0, @as_char_view(i));
macro ulong uint128.myhash(uint128 i) => wyhash::hash(0, @as_char_view(i));
macro ulong bool.myhash(bool b) => wyhash::hash(0, @as_char_view(b));
macro ulong typeid.myhash(typeid t) => ((ulong)(uptr)t).myhash();
macro ulong String.myhash(String c) => wyhash::hash(0, c);
macro ulong char[].myhash(char[] c) => wyhash::hash(0, c);

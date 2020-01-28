module openbb.common;

public import openbb.log;
public import openbb.exceptions;

struct RGBA
{
	ubyte r;
	ubyte g;
	ubyte b;
	ubyte a;
}

import std.string;

// type aliases for D2
package
{
	alias const(char) cchar;
	alias const(wchar) cwchar;
	alias const(dchar) cdchar;
	alias immutable(char) ichar;
	alias immutable(wchar) iwchar;
	alias immutable(dchar) idchar;
	alias const(char)[] cstring;
}
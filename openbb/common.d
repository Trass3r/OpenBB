module openbb.common;

public import openbb.log;

import std.string;

/*
version(Windows)
{
	version(X86)
	{
		pragma(lib, "luajit.lib");
	}
	else
		pragma(lib, "lua51.lib");
	
}*/

///
struct RGBA
{
align(1):
	ubyte r;
	ubyte g;
	ubyte b;
	ubyte a;

	string toString()
	{
		return std.string.format("[%d,%d,%d,%d]", r,g,b,a);
	}
}

//type aliases for D2
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
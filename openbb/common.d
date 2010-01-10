module openbb.common;

import std.string;

import openbb.theapp;

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

TheApp theApp;

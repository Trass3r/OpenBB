module openbb.log;

import std.stdio;


/// logging function
void log(T...)(T t)
{
	write(t);
}

/// ditto
void logln(T...)(T t)
{
	writeln(t);
}

/// logging function, formatted version
void logf(T...)(T t)
{
	writef(t);
}

/// logging function
void logfln(T...)(T t)
{
	writefln(t);
}

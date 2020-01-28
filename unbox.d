module unbox;

import openbb.io.boxfile;

import std.stdio;

int main(string[] args)
{
	writef("Beasts and Bumpkins UnBOX v1.0\nCopyright (c) 2008 Trass3r.\n\n");
	if (args.length < 2)
	{
		Usage();
		return -1;
	}
	auto file = new BOXFile(args[1]);
	file.extractAll();
	return 0;
}

void Usage()
{
	writef("Usage:\nUnBOX filename\n");
}

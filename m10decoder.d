/**
 *	this creates a command-line tool to convert m10 to wave files
 */
module m10decoder;

import openbb.io.boxfile;
import openbb.io.m10file;

import std.stdio;
import std.file;

int main(string[] args)
{
	if (args.length < 2)
	{
		writeln("Beasts and Bumpkins .m10 Decoder");
		writeln("Usage: " ~ args[0] ~ " {SPEECHx.BOX}");
		return 1;
	}

	string inputFilename = args[1];

	auto speechbox = new BOXFile(inputFilename);
	for (uint i=0; i<speechbox.numFiles; i++)
	{
		writeln(speechbox.entryName(i)[0 .. $-4] ~ ".wav");
		auto m10 = new M10File(speechbox[i]);
		std.file.write(speechbox.entryName(i)[0 .. $-4] ~ ".wav", m10.toWav());
	}
	return 0;
}